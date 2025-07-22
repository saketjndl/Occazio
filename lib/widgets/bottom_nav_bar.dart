import 'package:flutter/material.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const CustomBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

@override
  Widget build(BuildContext context) {
    // Get the current theme's BottomNavigationBarTheme
    final bottomNavTheme = Theme.of(context).bottomNavigationBarTheme;

    // Use BottomNavigationBar directly, no need for the outer Container
    // The theme will handle the background color and shadow via elevation.
    return BottomNavigationBar(
      // Use properties defined in the theme:
      selectedItemColor: bottomNavTheme.selectedItemColor ?? Theme.of(context).colorScheme.primary,
      unselectedItemColor: bottomNavTheme.unselectedItemColor ?? Colors.grey.shade600, // Fallback just in case
      backgroundColor: bottomNavTheme.backgroundColor ?? Colors.white, // Fallback just in case
      type: bottomNavTheme.type ?? BottomNavigationBarType.fixed,
      elevation: bottomNavTheme.elevation ?? 0, // Use theme elevation

      // Keep your existing items and interaction logic:
      currentIndex: selectedIndex,
      onTap: onItemTapped,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.event_outlined),
          activeIcon: Icon(Icons.event),
          label: 'Events',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.add_circle),
          activeIcon: Icon(Icons.add_circle_outline),
          label: 'Add',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Profile',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings), // Use non-outlined for consistency?
          activeIcon: Icon(Icons.settings),
          label: 'Settings',
        ),
      ],
    );
  }
}