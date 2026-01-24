/// Financial Intelligence Engine
/// Single source of truth for all financial analytics and insights
library;

import 'dart:async';
import 'package:flutter/foundation.dart';

import 'cache/intelligence_cache.dart';
import 'plugin_system.dart';
import 'models/intelligence_models.dart';
import 'modules/budget_intelligence_module.dart';
import 'modules/spending_intelligence_module.dart';


class FinancialIntelligenceEngine {
  /// Singleton instance
  static final FinancialIntelligenceEngine _instance =
      FinancialIntelligenceEngine._internal();

  factory FinancialIntelligenceEngine() => _instance;

  FinancialIntelligenceEngine._internal();

  // ---------------------------------------------------------------------------
  // CORE DEPENDENCIES
  // ---------------------------------------------------------------------------

  final _cache = IntelligenceCache();
  final _pluginSystem = PluginSystem();

  bool _initialized = false;

  // ---------------------------------------------------------------------------
  // PERFORMANCE METRICS
  // ---------------------------------------------------------------------------

  final _metrics = <String, List<Duration>>{};
  static const _maxMetricKeys = 50;

  // ---------------------------------------------------------------------------
  // INITIALIZATION
  // ---------------------------------------------------------------------------

  Future<void> initialize({
    required dynamic database,
    required dynamic supabase,
  }) async {
    if (_initialized) return;

    debugPrint('[IntelligenceEngine] Initializing...');

    _pluginSystem.register(BudgetIntelligenceModule());
    _pluginSystem.register(SpendingIntelligenceModule());

    final context = EngineContext(
      database: database,
      supabase: supabase,
    );

    await _pluginSystem.initializeAll(context);

    _cache.startPeriodicCleanup();

    _initialized = true;

    debugPrint(
      '[IntelligenceEngine] ✅ Initialized with '
      '${_pluginSystem.registeredPlugins.length} modules',
    );
  }

  void registerPlugin(IntelligencePlugin plugin) {
    _pluginSystem.register(plugin);
  }

  // ---------------------------------------------------------------------------
  // BUDGET INTELLIGENCE
  // ---------------------------------------------------------------------------

  Future<BudgetIntelligence> analyzeBudget({
    required String budgetId,
    bool forceRefresh = false,
  }) async {
    return _withErrorHandling(
      operation: 'analyze_budget',
      fn: () async {
        if (!_initialized) {
          return _defaultBudgetIntelligence(budgetId);
        }

        final cacheKey = 'engine:v1:budget:$budgetId';

        if (!forceRefresh) {
          final cached = _cache.get<BudgetIntelligence>(cacheKey);
          if (cached != null) return cached;
        }

        final result = await _pluginSystem.query<BudgetIntelligence>(
          pluginName: 'budget_intelligence',
          params: {'budgetId': budgetId},
        );

        final enriched = result.copyWith(
          computedAt: DateTime.now(),
          cacheKey: cacheKey,
        );

        _cache.set(cacheKey, enriched);
        return enriched;
      },
      fallback: _defaultBudgetIntelligence(budgetId),
    );
  }

  BudgetIntelligence _defaultBudgetIntelligence(String budgetId) {
    return BudgetIntelligence(
      budgetId: budgetId,
      health: BudgetHealthStatus.healthy,
      trendConfidence: TrendConfidence.normal,
      totalLimit: 0,
      totalSpent: 0,
      daysPassed: 0,
      daysTotal: 30,
      daysLeft: 30,
      spendRate: 0.0,
      forecastTotal: 0.0,
      forecastDelta: 0,
      isAnomalous: false,
      anomalyScore: 0.0,
      computedAt: DateTime.now(),
      cacheKey: 'fallback:budget:$budgetId',
    );
  }

  // ---------------------------------------------------------------------------
  // CATEGORY INTELLIGENCE
  // ---------------------------------------------------------------------------

  Future<CategoryPrediction> predictCategory({
    required String title,
    String? merchant,
    int? amount,
  }) async {
    return _withErrorHandling(
      operation: 'predict_category',
      fn: () async {
        return CategoryPrediction.unknown();
      },
      fallback: CategoryPrediction.unknown(),
    );
  }

