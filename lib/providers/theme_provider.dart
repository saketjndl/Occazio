// File: lib/providers/theme_provider.dart

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart'; // Needed for system brightness
// Optional: Import shared_preferences if you want to save the theme
// import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  MaterialColor _primaryPurple = Colors.deepPurple; // Correct type // Or Colors.purple, etc.

  // Default to system preference
  ThemeMode _themeMode = ThemeMode.system; // Start with System theme is often best

  // Getter to expose the current mode
  ThemeMode get themeMode => _themeMode;

  // --- ADDED: Getter for display name ---
  String get currentThemeModeName {
    switch (_themeMode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
      default:
        return 'System Default';
    }
  }

  // --- ADDED: Getter for actual ThemeData based on mode ---
  ThemeData get currentTheme {
    final brightness = SchedulerBinding.instance.window.platformBrightness;
    final useDarkMode = _themeMode == ThemeMode.dark ||
        (_themeMode == ThemeMode.system && brightness == Brightness.dark);
    return useDarkMode ? _buildDarkTheme() : _buildLightTheme();
  }

  // --- Define your theme configurations ---
  ThemeData _buildLightTheme() {
    final base = ThemeData.light(useMaterial3: true); // Start with base light theme

    return base.copyWith(
      brightness: Brightness.light, // Explicitly light
      // --- Color Scheme ---
      colorScheme: base.colorScheme.copyWith(
        // Primary Color (Purple)
        primary: _primaryPurple, // Your chosen purple
        onPrimary: Colors.white, // Text/icons on purple buttons/elements

        // Secondary Color (Optional - choose an accent)
        secondary: Colors.purple, // Example: Purple for contrast
        onSecondary: Colors.black, // Text/icons on secondary color

        // Backgrounds
        background: Colors.white, // Overall background
        surface: Colors.white, // Surface color for Cards, Dialogs etc.
        onBackground: Colors.black87, // Text on white background
        onSurface: Colors.black87, // Text/icons on surface colors

        // Error Color
        error: Colors.redAccent,
        onError: Colors.white,
      ),
      // --- Component Themes ---
      scaffoldBackgroundColor: Colors.white, // Ensure main background is white
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white, // White app bar
        foregroundColor: Colors.black87, // Icons/text on app bar
        elevation: 0.5, // Subtle shadow
        iconTheme: IconThemeData(color: _primaryPurple), // Purple icons? Or keep black?
         titleTextStyle: const TextStyle(color: Colors.black87, fontSize: 20, fontWeight: FontWeight.w500) // Ensure title text color
      ),
      cardTheme: CardTheme(
        color: Colors.white, // White cards
        elevation: 1,
        surfaceTintColor: Colors.transparent, // Prevents M3 tinting
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryPurple, // Purple buttons
          foregroundColor: Colors.white, // White text on buttons
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20), // Adjust padding if needed
        ),
      ),
      textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: _primaryPurple, // Purple text buttons
          )),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: _primaryPurple, // Purple selected icon/label
        unselectedItemColor: Colors.grey.shade600,
        elevation: 0.5,
        type: BottomNavigationBarType.fixed,
      ),
       inputDecorationTheme: InputDecorationTheme( // Theme for TextFormFields
         filled: true,
         fillColor: Colors.grey.shade100, // Light fill for text fields
         border: OutlineInputBorder(
           borderRadius: BorderRadius.circular(12),
           borderSide: BorderSide.none,
         ),
          prefixIconColor: _primaryPurple.shade300, // Slightly lighter purple for icons
       ),
       iconTheme: IconThemeData( // Default icon color
         color: Colors.grey.shade700,
       ),
       primaryIconTheme: IconThemeData( // Icons on primary background (like AppBar)
         color: _primaryPurple,
       ),
       listTileTheme: ListTileThemeData( // Consistent ListTile appearance
          iconColor: _primaryPurple,
       ),
       dividerTheme: DividerThemeData( // Consistent dividers
         color: Colors.grey.shade300,
         thickness: 1,
       )

      // Add more component themes as needed (ChipTheme, DialogTheme etc.)
    );
  }

  ThemeData _buildDarkTheme() {
    final base = ThemeData.dark(useMaterial3: true); // Start with base dark theme
    final darkBackgroundColor = Colors.grey[900]; // A common "light black" or Color(0xFF121212)
    final darkSurfaceColor = Colors.grey[850]; // Slightly lighter for cards/surfaces or Color(0xFF1E1E1E)

    return base.copyWith(
      brightness: Brightness.dark, // Explicitly dark
      // --- Color Scheme ---
       colorScheme: base.colorScheme.copyWith(
        // Primary Color (Lighter Purple for contrast)
        primary: _primaryPurple.shade300, // Use a lighter shade for dark mode
        onPrimary: Colors.black, // Text/icons on light purple buttons

        // Secondary Color (Optional - choose an accent)
        secondary: Colors.purple, // Same accent? Or maybe Colors.cyanAccent?
        onSecondary: Colors.black,

        // Backgrounds
        background: darkBackgroundColor, // Dark grey background
        surface: darkSurfaceColor,    // Slightly lighter dark grey for surfaces
        onBackground: Colors.white70, // Text on dark background
        onSurface: Colors.white, // Text/icons on surface colors

        // Error Color
        error: Colors.redAccent[100], // Lighter red
        onError: Colors.black,
      ),
      // --- Component Themes ---
       scaffoldBackgroundColor: darkBackgroundColor,
       appBarTheme: AppBarTheme(
         backgroundColor: darkSurfaceColor, // Dark app bar
         foregroundColor: Colors.white, // White icons/text on app bar
         elevation: 0.5,
       ),
        cardTheme: CardTheme(
          color: darkSurfaceColor, // Dark cards
          elevation: 1,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
       ),
       elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryPurple.shade300, // Lighter purple buttons
          foregroundColor: Colors.black, // Black text on light purple buttons
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
           padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        ),
      ),
       textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: _primaryPurple.shade300, // Lighter purple text buttons
          )),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: darkSurfaceColor,
          selectedItemColor: _primaryPurple.shade300, // Lighter purple selected icon/label
          unselectedItemColor: Colors.grey.shade500,
          elevation: 0.5,
          type: BottomNavigationBarType.fixed,
      ),
      inputDecorationTheme: InputDecorationTheme(
         filled: true,
         fillColor: Colors.grey.shade800, // Darker fill for text fields
         border: OutlineInputBorder(
           borderRadius: BorderRadius.circular(12),
           borderSide: BorderSide.none,
         ),
         hintStyle: TextStyle(color: Colors.grey.shade500),
         prefixIconColor: _primaryPurple.shade200,
       ),
       iconTheme: IconThemeData(
         color: Colors.grey.shade400, // Lighter grey default icons
       ),
        primaryIconTheme: IconThemeData(
         color: _primaryPurple.shade300,
       ),
        listTileTheme: ListTileThemeData(
          iconColor: _primaryPurple.shade300,
       ),
        dividerTheme: DividerThemeData(
         color: Colors.grey.shade700,
         thickness: 1,
       )
       // Add more component themes
    );
  }


  // --- ADDED: Method to explicitly set the theme mode ---
  void setThemeMode(ThemeMode mode) {
    if (_themeMode != mode) {
      _themeMode = mode;
      notifyListeners(); // Notify listeners to rebuild
      // _saveThemePreference(mode); // Optional: Save the preference
    }
  }

// --- Optional: Persistence using shared_preferences ---
// (Keep commented out unless you add the dependency and want persistence)
// Future<void> loadThemePreference() async { ... }
// Future<void> _saveThemePreference(ThemeMode mode) async { ... }

// --- Consider removing or adapting old methods if unused ---
// bool get isDarkMode => ... ; // Redundant if using currentTheme getter logic
// void toggleTheme() { ... } // Redundant if using setThemeMode

}