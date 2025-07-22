// File: lib/screens/home_screen.dart

import 'dart:async'; // For Timer (debouncing)
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore
import 'package:firebase_auth/firebase_auth.dart'; // Firebase Auth
import 'package:intl/intl.dart'; // For date formatting
import '../widgets/category_card.dart'; // Ensure this path is correct relative to this file
import 'package:occazziotest/screens/events_placeholder_screen.dart';

class HomeScreenContent extends StatefulWidget {
  const HomeScreenContent({super.key});

  @override
  State<HomeScreenContent> createState() => _HomeScreenContentState();
}

class _HomeScreenContentState extends State<HomeScreenContent> {

  // --- State Variables ---
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  bool _isSearching = false;
  List<DocumentSnapshot> _searchResults = [];
  String _searchQuery = "";
  List<DocumentSnapshot> _featuredVendorDocs = [];
  bool _isLoadingFeatured = true;
  List<DocumentSnapshot> _upcomingEvents = [];
  bool _isLoadingEvents = true;
  String? _eventsErrorMessage;

  // --- Firestore/Auth Instances ---
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // --- Static Data (Only Categories) ---
  final List<Map<String, dynamic>> _serviceCategories = const [
    { 'title': 'Venues', 'icon': Icons.location_city, 'color': Color(0xFF3F51B5), },
    { 'title': 'Catering', 'icon': Icons.restaurant_menu, 'color': Color(0xFF009688), },
    { 'title': 'Photography', 'icon': Icons.camera_alt, 'color': Color(0xFFE91E63), },
    { 'title': 'Decoration', 'icon': Icons.palette, 'color': Color(0xFF9C27B0), },
    { 'title': 'Music & DJs', 'icon': Icons.music_note, 'color': Color(0xFFFF9800), },
  ];
  // ------------------------------------

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _fetchFeaturedVendors();
    _fetchUpcomingEvents();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // --- Fetch Featured Vendors Logic ---
  Future<void> _fetchFeaturedVendors() async {
    if (!mounted) return;
    setStateIfMounted(() => _isLoadingFeatured = true);
    try {
      final querySnapshot = await _firestore.collection('sellers').orderBy('rating', descending: true).limit(3).get();
      if (mounted) {
        setStateIfMounted(() { _featuredVendorDocs = querySnapshot.docs; _isLoadingFeatured = false; });
        debugPrint("Fetched ${_featuredVendorDocs.length} featured vendors.");
      }
    } catch (e) {
      debugPrint("Error fetching featured vendors: $e");
      if (mounted) { setStateIfMounted(() => _isLoadingFeatured = false); }
    }
  }

