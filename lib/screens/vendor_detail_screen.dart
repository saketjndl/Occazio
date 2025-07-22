// File: lib/screens/vendor_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VendorDetailScreen extends StatefulWidget {
  final String sellerId;
  final Map<String, dynamic> eventDetails;

  const VendorDetailScreen({
    super.key,
    required this.sellerId,
    required this.eventDetails,
  });

  @override
  State<VendorDetailScreen> createState() => _VendorDetailScreenState();
}

class _VendorDetailScreenState extends State<VendorDetailScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // State Variables
  DocumentSnapshot? _sellerDoc;
  List<DocumentSnapshot> _sellerItems = [];
  List<Map<String, dynamic>> _reviews = [];
  bool _isLoading = true;
  bool _isLoadingItems = true;
  bool _isLoadingReviews = true;
  String? _errorMessage;
  bool _isAddingToCart = false;

  @override
  void initState() {
    super.initState();
    _logDebugInfo();
    _loadAllData();
  }

  void _logDebugInfo() {
    debugPrint("--- VendorDetailScreen Init ---");
    debugPrint("Received sellerId: ${widget.sellerId}");
    debugPrint("Received eventId via eventDetails['id']: ${widget.eventDetails['id']}");
    debugPrint("Full eventDetails map: ${widget.eventDetails}");
  }

  Future<void> _loadAllData() async {
    await _fetchSellerDetails();
    // Fetch additional data in parallel
    await Future.wait([
      _fetchSellerItems(),
      _fetchReviews(),
    ]);
  }

  // --- Data Fetching Methods ---
  Future<void> _fetchSellerDetails() async {
    if (!mounted) return;

    setStateIfMounted(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final doc = await _firestore.collection('sellers').doc(widget.sellerId).get();

      if (!mounted) return;

      if (doc.exists) {
        setStateIfMounted(() => _sellerDoc = doc);
      } else {
        setStateIfMounted(() => _errorMessage = "Vendor details not found.");
      }
    } catch (e) {
      debugPrint("Error fetching seller details for ID ${widget.sellerId}: $e");

      if (mounted) {
        setStateIfMounted(() => _errorMessage = "Failed to load vendor details.");
      }
    } finally {
      if (mounted) {
        setStateIfMounted(() => _isLoading = false);
      }
    }
  }

  Future<void> _fetchSellerItems() async {
    if (!mounted) return;

    setStateIfMounted(() => _isLoadingItems = true);

    try {
      final itemsQuery = await _firestore
          .collection('items')
          .where('sellerId', isEqualTo: widget.sellerId)
          .orderBy('category')
          .limit(10)
          .get();

      if (mounted) {
        setStateIfMounted(() => _sellerItems = itemsQuery.docs);
      }
    } catch (e) {
      debugPrint("Error fetching seller items: $e");
    } finally {
      if (mounted) {
        setStateIfMounted(() => _isLoadingItems = false);
      }
    }
  }

  Future<void> _fetchReviews() async {
    if (!mounted) return;

    setStateIfMounted(() => _isLoadingReviews = true);

    try {
      final reviewsQuery = await _firestore
          .collection('reviews')
          .where('sellerId', isEqualTo: widget.sellerId)
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get();

      if (mounted) {
        final reviews = reviewsQuery.docs
            .map((doc) => {
          ...doc.data(),
          'id': doc.id,
        })
            .toList();
        setStateIfMounted(() => _reviews = reviews);
      }
    } catch (e) {
      debugPrint("Error fetching reviews: $e");
    } finally {
      if (mounted) {
        setStateIfMounted(() => _isLoadingReviews = false);
      }
    }
  }

  // --- Cart Methods ---
  Future<void> _addToCart() async {
    final user = _auth.currentUser;
    final eventId = widget.eventDetails['id'] as String?;

    // Pre-checks with early returns
    if (user == null) {
      _showFeedbackSnackBar("Please log in to add items to cart.", isError: true);
      return;
    }

    if (_sellerDoc == null || !_sellerDoc!.exists) {
      _showFeedbackSnackBar("Vendor details unavailable.", isError: true);
      return;
    }

    if (eventId == null || eventId.isEmpty) {
      _showFeedbackSnackBar("Cannot add to cart: Event context is missing.", isError: true);
      debugPrint("Error: eventId is null or empty in eventDetails.");
      return;
    }

    setStateIfMounted(() => _isAddingToCart = true);

    try {
      // Extract seller data
      final sellerData = _sellerDoc!.data() as Map<String, dynamic>? ?? {};
      final sellerName = sellerData['businessName'] as String? ?? 'N/A';
      final sellerPhoto = sellerData['photoUrl'] ?? sellerData['coverImageUrl'];

      // Find primary item or use seller as fallback
      DocumentSnapshot? primaryItemDoc;
      num itemPrice = sellerData['defaultPrice'] ?? 5000;
      String itemName = sellerName;
      String? itemImageUrl = sellerPhoto;

      // Try to find venue item first
      if (_sellerItems.isNotEmpty) {
        // Look for venue category first
        primaryItemDoc = _sellerItems.firstWhere(
              (doc) => (doc.data() as Map<String, dynamic>)['category'] == 'venue',
          orElse: () => _sellerItems.first, // Otherwise use first item
        );

        final itemData = primaryItemDoc.data() as Map<String, dynamic>;
        itemName = itemData['name'] ?? itemName;
        itemPrice = itemData['price'] ?? itemPrice;

        if (itemData.containsKey('imageUrls') &&
            (itemData['imageUrls'] as List).isNotEmpty) {
          itemImageUrl = (itemData['imageUrls'] as List).first as String?;
        }

        debugPrint("Adding item '${itemName}' (ID: ${primaryItemDoc.id}) to cart");
      } else {
        debugPrint("No specific item found. Adding general service to cart.");
      }

      // Prepare cart item data
      final cartItemData = {
        'itemId': primaryItemDoc?.id,
        'itemName': itemName,
        'itemPrice': itemPrice,
        'sellerId': widget.sellerId,
        'sellerName': sellerName,
        'imageUrl': itemImageUrl,
        'quantity': 1,
        'addedAt': FieldValue.serverTimestamp(),
        'eventId': eventId,
        'eventDetails': {
          'date': widget.eventDetails['date'],
          'guestCount': widget.eventDetails['guestCount'],
          'eventName': widget.eventDetails['name'],
        }
      };

      // Add to cart collection
      final cartRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('cartItems');
      await cartRef.add(cartItemData);

      debugPrint("Item added to cart for user ${user.uid}, event ${eventId}");
      _showFeedbackSnackBar("$itemName added to your event cart!", isError: false);
    } catch (e) {
      debugPrint("Error adding item to cart: $e");
      _showFeedbackSnackBar(
          "Failed to add to cart. Please try again.", isError: true);
    } finally {
      setStateIfMounted(() => _isAddingToCart = false);
    }
  }

  // --- UI Helper Methods ---
  void setStateIfMounted(VoidCallback fn) {
    if (mounted) setState(fn);
  }

  void _showFeedbackSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: isError ? Colors.redAccent : Colors.green,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 70), // Space for FAB
      duration: const Duration(seconds: 3),
    ));
  }

  // --- Main Build Methods ---
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Determine app bar title based on state
    final appBarTitle = _isLoading
        ? 'Loading...'
        : (_sellerDoc?.data() as Map<String, dynamic>?)?['businessName'] ??
        'Vendor Details';

    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle),
        elevation: 0,
      ),
      body: _buildBody(theme, colorScheme),
      floatingActionButton: _buildFloatingActionButton(colorScheme),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget? _buildFloatingActionButton(ColorScheme colorScheme) {
    if (_isLoading || _sellerDoc == null || !_sellerDoc!.exists) {
      return null;
    }

    return FloatingActionButton.extended(
      onPressed: _isAddingToCart ? null : _addToCart,
      label: _isAddingToCart
          ? SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          color: colorScheme.onPrimary,
          strokeWidth: 2.5,
        ),
      )
          : const Text('Add to Cart'),
      icon: _isAddingToCart ? null : const Icon(Icons.add_shopping_cart),
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
      tooltip: 'Add this vendor to your event cart',
    );
  }

  Widget _buildBody(ThemeData theme, ColorScheme colorScheme) {
    // Handle various states
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: TextStyle(
                    color: theme.colorScheme.error,
                    fontSize: 16
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _fetchSellerDetails,
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (_sellerDoc == null || !_sellerDoc!.exists) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Vendor data could not be loaded.'),
        ),
      );
    }

    // Extract vendor data - FIX: Add proper null safety
    final Map<String, dynamic> data = _sellerDoc!.data() as Map<String, dynamic>? ?? {};
    final String businessName = data['businessName'] as String? ?? 'N/A';
    final String description = data['description'] as String? ?? 'No description available.';
    final String? coverImageUrl = data['coverImageUrl'] as String?;

    // Extract address information
    final Map<String, dynamic>? addressData = data['address'] as Map<String, dynamic>?;
    final String city = addressData?['city'] as String? ?? '';
    final String state = addressData?['state'] as String? ?? '';
    final String location = city.isNotEmpty
        ? (state.isNotEmpty ? '$city, $state' : city)
        : '';

    // Extract rating information
    final double rating = (data['rating'] as num?)?.toDouble() ?? 0.0;
    final int reviewCount = data['reviewCount'] as int? ?? 0;

    return RefreshIndicator(
      onRefresh: _loadAllData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover Image Section
            _buildCoverImage(coverImageUrl),

            // Main Content
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Basic Vendor Info
                  Text(
                    businessName,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Rating & Location Row
                  _buildRatingAndLocation(
                      theme,
                      rating,
                      reviewCount,
                      location
                  ),
                  const SizedBox(height: 20),

                  // Description Section
                  _buildDescriptionSection(theme, description),
                  const SizedBox(height: 24),

                  // Items/Services Section
                  _buildItemsSection(theme),
                  const SizedBox(height: 24),

                  // Reviews Section
                  _buildReviewsSection(theme),
                ],
              ),
            ),

            // Space for FAB
            const SizedBox(height: 90),
          ],
        ),
      ),
    );
  }

  // --- UI Component Methods ---
  Widget _buildCoverImage(String? coverImageUrl) {
    return SizedBox(
      height: 220,
      width: double.infinity,
      child: (coverImageUrl != null && coverImageUrl.isNotEmpty)
          ? Image.network(
        coverImageUrl,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                  loadingProgress.expectedTotalBytes!
                  : null,
              strokeWidth: 2.0,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return _buildImageErrorPlaceholder();
        },
      )
          : Container(
        color: Colors.grey[300],
        child: Center(
          child: Icon(
            Icons.business,
            size: 60,
            color: Colors.grey[700],
          ),
        ),
      ),
    );
  }

  Widget _buildImageErrorPlaceholder() {
    return Container(
      color: Colors.grey.shade300,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.hide_image_outlined,
              size: 40,
              color: Colors.grey.shade600,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Image not available',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingAndLocation(
      ThemeData theme,
      double rating,
      int reviewCount,
      String location,
      ) {
    return Row(
      children: [
        if (rating > 0) ...[
          Icon(
            Icons.star,
            color: Colors.amber.shade700,
            size: 20,
          ),
          const SizedBox(width: 4),
          Text(
            rating.toStringAsFixed(1),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          if (reviewCount > 0)
            Text(
              ' ($reviewCount reviews)',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey,
              ),
            ),
          const SizedBox(width: 12),
          Container(
            height: 16,
            width: 1,
            color: Colors.grey.shade300,
          ),
          const SizedBox(width: 12),
        ],
        if (location.isNotEmpty) ...[
          Icon(
            Icons.location_on_outlined,
            size: 18,
            color: Colors.grey.shade700,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              location,
              style: theme.textTheme.bodyLarge,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDescriptionSection(ThemeData theme, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          description,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.textTheme.bodyMedium?.color,
          ),
        ),
      ],
    );
  }

  Widget _buildItemsSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Services & Items Offered',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _isLoadingItems
            ? const Center(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: CircularProgressIndicator(),
          ),
        )
            : _sellerItems.isEmpty
            ? _buildEmptySection(
            'No items or services found for this vendor.')
            : _buildItemsList(theme),
      ],
    );
  }

  Widget _buildItemsList(ThemeData theme) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _sellerItems.length,
      itemBuilder: (context, index) {
        final item = _sellerItems[index].data() as Map<String, dynamic>;
        final itemName = item['name'] as String? ?? 'Unnamed Item';
        final itemPrice = (item['price'] as num?)?.toDouble() ?? 0.0;
        final itemCategory = item['category'] as String? ?? 'Other';
        final imageUrls = item['imageUrls'] as List<dynamic>? ?? [];
        final String? imageUrl =
        imageUrls.isNotEmpty ? imageUrls.first as String : null;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Item Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 80,
                    height: 80,
                    child: imageUrl != null
                        ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: Colors.grey.shade200,
                          child: Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                                  : null,
                              strokeWidth: 2,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey.shade200,
                          child: Icon(
                            Icons.image_not_supported,
                            color: Colors.grey.shade400,
                          ),
                        );
                      },
                    )
                        : Container(
                      color: Colors.grey.shade200,
                      child: Icon(
                        Icons.image,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Item Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        itemName,
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\$${itemPrice.toStringAsFixed(2)}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _capitalize(itemCategory),
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
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

  Widget _buildReviewsSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reviews',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _isLoadingReviews
            ? const Center(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: CircularProgressIndicator(),
          ),
        )
            : _reviews.isEmpty
            ? _buildEmptySection('No reviews yet for this vendor.')
            : _buildReviewsList(theme),
      ],
    );
  }

  Widget _buildReviewsList(ThemeData theme) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _reviews.length,
      itemBuilder: (context, index) {
        final review = _reviews[index];
        final reviewerName = review['userName'] as String? ?? 'Anonymous';
        final reviewText = review['comment'] as String? ?? 'No comment provided';
        final reviewRating = (review['rating'] as num?)?.toDouble() ?? 0.0;
        final reviewDate = review['createdAt'] as Timestamp?;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      reviewerName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (reviewDate != null)
                      Text(
                        _formatDate(reviewDate.toDate()),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: List.generate(
                    5,
                        (i) => Icon(
                      i < reviewRating ? Icons.star : Icons.star_border,
                      color: Colors.amber.shade700,
                      size: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  reviewText,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptySection(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          message,
          style: TextStyle(color: Colors.grey.shade600),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  // Helper Methods
  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}