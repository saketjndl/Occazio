import 'package:flutter/material.dart';

class AuthProvider with ChangeNotifier {
  bool _isLoggedIn = false;
  String? _token;
  String? _userId;

  bool get isLoggedIn => _isLoggedIn;
  String? get token => _token;
  String? get userId => _userId;

  Future<bool> login(String email, String password) async {
    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    // For demo purposes, always succeed
    _isLoggedIn = true;
    _token = 'demo_token';
    _userId = 'user_123';

    notifyListeners();
    return true;
  }

  Future<bool> signUp(String name, String email, String password) async {
    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    // For demo purposes, always succeed
    _isLoggedIn = true;
    _token = 'demo_token';
    _userId = 'user_123';

    notifyListeners();
    return true;
  }

  Future<void> logout() async {
    _isLoggedIn = false;
    _token = null;
    _userId = null;

    notifyListeners();
  }
}