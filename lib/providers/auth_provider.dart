import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider with ChangeNotifier {
  bool _isAuthenticated = false;
  String? _username;
  bool _isAdmin = true; // Defaulting to true for development

  bool get isAuthenticated => _isAuthenticated;
  String? get username => _username;
  bool get isAdmin => _isAdmin;

  AuthProvider() {
    _loadAuthStatus();
  }

  Future<void> _loadAuthStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _isAuthenticated = prefs.getBool('isAuthenticated') ?? false;
    _username = prefs.getString('username');
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    // In a real app, you'd call an API here.
    // For now, we'll simulate a successful login.
    if (username.isNotEmpty && password.length >= 6) {
      _isAuthenticated = true;
      _username = username;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isAuthenticated', true);
      await prefs.setString('username', username);
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> register(String username, String email, String password) async {
    // Simulate registration
    return login(username, password);
  }

  Future<void> logout() async {
    _isAuthenticated = false;
    _username = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('isAuthenticated');
    await prefs.remove('username');
    notifyListeners();
  }
}
