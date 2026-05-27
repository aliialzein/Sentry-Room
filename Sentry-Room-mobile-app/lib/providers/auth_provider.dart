import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../constants/api_constants.dart';

class AuthProvider with ChangeNotifier {
  bool _isAuthenticated = false;
  String? _username;
  String? _email;
  String? _fullName;
  String? _role;
  bool _isAdmin = false;
  bool _isActive = false;
  int? _userId;
  String? _errorMessage;

  bool _criticalAlerts = true;
  bool _cameraAlerts = true;
  bool _eventNotifications = true;
  bool _compactDashboard = false;
  bool _saveActivityLocally = true;
  bool _settingsLoaded = false;

  final ApiService _apiService = ApiService(ApiConstants.baseUrl);

  bool get isAuthenticated => _isAuthenticated;
  String? get username => _username;
  String? get email => _email;
  String? get fullName => _fullName;
  String? get role => _role;
  bool get isAdmin => _isAdmin;
  bool get isActive => _isActive;
  int? get userId => _userId;
  String? get errorMessage => _errorMessage;

  bool get criticalAlerts => _criticalAlerts;
  bool get cameraAlerts => _cameraAlerts;
  bool get eventNotifications => _eventNotifications;
  bool get compactDashboard => _compactDashboard;
  bool get saveActivityLocally => _saveActivityLocally;
  bool get settingsLoaded => _settingsLoaded;


  AuthProvider() {
    _loadAuthStatus();
  }

