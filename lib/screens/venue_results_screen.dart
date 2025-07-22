// File: lib/screens/venue_results_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// Import the detail screen we will create
import 'vendor_detail_screen.dart';

class VenueResultsScreen extends StatefulWidget {
  // Keep eventDetails if you need them for filtering or display
  final Map<String, dynamic> eventDetails;

  const VenueResultsScreen({
    super.key,
    required this.eventDetails,
  });

  @override
  State<VenueResultsScreen> createState() => _VenueResultsScreenState();
}

class _VenueResultsScreenState extends State<VenueResultsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // --- State for Fetched Data ---
  bool _isLoading = true;
  List<DocumentSnapshot> _venueSellers = []; // Store seller documents that offer venues
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchVenues(); // Fetch venues when screen loads
  }

  // --- Fetch Venues from Firestore ---
  Future<void> _fetchVenues() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null; // Clear previous errors
    });

    try {
      // Query sellers who have items in the 'venue' category.
      // This requires querying the 'items' subcollection or having relevant info on the seller doc.

      // --- METHOD 1: Querying sellers based on a field indicating they offer venues ---
      // (Requires adding e.g., a 'categoriesOffered': ['venue', 'catering'] array field to sellers)
      /*
      final querySnapshot = await _firestore
          .collection('sellers')
          .where('categoriesOffered', arrayContains: 'venue')
           // --- ADD MORE FILTERS BASED ON eventDetails ---
          // Example: Filter by city (requires city_lowercase field)
          // .where('address.city_lowercase', isEqualTo: widget.eventDetails['city']?.toLowerCase())
          // Example: Filter by verified status
          // .where('isVerified', isEqualTo: true)
          // --- END FILTERS ---
          .limit(20) // Limit results
          .get();
      */

      // --- METHOD 2: Querying items first, then getting unique sellers ---
      // (Can be less efficient if many venue items exist, but doesn't require modifying seller doc)
      final itemsSnapshot = await _firestore
          .collection('items')
          .where('category', isEqualTo: 'venue')
      // Optionally add filters based on item properties if available (e.g., capacity, though capacity might be on the seller doc)
          .limit(50) // Limit item fetch to avoid too many seller lookups
          .get();

      if (itemsSnapshot.docs.isEmpty) {
        if(mounted) setState(() { _venueSellers = []; _isLoading = false; });
        return;
      }

      // Get unique seller IDs from the found venue items
      final sellerIds = itemsSnapshot.docs.map((doc) => doc.data()?['sellerId'] as String?).where((id) => id != null).toSet().toList();

      if (sellerIds.isEmpty) {
        if(mounted) setState(() { _venueSellers = []; _isLoading = false; });
        return;
      }

      // Fetch the actual seller documents for these IDs
      // Use 'whereIn' query (limited to 30 IDs per query by Firestore V9+)
      // If more than 30, you need multiple queries. Let's handle up to 30 for now.
      QuerySnapshot querySnapshot;
      if (sellerIds.length <= 30) {
        querySnapshot = await _firestore
            .collection('sellers')
            .where(FieldPath.documentId, whereIn: sellerIds)
        // You can add filters here too, e.g., isVerified
        // .where('isVerified', isEqualTo: true)
            .limit(20) // Limit final results
            .get();
      } else {
        // Handle more than 30 IDs if necessary (e.g., multiple queries or different approach)
        // For now, just take the first 30
        querySnapshot = await _firestore
            .collection('sellers')
            .where(FieldPath.documentId, whereIn: sellerIds.sublist(0, 30))
            .limit(20)
            .get();
        debugPrint("Warning: More than 30 potential venue sellers found, only fetching details for the first 30 item matches.");
      }

      // --- END METHOD 2 ---


      if (mounted) {
        setState(() {
          _venueSellers = querySnapshot.docs;
          _isLoading = false;
        });
        debugPrint("Fetched ${_venueSellers.length} venue sellers.");
      }
    } catch (e) {
      debugPrint("Error fetching venues: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Failed to load venues: ${e.toString()}";
        });
      }
    }
  }

  // Function to navigate to the detail screen
  void _navigateToVendorDetail(DocumentSnapshot sellerDoc) {
    // Pass the Seller Document ID to the detail screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VendorDetailScreen(
          sellerId: sellerDoc.id,
          eventDetails: widget.eventDetails, // Pass event details along
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Matching Venues'),
        actions: [
          // Refresh Button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _fetchVenues, // Allow refresh
            tooltip: 'Refresh Results',
          )
          // TODO: Re-add filter button later if needed
          // IconButton(icon: const Icon(Icons.filter_list), onPressed: _showFilterSheet),
        ],
      ),
      body: _buildBody(theme, colorScheme), // Use helper to build body
    );
  }


  // --- Helper to build the body content ---
  Widget _buildBody(ThemeData theme, ColorScheme colorScheme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text(_errorMessage!, style: TextStyle(color: Colors.red[700]), textAlign: TextAlign.center)));
    }
    if (_venueSellers.isEmpty) {
      return const Center(child: Padding(padding: EdgeInsets.all(16.0), child: Text('No venues found matching your criteria.', textAlign: TextAlign.center)));
    }

    // Display fetched venues
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _venueSellers.length,
      itemBuilder: (context, index) {
        final doc = _venueSellers[index];
        // --- Extract data safely from DocumentSnapshot ---
        final data = doc.data() as Map<String, dynamic>? ?? {};
        final businessName = data['businessName'] as String? ?? 'N/A';
        // Access nested address fields safely
        final addressMap = data['address'] as Map<String, dynamic>?;
        final city = addressMap?['city'] as String? ?? '';
        final state = addressMap?['state'] as String? ?? '';
        final location = city.isNotEmpty && state.isNotEmpty ? '$city, $state' : city + state;
        // Access rating safely
        final rating = (data['rating'] as num?)?.toDouble() ?? 0.0;
        // Use photoUrl or a placeholder
        final imageUrl = data['photoUrl'] as String?; // Use main photo if available
        final coverImageUrl = data['coverImageUrl'] as String?; // Use cover for card header

        return Card(
          clipBehavior: Clip.antiAlias, // Ensures image respects rounded corners
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: InkWell( // Make the whole card tappable
            onTap: () => _navigateToVendorDetail(doc), // Navigate on tap
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Image Header ---
                SizedBox(
                  height: 180,
                  width: double.infinity,
                  child: (coverImageUrl != null && coverImageUrl.isNotEmpty)
                      ? Image.network(
                    coverImageUrl,
                    fit: BoxFit.cover,
                    // Loading and Error builders for network image
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(child: CircularProgressIndicator(strokeWidth: 2.0));
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container( color: Colors.grey[300], child: Icon(Icons.business, size: 50, color: Colors.grey[600]));
                    },
                  )
                  // Placeholder if no image URL
                      : Container( color: colorScheme.primary.withOpacity(0.1), child: Icon(Icons.location_city, size: 60, color: colorScheme.primary.withOpacity(0.5))),
                ),
                // --- Text Details ---
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text( businessName, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      if (location.isNotEmpty) // Show location only if available
                        Row( children: [ const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey), const SizedBox(width: 4), Text(location, style: theme.textTheme.bodyMedium), ], ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Rating
                          Row( children: [ const Icon(Icons.star, color: Colors.amber, size: 18), const SizedBox(width: 4), Text(rating.toStringAsFixed(1), style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)), if ((data['reviewCount'] as int? ?? 0) > 0) Text(' (${data['reviewCount']})', style: theme.textTheme.bodySmall), ],),
                          // You could add price indication here if available
                          // Text('\$\$\$', style: theme.textTheme.titleSmall?.copyWith(color: colorScheme.primary)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}