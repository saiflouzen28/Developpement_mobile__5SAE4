import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  /// 🔹 Tente la reconnexion automatique (session sauvegardée)
  Future<void> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('userId')) return;

    final userId = prefs.getInt('userId');
    if (userId == null) return;

    final userData = await DatabaseHelper.instance.getUserById(userId);
    if (userData != null) {
      _user = User.fromMap(userData);
      notifyListeners();
    }
  }

  /// 🔹 Connexion utilisateur (admin ou normal)
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _setError(null);
    try {
      final userData = await DatabaseHelper.instance.loginUser(email, password);
      if (userData != null) {
        _user = User.fromMap(userData);

        // Sauvegarder la session
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('userId', _user!.id!);

        // Debug info
        if (kDebugMode) {
          print('👤 Logged in as: ${_user!.email}');
          print('🛠️ Admin status: ${_user!.isAdmin}');
        }

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

  /// 🔹 Inscription utilisateur
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

      final userId = await DatabaseHelper.instance.registerUser(
        nom,
        prenom,
        email,
        password,
        numtel,
      );

      if (userId > 0) {
        // Auto-login après inscription
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

  /// 🔹 Déconnexion + suppression session
  Future<void> logout() async {
    _user = null;
    _error = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
    notifyListeners();
  }

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