  Future<void> _loadAuthStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isAuthenticated = prefs.getBool('isAuthenticated') ?? false;
      if (_isAuthenticated) {
        _userId = prefs.getInt('userId');
        _username = prefs.getString('username');
        _email = prefs.getString('email');
        _fullName = prefs.getString('fullName');
        _role = prefs.getString('role');
        _isAdmin = prefs.getBool('isAdmin') ?? false;
        _isActive = prefs.getBool('isActive') ?? true;
        _criticalAlerts = prefs.getBool('criticalAlerts') ?? true;
        _cameraAlerts = prefs.getBool('cameraAlerts') ?? true;
        _eventNotifications = prefs.getBool('eventNotifications') ?? true;
        _compactDashboard = prefs.getBool('compactDashboard') ?? false;
        _saveActivityLocally = prefs.getBool('saveActivityLocally') ?? true;
        _settingsLoaded = true;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading auth status: $e');
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> login(String identifier, String password) async {
    _errorMessage = null;

    if (identifier.isEmpty || password.isEmpty) {
      _errorMessage = "Identity and password are required";
      notifyListeners();
      return false;
    }

    try {
      debugPrint('Attempting login for: $identifier');

      final data = await _apiService.login(identifier, password);
      debugPrint('LOGIN RESPONSE DATA: $data');

      final user = data['user'];

      if (user == null) {
        throw Exception("Server missing user object in response");
      }

      final bool active = user['is_active'] ?? true;

      if (!active) {
        _errorMessage = "Your account is deactivated. Contact an admin.";
        notifyListeners();
        return false;
      }

      _userId = user['id'];
      _username = user['username'] ?? identifier;
      _email = user['email'];
      _fullName = user['full_name'];
      _role = user['role'];
      _isAdmin = user['is_admin'] ?? false;
      _isActive = active;

      if (_userId == null) {
        throw Exception("Server missing user ID in response");
      }

      _isAuthenticated = true;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isAuthenticated', true);
      await prefs.setInt('userId', _userId!);
      await prefs.setString('username', _username ?? identifier);

      if (_email != null) {
        await prefs.setString('email', _email!);
      }

      if (_fullName != null) {
        await prefs.setString('fullName', _fullName!);
      }

      if (_role != null) {
        await prefs.setString('role', _role!);
      }

      await prefs.setBool('isAdmin', _isAdmin);
      await prefs.setBool('isActive', _isActive);

      notifyListeners();
      return true;
    } catch (e) {
      _isAuthenticated = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      debugPrint('Login Failed: $_errorMessage');
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String username,
    required String email,
    required String password,
    required String fullName,
  }) async {
    _errorMessage = null;
    try {
      debugPrint('Attempting registration for: $username');
      await _apiService.register(
        username: username,
        email: email,
        password: password,
        fullName: fullName,
      );
      
      debugPrint('Registration success, logging in...');
      return await login(username, password);
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      debugPrint('Registration failed: $_errorMessage');
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProfile({
    required String username,
    required String email,
    required String fullName,
  }) async {
    _errorMessage = null;

    if (_userId == null) {
      _errorMessage = 'No logged-in user found.';
      notifyListeners();
      return false;
    }

    try {
      final updatedUser = await _apiService.updateUserProfile(
        userId: _userId!,
        username: username,
        email: email,
        fullName: fullName,
      );

      _userId = updatedUser['id'];
      _username = updatedUser['username'];
      _email = updatedUser['email'];
      _fullName = updatedUser['full_name'];
      _role = updatedUser['role'];
      _isAdmin = updatedUser['is_admin'] ?? false;
      _isActive = updatedUser['is_active'] ?? true;

      final prefs = await SharedPreferences.getInstance();

      await prefs.setBool('isAuthenticated', true);
      await prefs.setInt('userId', _userId!);
      await prefs.setString('username', _username ?? username);
      await prefs.setString('email', _email ?? email);

      if (_fullName != null && _fullName!.isNotEmpty) {
        await prefs.setString('fullName', _fullName!);
      } else {
        await prefs.remove('fullName');
      }

      if (_role != null) {
        await prefs.setString('role', _role!);
      }

      await prefs.setBool('isAdmin', _isAdmin);
      await prefs.setBool('isActive', _isActive);

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      debugPrint('Profile update failed: $_errorMessage');
      notifyListeners();
      return false;
    }
  }
  
  Future<bool> updateSettings({
    required bool criticalAlerts,
    required bool cameraAlerts,
    required bool eventNotifications,
    required bool compactDashboard,
    required bool saveActivityLocally,
  }) async {
    _errorMessage = null;

    try {
      _criticalAlerts = criticalAlerts;
      _cameraAlerts = cameraAlerts;
      _eventNotifications = eventNotifications;
      _compactDashboard = compactDashboard;
      _saveActivityLocally = saveActivityLocally;
      _settingsLoaded = true;

      final prefs = await SharedPreferences.getInstance();

      await prefs.setBool('criticalAlerts', _criticalAlerts);
      await prefs.setBool('cameraAlerts', _cameraAlerts);
      await prefs.setBool('eventNotifications', _eventNotifications);
      await prefs.setBool('compactDashboard', _compactDashboard);
      await prefs.setBool('saveActivityLocally', _saveActivityLocally);

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      debugPrint('Settings update failed: $_errorMessage');
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _isAuthenticated = false;
    _userId = null;
    _username = null;
    _email = null;
    _fullName = null;
    _role = null;
    _isAdmin = false;
    _isActive = false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('isAuthenticated');
    await prefs.remove('userId');
    await prefs.remove('username');
    await prefs.remove('email');
    await prefs.remove('fullName');
    await prefs.remove('role');
    await prefs.remove('isAdmin');
    await prefs.remove('isActive');
    notifyListeners();
  }

  
  Future<List<Map<String, dynamic>>> fetchAllUsers() async {
    try {
      return await _apiService.getUsers();
    } catch (e) {
      debugPrint('Fetch users failed: $e');
      return [];
    }
  }

  Future<bool> updateUserRole(int targetUserId, String newRole) async {
    try {
      await _apiService.updateUserRole(targetUserId, newRole);
      return true;
    } catch (e) {
      debugPrint('Role update failed: $e');
      return false;
    }
  }

  Future<bool> updateUserStatus(int targetUserId, bool isActive) async {
    try {
      await _apiService.updateUserStatus(targetUserId, isActive);
      return true;
    } catch (e) {
      debugPrint('Status update failed: $e');
      return false;
    }
  }
}
