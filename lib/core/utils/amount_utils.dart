import 'package:flutter/foundation.dart';

class AmountUtils {
  /// Maximum allowed amount in cents (e.g., $1,000,000,000,000.00 / 1 Trillion)
  /// This prevents overflow issues in calculations and logic attacks.
  static const int maxAmountCents = 100000000000000; 

  /// Parses a string amount and validates it for fintech safety.
  /// 
  /// [input] The raw text input from the user.
  /// [currency] Optional currency code for context-aware validation.
  /// 
  /// Returns the amount in CENTS.
  /// Throws [AmountValidationException] if the input is invalid or out of range.
  static int parseToCents(String input) {
    if (input.isEmpty) {
      throw const AmountValidationException('Amount cannot be empty');
    }

    // 1. Sanitize: Remove all non-numeric characters except decimal points/commas
    // We normalize commas to dots for parsing
    String sanitized = input.replaceAll(RegExp(r'[^\d,.]'), '').replaceAll(',', '.');

    // 2. Parse to double
    final doubleValue = double.tryParse(sanitized);
    if (doubleValue == null) {
      throw const AmountValidationException('Invalid number format');
    }

    // 3. Prevent Negative amounts unless explicitly allowed (usually not for assets/liabilities)
    if (doubleValue < 0) {
      throw const AmountValidationException('Amount must be positive');
    }

    // 4. Convert to cents
    final cents = (doubleValue * 100).round();

    // 5. Enforce Maximum Value
    if (cents > maxAmountCents) {
      throw AmountValidationException(
        'Amount exceeds maximum limit of \$1,000,000,000,000.00'
      );
    }

    return cents;
  }

  /// Formats cents back to a user-friendly string
  static String formatFromCents(int cents) {
    return (cents / 100).toStringAsFixed(2);
  }
}

class AmountValidationException implements Exception {
  final String message;
  const AmountValidationException(this.message);

  @override
  String toString() => message;
}
