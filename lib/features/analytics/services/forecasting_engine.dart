import 'package:drift/src/runtime/query_builder/query_builder.dart';

import '../../../data/drift/app_database.dart';

import '../budget_projection_engine.dart' as engine;
import '../../../core/finance/money.dart';

/// Forecasting Engine - Improved prediction algorithms
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
    
    // 1. Get current month expenses
    final expenses = await (_db.select(_db.expenses)
      ..where((e) => 
        e.budgetId.equals(budgetId) & 
        e.date.isBiggerOrEqualValue(start) &
        e.date.isSmallerOrEqualValue(end)
      ))
      .get();
    
    if (expenses.isEmpty) return 0.0;
    
    final currentSpentCents = expenses.fold(0, (sum, e) => sum + e.amount);
    final currentSpent = Money(currentSpentCents, Currency.EUR);
    
    // 2. Prepare history for the engine
    final history = expenses.map((e) => engine.DailySpending(
      date: e.date,
      amount: Money(e.amount, Currency.EUR),
    )).toList();

    // 3. Call the projection engine
    final result = engine.BudgetProjectionEngine.project(
      currentSpent: currentSpent,
      history: history,
      totalDays: daysInMonth,
      daysElapsed: currentDay,
      method: engine.ProjectionMethod.weighted,
    );

    return result.projectedTotal.toDouble();
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
