/// Bengali Numeral Utilities
/// Convert Western Arabic numerals to Bengali numerals for proper localization
library;

/// Bengali numeral mapping
/// Western: 0 1 2 3 4 5 6 7 8 9
/// Bengali: ০ ১ ২ ৩ ৪ ৫ ৬ ৭ ৮ ৯
class BengaliNumerals {
  // Mapping table for conversion
  static const Map<String, String> _numeralMap = {
    '0': '০',
    '1': '১',
    '2': '২',
    '3': '৩',
    '4': '৪',
    '5': '৫',
    '6': '৬',
    '7': '৭',
    '8': '৮',
    '9': '৯',
  };

  static const Map<String, String> _reverseMap = {
    '০': '0',
    '১': '1',
    '২': '2',
    '৩': '3',
    '৪': '4',
    '৫': '5',
    '৬': '6',
    '৭': '7',
    '৮': '8',
    '৯': '9',
  };

  /// Convert Western Arabic numerals to Bengali numerals
  /// Example: "123.45" → "১২৩.৪৫"
  static String toBengali(String input) {
    if (input.isEmpty) return input;

    final buffer = StringBuffer();
    for (final ch in input.split('')) {
      buffer.write(_numeralMap[ch] ?? ch);
    }
    return buffer.toString();
  }

  /// Convert Bengali numerals to Western Arabic numerals
  /// Example: "১২৩.৪৫" → "123.45"
  static String toWestern(String input) {
    if (input.isEmpty) return input;

    final buffer = StringBuffer();
    for (final ch in input.split('')) {
      buffer.write(_reverseMap[ch] ?? ch);
    }
    return buffer.toString();
  }

  /// Format a number with Bengali numerals
  /// Example: 123.45 → "১২৩.৪৫"
  static String formatNumber(num value, {int? decimalDigits}) {
    if (!value.isFinite) return '—';

    final formatted = decimalDigits != null
        ? value.toStringAsFixed(decimalDigits)
        : value.toString();

    return toBengali(formatted);
  }

  /// Format currency with Bengali numerals and Indian grouping (optional)
  /// Example: 123456.78 → "৳১,২৩,৪৫৬.৭৮"
  static String formatCurrency(
    double amount, {
    String symbol = '৳',
    int decimalDigits = 2,
    bool useIndianGrouping = true,
  }) {
    if (!amount.isFinite) return '—';

    final isNegative = amount < 0;
    final absAmount = amount.abs();

    final formatted = absAmount.toStringAsFixed(decimalDigits);
    final parts = formatted.split('.');
    final integerPart = parts[0];
    final decimalPart = parts.length > 1 ? parts[1] : null;

    final grouped = useIndianGrouping
        ? _applyIndianGrouping(integerPart)
        : _applyWesternGrouping(integerPart);

    final combined = decimalPart != null && decimalPart.isNotEmpty
        ? '$grouped.$decimalPart'
        : grouped;

    final withSymbol =
        '${isNegative ? '-' : ''}$symbol$combined';

    return toBengali(withSymbol);
  }

  /// Apply Indian number grouping: 1,00,00,000 (lakhs/crores)
  static String _applyIndianGrouping(String number) {
    if (number.length <= 3) return number;

    final lastThree = number.substring(number.length - 3);
    final prefix = number.substring(0, number.length - 3);

    final buffer = StringBuffer();
    int count = 0;

    for (int i = prefix.length - 1; i >= 0; i--) {
      buffer.write(prefix[i]);
      count++;
      if (count == 2 && i != 0) {
        buffer.write(',');
        count = 0;
      }
    }

    final groupedPrefix =
        buffer.toString().split('').reversed.join();

    return '$groupedPrefix,$lastThree';
  }

  /// Apply Western number grouping: 1,000,000 (thousands)
  static String _applyWesternGrouping(String number) {
    final buffer = StringBuffer();
    int count = 0;

    for (int i = number.length - 1; i >= 0; i--) {
      buffer.write(number[i]);
      count++;
      if (count == 3 && i != 0) {
        buffer.write(',');
        count = 0;
      }
    }

    return buffer.toString().split('').reversed.join();
  }

  /// Check if a string contains Bengali numerals
  static bool hasBengaliNumerals(String input) {
    return _reverseMap.keys.any(input.contains);
  }

  /// Check if a string contains only valid Bengali numerals and formatting
  static bool isValidBengaliNumber(String input) {
    if (input.isEmpty) return false;

    // Optional sign, digits, grouped commas, optional decimal
    final regex = RegExp(
      r'^-?[০-৯]+(,[০-৯]{2,3})*(\.[০-৯]+)?$',
    );
    return regex.hasMatch(input.replaceAll(' ', ''));
  }
}
