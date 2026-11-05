import 'dart:math' as math;
import 'package:decimal/decimal.dart';
import 'money.dart';

class TimeValueCalculator {
  /// Calculate Future Value (FV)
  /// FV = PV * (1 + r)^n
  static Money calculateFutureValue({
    required Money presentValue,
    required Decimal annualRate,
    required int years,
    int compoundsPerYear = 12,
  }) {
    if (years < 0) throw ArgumentError('Years cannot be negative');
    if (compoundsPerYear <= 0) throw ArgumentError('compoundsPerYear must be positive');
    if (annualRate == Decimal.zero || years == 0) {
      return presentValue;
    }

    final r = annualRate.toDouble() / 100 / compoundsPerYear;
    final n = years * compoundsPerYear;
    
    final fvFactor = math.pow(1 + r, n);
    final fvCents = (presentValue.cents * fvFactor).round();
    
    return Money(fvCents, presentValue.currency);
  }

  /// Calculate Monthly Loan Payment (PMT)
  /// PMT = P * [r(1+r)^n] / [(1+r)^n - 1]
  static Money calculateLoanPayment({
    required Money principal,
    required Decimal annualRate,
    required int months,
  }) {
    if (months <= 0) {
      throw ArgumentError('Loan term must be at least 1 month');
    }
    if (principal.cents <= 0) {
      return Money.zero(principal.currency);
    }

    if (annualRate == Decimal.zero) {
      return Money((principal.cents / months).round(), principal.currency);
    }

    final r = annualRate.toDouble() / 100 / 12;
    final n = months;
    final powFactor = math.pow(1 + r, n);
    
    if (powFactor == 1) {
      return Money((principal.cents / months).round(), principal.currency);
    }
    
    final pmtFactor = (r * powFactor) / (powFactor - 1);
    final pmtCents = (principal.cents * pmtFactor).round();
    
    return Money(pmtCents, principal.currency);
  }

  /// Calculate Years to Reach Goal
  /// n = log(FV/PV) / log(1 + r)
  static double calculateYearsToGoal({
    required Money currentAmount,
    required Money targetAmount,
    required Decimal annualRate,
    int compoundsPerYear = 12,
    Money? monthlyContribution,
  }) {
    if (currentAmount.currency != targetAmount.currency) {
      throw MoneyOperationException(
        'Currency mismatch in calculateYearsToGoal: ${currentAmount.currency} and ${targetAmount.currency}',
      );
    }
    if (monthlyContribution != null && monthlyContribution.currency != currentAmount.currency) {
      throw MoneyOperationException(
        'Currency mismatch: monthlyContribution is ${monthlyContribution.currency} but goal is ${currentAmount.currency}',
      );
    }
    if (targetAmount.cents <= currentAmount.cents) return 0.0;
    if (compoundsPerYear <= 0) throw ArgumentError('compoundsPerYear must be positive');
    
    if (annualRate <= Decimal.zero) {
      if (monthlyContribution != null && monthlyContribution.cents > 0) {
        final neededCents = targetAmount.cents - currentAmount.cents;
        final months = neededCents / monthlyContribution.cents;
        return months / 12.0;
      }
      return double.infinity;
    }

    if (currentAmount.cents <= 0) return double.infinity;
    
    final r = annualRate.toDouble() / 100 / compoundsPerYear;
    final fv = targetAmount.cents.toDouble();
    final pv = currentAmount.cents.toDouble();
    final logDenominator = math.log(1 + r);
    
    if (logDenominator == 0) return double.infinity;

    final periods = math.log(fv / pv) / logDenominator;
    return periods / compoundsPerYear;
  }

  /// Calculate Debt Snowball/Avalanche Payoff Time
  static DebtPayoffResult calculateDebtPayoff({
    required List<DebtAccount> debts,
    required Money monthlyExtra,
    bool useAvalanche = true, // true for Interest Rate, false for Smallest Balance
  }) {
    for (final debt in debts) {
      if (debt.balance.currency != monthlyExtra.currency ||
          debt.minPayment.currency != monthlyExtra.currency) {
        throw MoneyOperationException(
          'Currency mismatch in calculateDebtPayoff: debt ${debt.id} (${debt.balance.currency}) vs monthlyExtra (${monthlyExtra.currency})',
        );
      }
    }

    final activeDebts = debts.where((d) => d.balance.cents > 0).toList();
    if (activeDebts.isEmpty) {
      final currency = debts.isNotEmpty ? debts.first.balance.currency : monthlyExtra.currency;
      return DebtPayoffResult(months: 0, totalInterest: Money.zero(currency));
    }

    final currency = activeDebts.first.balance.currency;
    final sortedDebts = List<DebtAccount>.from(activeDebts);
    if (useAvalanche) {
      // Sort by interest rate descending
      sortedDebts.sort((a, b) => b.interestRate.compareTo(a.interestRate));
    } else {
      // Sort by balance ascending (Snowball)
      sortedDebts.sort((a, b) => a.balance.cents.compareTo(b.balance.cents));
    }

    final monthlyMinPayments = <String, int>{};
    for (var debt in debts) {
      monthlyMinPayments[debt.id] = debt.minPayment.cents;
    }

    var totalMonths = 0;
    var totalInterestCents = 0;
    final currentBalances = Map<String, int>.fromIterables(
      debts.map((d) => d.id),
      debts.map((d) => d.balance.cents),
    );

    while (currentBalances.values.any((b) => b > 0) && totalMonths < 600) { // 50 year cap
      totalMonths++;
      var extraPool = monthlyExtra.cents;

      // 1. Accrue interest & apply minimum payments
      for (var debt in sortedDebts) {
        final currentBal = currentBalances[debt.id]!;
        if (currentBal <= 0) {
          // Debt is paid off; its min payment cascades into the extra pool (Snowball effect)
          extraPool += monthlyMinPayments[debt.id]!;
          continue;
        }

        // Calculate monthly interest
        final monthlyRate = debt.interestRate.toDouble() / 100 / 12;
        final interest = (currentBal * monthlyRate).round();
        totalInterestCents += interest;
        var newBal = currentBal + interest;

        // Apply minimum payment
        final minPay = monthlyMinPayments[debt.id]!;
        final actualMinPayment = math.min(newBal, minPay);
        newBal -= actualMinPayment;
        currentBalances[debt.id] = newBal;

        if (newBal == 0) {
          // Any unused portion of min payment joins extra pool
          final leftoverMin = minPay - actualMinPayment;
          extraPool += leftoverMin;
        }
      }

      // 2. Apply extra pool strictly to highest-priority debt first
      for (var debt in sortedDebts) {
        if (extraPool <= 0) break;
        final currentBal = currentBalances[debt.id]!;
        if (currentBal <= 0) continue;

        final extraPayment = math.min(currentBal, extraPool);
        currentBalances[debt.id] = currentBal - extraPayment;
        extraPool -= extraPayment;
      }
    }

    return DebtPayoffResult(
      months: totalMonths,
      totalInterest: Money(totalInterestCents, currency),
    );
  }
}

class DebtAccount {
  final String id;
  final String name;
  final Money balance;
  final Decimal interestRate;
  final Money minPayment;

  DebtAccount({
    required this.id,
    required this.name,
    required this.balance,
    required this.interestRate,
    required this.minPayment,
  });
}

class DebtPayoffResult {
  final int months;
  final Money totalInterest;

  DebtPayoffResult({required this.months, required this.totalInterest});

  int get years => months ~/ 12;
  int get remainingMonths => months % 12;
}
