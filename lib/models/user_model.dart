import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

/// Lightweight user model used across the UI layer.
class UserModel {
  final String objectId;
  final String username;
  final String email;

  const UserModel({
    required this.objectId,
    required this.username,
    required this.email,
  });

  factory UserModel.fromParseUser(ParseUser user) {
    return UserModel(
      objectId: user.objectId ?? '',
      username: user.username ?? '',
      email: user.emailAddress ?? '',
    );
  }

  /// Returns the display name — falls back to email prefix if username is blank.
  String get displayName =>
      username.isNotEmpty ? username : email.split('@').first;

  /// Returns the first letter of [displayName] in upper case (avatar initial).
  String get initial => displayName.isNotEmpty
      ? displayName[0].toUpperCase()
      : '?';
}
