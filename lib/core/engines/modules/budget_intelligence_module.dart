/// Budget Intelligence Module
/// Calculates budget health, forecasts, and anomalies
library;

import 'dart:math' as math;
import 'package:flutter/foundation.dart';

import '../plugin_system.dart' as plugin;
import '../models/intelligence_models.dart';
import '../../../data/drift/app_database.dart';

/// Budget intelligence calculation module
class BudgetIntelligenceModule extends plugin.IntelligencePlugin {
  AppDatabase? _db;
  
  @override
  String get name => 'budget_intelligence';
  
  @override
  String get version => '1.0.0';
  
  @override
  Future<void> initialize(plugin.EngineContext context) async {
    _db = context.database as AppDatabase;
    debugPrint('[BudgetIntelligence] Initialized');
  }
  
  @override
  Future<plugin.PluginResult> analyze(plugin.AnalysisRequest request) async {
    final budgetId = request.get<String>('budgetId');
    if (budgetId == null) {
      throw ArgumentError('budgetId is required');
    }
    
    final intelligence = await analyzeBudget(budgetId);
    return plugin.PluginResult(data: intelligence);
  }
  
  /// Analyze budget health and forecast
  Future<BudgetIntelligence> analyzeBudget(String budgetId) async {
    // Fetch budget data
    final budget = await _db!.getBudgetById(budgetId);
    if (budget == null) {
      throw StateError('Budget not found: $budgetId');
    }
    
    // Fetch expenses in budget period
    final expenses = await _db!.getExpensesInDateRange(
      budget.ownerId,
      budget.startDate,
      budget.endDate,
    );
    
    // Calculate metrics
    final now = DateTime.now();
    final totalSpent = expenses.fold<int>(
      0,
      (sum, expense) => sum + expense.amount.toInt(),
    );
    
    // Time calculations
    final startDate = budget.startDate;
    final endDate = budget.endDate;
    final daysTotal = endDate.difference(startDate).inDays + 1;
    final daysPassed = now.difference(startDate).inDays + 1;
    final daysLeft = endDate.difference(now).inDays;
    
    // Spending rate
    final spendRate = daysPassed > 0 ? totalSpent / daysPassed : 0.0;
    
    // Forecast
    final forecastTotal = spendRate * daysTotal;
    final forecastDelta = forecastTotal.toInt() - (budget.totalLimit?.toInt() ?? 0);
    
    // Calculate daily history for anomaly detection
    final dailyHistory = _calculateDailyHistory(expenses, startDate, daysPassed);
    
    // Anomaly detection
    final anomalyResult = _detectAnomaly(dailyHistory);
    
    // Health status
    final health = _calculateHealthStatus(
      totalSpent: totalSpent,
      totalLimit: budget.totalLimit?.toInt() ?? 0,
      daysPassed: daysPassed,
      daysTotal: daysTotal,
    );
    
    // Trend confidence
    final confidence = _calculateTrendConfidence(dailyHistory);
    
    return BudgetIntelligence(
      budgetId: budgetId,
      health: health,
      trendConfidence: confidence,
      totalLimit: budget.totalLimit?.toInt() ?? 0,
      totalSpent: totalSpent,
      daysPassed: daysPassed,
      daysTotal: daysTotal,
      daysLeft: daysLeft,
      spendRate: spendRate,
      forecastTotal: forecastTotal,
      forecastDelta: forecastDelta,
      isAnomalous: anomalyResult.isAnomalous,
      anomalyScore: anomalyResult.score,
      computedAt: DateTime.now(),
      cacheKey: 'budget_$budgetId',
    );
  }
  
  /// Calculate daily spending history
  List<int> _calculateDailyHistory(
    List<Expense> expenses,
    DateTime startDate,
    int daysPassed,
  ) {
    final history = List<int>.filled(daysPassed, 0);
    
    for (final expense in expenses) {
      final dayIndex = expense.date.difference(startDate).inDays;
      if (dayIndex >= 0 && dayIndex < daysPassed) {
        history[dayIndex] += expense.amount.toInt();
      }
    }
    
    return history;
  }
  
  /// Calculate budget health status
  BudgetHealthStatus _calculateHealthStatus({
    required int totalSpent,
    required int totalLimit,
    required int daysPassed,
    required int daysTotal,
  }) {
    if (totalSpent >= totalLimit) {
      return BudgetHealthStatus.exceeded;
    }
    
    final idealPace = daysPassed / daysTotal;
    final actualPace = totalSpent / totalLimit;
    final paceRatio = actualPace / idealPace;
    
    if (paceRatio <= 0.9) {
      return BudgetHealthStatus.healthy;
    } else if (paceRatio <= 1.1) {
      return BudgetHealthStatus.watch;
    } else {
      return BudgetHealthStatus.risk;
    }
  }
  
  /// Calculate trend confidence based on spending consistency
  TrendConfidence _calculateTrendConfidence(List<int> dailyHistory) {
    if (dailyHistory.length < 7) {
      return TrendConfidence.normal; // Not enough data
    }
    
    final mean = dailyHistory.reduce((a, b) => a + b) / dailyHistory.length;
    final variance = dailyHistory
        .map((val) => math.pow(val - mean, 2))
        .reduce((a, b) => a + b) / dailyHistory.length;
    final stdDev = math.sqrt(variance);
    
    // Coefficient of variation
    final cv = mean > 0 ? stdDev / mean : 0;
    
    if (cv < 0.5) {
      return TrendConfidence.normal;
    } else if (cv < 1.0) {
      return TrendConfidence.slightlyUnusual;
    } else {
      return TrendConfidence.veryUnusual;
    }
  }
  
  /// Detect spending anomalies
  _AnomalyResult _detectAnomaly(List<int> dailyHistory) {
    if (dailyHistory.length < 7) {
      return _AnomalyResult(isAnomalous: false, score: 0.0);
    }
    
    final mean = dailyHistory.reduce((a, b) => a + b) / dailyHistory.length;
    final variance = dailyHistory
        .map((val) => math.pow(val - mean, 2))
        .reduce((a, b) => a + b) / dailyHistory.length;
    final stdDev = math.sqrt(variance);
    
    // Check last 3 days
    final recentDays = dailyHistory.sublist(
      math.max(0, dailyHistory.length - 3),
    );
    
    var anomalyScore = 0.0;
    for (final daySpend in recentDays) {
      if (stdDev > 0) {
        final zScore = (daySpend - mean) / stdDev;
        anomalyScore = math.max(anomalyScore, zScore.abs());
      }
    }
    
    // Anomaly if z-score > 2 (95% confidence)
    return _AnomalyResult(
      isAnomalous: anomalyScore > 2.0,
      score: anomalyScore,
    );
  }
}

class _AnomalyResult {
  final bool isAnomalous;
  final double score;
  
  _AnomalyResult({required this.isAnomalous, required this.score});
}
