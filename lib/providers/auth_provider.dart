// lib/providers/auth_provider.dart

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart'; // 1. Import shared_preferences
import '../database/database_helper.dart';
import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  // 2. --- NEW METHOD to check for a saved session ---
  Future<void> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('userId')) {
      return; // No saved user, do nothing.
    }
    final userId = prefs.getInt('userId');
    if (userId == null) {
      return;
    }

    // Fetch the full user details from the database using the saved ID.
    // NOTE: Make sure you have a `getUserById` method in your DatabaseHelper.
    final userData = await DatabaseHelper.instance.getUserById(userId);
    if (userData != null) {
      _user = User.fromMap(userData);
      notifyListeners();
    }
  }

  // 3. --- UPDATED login method ---
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _setError(null);
    try {
      final userData = await DatabaseHelper.instance.loginUser(email, password);
      if (userData != null) {
        _user = User.fromMap(userData);

        // --- SAVE USER SESSION ---
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('userId', _user!.id!); // Save the logged-in user's ID

        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        _setError('Invalid email or password');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Login failed: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  // 4. --- UPDATED register method ---
  Future<bool> register(String nom, String prenom, String email, String password, String numtel) async {
    _setLoading(true);
    _setError(null);
    try {
      final existingUser = await DatabaseHelper.instance.getUserByEmail(email);
      if (existingUser != null) {
        _setError('User with this email already exists');
        _setLoading(false);
        return false;
      }

      final userId = await DatabaseHelper.instance.registerUser(nom, prenom, email, password, numtel);
      if (userId > 0) {
        // Auto-login after registration and SAVE the session
        final success = await login(email, password);
        return success;
      }

      _setError('Registration failed');
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('Registration failed: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  // 5. --- UPDATED logout method ---
  Future<void> logout() async {
    _user = null;
    _error = null;

    // --- CLEAR USER SESSION ---
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId'); // Remove the user ID from storage

    notifyListeners();
  }

  // Helper methods remain the same
  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }
}
