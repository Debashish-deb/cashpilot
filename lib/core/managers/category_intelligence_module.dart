/// Category Intelligence Module
/// Analyzes spending patterns, detects trends, and generates insights per category
library;

import 'dart:math';
import 'package:drift/drift.dart' show Variable;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/drift/app_database.dart';
import '../providers/app_providers.dart';

/// Category spending insight
class CategoryInsight {
  final String categoryId;
  final String categoryName;
  final int totalSpent;
  final int limit;
  final double percentage;
  final int remainingAmount;
  final int transactionCount;
  final int avgTransaction;
  
  // Pattern analysis
  final SpendingTrend trend;
  final String? peakDay;
  final int? peakHour;
  
  // Predictions
  final int predictedMonthEnd;
  final int daysUntilLimitReached;
  final double confidence;
  
  // Comparisons
  final double vsLastPeriodPercent;
  final double vsAveragePercent;
  
  // Insights
  final List<InsightMessage> insights;
  final List<String> recommendations;
  
  CategoryInsight({
    required this.categoryId,
    required this.categoryName,
    required this.totalSpent,
    required this.limit,
    required this.percentage,
    required this.remainingAmount,
    required this.transactionCount,
    required this.avgTransaction,
    required this.trend,
    this.peakDay,
    this.peakHour,
    required this.predictedMonthEnd,
    required this.daysUntilLimitReached,
    required this.confidence,
    required this.vsLastPeriodPercent,
    required this.vsAveragePercent,
    required this.insights,
    required this.recommendations,
  });
}

enum SpendingTrend { increasing, decreasing, stable }

class InsightMessage {
  final String type; // 'warning', 'tip', 'achievement', 'pattern'
  final String severity; // 'info', 'warning', 'critical'
  final String message;
  final String? action;
  
  const InsightMessage({
    required this.type,
    required this.severity,
    required this.message,
    this.action,
  });
}

/// Provider for category insights
final categoryInsightsProvider = FutureProvider.family<CategoryInsight, String>((ref, categoryId) async {
  final db = ref.watch(databaseProvider);
  final module = CategoryIntelligenceModule(db);
  
  return await module.analyzeCategory(categoryId);
});

/// Category Intelligence Module
class CategoryIntelligenceModule {
  final AppDatabase db;
  
  CategoryIntelligenceModule(this.db);
  
  Future<CategoryInsight> analyzeCategory(String categoryId) async {
    // Fetch category data
    final category = await _getCategory(categoryId);
    if (category == null) {
      throw Exception('Category not found');
    }
    
    // Get time range (current budget period)
    final budget = await _getBudget(category.budgetId);
    final startDate = budget.startDate;
    final endDate = budget.endDate;
    
    // Fetch transactions
    final transactions = await _getTransactions(categoryId, startDate, endDate);
    final totalSpent = transactions.fold(0, (sum, t) => sum + t.amount);
    final transactionCount = transactions.length;
    final avgTransaction = transactionCount > 0 ? (totalSpent / transactionCount).round() : 0;
    
    // Calculate percentage
    final percentage = category.limitAmount > 0 
        ? (totalSpent / category.limitAmount) * 100 
        : 0.0;
    final remainingAmount = category.limitAmount - totalSpent;
    
    // Analyze patterns
    final trend = _detectTrend(transactions);
    final peakDay = _findPeakDay(transactions);
    final peakHour = _findPeakHour(transactions);
    
    // Make predictions
    final predictedMonthEnd = _predictMonthEnd(totalSpent, startDate, endDate);
    final daysUntilLimit = _calculateDaysToLimit(totalSpent, category.limitAmount, transactions, endDate);
    final confidence = _calculateConfidence(transactions);
    
    // Compare to historical data
    final vsLastPeriod = await _compareToLastPeriod(categoryId, totalSpent);
    final vsAverage = await _compareToAverage(categoryId, totalSpent);
    
    // Generate insights
    final insights = _generateInsights(
      category,
      totalSpent,
      percentage,
      trend,
      peakDay,
      avgTransaction,
      vsAverage,
    );
    
    // Generate recommendations
    final recommendations = _generateRecommendations(
      percentage,
      predictedMonthEnd,
      category.limitAmount,
      vsAverage,
    );
    
    return CategoryInsight(
      categoryId: categoryId,
      categoryName: category.name,
      totalSpent: totalSpent,
      limit: category.limitAmount,
      percentage: percentage,
      remainingAmount: remainingAmount,
      transactionCount: transactionCount,
      avgTransaction: avgTransaction,
      trend: trend,
      peakDay: peakDay,
      peakHour: peakHour,
      predictedMonthEnd: predictedMonthEnd,
      daysUntilLimitReached: daysUntilLimit,
      confidence: confidence,
      vsLastPeriodPercent: vsLastPeriod,
      vsAveragePercent: vsAverage,
      insights: insights,
      recommendations: recommendations,
    );
  }
  