  // ---------------------------------------------------------------------------
  // SPENDING INTELLIGENCE
  // ---------------------------------------------------------------------------

  Future<SpendingIntelligence> analyzeSpending({
    required String userId,
    AnalysisScope scope = AnalysisScope.last30Days,
    bool forceRefresh = false,
  }) async {
    return _withErrorHandling(
      operation: 'analyze_spending',
      fn: () async {
        if (!_initialized) {
          return _defaultSpendingIntelligence(userId);
        }

        final cacheKey = 'engine:v1:spending:$userId:${scope.name}';

        if (!forceRefresh) {
          final cached = _cache.get<SpendingIntelligence>(cacheKey);
          if (cached != null) return cached;
        }

        final result = await _pluginSystem.query<SpendingIntelligence>(
          pluginName: 'spending_intelligence',
          params: {
            'userId': userId,
            'scope': scope,
          },
        );

        _cache.set(cacheKey, result);
        return result;
      },
      fallback: _defaultSpendingIntelligence(userId),
    );
  }

  SpendingIntelligence _defaultSpendingIntelligence(String userId) {
    return SpendingIntelligence(
      userId: userId,
      averageDaily: 0.0,
      patterns: const [],
      topCategories: const {},
      peakDays: const [],
      computedAt: DateTime.now(),
    );
  }

  // ---------------------------------------------------------------------------
  // ML FEEDBACK
  // ---------------------------------------------------------------------------

  Future<void> submitFeedback(MLFeedback feedback) async {
    try {
      debugPrint(
        '[IntelligenceEngine] ✅ Feedback recorded: ${feedback.actualCategory}',
      );
    } catch (e, stack) {
      debugPrint('[IntelligenceEngine] ❌ Feedback error: $e');
      if (kDebugMode) debugPrint(stack.toString());
    }
  }

  // ---------------------------------------------------------------------------
  // CACHE MANAGEMENT
  // ---------------------------------------------------------------------------

  void invalidateBudget(String budgetId) {
    _cache.invalidatePattern('engine:v1:budget:$budgetId');
  }

  void invalidateSpending(String userId) {
    _cache.invalidatePattern('engine:v1:spending:$userId');
  }

  void clearCache() {
    _cache.clear();
  }

  CacheStats getCacheStats() => _cache.getStats();

  // ---------------------------------------------------------------------------
  // PERFORMANCE & MONITORING
  // ---------------------------------------------------------------------------

  Map<String, Duration> getAverageMetrics() {
    final avg = <String, Duration>{};

    for (final entry in _metrics.entries) {
      if (entry.value.isEmpty) continue;
      final total = entry.value.reduce((a, b) => a + b);
      avg[entry.key] = total ~/ entry.value.length;
    }

    return avg;
  }

  Future<T> _withErrorHandling<T>({
    required String operation,
    required Future<T> Function() fn,
    required T fallback,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      final result = await fn();
      stopwatch.stop();
      _recordMetric(operation, stopwatch.elapsed);
      return result;
    } catch (error, stackTrace) {
      stopwatch.stop();
      _recordMetric('$operation:error', stopwatch.elapsed);

      debugPrint('[IntelligenceEngine] ❌ Error in $operation: $error');
      if (kDebugMode) debugPrint(stackTrace.toString());

      return fallback;
    }
  }

  void _recordMetric(String operation, Duration duration) {
    if (_metrics.length >= _maxMetricKeys &&
        !_metrics.containsKey(operation)) {
      return;
    }

    _metrics.putIfAbsent(operation, () => []);
    final list = _metrics[operation]!;
    list.add(duration);

    if (list.length > 100) {
      list.removeAt(0);
    }

    if (duration > const Duration(seconds: 1)) {
      debugPrint(
        '[IntelligenceEngine] ⚠️ Slow operation: '
        '$operation took ${duration.inMilliseconds}ms',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // LIFECYCLE
  // ---------------------------------------------------------------------------

  Future<void> dispose() async {
    _cache.dispose();

    await _pluginSystem.disposeAll();
    _cache.clear();

    _initialized = false;
    debugPrint('[IntelligenceEngine] Disposed');
  }
}
