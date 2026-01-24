/// Locale-aware date formatting utilities
/// Ensures Bengali and Finnish show full month/day names
library;

import 'package:intl/intl.dart';

class LocalizedDateFormatter {
  /// Format a date range with locale-aware month names
  /// Bengali and Finnish use full names (MMMM), others use abbreviated (MMM)
  static String formatDateRange(DateTime start, DateTime end, String locale) {
    final monthFormat = _shouldUseFullMonthName(locale) ? 'MMMM' : 'MMM';
    final startStr = DateFormat('$monthFormat d', locale).format(start);
    final endStr = DateFormat('$monthFormat d, yyyy', locale).format(end);
    return '$startStr • $endStr';
  }

  /// Format month and day with locale-aware month name
  static String formatMonthDay(DateTime date, String locale) {
    final monthFormat = _shouldUseFullMonthName(locale) ? 'MMMM' : 'MMM';
    return DateFormat('$monthFormat d', locale).format(date);
  }

  /// Format month, day, and year with locale-aware month name
  static String formatMonthDayYear(DateTime date, String locale) {
    final monthFormat = _shouldUseFullMonthName(locale) ? 'MMMM' : 'MMM';
    return DateFormat('$monthFormat d, y', locale).format(date);
  }

  /// Format full date with weekday, month, day, and year (used in expense form)
  static String formatFullDate(DateTime date, String locale) {
    // Always use full format for clarity
    return DateFormat('EEEE, MMMM d, yyyy', locale).format(date);
  }

  /// Check if locale should use full month names for clarity
  static bool _shouldUseFullMonthName(String locale) {
    // Bengali and Finnish benefit from full month names
    // Can add more locales as needed
    return locale == 'bn' || locale == 'fi';
  }
}
