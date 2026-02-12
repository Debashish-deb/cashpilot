/// Metrics Engine
/// Phase 2: Pure mathematical calculations on expense data
/// NO business logic, NO opinions, just numbers
library;

import 'dart:math';
import 'package:drift/drift.dart';
import '../../../data/drift/app_database.dart';
import '../models/analytics_models.dart';

/// Pure math engine for expense analytics
/// All functions are deterministic and side-effect free
class MetricsEngine {
  final AppDatabase _db;
  
  MetricsEngine(this._db);
  
  // ========================================================================
  // BASIC AGGREGATIONS
  // ========================================================================
  
  /// Calculate total spending in date range
  Future<double> getTotalSpend(DateRange range, String budgetId) async {
    final expenses = await _getExpensesInRange(range, budgetId);
    return expenses.fold<double>(0, (sum, e) => sum + e.amount);
  }
  
  /// Average daily spending (total / days with activity)
  Future<double> getAverageDaily(DateRange range, String budgetId) async {
    final dailySpends = await getDailySpending(range, budgetId);
    if (dailySpends.isEmpty) return 0;
    
    final activeDays = dailySpends.where((d) => d.amount > 0).length;
    if (activeDays == 0) return 0;
    
    final total = dailySpends.fold<double>(0, (sum, d) => sum + d.amount);
    return total / activeDays;
  }
  
  /// What percentage of budget is spent on each category
  Future<Map<String, double>> getCategoryShares(
    DateRange range, 
    String budgetId,
  ) async {
    final expenses = await _getExpensesInRange(range, budgetId);
    final total = expenses.fold<double>(0, (sum, e) => sum + e.amount);
    
    if (total == 0) return {};
    
    final shares = <String, double>{};
    for (final expense in expenses) {
      final category = expense.categoryId ?? 'uncategorized';
      shares[category] = (shares[category] ?? 0) + expense.amount;
    }
    
    // Convert to percentages
    return shares.map((k, v) => MapEntry(k, v / total));
  }
  
  // ========================================================================
  // STATISTICAL MEASURES
  // ========================================================================
  
  /// Calculate variance of daily spending
  Future<double> getVariance(DateRange range, String budgetId) async {
    final dailySpends = await getDailySpending(range, budgetId);
    if (dailySpends.length < 2) return 0;
    
    final amounts = dailySpends.map((d) => d.amount).toList();
    final mean = amounts.reduce((a, b) => a + b) / amounts.length;
    
    final squaredDiffs = amounts.map((x) => pow(x - mean, 2));
    return squaredDiffs.reduce((a, b) => a + b) / amounts.length;
  }
  
  /// Standard deviation of daily spending
  Future<double> getStandardDeviation(DateRange range, String budgetId) async {
    final variance = await getVariance(range, budgetId);
    return sqrt(variance);
  }
  
  /// Coefficient of variation (std dev / mean)
  /// Higher = more erratic spending
  Future<double> getCoefficientOfVariation(
    DateRange range, 
    String budgetId,
  ) async {
    final stdDev = await getStandardDeviation(range, budgetId);
    final mean = await getAverageDaily(range, budgetId);
    
    if (mean == 0) return 0;
    return stdDev / mean;
  }
  
  // ========================================================================
  // DAILY & PATTERNS
  // ========================================================================
  
  /// Get daily spending amounts
  Future<List<DailySpend>> getDailySpending(
    DateRange range, 
    String budgetId,
  ) async {
    final expenses = await _getExpensesInRange(range, budgetId);
    
    // Group by date
    final dailyMap = <DateTime, List<Expense>>{};
    for (final expense in expenses) {
      final date = DateTime(
        expense.date.year, 
        expense.date.month, 
        expense.date.day,
      );
      dailyMap.putIfAbsent(date, () => []).add(expense);
    }
    
    // Convert to DailySpend objects
    final result = <DailySpend>[];
    for (final entry in dailyMap.entries) {
      final total = entry.value.fold<double>(0, (sum, e) => sum + e.amount);
      result.add(DailySpend(
        date: entry.key,
        amount: total,
        transactionCount: entry.value.length,
      ));
    }
    
    result.sort((a, b) => b.date.compareTo(a.date)); // Newest first
    return result;
  }
  
  /// Count of days with actual spending activity
  Future<int> getActiveDays(DateRange range, String budgetId) async {
    final dailySpends = await getDailySpending(range, budgetId);
    return dailySpends.where((d) => d.amount > 0).length;
  }
  
  /// Average spending for each weekday (1=Mon, 7=Sun)
  Future<Map<int, double>> getWeekdayBaseline(String budgetId) async {
    // Look back 8 weeks for patterns
    final now = DateTime.now();
    final eightWeeksAgo = now.subtract(const Duration(days: 56));
    final range = DateRange(start: eightWeeksAgo, end: now);
    
    final dailySpends = await getDailySpending(range, budgetId);
    
    // Group by weekday
    final weekdayTotals = <int, double>{};
    final weekdayCounts = <int, int>{};
    
    for (final day in dailySpends) {
      final weekday = day.date.weekday; // 1-7
      weekdayTotals[weekday] = (weekdayTotals[weekday] ?? 0) + day.amount;
      weekdayCounts[weekday] = (weekdayCounts[weekday] ?? 0) + 1;
    }
    
    // Calculate averages
    final baseline = <int, double>{};
    for (int i = 1; i <= 7; i++) {
      final total = weekdayTotals[i] ?? 0;
      final count = weekdayCounts[i] ?? 1;
      baseline[i] = total / count;
    }
    
    return baseline;
  }
  