  // --- Fetch Upcoming Events Logic ---
  Future<void> _fetchUpcomingEvents() async {
    final user = _auth.currentUser;
    if (user == null) { setStateIfMounted(() { _isLoadingEvents = false; _eventsErrorMessage = "Please log in to see events."; }); return; }
    if (!mounted) return;
    setStateIfMounted(() { _isLoadingEvents = true; _eventsErrorMessage = null; });
    try {
      final now = Timestamp.now();
      final querySnapshot = await _firestore
          .collection('events')
          .where('userId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'confirmed')
          .where('date', isGreaterThanOrEqualTo: now)
          .orderBy('date', descending: false) // Requires Index
          .limit(5)
          .get();
      if (mounted) {
        setStateIfMounted(() { _upcomingEvents = querySnapshot.docs; _isLoadingEvents = false; });
        debugPrint("Fetched ${_upcomingEvents.length} upcoming confirmed events.");
      }
    } catch (e) {
      debugPrint("!!! Error fetching upcoming events: $e");
      if (mounted) {
        setStateIfMounted(() { _isLoadingEvents = false; _eventsErrorMessage = "Could not load events."; });
        if (e is FirebaseException && e.code == 'failed-precondition') {
          debugPrint(">>> Firestore Index Missing for events query. Likely need composite index on userId (==), status (==), date (asc). Check console link.");
          showErrorSnackBar('Event display requires setup. Check Debug Console.');
        } else {
          showErrorSnackBar('Failed to load upcoming events.');
        }
      }
    }
  }

  // --- Debounce Search Logic ---
  void _onSearchChanged() {
    final newQuery = _searchController.text;
    if (_searchQuery != newQuery) { setStateIfMounted(() { _searchQuery = newQuery; }); }
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (_searchController.text.isNotEmpty) { _performSearch(_searchController.text); }
      else { if (mounted) { setStateIfMounted(() { _isSearching = false; _searchResults = []; }); } }
    });
  }

  // --- Perform Firestore Search (Using businessName_lowercase - Requires Index!) ---
  Future<void> _performSearch(String query) async {
    final trimmedQuery = query.trim();
    final lowercaseQuery = trimmedQuery.toLowerCase();
    if (lowercaseQuery.isEmpty) {
      setStateIfMounted(() { _searchResults = []; _isSearching = false; });
      return;
    }
    debugPrint("Performing search for prefix: '$lowercaseQuery' on 'businessName_lowercase'");
    setStateIfMounted(() => _isSearching = true);
    List<DocumentSnapshot> results = [];
    try {
      final querySnapshot = await _firestore
          .collection('sellers')
          .where('businessName_lowercase', isGreaterThanOrEqualTo: lowercaseQuery)
          .where('businessName_lowercase', isLessThan: '$lowercaseQuery\uf8ff')
          .orderBy('businessName_lowercase') // Requires Index
          .limit(15)
          .get();
      results = querySnapshot.docs;
      debugPrint("Search successful, found ${results.length} results.");
    } catch (e) {
      debugPrint("!!! Search Error: $e");
      if (e is FirebaseException && e.code == 'failed-precondition') {
        debugPrint(">>> Firestore Index Missing on 'sellers' collection for field 'businessName_lowercase' (ascending). Create via Firebase Console link (check logs above) or manually.");
        showErrorSnackBar('Search setup required. Check Debug Console for index link.');
      } else {
        showErrorSnackBar('Search failed: ${e.toString()}');
      }
      results = [];
    } finally {
      setStateIfMounted(() { _searchResults = results; _isSearching = false; });
    }
  }
  // --- End Search Logic ---

  // --- Helper to dismiss keyboard ---
  void _dismissKeyboard() {
    final currentFocus = FocusScope.of(context);
    if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
      FocusManager.instance.primaryFocus?.unfocus();
    }
  }

  // --- Safe setState helper ---
  void setStateIfMounted(VoidCallback fn) {
    if (mounted) {
      setState(fn);
    }
  }

  // --- Safe showSnackBar helper ---
  void showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.redAccent)
      );
    }
  }

  // --- ================== Main Build Method ================== ---
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bool showResultsArea = _searchQuery.isNotEmpty || _isSearching;

    return GestureDetector(
      onTap: _dismissKeyboard,
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: theme.scaffoldBackgroundColor,
        child: Column(
          children: [
            // --- Search Bar ---
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: theme.brightness == Brightness.light ? Colors.white : theme.cardTheme.color ?? theme.colorScheme.surface,
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search vendors by name...',
                  prefixIcon: Icon(Icons.search, color: colorScheme.primary),
                  suffixIcon: _searchQuery.isNotEmpty ? IconButton( icon: const Icon(Icons.clear), onPressed: () => _searchController.clear(), tooltip: "Clear Search", ) : null,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.dividerColor)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.dividerColor)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colorScheme.primary, width: 1.5)),
                ),
                textInputAction: TextInputAction.search,
                onSubmitted: (value) { _performSearch(value); _dismissKeyboard(); },
              ),
            ), // End Search Bar Container

            // --- Scrollable Content Area ---
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  debugPrint("Pull to refresh triggered.");
                  await _fetchFeaturedVendors();
                  await _fetchUpcomingEvents();
                },
                child: ListView(
                  padding: EdgeInsets.zero,
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  children: [
                    // Conditional Search Results
                    if (showResultsArea) _buildSearchResultsWidget(theme, colorScheme),
                    // Always Original Content
                    _buildOriginalHomeContent(theme, colorScheme),
                  ],
                ),
              ), // End RefreshIndicator
            ), // End Expanded
          ],
        ),
      ),
    );
  } // End build method

  // --- ================== Helper: Builds Search Results ================== ---
  Widget _buildSearchResultsWidget(ThemeData theme, ColorScheme colorScheme) {
    if (_isSearching) { return const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 40.0), child: CircularProgressIndicator())); }
    if (!_isSearching && _searchQuery.isNotEmpty && _searchResults.isEmpty) { return Center(child: Padding(padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 20), child: Text('No vendors found for "$_searchQuery".'))); }
    if (_searchResults.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
              child: Text("Search Results (${_searchResults.length}):", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            ),
            Column( // Column to hold results cards/tiles
              children: _searchResults.map<Widget>((doc) {
                final data = doc.data() as Map<String, dynamic>?;
                if (data == null) return const SizedBox.shrink();
                final businessName = data['businessName'] as String? ?? 'N/A';
                final city = (data['address'] as Map<String, dynamic>?)?['city'] as String? ?? '';
                final rating = (data['rating'] as num?)?.toDouble() ?? 0.0;
                // Using Card for results
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                    leading: CircleAvatar(backgroundColor: colorScheme.primary.withOpacity(0.1), child: Icon(Icons.storefront, color: colorScheme.primary)),
                    title: Text(businessName, style: theme.textTheme.titleMedium),
                    subtitle: Text(city, style: theme.textTheme.bodyMedium?.copyWith(color: theme.textTheme.bodySmall?.color)),
                    trailing: Row( mainAxisSize: MainAxisSize.min, children: [ Icon(Icons.star, color: Colors.amber.shade700, size: 16), Text(' ${rating.toStringAsFixed(1)}') ],),
                    onTap: () { _dismissKeyboard(); debugPrint("Tapped Search Result Seller ID: ${doc.id}"); /* TODO: Navigate */},
                  ),
                );
              }).toList(),
            ),
            const Divider(height: 24, thickness: 1, indent: 16, endIndent: 16), // Separator
          ],
        ),
      );
    }
    return const SizedBox.shrink(); // Default empty
  } // End _buildSearchResultsWidget


  // --- ================== Helper: Builds Original Home Content ================== ---
  Widget _buildOriginalHomeContent(ThemeData theme, ColorScheme colorScheme) {
    final DateFormat dateFormatter = DateFormat('EEE, d MMM • h:mm a'); // Date formatter

    // This Column is directly inside the parent ListView
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- Browse Services Section ---
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Available Services', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        SizedBox(
          height: 140,
          child: ListView.builder(
            // --- CORRECTED padding and itemBuilder ---
            padding: const EdgeInsets.symmetric(horizontal: 12), // Padding FOR the items
            scrollDirection: Axis.horizontal,
            itemCount: _serviceCategories.length,
            itemBuilder: (context, index) {
              final service = _serviceCategories[index];
              // Use your CategoryCard (ensure it is themed correctly)
              return CategoryCard(
                title: service['title'],
                icon: service['icon'],
                color: service['color'],
                onTap: () { _dismissKeyboard(); /* TODO */ },
              );
            }, // --- END itemBuilder ---
          ),
        ),
        const SizedBox(height: 24),

        // --- Featured Vendors Section ---
        Padding( // Header
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Featured Vendors', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        _isLoadingFeatured // Loading Check
            ? const Center(child: Padding(padding: EdgeInsets.all(24.0), child: CircularProgressIndicator(strokeWidth: 2.5)))
            : _featuredVendorDocs.isEmpty // Empty Check
            ? const Center(child: Padding(padding: EdgeInsets.all(24.0), child: Text('No featured vendors available.')))
            : Column( // Column holding vendor cards (NO nested ListView/Padding wrapper)
          children: _featuredVendorDocs.map<Widget>((doc) { // Explicit Widget type
            final vendorData = doc.data() as Map<String, dynamic>?;
            if (vendorData == null) return const SizedBox.shrink(); // Handle null
            final vendorName = vendorData['businessName'] as String? ?? 'N/A';
            final rating = (vendorData['rating'] as num?)?.toDouble() ?? 0.0;
            final city = (vendorData['address'] as Map<String, dynamic>?)?['city'] as String? ?? '';
            final displayCategory = vendorData['category'] ?? (vendorData['eventTypes'] as List?)?.first ?? '';
            // --- Vendor Card ---
            return Card(
              // --- CORRECTED margin application ---
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 8), // Equal L/R margin, some top/bottom margin
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: InkWell(
                onTap: () { _dismissKeyboard(); debugPrint("Tapped Featured Vendor ID: ${doc.id}"); /* TODO: Navigate */ },
                borderRadius: BorderRadius.circular(12),
                // --- CORRECTED child: Use Padding ---
                child: Padding(
                  padding: const EdgeInsets.all(0), // Padding applied by Row content perhaps? Or add some here e.g., 8.0
                  child: Row(
                    children: [
                      Container( width: 100, height: 100, decoration: BoxDecoration(/*...*/) , child: Icon(Icons.storefront, size: 40, color: colorScheme.primary)),
                      Expanded( child: Padding( padding: const EdgeInsets.all(12), child: Column( crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(vendorName, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(city.isNotEmpty ? '$displayCategory - $city' : displayCategory, style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withOpacity(0.6))),
                        const SizedBox(height: 8),
                        Row(children: [ Icon(Icons.star, size: 16, color: Colors.amber.shade700), const SizedBox(width: 4), Text(rating.toStringAsFixed(1), style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),]),
                      ],),),),
                      Padding( padding: const EdgeInsets.all(12), child: Icon(Icons.bookmark_border, color: colorScheme.primary)),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

// --- Upcoming Events Section ---
Padding(
  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        'Upcoming Events',
        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
      TextButton(
        onPressed: () {
          _dismissKeyboard();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EventsPlaceholderScreen(),
            ),
          );
        },
        child: Text(
          'View All',
          style: TextStyle(color: colorScheme.primary),
        ),
      ),
    ],
  ),
),

_isLoadingEvents // Loading Check
    ? const Center(child: Padding(padding: EdgeInsets.all(24.0), child: CircularProgressIndicator(strokeWidth: 2.5)))
    : _eventsErrorMessage != null // Error Check
    ? Center(child: Padding(padding: EdgeInsets.all(24.0), child: Text(_eventsErrorMessage!)))
    : _upcomingEvents.isEmpty // Empty Check
    ? const Center(child: Padding(padding: EdgeInsets.all(24.0), child: Text('No upcoming events found.')))
    : Column( // Column holding event cards
  children: _upcomingEvents.map<Widget>((doc) { // Explicit Widget type
    final eventData = doc.data() as Map<String, dynamic>?;
    if (eventData == null) return const SizedBox.shrink(); // Handle null
    final eventName = eventData['name'] as String? ?? 'Unnamed Event';
    final eventDate = (eventData['date'] as Timestamp?)?.toDate();
    final formattedDate = eventDate != null ? dateFormatter.format(eventDate) : 'Date TBD';
    IconData eventIcon = Icons.event;
    // ... determine icon ...
    // --- Event Card ---
    return Card(
      // --- CORRECTED margin application ---
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16), // Applied margin here
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: theme.brightness == Brightness.light ? colorScheme.primaryContainer.withOpacity(0.6) : colorScheme.surfaceVariant,
      child: InkWell(
        onTap: () { /* ... */ },
        borderRadius: BorderRadius.circular(12),
        child: Padding( // <-- ADDED THIS PADDING WIDGET
          padding: const EdgeInsets.all(16.0), // Padding FOR the content
          child: Row( // The Row is now the child of Padding
            children: [
              CircleAvatar(radius: 24, backgroundColor: colorScheme.primary.withOpacity(0.1), child: Icon(eventIcon, color: colorScheme.primary, size: 24)),
              const SizedBox(width: 16),
              Expanded( child: Column( crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(eventName, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(formattedDate, style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor)),
              ],),),
              Icon(Icons.arrow_forward_ios, size: 16, color: theme.hintColor),
            ],
          ),
        ), //
      ),
    );
    // --- End Event Card ---
  }).toList(),
),        const SizedBox(height: 24), // Bottom padding
      ],
    );
  } // End _buildOriginalHomeContent

} // End _HomeScreenContentState