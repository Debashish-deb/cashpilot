import 'dart:math' as math;
import '../../core/finance/money.dart';
import '../../core/finance/percentage_calculator.dart';
import 'package:decimal/decimal.dart';

class HealthScoreEngine {
  /// Calculate the overall financial health score (0-100)
  static HealthScoreResult calculate({
    required Money totalBudget,
    required Money spent,
    required Money savings,
    required Money debt,
    required double momentum, // Trend in spending (-1.0 to 1.0)
  }) {
    // 1. Budget Adherence (40%)
    final budgetScore = _calculateBudgetScore(totalBudget, spent);
    
    // 2. Savings Ratio (30%)
    final savingsScore = _calculateSavingsScore(savings, totalBudget);
    
    // 3. Debt-to-Income (20%)
    final debtScore = _calculateDebtScore(debt, totalBudget);
    
    // 4. Momentum/Trends (10%)
    final momentumScore = _calculateMomentumScore(momentum);

    final totalScore = (budgetScore * 0.4) +
                      (savingsScore * 0.3) +
                      (debtScore * 0.2) +
                      (momentumScore * 0.1);

    final insights = _generateInsights(
      totalScore,
      budgetScore,
      savingsScore,
      debtScore,
      momentumScore,
    );

    return HealthScoreResult(
      score: totalScore.round().clamp(0, 100),
      budgetScore: budgetScore.round(),
      savingsScore: savingsScore.round(),
      debtScore: debtScore.round(),
      momentumScore: momentumScore.round(),
      insights: insights,
    );
  }

  static double _calculateBudgetScore(Money budget, Money spent) {
    if (budget.cents == BigInt.zero) return 0;
    if (spent.cents == BigInt.zero) return 100;
    
    final ratio = spent.cents.toDouble() / budget.cents.toDouble();
    if (ratio <= 1.0) {
      // Linear decrease from 100 to 70 as ratio goes from 0 to 1
      return 100 - (ratio * 30);
    } else {
      // Exponential decrease after exceeding budget
      return 70 * math.exp(-(ratio - 1.0) * 2);
    }
  }

  static double _calculateSavingsScore(Money savings, Money budget) {
    if (budget.cents == BigInt.zero) return 0;
    
    // Target: Savings should be at least 20% of monthly budget
    final targetSavings = budget.cents.toDouble() * 0.2;
    if (savings.cents.toDouble() >= targetSavings) return 100;
    
    return (savings.cents.toDouble() / targetSavings) * 100;
  }

  static double _calculateDebtScore(Money debt, Money budget) {
    if (budget.cents == BigInt.zero) return 100; // No budget = no income for this ratio?
    
    // Target: Debt should be less than 50% of monthly budget
    final debtRatio = debt.cents.toDouble() / (budget.cents.toDouble() * 12); // Annualized budget
    if (debtRatio == 0) return 100;
    
    if (debtRatio <= 0.3) return 100;
    if (debtRatio >= 1.0) return 0;
    
    return 100 - ((debtRatio - 0.3) / 0.7 * 100);
  }

  static double _calculateMomentumScore(double momentum) {
    // Momentum: -1.0 (spending up) to 1.0 (spending down)
    return ((momentum + 1.0) / 2.0) * 100;
  }

  static List<String> _generateInsights(
    double total,
    double budget,
    double savings,
    double debt,
    double momentum,
  ) {
    final insights = <String>[];

    if (budget < 60) {
      insights.add('Spending is significantly over budget. Review your non-essential categories.');
    } else if (budget < 85) {
      insights.add('Budget adherence is fair, but there is room for optimization.');
    }

    if (savings < 50) {
      insights.add('Savings are below target. Consider automating your savings transfers.');
    }

    if (debt < 40) {
      insights.add('High debt-to-income ratio detected. Focus on high-interest debt payoffs.');
    }

    if (momentum < 40) {
      insights.add('Spending trend is increasing week-over-week. Try to tighten your budget.');
    } else if (momentum > 80) {
      insights.add('Great job! Your spending is on a downward trend compared to last month.');
    }

    return insights;
  }
}

class HealthScoreResult {
  final int score;
  final int budgetScore;
  final int savingsScore;
  final int debtScore;
  final int momentumScore;
  final List<String> insights;

  HealthScoreResult({
    required this.score,
    required this.budgetScore,
    required this.savingsScore,
    required this.debtScore,
    required this.momentumScore,
    required this.insights,
  });

  String get label {
    if (score >= 90) return 'Excellent';
    if (score >= 80) return 'Good';
    if (score >= 70) return 'Fair';
    if (score >= 50) return 'Needs Attention';
    return 'Poor';
  }
}
