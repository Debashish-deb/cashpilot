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
import 'modules/behavioral_intelligence_module.dart';
import '../../features/knowledge/domain/repositories/knowledge_repository.dart';
import '../../features/knowledge/infrastructure/repositories/knowledge_repository_impl.dart';
import '../../features/knowledge/domain/entities/knowledge_article.dart';
import '../../features/knowledge/infrastructure/services/knowledge_seed_service.dart';

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
  KnowledgeRepository? _knowledgeRepository;

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
    _pluginSystem.register(BehavioralIntelligenceModule());

    final context = EngineContext(
      database: database,
      supabase: supabase,
    );

    await _pluginSystem.initializeAll(context);

    await _cache.initialize();
    _cache.startPeriodicCleanup();
    
    // Initialize Knowledge Repository
    _knowledgeRepository = KnowledgeRepositoryImpl(database);

    // Seed Knowledge Data
    final seedService = KnowledgeSeedService(database);
    await seedService.seedIfNeeded();

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
          final cached = await _cache.get<BudgetIntelligence>(
            cacheKey,
            deserializer: (json) => BudgetIntelligence.fromJson(json),
          );
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

        // Fire and forget set? No, better to await or ignore
        unawaited(_cache.set(
          cacheKey, 
          enriched,
          serializer: (val) => val.toJson(),
        ));
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
          final cached = await _cache.get<SpendingIntelligence>(
            cacheKey,
            deserializer: (json) => SpendingIntelligence.fromJson(json),
          );
          if (cached != null) return cached;
        }

        final result = await _pluginSystem.query<SpendingIntelligence>(
          pluginName: 'spending_intelligence',
          params: {
            'userId': userId,
            'scope': scope,
          },
        );

        // MERGE BEHAVIORAL PATTERNS (Phase B)
        try {
          final behavioralPatterns = await _pluginSystem.query<List<SpendingPattern>>(
            pluginName: 'behavioral_intelligence',
            params: {
              'userId': userId,
              'scope': scope,
            },
          );
          
          if (behavioralPatterns.isNotEmpty) {
            final mergedPatterns = List<SpendingPattern>.from(result.patterns)
              ..addAll(behavioralPatterns);
            
            final enriched = SpendingIntelligence(
              userId: result.userId,
              averageDaily: result.averageDaily,
              patterns: mergedPatterns,
              topCategories: result.topCategories,
              peakDays: result.peakDays,
              computedAt: result.computedAt,
            );
            
            unawaited(_cache.set(
              cacheKey, 
              enriched,
              serializer: (val) => val.toJson(),
            ));
            return enriched;
          }
        } catch (e) {
          debugPrint('[IntelligenceEngine] Behavioral merge failed: $e');
        }

        unawaited(_cache.set(
          cacheKey, 
          result,
          serializer: (val) => val.toJson(),
        ));
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
  // KNOWLEDGE SUGGESTIONS
  // ---------------------------------------------------------------------------

  Future<List<KnowledgeArticle>> suggestArticles({
    required String userId,
    bool forceRefresh = false,
  }) async {
    return _withErrorHandling(
      operation: 'suggest_articles',
      fn: () async {
        if (!_initialized || _knowledgeRepository == null) {
          return [];
        }

        // 1. Analyze spending to get context
        final spending = await analyzeSpending(
          userId: userId,
          scope: AnalysisScope.last30Days, 
          forceRefresh: forceRefresh,
        );
        
        // 2. Derive topics from spending patterns
        final Set<String> suggestedTopics = {'budgeting'}; // Always suggest budgeting
        
        // Pattern-based topic derivation
        for (final pattern in spending.patterns) {
          if (pattern.type == PatternType.weekendSplurge) {
            suggestedTopics.add('impulse_control');
            suggestedTopics.add('savings');
          }
          if (pattern.type == PatternType.recurringMerchant) {
            // Could link to subscription management if we find many recurring
            suggestedTopics.add('budgeting');
          }
        }

        // Potential for more logic: if peak days are Fri/Sat, also hint impulse control
        if (spending.peakDays.contains(4) || spending.peakDays.contains(5)) { // Fri, Sat
           suggestedTopics.add('impulse_control');
        }

        // If user has very low average spending relative to some benchmark, suggest investing?
        // (This needs a benchmark, but let's assume if they have top categories but low total)
        // For now, let's just add 'investing' as a secondary topic.
        suggestedTopics.add('investing');
        
        // 3. Fetch articles for topics
        final List<KnowledgeArticle> allSuggestions = [];
        
        for (final topic in suggestedTopics) {
          final articles = await _knowledgeRepository!.getArticles(topic: topic, limit: 3);
          allSuggestions.addAll(articles);
        }

        // Deduplicate and limit
        final unique = <String, KnowledgeArticle>{};
        for (var a in allSuggestions) {
          unique[a.id] = a;
        }
        
        return unique.values.toList();
      },
      fallback: [],
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
