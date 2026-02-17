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
    if (annualRate == Decimal.zero) {
      return Money((principal.cents / months).round(), principal.currency);
    }

    final r = annualRate.toDouble() / 100 / 12;
    final n = months;
    
    final pmtFactor = (r * math.pow(1 + r, n)) / (math.pow(1 + r, n) - 1);
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
  }) {
    if (currentAmount.cents == 0) return double.infinity;
    if (targetAmount <= currentAmount) return 0;
    
    final r = annualRate.toDouble() / 100 / compoundsPerYear;
    final fv = targetAmount.cents.toDouble();
    final pv = currentAmount.cents.toDouble();
    
    final periods = math.log(fv / pv) / math.log(1 + r);
    return periods / compoundsPerYear;
  }

  /// Calculate Debt Snowball/Avalanche Payoff Time
  static DebtPayoffResult calculateDebtPayoff({
    required List<DebtAccount> debts,
    required Money monthlyExtra,
    bool useAvalanche = true, // true for Interest Rate, false for Smallest Balance
  }) {
    final sortedDebts = List<DebtAccount>.from(debts);
    if (useAvalanche) {
      // Sort by interest rate descending
      sortedDebts.sort((a, b) => b.interestRate.compareTo(a.interestRate));
    } else {
      // Sort by balance ascending (Snowball)
      sortedDebts.sort((a, b) => a.balance.cents.compareTo(b.balance.cents));
    }

    final monthlyPayments = <String, Money>{};
    for (var debt in debts) {
      monthlyPayments[debt.id] = debt.minPayment;
    }

    var totalMonths = 0;
    var totalInterestCents = 0;
    final currentBalances = Map<String, int>.fromIterables(
      debts.map((d) => d.id),
      debts.map((d) => d.balance.cents),
    );

    while (currentBalances.values.any((b) => b > 0) && totalMonths < 600) { // 50 year cap
      totalMonths++;
      var extraRemaining = monthlyExtra.cents;

      for (var debt in sortedDebts) {
        if (currentBalances[debt.id]! <= 0) continue;

        // Calculate interest for this month
        final monthlyRate = debt.interestRate.toDouble() / 100 / 12;
        final interest = (currentBalances[debt.id]! * monthlyRate).round();
        totalInterestCents += interest;
        currentBalances[debt.id] = currentBalances[debt.id]! + interest;

        // Apply min payment
        var payment = math.min(currentBalances[debt.id]!, monthlyPayments[debt.id]!.cents);
        currentBalances[debt.id] = currentBalances[debt.id]! - payment;

        // If extra remains and this is the priority debt, apply it
        if (extraRemaining > 0 && currentBalances[debt.id]! > 0) {
          final extraPayment = math.min(currentBalances[debt.id]!, extraRemaining);
          currentBalances[debt.id] = currentBalances[debt.id]! - extraPayment;
          extraRemaining -= extraPayment;
        }
      }
    }

    return DebtPayoffResult(
      months: totalMonths,
      totalInterest: Money(totalInterestCents, debts.first.balance.currency),
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
