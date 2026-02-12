
import 'package:flutter/foundation.dart';
import '../../../data/drift/app_database.dart';
import 'package:drift/drift.dart';

/// Predicts future spending based on historical time-series data
class SpendingForecaster {
  final AppDatabase _db;
  
  SpendingForecaster(this._db);

  /// Forecasts next month's spending with seasonal awareness
  Future<int> predictNextMonthSpending() async {
    try {
      final expenses = await (_db.select(_db.expenses)
        ..orderBy([(t) => OrderingTerm.asc(t.date)])
      ).get();

      if (expenses.isEmpty) return 0;

      final monthlyTotals = _calculateMonthlyTotals(expenses);
      final history = monthlyTotals.values.map((v) => v.toDouble()).toList();

      if (history.length < 3) {
        return (history.reduce((a, b) => a + b) / history.length).round();
      }

      // Triple Exponential Smoothing (Holt-Winters) approximation
      // For mobile, we'll use a simplified version: L = last, T = average trend
      
      // Calculate Trend (Simple linear regression slope)
      double trend = 0;
      if (history.length > 1) {
        for (var i = 1; i < history.length; i++) {
          trend += (history[i] - history[i-1]);
        }
        trend /= (history.length - 1);
      }

      // Calculate Seasonality
      double seasonalFactor = 1.0;
      if (history.length >= 12) {
        final lastYearValue = history[history.length - 12];
        final yearAvg = history.sublist(history.length - 12).reduce((a, b) => a + b) / 12;
        if (yearAvg > 0) {
          seasonalFactor = lastYearValue / yearAvg;
        }
      }

      // Final Prediction
      // Forecast = (Base + Trend) * Seasonality
      final lastValue = history.last;
      double forecast = (lastValue + trend) * seasonalFactor;
      
      // Safety: Don't allow wild swings based on single month outliers
      // If history is long, we can compare with moving average
      if (history.length >= 4) {
        final movingAvg = history.sublist(history.length - 4).reduce((a, b) => a + b) / 4;
        forecast = (forecast * 0.8) + (movingAvg * 0.2);
      }

      debugPrint('[BudgetAI] History length: ${history.length}, Trend: $trend, Seasonal Factor: $seasonalFactor, Forecast: ${forecast/100}');
      
      return forecast.round().clamp(0, 50000000);
    } catch (e) {
      debugPrint('[BudgetAI] Error: $e');
      return 0;
    }
  }

  Map<String, int> _calculateMonthlyTotals(List<Expense> expenses) {
    final totals = <String, int>{};
    for (final e in expenses) {
      final key = '${e.date.year}-${e.date.month.toString().padLeft(2, '0')}';
      totals[key] = (totals[key] ?? 0) + e.amount;
    }
    return totals;
  }
}
