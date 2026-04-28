import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

import '../models/user_model.dart';

/// Wraps all Parse authentication calls.
class AuthService {
  // ─── Sign-up ──────────────────────────────────────────────────────────────

  Future<UserModel> signUp({
    required String username,
    required String email,
    required String password,
  }) async {
    final user = ParseUser(username.trim(), password, email.trim().toLowerCase());
    final response = await user.signUp();

    if (response.success && response.result != null) {
      return UserModel.fromParseUser(response.result as ParseUser);
    }

    throw AuthException(_errorFrom(response));
  }

  // ─── Login ────────────────────────────────────────────────────────────────

  Future<UserModel> login({
    required String username,
    required String password,
  }) async {
    final user = ParseUser(username.trim(), password, null);
    final response = await user.login();

    if (response.success && response.result != null) {
      return UserModel.fromParseUser(response.result as ParseUser);
    }

    throw AuthException(_errorFrom(response));
  }

  // ─── Logout ───────────────────────────────────────────────────────────────

  Future<void> logout() async {
    final ParseUser? user = await ParseUser.currentUser() as ParseUser?;
    if (user == null) return;

    final response = await user.logout();
    if (!response.success) {
      // Log but never block local logout — session may already be expired
      // ignore: avoid_print
      print('[AuthService] Server logout error: ${_errorFrom(response)}');
    }
  }

  // ─── Session check ────────────────────────────────────────────────────────

  /// Restores the locally-cached Parse session and validates it with the
  /// server. Returns null if there is no valid session.
  Future<UserModel?> getCurrentUser() async {
    try {
      final ParseUser? cached = await ParseUser.currentUser() as ParseUser?;
      if (cached == null) return null;

      // Fetch the user record from the server to confirm the session is alive.
      // ParseUser.fetch() uses the cached session token automatically.
      final response = await cached.getUpdatedUser();
      if (response.success && response.result != null) {
        return UserModel.fromParseUser(response.result as ParseUser);
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  String _errorFrom(ParseResponse response) {
    if (response.error != null) {
      return response.error!.message;
    }
    return 'An unexpected error occurred. Please try again.';
  }
}

/// Thrown by [AuthService] on authentication failures.
class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}
