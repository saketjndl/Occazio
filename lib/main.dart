import 'package:flutter/material.dart';
import 'package:occazziotest/screens/cart_screen.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
// --- MODIFIED IMPORT ---
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider; // HIDE firebase's AuthProvider
import 'screens/settings_screen.dart';

// Screens
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/main_screen.dart';
import 'screens/create_event_screen.dart';

// Providers
// --- YOUR PROVIDER IMPORT (Leave as is) ---
import 'providers/auth_provider.dart'; // Your ChangeNotifier AuthProvider
import 'providers/theme_provider.dart';

// --- Rest of your main.dart code ---
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(
    MultiProvider(
      providers: [
        // Now this will correctly use YOUR AuthProvider from providers/auth_provider.dart
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const OccazioApp(),
    ),
  );
}

class OccazioApp extends StatelessWidget {
  const OccazioApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Get the ThemeProvider instance
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      // --- ADD THEME CONFIGURATION HERE ---
      title: 'Occazio', // Or use localization later
      debugShowCheckedModeBanner: false,

      // Get the actual ThemeData from the provider
      theme: themeProvider.currentTheme,

      // Also use the provider for dark theme (currentTheme handles logic)
      darkTheme: themeProvider.currentTheme,

      // Tell MaterialApp which mode to respect
      themeMode: themeProvider.themeMode,
      // --- END THEME CONFIGURATION ---

      initialRoute: '/splash', // Start with splash screen
      routes: {
        // Your existing routes are fine
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/main': (context) => const MainScreen(),
        '/create_event': (context) => const CreateEventScreen(),
        // Make sure you have the '/settings' route if you created SettingsScreen
        '/settings': (context) => const SettingsScreen(), // Add this if missing
        '/cart': (context) => const CartScreen(),
      },
    );
  }
}
