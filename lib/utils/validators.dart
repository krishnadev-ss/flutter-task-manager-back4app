/// Form field validators used across the app.
class Validators {
  Validators._();

  static const String _bitsWilpDomain = '@wilp.bits-pilani.ac.in';

  /// Returns a validator that fails if the field is empty.
  static String? Function(String?) required(String fieldName) {
    return (value) {
      if (value == null || value.trim().isEmpty) {
        return '$fieldName is required';
      }
      return null;
    };
  }

  /// BITS WILP email format + domain check.
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final normalizedValue = value.trim().toLowerCase();
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(normalizedValue)) {
      return 'Enter a valid email address';
    }
    if (!normalizedValue.endsWith(_bitsWilpDomain)) {
      return 'Use your BITS WILP email ending with $_bitsWilpDomain';
    }
    return null;
  }

  /// Password: at least 8 chars.
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    return null;
  }

  /// Task title: non-empty, max 120 chars.
  static String? taskTitle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Title is required';
    }
    if (value.trim().length > 120) {
      return 'Title must be 120 characters or fewer';
    }
    return null;
  }
}