  Future<SemiBudget?> _getCategory(String categoryId) async {
    return await (db.select(db.semiBudgets)
      ..where((t) => t.id.equals(categoryId)))
      .getSingleOrNull();
  }
  
  Future<Budget> _getBudget(String budgetId) async {
    return await (db.select(db.budgets)
      ..where((t) => t.id.equals(budgetId)))
      .getSingle();
  }
  
  Future<List<Expense>> _getTransactions(String categoryId, DateTime start, DateTime end) async {
    // Get all expenses for this category in the date range
    final query = db.select(db.expenses)
      ..where((t) => t.semiBudgetId.equals(categoryId))
      ..where((t) => t.isDeleted.equals(false));
    
    final allExpenses = await query.get();
    
    // Filter by date range and sort in Dart
    final filtered = allExpenses.where((e) => 
      !e.date.isBefore(start) && !e.date.isAfter(end)
    ).toList();
    
    filtered.sort((a, b) => a.date.compareTo(b.date));
    return filtered;
  }
  
  SpendingTrend _detectTrend(List<Expense> transactions) {
    if (transactions.length < 7) return SpendingTrend.stable;
    
    // Simple linear regression on daily totals
    final daily = <int, int>{};
    for (final tx in transactions) {
      final day = tx.date.day;
      daily[day] = (daily[day] ?? 0) + tx.amount;
    }
    
    final days = daily.keys.toList()..sort();
    if (days.length < 3) return SpendingTrend.stable;
    
    double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;
    for (int i = 0; i < days.length; i++) {
      final x = i.toDouble();
      final y = daily[days[i]]!.toDouble();
      sumX += x;
      sumY += y;
      sumXY += x * y;
      sumX2 += x * x;
    }
    
    final n = days.length;
    final slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);
    
