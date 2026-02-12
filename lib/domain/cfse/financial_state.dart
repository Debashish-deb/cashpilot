import 'package:flutter/foundation.dart';

/// Risk profile assessment based on financial state
enum RiskProfile {
  conservative,
  moderate,
  aggressive,
  critical, // When burn rate exceeds cash position
}

/// The Canonical Financial State - The single source of truth for a user's financial reality.
@immutable
class FinancialState {
  final DateTime timestamp;
  
  /// Total liquid cash available across all accounts (in cents)
  final int cashPosition;
  
  /// Expected monthly spending based on recent history (in cents)
  final int monthlyBurnRate;
  
  /// Percentage of income saved: (Income - Expenses) / Income (0.0 to 1.0)
  final double savingsRate;
  
  /// Percentage of net worth tied to investments (0.0 to 1.0)
  final double investmentExposure;
  
  /// Total Assets - Total Liabilities (in cents)
  final int netWorth;
  
  /// Overall budget adherence (0.0 to 1.0, where 1.0 is perfect)
  final double budgetHealth;
  
  /// Dynamic risk assessment
  final RiskProfile riskProfile;
  
  /// Progress towards all active financial goals (0.0 to 1.0)
  final double goalProgress;

  const FinancialState({
    required this.timestamp,
    required this.cashPosition,
    required this.monthlyBurnRate,
    required this.savingsRate,
    required this.investmentExposure,
    required this.netWorth,
    required this.budgetHealth,
    required this.riskProfile,
    required this.goalProgress,
  });

  /// Factory for an empty/initial state
  factory FinancialState.initial() => FinancialState(
    timestamp: DateTime.now(),
    cashPosition: 0,
    monthlyBurnRate: 0,
    savingsRate: 0.0,
    investmentExposure: 0.0,
    netWorth: 0,
    budgetHealth: 1.0,
    riskProfile: RiskProfile.conservative,
    goalProgress: 0.0,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FinancialState &&
          runtimeType == other.runtimeType &&
          timestamp == other.timestamp &&
          cashPosition == other.cashPosition &&
          monthlyBurnRate == other.monthlyBurnRate &&
          savingsRate == other.savingsRate &&
          investmentExposure == other.investmentExposure &&
          netWorth == other.netWorth &&
          budgetHealth == other.budgetHealth &&
          riskProfile == other.riskProfile &&
          goalProgress == other.goalProgress;

  @override
  int get hashCode =>
      timestamp.hashCode ^
      cashPosition.hashCode ^
      monthlyBurnRate.hashCode ^
      savingsRate.hashCode ^
      investmentExposure.hashCode ^
      netWorth.hashCode ^
      budgetHealth.hashCode ^
      riskProfile.hashCode ^
      goalProgress.hashCode;

  @override
  String toString() {
    return 'FinancialState(timestamp: $timestamp, netWorth: ${netWorth / 100}, budgetHealth: $budgetHealth)';
  }

  FinancialState copyWith({
    DateTime? timestamp,
    int? cashPosition,
    int? monthlyBurnRate,
    double? savingsRate,
    double? investmentExposure,
    int? netWorth,
    double? budgetHealth,
    RiskProfile? riskProfile,
    double? goalProgress,
  }) {
    return FinancialState(
      timestamp: timestamp ?? this.timestamp,
      cashPosition: cashPosition ?? this.cashPosition,
      monthlyBurnRate: monthlyBurnRate ?? this.monthlyBurnRate,
      savingsRate: savingsRate ?? this.savingsRate,
      investmentExposure: investmentExposure ?? this.investmentExposure,
      netWorth: netWorth ?? this.netWorth,
      budgetHealth: budgetHealth ?? this.budgetHealth,
      riskProfile: riskProfile ?? this.riskProfile,
      goalProgress: goalProgress ?? this.goalProgress,
    );
  }
}
