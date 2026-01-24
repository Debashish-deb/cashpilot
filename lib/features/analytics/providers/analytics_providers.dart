/// Analytics Providers — Enterprise-Optimized Edition
/// Clean, safe, predictable Riverpod setup for analytics state.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/health_score_calculator.dart';
import '../services/insight_engine.dart';
import '../models/insight_card.dart';

/// ---------------------------------------------------------------------------
/// INSIGHT ENGINE PROVIDER
/// Provides a singleton instance of the InsightEngine.
/// ---------------------------------------------------------------------------
final insightEngineProvider = Provider<InsightEngine>((ref) {
  return insightEngine; // Already your global instance
});

/// ---------------------------------------------------------------------------
/// CURRENT INSIGHT CARDS PROVIDER (UI State)
/// Holds the insights currently displayed on the analytics screen.
/// Uses StateProvider for fast rebuilds.
/// ---------------------------------------------------------------------------
final currentInsightCardsProvider =
    StateProvider<List<InsightCard>>((ref) => const []);

/// Safe setter for optimized updates — avoids rebuild storms
extension InsightCardStateHelpers on WidgetRef {
  void setInsightCards(List<InsightCard> cards) {
    // Remove duplicates, sort latest first
    final unique = {
      for (final c in cards) c.id: c,
    }.values.toList()
      ..sort((a, b) => a.compareBySeverity(b));

    read(currentInsightCardsProvider.notifier).state = unique;
  }
}

/// ---------------------------------------------------------------------------
/// HEALTH SCORE PROVIDER — calculated per budget
/// Uses Provider.family for strongly typed params.
/// ---------------------------------------------------------------------------
final healthScoreProvider =
    Provider.family<HealthScoreResult, Map<String, dynamic>>((ref, data) {
  return HealthScoreCalculator.calculate(
    totalBudget: (data['totalBudget'] as num).toDouble(),
    totalSpent: (data['totalSpent'] as num).toDouble(),
    categorySpending:
        (data['categorySpending'] as Map).cast<String, double>(),
    categoryLimits:
        (data['categoryLimits'] as Map).cast<String, double>(),
    lastPeriodSpending:
        (data['lastPeriodSpending'] as num?)?.toDouble(),
    recurringExpenses:
        (data['recurringExpenses'] as num?)?.toDouble(),
  );
});

/// ---------------------------------------------------------------------------
/// ANALYTICS LOADING STATE (bool)
/// Used to show loading indicators on the Analytics dashboard.
/// ---------------------------------------------------------------------------
final analyticsLoadingProvider = StateProvider<bool>((ref) => false);

/// Extra helper for convenience
extension AnalyticsLoadingHelper on WidgetRef {
  void startAnalyticsLoading() =>
      read(analyticsLoadingProvider.notifier).state = true;

  void stopAnalyticsLoading() =>
      read(analyticsLoadingProvider.notifier).state = false;
}

// ============================================================================
// PHASE 3: ADVANCED ANALYTICS (NEW)
// ============================================================================

/// ---------------------------------------------------------------------------
/// DASHBOARD VIEW MODES
/// Quick view, Comparison, Trends, Forecast
/// ---------------------------------------------------------------------------
enum AnalyticsDashboardMode {
  quick,       // Today + this month summary
  comparison,  // Month vs month, week vs week
  trends,      // 12-month line charts
  forecast,    // End-of-month projections
}

final analyticsDashboardModeProvider = StateProvider<AnalyticsDashboardMode>(
  (ref) => AnalyticsDashboardMode.quick,
);

/// ---------------------------------------------------------------------------
/// REPORT TYPE SELECTION
/// Monthly, Quarterly, Annual, Custom
/// ---------------------------------------------------------------------------
enum AnalyticsReportType {
  monthly,
  quarterly,
  annual,
  custom,
}

final analyticsReportTypeProvider = StateProvider<AnalyticsReportType>(
  (ref) => AnalyticsReportType.monthly,
);

/// Custom date range for reports
final customAnalyticsRangeProvider = StateProvider<DateTimeRange?>(
  (ref) => null,
);

/// ---------------------------------------------------------------------------
/// MONTH-END FORECAST
/// Predicts end-of-month spending based on current pace
/// ---------------------------------------------------------------------------
class MonthEndForecast {
  final double currentSpent;
  final double projectedTotal;
  final double budgetLimit;
  final double safeToSpend;
  final int daysRemaining;
  final double dailyAverage;
  final bool onTrack;
  
  const MonthEndForecast({
    required this.currentSpent,
    required this.projectedTotal,
    required this.budgetLimit,
    required this.safeToSpend,
    required this.daysRemaining,
    required this.dailyAverage,
    required this.onTrack,
  });
  
  double get projectedSavings => budgetLimit - projectedTotal;
  double get percentUsed => budgetLimit > 0 ? (currentSpent / budgetLimit * 100) : 0;
}

/// Calculate month-end forecast
final monthEndForecastProvider = Provider.family<MonthEndForecast, ({double spent, double budget})>((ref, data) {
  final now = DateTime.now();
  final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
  final daysPassed = now.day;
  final daysRemaining = daysInMonth - daysPassed;
  
  // Daily average so far
  final dailyAverage = daysPassed > 0 ? data.spent / daysPassed : 0.0;
  
  // Projected total at current pace
  final projectedTotal = dailyAverage * daysInMonth;
  
  // Safe to spend: budget - projected bills - already spent
  // Simplified: what's left divided by remaining days
  final remaining = data.budget - data.spent;
  final safeToSpend = daysRemaining > 0 ? remaining / daysRemaining : 0.0;
  
  return MonthEndForecast(
    currentSpent: data.spent,
    projectedTotal: projectedTotal,
    budgetLimit: data.budget,
    safeToSpend: safeToSpend.clamp(0, remaining),
    daysRemaining: daysRemaining,
    dailyAverage: dailyAverage,
    onTrack: projectedTotal <= data.budget,
  );
});

/// ---------------------------------------------------------------------------
/// SPENDING COMPARISON
/// Compare periods for trend analysis
/// ---------------------------------------------------------------------------
class SpendingComparison {
  final double currentPeriod;
  final double previousPeriod;
  final double changePercent;
  final bool improved;
  final String periodLabel;
  
  const SpendingComparison({
    required this.currentPeriod,
    required this.previousPeriod,
    required this.changePercent,
    required this.improved,
    required this.periodLabel,
  });
}

/// ---------------------------------------------------------------------------
/// CATEGORY TRENDS
/// Track category spending over time
/// ---------------------------------------------------------------------------
class CategoryTrend {
  final String categoryId;
  final String categoryName;
  final List<double> monthlySpending; // Last 12 months
  final double trend; // % change
  final bool increasing;
  
  const CategoryTrend({
    required this.categoryId,
    required this.categoryName,
    required this.monthlySpending,
    required this.trend,
    required this.increasing,
  });
}

/// ---------------------------------------------------------------------------
/// SPENDING PATTERN ANALYSIS
/// Day of week patterns, merchant analysis
/// ---------------------------------------------------------------------------
class SpendingPattern {
  final Map<String, double> dayOfWeekSpending; // Mon-Sun totals
  final String highestSpendingDay;
  final String lowestSpendingDay;
  final double weekendVsWeekday; // Ratio
  
  const SpendingPattern({
    required this.dayOfWeekSpending,
    required this.highestSpendingDay,
    required this.lowestSpendingDay,
    required this.weekendVsWeekday,
  });
}

