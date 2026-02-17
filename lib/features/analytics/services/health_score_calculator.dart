/// Budget Health Score Calculator — Pro Edition
/// More accurate scoring, safer math, cleaner insights.
/// Structure unchanged, logic improved.
library;

import 'dart:math' as math;
import '../health_score_engine.dart' as engine;
import '../../../core/finance/money.dart';

/// Health score result
class HealthScoreResult {
  final int score; // 0–100
  final String level; // excellent/good/fair/poor/critical
  final Map<String, double> componentScores;
  final List<String> insights;

  const HealthScoreResult({
    required this.score,
    required this.level,
    required this.componentScores,
    required this.insights,
  });

  /// Emoji indicator for UI cards
  String get emoji {
    if (score >= 80) return '🟢';
    if (score >= 60) return '🟡';
    if (score >= 40) return '🟠';
    if (score >= 20) return '🔴';
    return '🚨';
  }

  /// Detailed human-readable description
  String get description {
    if (score >= 80) {
      return 'Outstanding financial health! Your budget management is exemplary. Keep maintaining these excellent habits.';
    }
    if (score >= 60) {
      return 'Healthy budget management with room for minor improvements. You\'re on the right track.';
    }
    if (score >= 40) {
      return 'Your budget needs attention. Consider reviewing your spending patterns and making adjustments.';
    }
    if (score >= 20) {
      return 'Immediate action required. Your spending significantly exceeds healthy patterns. Review expenses now.';
    }
    return 'Critical budget situation! Urgent intervention needed. Seek financial guidance if necessary.';
  }

  /// Short label for UI badges
  String get shortLabel {
    if (score >= 80) return 'Excellent';
    if (score >= 60) return 'Good';
    if (score >= 40) return 'Fair';
    if (score >= 20) return 'Poor';
    return 'Critical';
  }

  /// Priority level for notifications (1-5, 5 being most urgent)
  int get priorityLevel {
    if (score >= 80) return 1;
    if (score >= 60) return 2;
    if (score >= 40) return 3;
    if (score >= 20) return 4;
    return 5;
  }

  /// Recommended action based on score
  String get recommendedAction {
    if (score >= 80) {
      return 'Continue current spending habits and consider increasing savings goals.';
    }
    if (score >= 60) {
      return 'Review category budgets to optimize spending. Small adjustments can improve your score.';
    }
    if (score >= 40) {
      return 'Identify top spending categories and set stricter limits. Consider cutting non-essential expenses.';
    }
    if (score >= 20) {
      return 'Take immediate action: freeze non-essential spending and review all subscriptions.';
    }
    return 'Emergency mode: Stop all discretionary spending. Contact a financial advisor for assistance.';
  }

  /// Hex color for UI theming
  String get colorHex {
    if (score >= 80) return '#4CAF50'; // Green
    if (score >= 60) return '#FFC107'; // Amber/Yellow
    if (score >= 40) return '#FF9800'; // Orange
    if (score >= 20) return '#F44336'; // Red
    return '#D32F2F'; // Dark Red
  }

  /// Motivation message for users
  String get motivationalMessage {
    if (score >= 80) {
      return '🎉 Amazing work! You\'re a budgeting champion!';
    }
    if (score >= 60) {
      return '👍 Good job! A few tweaks and you\'ll be excellent!';
    }
    if (score >= 40) {
      return '💪 You can do this! Time to take control!';
    }
    if (score >= 20) {
      return '⚠️ Don\'t give up! Small changes make big differences.';
    }
    return '🆘 Help is available. Take it one step at a time.';
  }

  /// Whether to show alert notifications
  bool get shouldAlert => score < 60;

  /// Whether this is a critical state requiring immediate attention
  bool get isCritical => score < 40;

  /// Whether this represents good financial health
  bool get isHealthy => score >= 60;
}

/// Health Score Calculator
class HealthScoreCalculator {
  /// Calculate budget health score (0–100)
  static HealthScoreResult calculate({
    required double totalBudget,
    required double totalSpent,
    required Map<String, double> categorySpending,
    required Map<String, double> categoryLimits,
    double? lastPeriodSpending,
    double? recurringExpenses,
  }) {
    // 1. Convert legacy doubles to Money
    final budgetMoney = Money.fromDouble(totalBudget, Currency.EUR);
    final spentMoney = Money.fromDouble(totalSpent, Currency.EUR);
    final savingsMoney = Money.fromDouble(0.0, Currency.EUR); // Placeholder
    final debtMoney = Money.fromDouble(0.0, Currency.EUR); // Placeholder
    
    // 2. Call the new engine
    final result = engine.HealthScoreEngine.calculate(
      totalBudget: budgetMoney,
      spent: spentMoney,
      savings: savingsMoney,
      debt: debtMoney,
      momentum: 0.0, // Placeholder
    );

    return HealthScoreResult(
      score: result.score,
      level: _getHealthLevel(result.score),
      componentScores: {
        'usage': result.budgetScore.toDouble(),
        'savings': result.savingsScore.toDouble(),
        'debt': result.debtScore.toDouble(),
        'momentum': result.momentumScore.toDouble(),
      },
      insights: result.insights,
    );
  }

