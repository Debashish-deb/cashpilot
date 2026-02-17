import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cashpilot/l10n/app_localizations.dart';

import '../providers/app_providers.dart';
import '../utils/bengali_numerals.dart';

final formatManagerProvider = Provider<FormatManager>((ref) {
  final language = ref.watch(languageProvider);
  return FormatManager(locale: language.code);
});

/// FormatManager
/// Single source of truth for all data formatting
///
/// Guarantees:
/// - Locale-safe formatting
/// - Financial correctness
/// - No crashes on invalid input
/// - Consistent output across the app
class FormatManager {
  final String locale;

  FormatManager({required this.locale});

  // ---------------------------------------------------------------------------
  // CURRENCY
  // ---------------------------------------------------------------------------

  String formatCurrency(
    double amount, {
    String currencyCode = 'EUR',
    int decimalDigits = 2,
  }) {
    try {
      if (!amount.isFinite) {
        return '—';
      }

      // Use Bengali formatting for Bengali locale
      if (locale == 'bn') {
        return BengaliNumerals.formatCurrency(
          amount,
          symbol: _getCurrencySymbol(currencyCode),
          decimalDigits: decimalDigits,
          useIndianGrouping: true,
        );
      }

      final format = NumberFormat.currency(
        locale: locale,
        symbol: _getCurrencySymbol(currencyCode),
        decimalDigits: decimalDigits,
      );

      return format.format(amount);
    } catch (_) {
      // Absolute fallback — formatting must never crash UI
      final fallback = '${_getCurrencySymbol(currencyCode)}${amount.toStringAsFixed(decimalDigits)}';
      return locale == 'bn' ? BengaliNumerals.toBengali(fallback) : fallback;
    }
  }

  /// Format cents from BigInt directly
  String formatCents(
    BigInt cents, {
    String currencyCode = 'EUR',
    int decimalDigits = 2,
  }) {
    return formatCurrency(
      cents.toDouble() / 100.0,
      currencyCode: currencyCode,
      decimalDigits: decimalDigits,
    );
  }

  String formatNumber(num value, {int? decimalDigits}) {
    try {
      final formatted = NumberFormat.decimalPattern(locale).format(value);
      return locale == 'bn' ? BengaliNumerals.toBengali(formatted) : formatted;
    } catch (_) {
      final fallback = value.toString();
      return locale == 'bn' ? BengaliNumerals.toBengali(fallback) : fallback;
    }
  }

  String formatPercentage(double value, {int decimalDigits = 0}) {
    try {
      final format = NumberFormat.percentPattern(locale);
      format.minimumFractionDigits = decimalDigits;
      format.maximumFractionDigits = decimalDigits;
      // NumberFormat.percentPattern expects 0.1 to be 10%, 1.0 to be 100%
      // But typically in UI we have "percentage" as 0..1 or 0..100.
      // Standard Dart NumberFormat expects 0..1 input for percent.
      // However, my app often calculates 0..100 integers.
      // SAFE DESIGN: Accept 0..1 fraction. 
      // If the caller has 0..100, they must divide by 100.
      final formatted = format.format(value);
      return locale == 'bn' ? BengaliNumerals.toBengali(formatted) : formatted;
    } catch (_) {
      final fallback = '${(value * 100).toStringAsFixed(decimalDigits)}%';
      return locale == 'bn' ? BengaliNumerals.toBengali(fallback) : fallback;
    }
  }

  /// Removes trailing zeros safely (e.g. 10.00 → 10, 10.50 → 10.5)
  String removeTrailingZeros(double amount) {
    if (!amount.isFinite) return '0';

    final fixed = amount.toStringAsFixed(2);
    return fixed.replaceFirst(RegExp(r'\.?0+$'), '');
  }

  String _getCurrencySymbol(String code) {
    switch (code.toUpperCase()) {
      case 'EUR':
        return '€';
      case 'USD':
        return '\$';
      case 'GBP':
        return '£';
      case 'BDT':
        return '৳';
      case 'JPY':
        return '¥';
      case 'INR':
        return '₹';
      case 'AUD':
        return 'A\$';
      case 'CAD':
        return 'C\$';
      default:
        // Fallback: show code with space for clarity
        return '$code ';
    }
  }

  // ---------------------------------------------------------------------------
  // DATES
  // ---------------------------------------------------------------------------

  String formatDate(DateTime date, {String? pattern}) {
    try {
      final formatted = pattern != null
          ? DateFormat(pattern, locale).format(date)
          : DateFormat.yMMMd(locale).format(date);
      return locale == 'bn' ? BengaliNumerals.toBengali(formatted) : formatted;
    } catch (_) {
      final fallback = _fallbackDate(date);
      return locale == 'bn' ? BengaliNumerals.toBengali(fallback) : fallback;
    }
  }

  String formatTime(DateTime date) {
    try {
      return DateFormat.jm(locale).format(date);
    } catch (_) {
      return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    }
  }

  String formatDateTime(DateTime date) {
    try {
      return DateFormat.yMMMd(locale).add_jm().format(date);
    } catch (_) {
      return '${_fallbackDate(date)} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    }
  }

  /// Returns "Today", "Yesterday", or formatted date
  String formatRelativeDate(DateTime date, AppLocalizations l10n) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final input = DateTime(date.year, date.month, date.day);

    if (input == today) {
      return l10n.commonToday;
    } else if (input == today.subtract(const Duration(days: 1))) {
      return l10n.commonYesterday;
    } else {
      return formatDate(date);
    }
  }

  // ---------------------------------------------------------------------------
  // FALLBACKS
  // ---------------------------------------------------------------------------

  String _fallbackDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