  /// Rolling average for last N days
  Future<double> getRollingAverage(int days, String budgetId) async {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: days));
    final range = DateRange(start: start, end: now);
    
    final dailySpends = await getDailySpending(range, budgetId);
    if (dailySpends.isEmpty) return 0;
    
    final total = dailySpends.fold<double>(0, (sum, d) => sum + d.amount);
    return total / days;
  }
  
  // ========================================================================
  // TRENDS
  // ========================================================================
  
  /// Spending trend (positive = increasing, negative = decreasing)
  /// Compares recent vs historical average
  Future<double> getSpendingTrend(String budgetId) async {
    final recent7 = await getRollingAverage(7, budgetId);
    final historical30 = await getRollingAverage(30, budgetId);
    
    if (historical30 == 0) return 0;
    return (recent7 - historical30) / historical30;
  }
  
  /// Top N categories by spending
  Future<List<String>> getTopCategories(int count, String budgetId) async {
    final now = DateTime.now();
    final monthAgo = now.subtract(const Duration(days: 30));
    final range = DateRange(start: monthAgo, end: now);
    
    final shares = await getCategoryShares(range, budgetId);
    final sorted = shares.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(count).map((e) => e.key).toList();
  }

  /// Calculate "Burn Rate" - average daily spend over last 7 days vs 30 days
  Future<Map<String, double>> getBurnRate(String budgetId) async {
    final now = DateTime.now();
    final recentRange = DateRange(start: now.subtract(const Duration(days: 7)), end: now);
    final monthRange = DateRange(start: now.subtract(const Duration(days: 30)), end: now);

    final recentDaily = await getAverageDaily(recentRange, budgetId);
    final monthlyDaily = await getAverageDaily(monthRange, budgetId);

    return {
      'current_daily': recentDaily,
      'baseline_daily': monthlyDaily,
      'ratio': monthlyDaily > 0 ? recentDaily / monthlyDaily : 1.0,
    };
  }

  /// Generate Category Heatmap data (Category -> Day of Week -> Intensity)
  Future<List<Map<String, dynamic>>> getCategoryHeatmap(String budgetId) async {
    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 90)); // Last 90 days for heatmap
    final expenses = await _getExpensesInRange(DateRange(start: start, end: now), budgetId);

    final heatmap = <String, Map<int, double>>{}; // Category -> Weekday -> Amount

    for (final e in expenses) {
      final cat = e.categoryId ?? 'other';
      final weekday = e.date.weekday;
      heatmap.putIfAbsent(cat, () => {});
      heatmap[cat]![weekday] = (heatmap[cat]![weekday] ?? 0) + e.amount;
    }

    return heatmap.entries.map((e) => {
      'category': e.key,
      'data': e.value,
    }).toList();
  }
  
  /// Merchant frequency (how many times each merchant appears)
  Future<Map<String, int>> getMerchantFrequency(String budgetId) async {
    final now = DateTime.now();
    final monthAgo = now.subtract(const Duration(days: 30));
    final range = DateRange(start: monthAgo, end: now);
    
    final expenses = await _getExpensesInRange(range, budgetId);
    
    final frequency = <String, int>{};
    for (final expense in expenses) {
      final merchant = expense.merchantName ?? 'unknown';
      frequency[merchant] = (frequency[merchant] ?? 0) + 1;
    }
    
    return frequency;
  }
  
  // ========================================================================
  // COMPREHENSIVE SNAPSHOT
  // ========================================================================
  
  /// Get complete metrics snapshot for a budget
  Future<MetricsSnapshot> getSnapshot(String budgetId) async {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final range = DateRange(start: monthStart, end: now);
    
    return MetricsSnapshot(
      totalSpent: await getTotalSpend(range, budgetId),
      averageDaily: await getAverageDaily(range, budgetId),
      variance: await getVariance(range, budgetId),
      activeDays: await getActiveDays(range, budgetId),
      monthsOfHistory: await getMonthsOfHistory(budgetId),
      categoryShares: await getCategoryShares(range, budgetId),
      weekdayBaseline: await getWeekdayBaseline(budgetId),
    );
  }
  
  // ========================================================================
  // PRIVATE HELPERS
  // ========================================================================
  
  /// Get all expenses in date range for a budget
  Future<List<Expense>> _getExpensesInRange(
    DateRange range, 
    String budgetId,
  ) async {
    return await (_db.select(_db.expenses)
      ..where((e) => e.budgetId.equals(budgetId))
      ..where((e) => 
        e.date.isBiggerOrEqualValue(range.start) &
        e.date.isSmallerOrEqualValue(range.end))
      ..where((e) => e.isDeleted.equals(false)))
      .get();
  }
  
  /// Count how many months of expense history exist
  Future<int> getMonthsOfHistory(String budgetId) async {
    final oldest = await (_db.select(_db.expenses)
      ..where((e) => e.budgetId.equals(budgetId))
      ..where((e) => e.isDeleted.equals(false))
      ..orderBy([(e) => OrderingTerm.asc(e.date)])
      ..limit(1))
      .getSingleOrNull();
    
    if (oldest == null) return 0;
    
    final now = DateTime.now();
    final monthsDiff = (now.year - oldest.date.year) * 12 +
                      (now.month - oldest.date.month);
    
    return max(1, monthsDiff);
  }
}