    if (slope > 100) return SpendingTrend.increasing;
    if (slope < -100) return SpendingTrend.decreasing;
    return SpendingTrend.stable;
  }
  
  String? _findPeakDay(List<Expense> transactions) {
    if (transactions.isEmpty) return null;
    
    final daySpending = <int, int>{};
    for (final tx in transactions) {
      final weekday = tx.date.weekday;
      daySpending[weekday] = (daySpending[weekday] ?? 0) + tx.amount;
    }
    
    final peakDay = daySpending.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[peakDay - 1];
  }
  
  int? _findPeakHour(List<Expense> transactions) {
    if (transactions.isEmpty) return null;
    
    final hourSpending = <int, int>{};
    for (final tx in transactions) {
      final hour = tx.date.hour;
      hourSpending[hour] = (hourSpending[hour] ?? 0) + tx.amount;
    }
    
    return hourSpending.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }
  
  int _predictMonthEnd(int currentSpent, DateTime start, DateTime end) {
    final now = DateTime.now();
    final daysElapsed = now.difference(start).inDays;
    final daysTotal = end.difference(start).inDays;
    
    if (daysElapsed == 0) return currentSpent;
    
    final avgPerDay = currentSpent / daysElapsed;
    return (avgPerDay * daysTotal).round();
  }
  
  int _calculateDaysToLimit(int currentSpent, int limit, List<Expense> transactions, DateTime end) {
    if (currentSpent >= limit) return 0;
    if (transactions.isEmpty) return 999;
    
    // Use last 7 days average
    final recent = transactions.where((t) => 
      DateTime.now().difference(t.date).inDays <= 7
    ).toList();
    
    if (recent.isEmpty) return 999;
    
    final recentSpent = recent.fold(0, (sum, t) => sum + t.amount);
    final avgPerDay = recentSpent / recent.length;
    
    if (avgPerDay == 0) return 999;
    
    final remaining = limit - currentSpent;
    final daysToLimit = (remaining / avgPerDay).ceil();
    
    final daysRemaining = end.difference(DateTime.now()).inDays;
    return min(daysToLimit, daysRemaining);
  }
  
  double _calculateConfidence(List<Expense> transactions) {
    if (transactions.length < 3) return 0.5;
    
    final  amounts = transactions.map((t) => t.amount.toDouble()).toList();
    final mean = amounts.reduce((a, b) => a + b) / amounts.length;
    final variance = amounts.map((x) => pow(x - mean, 2)).reduce((a, b) => a + b) / amounts.length;
    final stdDev = sqrt(variance);
    final cv = stdDev / mean;
    
    // Lower coefficient of variation = higher confidence
    return max(0.0, min(1.0, 1.0 - cv));
  }
  
  Future<double> _compareToLastPeriod(String categoryId, int currentSpent) async {
    try {
      // Get current budget period dates
      final category = await _getCategory(categoryId);
      if (category == null) return 0.0;
      
      final budget = await _getBudget(category.budgetId);
      final periodLength = budget.endDate.difference(budget.startDate).inDays;
      
      // Calculate last period dates
      final lastPeriodStart = budget.startDate.subtract(Duration(days: periodLength));
      final lastPeriodEnd = budget.startDate.subtract(const Duration(days: 1));
      
      // Get last period transactions
      final lastPeriodTxs = await _getTransactions(categoryId, lastPeriodStart, lastPeriodEnd);
      final lastPeriodSpent = lastPeriodTxs.fold(0, (sum, t) => sum + t.amount);
      
      if (lastPeriodSpent == 0) return 0.0;
      
      // Calculate percentage difference
      final diff = ((currentSpent - lastPeriodSpent) / lastPeriodSpent) * 100;
      return diff;
    } catch (e) {
      return 0.0;
    }
  }
  
  Future<double> _compareToAverage(String categoryId, int currentSpent) async {
    try {
      // Get last 3 months of expenses for this category
      final threeMonthsAgo = DateTime.now().subtract(const Duration(days: 90));
      final allTxs = await db.customSelect(
        '''
        SELECT amount FROM expenses 
        WHERE semi_budget_id = ? 
        AND is_deleted = 0
        AND date >= ?
        ORDER BY date DESC
        ''',
        variables: [
          Variable.withString(categoryId),
          Variable.withDateTime(threeMonthsAgo),
        ],
        readsFrom: {db.expenses},
      ).get();
      
      if (allTxs.isEmpty) return 0.0;
      
      final total = allTxs.fold(0, (sum, row) => sum + (row.read<int>('amount') ?? 0));
      final avg = total / 3; // Average per month
      
      if (avg == 0) return 0.0;
      
      // Calculate percentage difference from average
      final diff = ((currentSpent - avg) / avg) * 100;
      return diff;
    } catch (e) {
      return 0.0;
    }
  }
  
  List<InsightMessage> _generateInsights(
    SemiBudget category,
    int totalSpent,
    double percentage,
    SpendingTrend trend,
    String? peakDay,
    int avgTransaction,
    double vsAverage,
  ) {
    final insights = <InsightMessage>[];
    
    // Budget status insight
    if (percentage > 100) {
      insights.add(InsightMessage(
        type: 'warning',
        severity: 'critical',
        message: '${percentage.toInt()}% of ${category.name} budget spent - Over limit!',
        action: 'Review expenses',
      ));
    } else if (percentage > 90) {
      insights.add(InsightMessage(
        type: 'warning',
        severity: 'warning',
        message: 'Approaching ${category.name} budget limit (${percentage.toInt()}%)',
        action: 'Reduce spending',
      ));
    } else if (percentage > 75) {
      insights.add(InsightMessage(
        type: 'warning',
        severity: 'info',
        message: '${percentage.toInt()}% of ${category.name} budget used',
      ));
    }
    
    // Trend insight
    if (trend == SpendingTrend.increasing) {
      insights.add(InsightMessage(
        type: 'pattern',
        severity: 'info',
        message: '${category.name} spending is trending upward',
      ));
    }
    
    // Pattern insight
    if (peakDay != null) {
      insights.add(InsightMessage(
        type: 'pattern',
        severity: 'info',
        message: 'You spend most on ${category.name} on ${peakDay}s',
      ));
    }
    
    // Comparison insight
    if (vsAverage > 20) {
      insights.add(InsightMessage(
        type: 'tip',
        severity: 'warning',
        message: '${category.name} spending is ${vsAverage.toInt()}% above your average',
        action: 'Find savings',
      ));
    }
    
    return insights;
  }
  
  List<String> _generateRecommendations(
    double percentage,
    int predictedMonthEnd,
    int limit,
    double vsAverage,
  ) {
    final recommendations = <String>[];
    
    if (predictedMonthEnd > limit) {
      final overage = predictedMonthEnd - limit;
      recommendations.add('On track to exceed by \$${(overage / 100).toStringAsFixed(2)}');
    }
    
    if (vsAverage > 15) {
      recommendations.add('Look for alternative options to reduce costs');
    }
    
    if (percentage > 50 && percentage < 75) {
      recommendations.add('You\'re on track! Continue current spending pace');
    }
    
    return recommendations;
  }
}
