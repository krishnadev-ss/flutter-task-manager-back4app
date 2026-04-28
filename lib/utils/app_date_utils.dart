import 'package:intl/intl.dart';

/// Date/time formatting helpers used across the app.
class AppDateUtils {
  AppDateUtils._();

  static final DateFormat _displayFormat = DateFormat('MMM d, yyyy');

  /// Formats [date] as "Jan 5, 2025". Returns empty string for null.
  static String format(DateTime? date) {
    if (date == null) return '';
    return _displayFormat.format(date.toLocal());
  }

  /// Returns a human-friendly relative label:
  ///   "Today", "Tomorrow", "Yesterday", or the formatted date.
  static String relative(DateTime? date) {
    if (date == null) return '';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);

    final diff = target.difference(today).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff == -1) return 'Yesterday';
    return format(date);
  }

  /// Returns true when [date] is in the past (before today at midnight).
  static bool isOverdue(DateTime? date) {
    if (date == null) return false;
    final today = DateTime.now();
    final todayMidnight = DateTime(today.year, today.month, today.day);
    return date.isBefore(todayMidnight);
  }

  /// Strips the time component and returns a pure date [DateTime].
  static DateTime dateOnly(DateTime dt) =>
      DateTime(dt.year, dt.month, dt.day);
}
