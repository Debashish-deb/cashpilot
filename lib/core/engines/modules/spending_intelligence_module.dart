/// Spending Intelligence Module
/// Analyzes spending patterns, trends, and category breakdowns
library;

import 'dart:math' as math;
import 'package:flutter/foundation.dart';

import '../plugin_system.dart' as plugin;
import '../models/intelligence_models.dart';
import '../../../data/drift/app_database.dart';

/// Spending pattern detection and analysis module
class SpendingIntelligenceModule extends plugin.IntelligencePlugin {
  AppDatabase? _db;
  
  @override
  String get name => 'spending_intelligence';
  
  @override
  String get version => '1.0.0';
  
  @override
  Future<void> initialize(plugin.EngineContext context) async {
    _db = context.database as AppDatabase;
    debugPrint('[SpendingIntelligence] Initialized');
  }
  
  @override
  Future<plugin.PluginResult> analyze(plugin.AnalysisRequest request) async {
    final userId = request.get<String>('userId');
    final scope = request.get<AnalysisScope>('scope') ?? AnalysisScope.last30Days;
    
    if (userId == null) {
      throw ArgumentError('userId is required');
    }
    
    final intelligence = await analyzeSpending(userId, scope);
    return plugin.PluginResult(data: intelligence);
  }
  
  /// Analyze user spending patterns
  Future<SpendingIntelligence> analyzeSpending(
    String userId,
    AnalysisScope scope,
  ) async {
    // Calculate date range based on scope
    final dateRange = _getDateRange(scope);
    
    // Fetch expenses in range
    final expenses = await _db!.getExpensesByUserInDateRange(
      userId: userId,
      startDate: dateRange.start,
      endDate: dateRange.end,
    );
    
    if (expenses.isEmpty) {
      return _emptyIntelligence(userId);
    }
    
    // Calculate average daily spending
    final totalSpent = expenses.fold<int>(
      0,
      (sum, e) => sum + e.amount.toInt(),
    );
    final days = dateRange.end.difference(dateRange.start).inDays + 1;
    final averageDaily = totalSpent / days;
    
    // Analyze patterns
    final patterns = _detectPatterns(expenses);
    
    // Category breakdown
    final topCategories = _calculateTopCategories(expenses);
    
    // Peak spending days (0=Monday, 6=Sunday)
    final peakDays = _findPeakDays(expenses);
    
    return SpendingIntelligence(
      userId: userId,
      averageDaily: averageDaily,
      patterns: patterns,
      topCategories: topCategories,
      peakDays: peakDays,
      computedAt: DateTime.now(),
    );
  }
  
  /// Get date range for analysis scope
  _DateRange _getDateRange(AnalysisScope scope) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    switch (scope) {
      case AnalysisScope.currentMonth:
        return _DateRange(
          start: DateTime(now.year, now.month, 1),
          end: today,
        );
      
      case AnalysisScope.last30Days:
        return _DateRange(
          start: today.subtract(const Duration(days: 30)),
          end: today,
        );
      
      case AnalysisScope.last90Days:
        return _DateRange(
          start: today.subtract(const Duration(days: 90)),
          end: today,
        );
      
      case AnalysisScope.yearToDate:
        return _DateRange(
          start: DateTime(now.year, 1, 1),
          end: today,
        );
      
      case AnalysisScope.allTime:
        return _DateRange(
          start: DateTime(2020, 1, 1), // Reasonable start
          end: today,
        );
    }
  }
  
  /// Detect spending patterns
  List<SpendingPattern> _detectPatterns(List<Expense> expenses) {
    final patterns = <SpendingPattern>[];
    
    // Group by merchant
    final merchantGroups = <String, List<Expense>>{};
    for (final expense in expenses) {
      final merchant = expense.merchantName ?? 'Unknown';
      merchantGroups.putIfAbsent(merchant, () => []).add(expense);
    }
    
    // Find recurring merchants (4+ transactions)
    for (final entry in merchantGroups.entries) {
      if (entry.value.length >= 4) {
        final avgAmount = entry.value
            .map((e) => e.amount.toInt())
            .reduce((a, b) => a + b) ~/ entry.value.length;
        
        patterns.add(SpendingPattern(
          id: 'recurring_merchant_${entry.key}',
          type: PatternType.recurringMerchant,
          merchant: entry.key,
          frequencyCount: entry.value.length,
          averageAmount: avgAmount,
          confidence: math.min(entry.value.length / 10, 1.0),
        ));
      }
    }
    
    // Detect weekend splurges (spending 50%+ higher on weekends)
    final weekdaySpending = <int>[];
    final weekendSpending = <int>[];
    
    for (final expense in expenses) {
      final weekday = expense.date.weekday;
      if (weekday >= 6) {
        weekendSpending.add(expense.amount.toInt());
      } else {
        weekdaySpending.add(expense.amount.toInt());
      }
    }
    
    if (weekdaySpending.isNotEmpty && weekendSpending.isNotEmpty) {
      final weekdayAvg = weekdaySpending.reduce((a, b) => a + b) / weekdaySpending.length;
      final weekendAvg = weekendSpending.reduce((a, b) => a + b) / weekendSpending.length;
      
      if (weekendAvg > weekdayAvg * 1.5) {
        patterns.add(SpendingPattern(
          id: 'weekend_splurge',
          type: PatternType.weekendSplurge,
          merchant: null,
          frequencyCount: weekendSpending.length,
          averageAmount: weekendAvg.toInt(),
          confidence: math.min((weekendAvg - weekdayAvg) / weekdayAvg, 1.0),
        ));
      }
    }
    
    return patterns;
  }
  
  /// Calculate top spending categories
  Map<String, int> _calculateTopCategories(List<Expense> expenses) {
    final categoryTotals = <String, int>{};
    
    for (final expense in expenses) {
      final category = expense.semiBudgetId ?? 'uncategorized';
      categoryTotals[category] = (categoryTotals[category] ?? 0) + expense.amount.toInt();
    }
    
    // Sort and take top 5
    final sorted = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return Map.fromEntries(sorted.take(5));
  }
  
  /// Find peak spending days of week
  List<int> _findPeakDays(List<Expense> expenses) {
    final dailyTotals = List<int>.filled(7, 0); // Mon-Sun
    
    for (final expense in expenses) {
      final weekday = (expense.date.weekday - 1) % 7; // 0=Mon, 6=Sun
      dailyTotals[weekday] += expense.amount.toInt();
    }
    
    // Find days above average
    final total = dailyTotals.reduce((a, b) => a + b);
    final average = total / 7;
    
    final peakDays = <int>[];
    for (var i = 0; i < 7; i++) {
      if (dailyTotals[i] > average * 1.2) {
        peakDays.add(i);
      }
    }
    
    return peakDays;
  }
  
  /// Empty intelligence for no data
  SpendingIntelligence _emptyIntelligence(String userId) {
    return SpendingIntelligence(
      userId: userId,
      averageDaily: 0.0,
      patterns: [],
      topCategories: {},
      peakDays: [],
      computedAt: DateTime.now(),
    );
  }
}

class _DateRange {
  final DateTime start;
  final DateTime end;
  
  _DateRange({required this.start, required this.end});
}
