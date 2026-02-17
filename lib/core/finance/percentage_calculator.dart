import 'package:decimal/decimal.dart';
import 'package:rational/rational.dart';
import 'money.dart';

class PercentageCalculator {
  /// Calculate what percentage 'part' is of 'whole'
  static Decimal calculate({required Money part, required Money whole}) {
    if (whole.cents == 0) {
      throw PercentageException('Cannot calculate percentage of a zero total');
    }
    
    if (part.currency != whole.currency) {
      throw PercentageException('Currency mismatch in percentage calculation');
    }

    // (part / whole) * 100
    return (Decimal.fromInt(part.cents).toRational() / 
            Decimal.fromInt(whole.cents).toRational() * 
            Rational.fromInt(100))
        .toDecimal(scaleOnInfinitePrecision: 4);
  }

  /// Calculate percentage change from old to new
  static Decimal change({required Money oldValue, required Money newValue}) {
    if (oldValue.cents == 0) {
      return newValue.cents > 0 ? Decimal.fromInt(100) : Decimal.zero;
    }
    
    if (oldValue.currency != newValue.currency) {
      throw PercentageException('Currency mismatch in change calculation');
    }

    // ((new - old) / old) * 100
    final diff = newValue.cents - oldValue.cents;
    return (Decimal.fromInt(diff).toRational() / 
            Decimal.fromInt(oldValue.cents).toRational() * 
            Rational.fromInt(100))
        .toDecimal(scaleOnInfinitePrecision: 4);
  }

  /// Apply a percentage to a base amount
  static Money applyPercentage({required Money base, required Decimal percentage}) {
    final product = base.cents.toRational() * percentage.toRational();
    final resultCents = (product / Rational.fromInt(100))
        .toDecimal()
        .toBigInt()
        .toInt();
        
    return Money(resultCents, base.currency);
  }

  /// Distribute a total amount across multiple percentages without rounding loss
  static List<Money> distributeByPercentage({
    required Money total,
    required List<Decimal> percentages,
  }) {
    final totalPercent = percentages.fold(Decimal.zero, (sum, p) => sum + p);
    
    if (totalPercent != Decimal.fromInt(100)) {
      throw PercentageException('Percentages must sum exactly to 100');
    }

    int remainingCents = total.cents;
    final results = <int>[];

    for (var p in percentages) {
      final product = total.cents.toRational() * p.toRational();
      final share = (product / Rational.fromInt(100))
          .toDecimal()
          .toBigInt()
          .toInt();
      results.add(share);
      remainingCents -= share;
    }

    // Distribute remaining cents due to rounding
    for (var i = 0; i < remainingCents; i++) {
      results[i]++;
    }

    return results.map((c) => Money(c, total.currency)).toList();
  }
}

class PercentageException implements Exception {
  final String message;
  PercentageException(this.message);
  @override
  String toString() => 'PercentageException: $message';
}
