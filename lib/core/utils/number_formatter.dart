/// Number localization utilities
/// Converts Western numerals to locale-specific numerals (Bengali, etc.)
library;

class LocalizedNumberFormatter {
  /// Bengali numeral mapping
  static const Map<String, String> _bengaliNumerals = {
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

  /// Convert Western numerals to locale-specific numerals
  static String localizeNumber(String input, String locale) {
    if (locale == 'bn') {
      return _convertToBengali(input);
    }
    // Finnish uses Western numerals, no conversion needed
    return input;
  }

  /// Convert Western numerals to Bengali
  static String _convertToBengali(String input) {
    String result = input;
    _bengaliNumerals.forEach((western, bengali) {
      result = result.replaceAll(western, bengali);
    });
    return result;
  }

  /// Format a number value with locale-specific numerals
  static String formatNumber(num value, String locale, {int decimals = 2}) {
    final formatted = value.toStringAsFixed(decimals);
    return localizeNumber(formatted, locale);
  }

  /// Format a percentage with locale-specific numerals
  static String formatPercentage(num value, String locale, {int decimals = 1}) {
    final formatted = value.toStringAsFixed(decimals);
    return '${localizeNumber(formatted, locale)}%';
  }

  /// Format currency amount with locale-specific numerals
  static String formatCurrency(num value, String currency, String locale, {int decimals = 2}) {
    final formatted = value.toStringAsFixed(decimals);
    final localizedNumber = localizeNumber(formatted, locale);
    
    // Currency symbol placement
    final symbol = _getCurrencySymbol(currency);
    return '$symbol$localizedNumber';
  }

  /// Get currency symbol
  static String _getCurrencySymbol(String currency) {
    switch (currency) {
      case 'EUR':
        return '€';
      case 'USD':
        return '\$';
      case 'GBP':
        return '£';
      case 'BDT':
        return '৳';
      case 'INR':
        return '₹';
      default:
        return currency;
    }
  }
}
