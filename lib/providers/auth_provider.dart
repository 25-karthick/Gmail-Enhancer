import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  User? _user;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;

  AuthProvider() {
    // 🔥 Listen to Firebase Auth State changes
    _authService.authStateChanges.listen((User? user) {
      _user = user;
      notifyListeners();
    });
  }

  /// 🔹 Sign in with Google
  Future<bool> signIn() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = await _authService.signInWithGoogle();
      _isLoading = false;
      notifyListeners();
      return user != null;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// 🔸 Logout user
  Future<void> signOut() async {
    try {
      await _authService.signOut(); // ensures Google + Firebase logout
      _user = null;
      notifyListeners();
    } catch (e) {
      _error = "Sign out failed: $e";
      notifyListeners();
    }
  }

  /// Clear error message from UI
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
