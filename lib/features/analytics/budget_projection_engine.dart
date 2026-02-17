import 'dart:math' as math;
import 'package:decimal/decimal.dart';
import '../../core/finance/money.dart';

enum ProjectionMethod {
  linear, // Basic average
  weighted, // Weighted towards recent spending
  pattern; // Calendar-aware (e.g., rent on 1st, groceries on weekends)
}

class BudgetProjectionEngine {
  /// Project remaining spending for the budget period
  static ProjectionResult project({
    required Money currentSpent,
    required List<DailySpending> history,
    required int totalDays,
    required int daysElapsed,
    ProjectionMethod method = ProjectionMethod.weighted,
  }) {
    if (daysElapsed == 0) return ProjectionResult.zero(currentSpent.currency);
    
    final daysRemaining = totalDays - daysElapsed;
    if (daysRemaining <= 0) return ProjectionResult(projectedTotal: currentSpent, confidence: 1.0);

    Money projectedRemaining;

    switch (method) {
      case ProjectionMethod.linear:
        projectedRemaining = _calculateLinear(currentSpent, daysElapsed, daysRemaining);
        break;
      case ProjectionMethod.weighted:
        projectedRemaining = _calculateWeighted(history, daysRemaining);
        break;
      case ProjectionMethod.pattern:
        projectedRemaining = _calculatePattern(history, totalDays, daysElapsed);
        break;
    }

    final projectedTotal = currentSpent + projectedRemaining;
    final confidence = _calculateConfidence(history, method);

    return ProjectionResult(
      projectedTotal: projectedTotal,
      confidence: confidence,
    );
  }

  static Money _calculateLinear(Money currentSpent, int daysElapsed, int daysRemaining) {
    final dailyRate = currentSpent.cents / daysElapsed;
    return Money((dailyRate * daysRemaining).round(), currentSpent.currency);
  }

  static Money _calculateWeighted(List<DailySpending> history, int daysRemaining) {
    if (history.isEmpty) return Money.zero(Currency.USD); // Default fallback

    // Weight recent days more heavily (e.g., last 7 days = 70%, previous = 30%)
    final List<DailySpending> recentHistory = history.length > 7 ? history.sublist(history.length - 7) : history;
    final List<DailySpending> olderHistory = history.length > 7 ? history.sublist(0, history.length - 7) : <DailySpending>[];

    double recentAvg = recentHistory.isEmpty 
        ? 0.0 
        : (recentHistory.fold<int>(0, (int sum, s) => sum + s.amount.cents)).toDouble() / recentHistory.length;
    
    double olderAvg = olderHistory.isEmpty 
        ? recentAvg 
        : (olderHistory.fold<int>(0, (int sum, s) => sum + s.amount.cents)).toDouble() / olderHistory.length;

    final weightedDailyRate = (recentAvg * 0.7) + (olderAvg * 0.3);
    return Money((weightedDailyRate * daysRemaining).round(), history.first.amount.currency);
  }

  static Money _calculatePattern(List<DailySpending> history, int totalDays, int daysElapsed) {
    // Simplified pattern matching (Weekday vs Weekend)
    double weekdayAvg = 0;
    int weekdayCount = 0;
    double weekendAvg = 0;
    int weekendCount = 0;

    for (var s in history) {
      if (s.date.weekday <= 5) {
        weekdayAvg += s.amount.cents;
        weekdayCount++;
      } else {
        weekendAvg += s.amount.cents;
        weekendCount++;
      }
    }

    weekdayAvg = weekdayCount > 0 ? weekdayAvg / weekdayCount : 0;
    weekendAvg = weekendCount > 0 ? weekendAvg / weekendCount : 0;

    int remainingWeekdays = 0;
    int remainingWeekends = 0;
    
    final startDate = history.first.date.add(Duration(days: daysElapsed));
    for (var i = 0; i < (totalDays - daysElapsed); i++) {
      final date = startDate.add(Duration(days: i));
      if (date.weekday <= 5) {
        remainingWeekdays++;
      } else {
        remainingWeekends++;
      }
    }

    final projectedCents = (weekdayAvg * remainingWeekdays) + (weekendAvg * remainingWeekends);
    return Money(projectedCents.round(), history.first.amount.currency);
  }

  static double _calculateConfidence(List<DailySpending> history, ProjectionMethod method) {
    if (history.length < 5) return 0.5;
    
    // Variance-based confidence
    final avg = history.fold<int>(0, (sum, s) => sum + s.amount.cents) / history.length;
    final variance = history.fold(0.0, (sum, s) => sum + (s.amount.cents - avg) * (s.amount.cents - avg)) / history.length;
    final stdDev = math.sqrt(variance);
    
    // Lower relative std dev = higher confidence
    final relativeStdDev = stdDev / (avg + 1);
    double confidence = 1.0 - (relativeStdDev / 2.0);
    
    return confidence.clamp(0.1, 0.95);
  }
}

class DailySpending {
  final DateTime date;
  final Money amount;

  DailySpending({required this.date, required this.amount});
}

class ProjectionResult {
  final Money projectedTotal;
  final double confidence;

  ProjectionResult({required this.projectedTotal, required this.confidence});

  factory ProjectionResult.zero(Currency currency) => 
      ProjectionResult(projectedTotal: Money.zero(currency), confidence: 0.0);
}
