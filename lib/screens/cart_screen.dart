// File: lib/screens/cart_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// Optional: Import intl package for currency formatting
// import 'package:intl/intl.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<QuerySnapshot>? _cartStream;
  double _cartTotal = 0.0; // To hold the calculated total

  @override
  void initState() {
    super.initState();
    _initializeCartStream();
  }

  // Initialize stream only if user is logged in
  void _initializeCartStream() {
    final user = _auth.currentUser;
    if (user != null) {
      setState(() {
        _cartStream = _firestore
            .collection('users')
            .doc(user.uid)
            .collection('cartItems')
            .orderBy('addedAt', descending: true) // Show newest first
            .snapshots(); // Listen for real-time changes
      });
    } else {
      // Handle case where user might log out while cart is potentially visible
      // Or ensure cart screen isn't accessible if logged out
      debugPrint("CartScreen initState: User is null, cannot initialize stream.");
    }
  }

  // --- Safe setState helper ---
  void setStateIfMounted(VoidCallback fn) {
    if (mounted) {
      setState(fn);
    }
  }

  // --- Helper to show feedback SnackBar ---
  void _showFeedbackSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).removeCurrentSnackBar(); // Remove previous
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: isError ? Colors.redAccent : Colors.green,
      behavior: SnackBarBehavior.floating,
    ));
  }

  // --- Function to Remove Item from Cart ---
  Future<void> _removeItem(String cartItemId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    debugPrint("Attempting to remove cart item: $cartItemId");
    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('cartItems')
          .doc(cartItemId)
          .delete();
      // No need for SnackBar here, StreamBuilder handles UI update automatically
      // _showFeedbackSnackBar("Item removed from cart.", isError: false); // Optional
    } catch (e) {
      debugPrint("Error removing cart item $cartItemId: $e");
      _showFeedbackSnackBar("Could not remove item: ${e.toString()}", isError: true);
    }
  }

  // --- === COMBINED Checkout and Booking Update Logic === ---
  Future<void> _confirmBookingAndCheckout(List<DocumentSnapshot> cartDocs) async {
    final user = _auth.currentUser;
    // Double check conditions before proceeding
    if (user == null || cartDocs.isEmpty || _cartTotal <= 0) {
      debugPrint("Checkout preconditions not met (user: ${user?.uid}, cartEmpty: ${cartDocs.isEmpty}, total: $_cartTotal)");
      return;
    }

    // --- Show Loading Dialog ---
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Dialog( child: Padding( padding: EdgeInsets.all(20.0), child: Row(mainAxisSize: MainAxisSize.min, children: [ CircularProgressIndicator(), SizedBox(width: 20), Text("Confirming Booking...")]))));

    String? eventIdToUpdate; // Assumes all items in checkout belong to the same event
    List<Map<String, dynamic>> bookedItemsData = []; // For potential subcollection later

    try {
      // --- Prepare Batched Write ---
      WriteBatch batch = _firestore.batch();

      // --- Process Cart Items for Deletion and Extract Data ---
      for (var cartDoc in cartDocs) {
        final cartData = cartDoc.data() as Map<String, dynamic>? ?? {};

        // Extract event ID - crucial assumption: it's the same for all items
        final currentEventId = cartData['eventId'] as String?;
        if (eventIdToUpdate == null && currentEventId != null) {
          eventIdToUpdate = currentEventId;
        } else if (currentEventId != null && eventIdToUpdate != currentEventId) {
          // Handle error: items from different events in cart checkout (not supported by this logic)
          throw Exception("Cannot checkout items from multiple events at once.");
        }

        // Optionally prepare data to be stored in a 'bookedItems' subcollection of the event
        final bookedItemData = {
          'itemId': cartData['itemId'], 'itemName': cartData['itemName'], 'itemPrice': cartData['itemPrice'],
          'sellerId': cartData['sellerId'], 'sellerName': cartData['sellerName'], 'imageUrl': cartData['imageUrl'],
          'quantity': cartData['quantity'], 'bookedAt': FieldValue.serverTimestamp(),
        };
        bookedItemsData.add(bookedItemData); // Can be used later if needed

        // Schedule cart item deletion in the batch
        batch.delete(cartDoc.reference);
      }

      // --- Schedule Event Update (if eventId was found) ---
      if (eventIdToUpdate != null) {
        final eventRef = _firestore.collection('events').doc(eventIdToUpdate);
        batch.update(eventRef, {
          'status': 'confirmed', // Update status
          'bookedAt': FieldValue.serverTimestamp(), // Add booking timestamp
          // Consider adding booked items to '/events/{id}/bookedItems/' subcollection instead of directly here
        });
        debugPrint("Scheduled update for event '$eventIdToUpdate' to status 'confirmed'.");
      } else {
        // If no eventId found, maybe just clear cart without updating event?
        debugPrint("Warning: No eventId found in cart items. Only clearing cart.");
        // Depending on app logic, you might throw an error or show a different message.
      }


      // --- Commit the Batch (Deletes cart items, updates event) ---
      await batch.commit();
      debugPrint("Booking batch committed successfully.");

      // --- Close Loading & Show Success ---
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        _showFeedbackSnackBar('Booking Confirmed!', isError: false);
        Navigator.pop(context); // Go back from cart screen
      }

    } catch (e) {
      debugPrint("Error during booking confirmation/checkout: $e");
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        _showFeedbackSnackBar("Booking failed: ${e.toString()}", isError: true);
      }
    }
  }
  // --- === END Checkout Logic === ---

  @override
  Widget build(BuildContext context) {
    // Optional: Currency Formatter
    // final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    final theme = Theme.of(context); // Get theme for fallback styling

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Event Cart'), // More specific title
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _cartStream,
        builder: (context, snapshot) {
          // 1. Handle Loading State
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // 2. Handle Error State
          if (snapshot.hasError) {
            debugPrint("Cart Stream Error: ${snapshot.error}");
            return Center(child: Text('Error loading cart: ${snapshot.error}'));
          }
          // 3. Handle No User (Stream is null or no auth)
          if (_auth.currentUser == null) {
            return const Center(child: Text('Please log in to view your cart.'));
          }
          // 4. Handle Cart Data (or Empty Cart)
          if (!snapshot.hasData) {
            // This case might mean the stream started but no data arrived yet, treat as loading
            return const Center(child: CircularProgressIndicator());
          }

          final cartDocs = snapshot.data!.docs;

          if (cartDocs.isEmpty) {
            return const Center(
                child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column( // Nicer empty cart message
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.remove_shopping_cart_outlined, size: 60, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('Your cart is empty.', style: TextStyle(fontSize: 18, color: Colors.grey)),
                      ],
                    )
                )
            );
          }

          // 5. Calculate Total (inside builder to react to stream changes)
          double calculatedTotal = 0;
          for (var doc in cartDocs) {
            final data = doc.data() as Map<String, dynamic>? ?? {};
            final price = (data['itemPrice'] as num?) ?? 0;
            final quantity = (data['quantity'] as num?) ?? 1;
            calculatedTotal += (price * quantity);
          }
          // Schedule state update for total after build frame completes
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _cartTotal != calculatedTotal) {
              setState(() { _cartTotal = calculatedTotal; });
            }
          });

          // 6. Build UI with Cart Items
          return Column(
            children: [
              // --- List of Cart Items ---
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: cartDocs.length,
                  itemBuilder: (context, index) {
                    final doc = cartDocs[index];
                    final data = doc.data() as Map<String, dynamic>? ?? {};
                    final itemName = data['itemName'] as String? ?? 'Item';
                    final sellerName = data['sellerName'] as String? ?? 'Seller';
                    final price = (data['itemPrice'] as num?) ?? 0;
                    final imageUrl = data['imageUrl'] as String?;

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
                      elevation: 1,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      child: ListTile(
                        leading: SizedBox(
                          width: 55, height: 55, // Slightly larger image
                          child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: (imageUrl != null && imageUrl.isNotEmpty)
                                  ? Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.image_not_supported, size: 24, color: Colors.grey)),
                                  loadingBuilder: (context, child, prog) => prog == null ? child : const Center(child: CircularProgressIndicator(strokeWidth: 2))
                              )
                                  : Container(decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(4)), child: const Icon(Icons.business_center, color: Colors.grey))
                          ),
                        ),
                        title: Text(itemName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("by $sellerName", style: theme.textTheme.bodySmall),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text( '₹${price.toStringAsFixed(0)}', // Basic Indian Rupee format
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Theme.of(context).colorScheme.primary),
                            ),
                            const SizedBox(width: 4), // Add space before delete
                            IconButton( // Remove button
                              icon: Icon(Icons.delete_outline, color: theme.colorScheme.error), // Use theme error color
                              onPressed: () => _removeItem(doc.id),
                              tooltip: 'Remove Item',
                              iconSize: 20, // Slightly smaller icon
                              padding: EdgeInsets.zero, // Reduce padding
                              constraints: const BoxConstraints(), // Reduce constraints
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // --- Total and Checkout Area ---
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16), // Adjusted padding
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  boxShadow: [ BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 5, offset: const Offset(0, -2)), ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total Amount:', style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor)),
                        Text(
                            '₹${_cartTotal.toStringAsFixed(0)}',
                            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary) // Make total stand out
                        ),
                      ],
                    ),
                    ElevatedButton.icon( // Use icon button
                      icon: const Icon(Icons.shopping_cart_checkout), // Checkout icon
                      label: const Text('Confirm Booking'), // Updated label
                      onPressed: cartDocs.isEmpty ? null : () => _confirmBookingAndCheckout(cartDocs), // Pass cartDocs
                      style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                      ),
                    )
                  ],
                ),
              ) // End Checkout Area
            ],
          ); // End main Column
        }, // End StreamBuilder builder
      ), // End StreamBuilder
    ); // End Scaffold
  } // End build
} // End _CartScreenState