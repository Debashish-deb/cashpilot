import 'package:decimal/decimal.dart';
import 'package:rational/rational.dart';
import 'package:intl/intl.dart';

enum Currency {
  USD,
  EUR,
  GBP,
  JPY,
  CAD,
  AUD,
  INR,
  BHD; // Bahraini Dinar (3 decimal places)

  int get decimalPlaces {
    switch (this) {
      case Currency.JPY:
        return 0;
      case Currency.BHD:
        return 3;
      default:
        return 2;
    }
  }

  String get symbol {
    switch (this) {
      case Currency.USD:
      case Currency.CAD:
      case Currency.AUD:
        return '\$';
      case Currency.EUR:
        return '€';
      case Currency.GBP:
        return '£';
      case Currency.JPY:
        return '¥';
      case Currency.INR:
        return '₹';
      case Currency.BHD:
        return 'BD';
    }
  }
}

class Money {
  final int cents;
  final Currency currency;

  const Money(this.cents, this.currency);

  /// Parse from string (e.g., "100.50", "$1,000.00")
  factory Money.parse(String amount, Currency currency) {
    try {
      // Clean string: remove symbols, commas, spaces
      String cleaned = amount.replaceAll(RegExp(r'[^\d.]'), '');
      
      if (cleaned.isEmpty) throw MoneyParseException('Empty amount');
      
      // Use Decimal for precise intermediate parsing
      final decimal = Decimal.parse(cleaned);
      
      // Convert to cents based on currency precision
      final factor = BigInt.from(10).pow(currency.decimalPlaces);
      final product = decimal * Decimal.fromBigInt(factor);
      final centsValue = (product is Decimal ? product : (product as Rational).toDecimal()).toBigInt().toInt();
      
      if (centsValue < 0) throw MoneyParseException('Negative amount not allowed');
      if (centsValue > 1000000000000) throw MoneyParseException('Amount too large');
      
      return Money(centsValue, currency);
    } catch (e) {
      throw MoneyParseException('Invalid money format: $amount');
    }
  }

  /// Zero amount in specified currency
  factory Money.zero(Currency currency) => Money(0, currency);

  // Arithmetic operations
  Money operator +(Money other) {
    _checkCurrency(other);
    return Money(cents + other.cents, currency);
  }

  Money operator -(Money other) {
    _checkCurrency(other);
    if (cents < other.cents) {
      throw MoneyOperationException('Resulting amount cannot be negative');
    }
    return Money(cents - other.cents, currency);
  }

  Money operator *(num factor) {
    final product = Decimal.fromInt(cents).toRational() * 
                   Decimal.parse(factor.toString()).toRational();
    final result = product.toDecimal().toBigInt().toInt();
    return Money(result, currency);
  }

  Decimal operator /(Money other) {
    _checkCurrency(other);
    if (other.cents == 0) throw MoneyOperationException('Division by zero');
    return (Decimal.fromInt(cents) / Decimal.fromInt(other.cents))
        .toDecimal(scaleOnInfinitePrecision: 4);
  }

  /// Calculate percentage of this money
  Money percentage(num percent) {
    if (percent < 0 || percent > 100) {
      throw MoneyOperationException('Percentage must be between 0 and 100');
    }
    return this * (percent / 100);
  }

  /// Allocate money across targets using Banker's Rounding (to prevent loss)
  List<Money> allocate(List<int> ratios) {
    if (ratios.isEmpty) return [];
    
    final totalRatio = ratios.fold(0, (sum, r) => sum + r);
    if (totalRatio == 0) throw MoneyOperationException('Total ratio cannot be zero');
    
    int remainder = cents;
    final results = <int>[];
    
    for (var ratio in ratios) {
      final share = (cents * ratio) ~/ totalRatio;
      results.add(share);
      remainder -= share;
    }
    
    // Distribute remainder (cents) to targets to maintain integrity
    for (var i = 0; i < remainder; i++) {
      results[i]++;
    }
    
    return results.map((c) => Money(c, currency)).toList();
  }

  /// Comparison
  bool operator >(Money other) => cents > other.cents && currency == other.currency;
  bool operator <(Money other) => cents < other.cents && currency == other.currency;
  bool operator >=(Money other) => cents >= other.cents && currency == other.currency;
  bool operator <=(Money other) => cents <= other.cents && currency == other.currency;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Money && cents == other.cents && currency == other.currency;

  @override
  int get hashCode => cents.hashCode ^ currency.hashCode;

  /// Formatting
  String format({bool showSymbol = true}) {
    final factor = pow(10, currency.decimalPlaces);
    final amount = cents / factor;
    
    final formatter = NumberFormat.currency(
      symbol: showSymbol ? currency.symbol : '',
      decimalDigits: currency.decimalPlaces,
    );
    
    return formatter.format(amount).trim();
  }

  void _checkCurrency(Money other) {
    if (currency != other.currency) {
      throw MoneyOperationException('Currency mismatch: $currency vs ${other.currency}');
    }
  }

  /// Create from double (e.g., 100.50)
  factory Money.fromDouble(double amount, Currency currency) {
    final factor = pow(10, currency.decimalPlaces);
    return Money((amount * factor).round(), currency);
  }

  /// Convert to double
  double toDouble() {
    final factor = pow(10, currency.decimalPlaces);
    return cents / factor;
  }

  @override
  String toString() => format();
}

/// Helper for exponentiation
num pow(num base, int exponent) {
  num result = 1;
  for (var i = 0; i < exponent; i++) {
    result *= base;
  }
  return result;
}

class MoneyParseException implements Exception {
  final String message;
  MoneyParseException(this.message);
  @override
  String toString() => 'MoneyParseException: $message';
}

class MoneyOperationException implements Exception {
  final String message;
  MoneyOperationException(this.message);
  @override
  String toString() => 'MoneyOperationException: $message';
}
