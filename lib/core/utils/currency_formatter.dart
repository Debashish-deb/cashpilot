
import 'package:intl/intl.dart';

class CurrencyFormatter {
  static String format(double amount, {String currencyCode = 'EUR', int decimalDigits = 2}) {
    final format = NumberFormat.currency(
      symbol: _getSymbol(currencyCode),
      decimalDigits: decimalDigits,
    );
    return format.format(amount);
  }

  static String _getSymbol(String currencyCode) {
    switch (currencyCode) {
      case 'EUR': return '€';
      case 'USD': return '\$';
      case 'GBP': return '£';
      case 'BDT': return '৳';
      default: return currencyCode;
    }
  }
}
