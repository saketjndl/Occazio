import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Auth Provider for handling authentication
class AuthProvider with ChangeNotifier {
  bool _isAuthenticated = false;
  String? _userId;
  String? _userEmail;
  String? _token;

  bool get isAuthenticated => _isAuthenticated;
  String? get userId => _userId;
  String? get userEmail => _userEmail;
  String? get token => _token;

  Future<bool> login(String email, String password) async {
    // Simulate API call with a delay
    await Future.delayed(const Duration(seconds: 1));

    // This would be replaced with actual API authentication logic
    if (email.isNotEmpty && password.isNotEmpty) {
      _isAuthenticated = true;
      _userId = "user_${DateTime.now().millisecondsSinceEpoch}";
      _userEmail = email;
      _token = "sample_token_${DateTime.now().millisecondsSinceEpoch}";

      // Store auth data
      _saveAuthData();
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> signup(String name, String email, String password) async {
    // Simulate API call with a delay
    await Future.delayed(const Duration(seconds: 1));

    // This would be replaced with actual API registration logic
    if (name.isNotEmpty && email.isNotEmpty && password.isNotEmpty) {
      _isAuthenticated = true;
      _userId = "user_${DateTime.now().millisecondsSinceEpoch}";
      _userEmail = email;
      _token = "sample_token_${DateTime.now().millisecondsSinceEpoch}";

      // Store auth data
      _saveAuthData();
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> logout() async {
    _isAuthenticated = false;
    _userId = null;
    _userEmail = null;
    _token = null;

    final prefs = await SharedPreferences.getInstance();
    prefs.remove('auth_token');
    prefs.remove('user_id');
    prefs.remove('user_email');
    notifyListeners();
  }

  Future<bool> autoLogin() async {
    final prefs = await SharedPreferences.getInstance();

    if (!prefs.containsKey('auth_token')) {
      return false;
    }

    _token = prefs.getString('auth_token');
    _userId = prefs.getString('user_id');
    _userEmail = prefs.getString('user_email');
    _isAuthenticated = true;
    notifyListeners();
    return true;
  }

  Future<void> _saveAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('auth_token', _token!);
    prefs.setString('user_id', _userId!);
    prefs.setString('user_email', _userEmail!);
  }
}

// Theme Provider for handling theme settings
class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  ThemeProvider() {
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('dark_mode') ?? false;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('dark_mode', _isDarkMode);
    notifyListeners();
  }

  ThemeData get currentTheme {
    if (_isDarkMode) {
      return ThemeData(
        primaryColor: const Color(0xFF6A1B9A),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6A1B9A),
          primary: const Color(0xFF6A1B9A),
          secondary: const Color(0xFF9C27B0),
          tertiary: const Color(0xFFE1BEE7),
          brightness: Brightness.dark,
        ),
        fontFamily: 'Roboto',
        useMaterial3: true,
      );
    } else {
      return ThemeData(
        primaryColor: const Color(0xFF6A1B9A),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6A1B9A),
          primary: const Color(0xFF6A1B9A),
          secondary: const Color(0xFF9C27B0),
          tertiary: const Color(0xFFE1BEE7),
          brightness: Brightness.light,
        ),
        fontFamily: 'Roboto',
        useMaterial3: true,
      );
    }
  }
}