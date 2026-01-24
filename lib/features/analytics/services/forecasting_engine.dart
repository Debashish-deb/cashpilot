import 'package:drift/src/runtime/query_builder/query_builder.dart';

import '../../../data/drift/app_database.dart';

/// Forecasting Engine - Improved prediction algorithms
/// Replaces naive (monthSpent/day * totalDays) with weighted forecasting
class ForecastingEngine {
  final AppDatabase _db;
  
  ForecastingEngine(this._db);
  
  /// Forecast month-end spending using weighted algorithm
  Future<double> forecastMonthEnd({
    required String budgetId,
    required DateTime currentDate,
  }) async {
    final start = DateTime(currentDate.year, currentDate.month, 1);
    final end = DateTime(currentDate.year, currentDate.month + 1, 0);
    final today = DateTime(currentDate.year, currentDate.month, currentDate.day);
    
    final daysInMonth = end.day;
    final currentDay = today.day;
    final remainingDays = daysInMonth - currentDay;
    
    if (remainingDays <= 0) return 0.0;
    
    // Get all expenses this month
    final expenses = await (_db.select(_db.expenses)
      ..where((e) => 
        e.budgetId.equals(budgetId) & 
        e.date.isBiggerOrEqualValue(start) &
        e.date.isSmallerOrEqualValue(end)
      ))
      .get();
    
    if (expenses.isEmpty) return 0.0;
    
    final currentSpent = expenses.fold(0.0, (sum, e) => sum + e.amount / 100.0);
    
    // Get historical data (last 8 weeks for weekday baseline)
    final historical = await _getHistoricalExpenses(budgetId, weeks: 8);
    final weekdayBaseline = _calculateWeekdayBaseline(historical);
    
    // Calculate recent 7-day average (weighted)
    final recent7Days = expenses
      .where((e) => e.date.isAfter(today.subtract(const Duration(days: 7))))
      .toList();
    
    final recent7Average = recent7Days.isEmpty 
      ? currentSpent / currentDay
      : recent7Days.fold(0.0, (sum, e) => sum + e.amount / 100.0) / 7;
    
    // Forecast remaining days using blended approach
    double forecastedRemaining = 0.0;
    for (int i = currentDay + 1; i <= daysInMonth; i++) {
      final futureDate = DateTime(currentDate.year, currentDate.month, i);
      final weekday = futureDate.weekday;
      
      final baselineForDay = weekdayBaseline[weekday] ?? recent7Average;
      
      // Blend: 60% historical baseline + 40% recent trend
      final dailyForecast = (baselineForDay * 0.6) + (recent7Average * 0.4);
      forecastedRemaining += dailyForecast;
    }
    
    return currentSpent + forecastedRemaining;
  }
  
  /// Get historical expenses for baseline calculation
  Future<List<Expense>> _getHistoricalExpenses(String budgetId, {required int weeks}) async {
    final cutoff = DateTime.now().subtract(Duration(days: weeks * 7));
    return await (_db.select(_db.expenses)
      ..where((e) => 
        e.budgetId.equals(budgetId) & 
        e.date.isBiggerOrEqualValue(cutoff)
      ))
      .get();
  }
  
  /// Calculate average spending by weekday (Mon=1, Sun=7)
  Map<int, double> _calculateWeekdayBaseline(List<Expense> expenses) {
    final byWeekday = <int, List<double>>{};
    
    for (final expense in expenses) {
      final weekday = expense.date.weekday;
      byWeekday.putIfAbsent(weekday, () => []).add(expense.amount / 100.0);
    }
    
    return byWeekday.map((day, amounts) {
      final avg = amounts.reduce((a, b) => a + b) / amounts.length;
      return MapEntry(day, avg);
    });
  }
  
  /// Calculate variance for confidence scoring
  double calculateVariance(List<double> values) {
    if (values.isEmpty) return 0.0;
    final mean = values.reduce((a, b) => a + b) / values.length;
    final squaredDiffs = values.map((v) => (v - mean) * (v - mean));
    return squaredDiffs.reduce((a, b) => a + b) / values.length;
  }
}

extension on GeneratedColumn<DateTime> {
  isBiggerOrEqualValue(DateTime start) {}
}
