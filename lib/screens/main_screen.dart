import 'package:flutter/material.dart';

// --- Import Your Screen Widgets ---
import 'home_screen.dart';          // For Index 0
import 'events_placeholder_screen.dart'; // For Index 1 Placeholder
import 'profile_screen.dart';        // For Index 3
import 'settings_screen.dart';       // For Index 4
import 'create_event_screen.dart';   // For Index 2 Navigation Target
import 'cart_screen.dart';           // For Cart Navigation Target

// --- Import Your Custom Bottom Navigation Bar ---
import '../widgets/bottom_nav_bar.dart'; // Verify this path is correct

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0; // Default to Home (Index 0)

  // --- List of Widgets for the Main Screen Body (IndexedStack) ---
  // Index 2 is a placeholder, tap action navigates elsewhere
  static final List<Widget> _widgetOptions = <Widget>[
    const HomeScreenContent(),         // Index 0: Home
    const EventsPlaceholderScreen(),   // Index 1: Events
    Container(),                       // Index 2: Placeholder for 'Add' action
    const ProfileScreen(),             // Index 3: Profile
    const SettingsScreen(),            // Index 4: Settings
  ];

  // --- Callback function when BottomNavBar item is tapped ---
  void _onItemTapped(int index) {
    // --- SPECIAL HANDLING FOR INDEX 2 ('Add' button) ---
    if (index == 2) {
      Navigator.push( context, MaterialPageRoute(builder: (context) => const CreateEventScreen()), );
      debugPrint("Navigate to Create Event Screen triggered from BottomNav.");
      return; // Don't change selected index
    }
    // --- END SPECIAL HANDLING ---

    // Handle taps for other valid indices (0, 1, 3, 4)
    if (index >= 0 && index < _widgetOptions.length && index != 2) {
      if (mounted) { setState(() { _selectedIndex = index; }); }
    } else if (index >= _widgetOptions.length){
      debugPrint("Warning: Invalid index tapped $index in BottomNavBar.");
    }
  }

  // --- Build AppBar based on the currently displayed screen ---
  AppBar? _buildAppBar() {
    switch (_selectedIndex) {
      case 0: // Home Tab AppBar Configuration
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        final appBarTheme = theme.appBarTheme;
        final bool isDarkMode = theme.brightness == Brightness.dark;
        final String textLogoAssetPath = isDarkMode
            ? 'assets/images/logo/occaziologo1.png' // White logo for Dark
            : 'assets/images/logo/occaziologo1P.png';  // Purple logo for Light

        return AppBar(
          backgroundColor: appBarTheme.backgroundColor ?? colorScheme.surface,
          foregroundColor: appBarTheme.foregroundColor ?? colorScheme.onSurface,
          elevation: appBarTheme.elevation ?? 0.5,
          centerTitle: false,
          title: Padding( // Logo Title
            padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
            child: Image.asset(
              textLogoAssetPath, // Uses themed logo
              height: 35,        // Adjust height
              fit: BoxFit.contain,
              semanticLabel: 'Occazio Logo',
              errorBuilder: (context, error, stackTrace) => Text('Occazio', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: colorScheme.primary)),
            ),
          ),
          actions: [ // --- AppBar Actions ---
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              color: appBarTheme.actionsIconTheme?.color ?? colorScheme.onSurface,
              tooltip: 'Notifications',
              onPressed: () { /* TODO: Implement Notifications */
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notifications Tapped (Not Implemented)')));
              },
            ),
            // --- Cart Icon Button ---
            IconButton(
              icon: const Icon(Icons.shopping_cart_outlined),
              color: appBarTheme.actionsIconTheme?.color ?? colorScheme.onSurface,
              tooltip: 'Cart',
              // --- Navigate to Cart Screen ---
              onPressed: () {
                Navigator.pushNamed(context, '/cart'); // Use named route
              },
            ),
          ],
        ); // End AppBar for Home

      case 1: // Events Tab (Using placeholder screen)
      // You might want to add a "+" icon here later to also navigate to CreateEvent
        return AppBar(title: const Text('Events'));

    // Case 2 is unreachable via _selectedIndex assignment

      case 3: // Profile Tab (Screen has its own AppBar)
        return null;

      case 4: // Settings Tab (Screen has its own AppBar)
        return null;

      default:
        return null;
    }
  } // End _buildAppBar


  // --- Floating Action Button is REMOVED ---


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(), // Builds AppBar based on _selectedIndex
      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions, // Displays the widget for the selected index
      ),
      // Floating Action Button REMOVED
      bottomNavigationBar: CustomBottomNavBar( // Your custom bottom navigation bar
        selectedIndex: _selectedIndex, // Highlights the correct icon
        onItemTapped: _onItemTapped,   // Handles tap actions
      ),
    );
  }
}