  // -------------------------------------------------------------------------
  // 1. USAGE SCORE — how efficiently user uses the total budget
  // -------------------------------------------------------------------------
  static double _calculateUsageScore(
    double usagePercent,
    List<String> insights,
  ) {
    // Optimal zone: 70%–85%
    if (usagePercent <= 0.50) {
      insights.add('Large unused budget available');
      return 60;
    }
    if (usagePercent <= 0.70) {
      insights.add('Good budget control');
      return 85;
    }
    if (usagePercent <= 0.85) {
      insights.add('Optimal budget usage');
      return 100;
    }
    if (usagePercent <= 1.0) {
      insights.add('Approaching full budget');
      return 70;
    }
    if (usagePercent <= 1.15) {
      insights.add('Over budget — reduce spending');
      return 40;
    }

    insights.add('Severely over budget — take action soon');
    return 15;
  }

  // -------------------------------------------------------------------------
  // 2. CONSISTENCY SCORE — compares to the last period
  // -------------------------------------------------------------------------
  static double _calculateConsistencyScore(
    double currentSpending,
    double? lastPeriodSpending,
    List<String> insights,
  ) {
    if (lastPeriodSpending == null || lastPeriodSpending <= 0) {
      return 75; // Neutral score
    }

    final change =
        ((currentSpending - lastPeriodSpending) / lastPeriodSpending).abs();

    if (change <= 0.10) return 100; // very stable
    if (change <= 0.25) return 85; // acceptable variation
    if (change <= 0.50) {
      insights.add('Spending varies noticeably from last period');
      return 60;
    }

    insights.add('Large spending change vs previous period');
    return 35;
  }

  // -------------------------------------------------------------------------
  // 3. CATEGORY BALANCE — distribution across categories
  // -------------------------------------------------------------------------
  static double _calculateCategoryBalanceScore(
    Map<String, double> categorySpending,
    Map<String, double> categoryLimits,
    List<String> insights,
  ) {
    if (categoryLimits.isEmpty) return 75; // No limit info → neutral

    int overspent = 0;
    int optimal = 0;

    for (final entry in categoryLimits.entries) {
      final limit = math.max(entry.value, 0.0);
      if (limit == 0) continue;

      final spent = math.max(categorySpending[entry.key] ?? 0.0, 0.0);
      final usage = spent / limit;

      if (usage > 1.0) overspent++;
      if (usage >= 0.70 && usage <= 0.90) optimal++;
    }

    if (overspent > 0) {
      insights.add('$overspent category${overspent == 1 ? "" : "ies"} over budget');
      return math.max(20.0, (100 - overspent * 25).toDouble());
    }

    if (optimal >= categoryLimits.length / 2) {
      insights.add('Spending across categories looks balanced');
      return 100;
    }

    return 80;
  }

  // -------------------------------------------------------------------------
  // 4. RECURRING RATIO — fixed monthly costs vs total spending
  // -------------------------------------------------------------------------
  static double _calculateRecurringRatioScore(
    double totalSpent,
    double? recurringExpenses,
    List<String> insights,
  ) {
    if (recurringExpenses == null || totalSpent <= 0) {
      return 75; // Neutral
    }

    final ratio = (recurringExpenses / totalSpent).clamp(0.0, 1.0);

    if (ratio <= 0.30) return 100; // flexible spending
    if (ratio <= 0.50) return 80; // healthy mix
    if (ratio <= 0.70) {
      insights.add('High percentage of recurring expenses');
      return 60;
    }

    insights.add('Recurring expenses dominate your budget');
    return 40;
  }

  // -------------------------------------------------------------------------
  // LEVEL LABEL (UI-friendly)
  // -------------------------------------------------------------------------
  static String _getHealthLevel(int score) {
    if (score >= 80) return 'excellent';
    if (score >= 60) return 'good';
    if (score >= 40) return 'fair';
    if (score >= 20) return 'poor';
    return 'critical';
  }
}
