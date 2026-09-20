import 'package:intl/intl.dart';

/// Date and time formatting utilities.
class AppDateUtils {
  AppDateUtils._();

  static final DateFormat _timeFormat = DateFormat('HH:mm');
  static final DateFormat _dateFormat = DateFormat('MMM d, yyyy');
  static final DateFormat _dayFormat = DateFormat('EEE');
  static final DateFormat _shortDateFormat = DateFormat('MMM d');

  /// Format time as HH:mm (e.g., "13:45")
  static String formatTime(DateTime dateTime) => _timeFormat.format(dateTime);

  /// Format date as "Sep 19, 2026"
  static String formatDate(DateTime dateTime) => _dateFormat.format(dateTime);

  /// Format as short date "Sep 19"
  static String formatShortDate(DateTime dateTime) => _shortDateFormat.format(dateTime);

  /// Format as day of week "Mon"
  static String formatDay(DateTime dateTime) => _dayFormat.format(dateTime);

  /// Returns "Today", "Yesterday", or the formatted date
  static String formatRelativeDate(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (date == today) return 'Today';
    if (date == today.subtract(const Duration(days: 1))) return 'Yesterday';
    return formatDate(dateTime);
  }

  /// Returns time-aware greeting
  static String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }
}
