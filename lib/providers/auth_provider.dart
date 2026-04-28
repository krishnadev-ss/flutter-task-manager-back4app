import 'package:flutter/foundation.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated }

/// Manages authentication state for the whole app via [ChangeNotifier].
class AuthProvider extends ChangeNotifier {
  AuthProvider() : _authService = AuthService();

  final AuthService _authService;

  AuthStatus _status = AuthStatus.initial;
  UserModel? _currentUser;
  String? _errorMessage;

  // ─── Getters ──────────────────────────────────────────────────────────────

  AuthStatus get status => _status;
  UserModel? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoading => _status == AuthStatus.loading;

  // ─── Session check ────────────────────────────────────────────────────────

  /// Called once on app startup (from SplashScreen) to restore a saved session.
  Future<void> checkSession() async {
    _status = AuthStatus.loading;
    notifyListeners();

    try {
      final user = await _authService.getCurrentUser();
      if (user != null) {
        _currentUser = user;
        _status = AuthStatus.authenticated;
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (_) {
      _status = AuthStatus.unauthenticated;
    }

    notifyListeners();
  }

  // ─── Sign-up ──────────────────────────────────────────────────────────────

  Future<bool> signUp({
    required String username,
    required String email,
    required String password,
  }) async {
    _beginLoading();

    try {
      _currentUser = await _authService.signUp(
        username: username,
        email: email,
        password: password,
      );
      _status = AuthStatus.authenticated;
      _errorMessage = null;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _failWith(e.message);
      return false;
    } catch (_) {
      _failWith('An unexpected error occurred. Please try again.');
      return false;
    }
  }

  // ─── Login ────────────────────────────────────────────────────────────────

  Future<bool> login({
    required String username,
    required String password,
  }) async {
    _beginLoading();

    try {
      _currentUser = await _authService.login(
        username: username,
        password: password,
      );
      _status = AuthStatus.authenticated;
      _errorMessage = null;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _failWith(e.message);
      return false;
    } catch (_) {
      _failWith('An unexpected error occurred. Please try again.');
      return false;
    }
  }

  // ─── Logout ───────────────────────────────────────────────────────────────

  Future<void> logout() async {
    _beginLoading();
    try {
      await _authService.logout();
    } catch (_) {
      // Always perform local logout even if the server call fails
    }
    _currentUser = null;
    _status = AuthStatus.unauthenticated;
    _errorMessage = null;
    notifyListeners();
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  void _beginLoading() {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();
  }

  void _failWith(String message) {
    _errorMessage = message;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}
