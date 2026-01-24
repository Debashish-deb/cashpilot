/// Intelligence Engine Riverpod Providers
/// Exposes Financial Intelligence Engine through Riverpod
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../engines/financial_intelligence_engine.dart';
import '../engines/models/intelligence_models.dart';
import 'app_providers.dart';

// ============================================================
// ENGINE SINGLETON
// ============================================================

/// Financial Intelligence Engine singleton
final intelligenceEngineProvider =
    Provider<FinancialIntelligenceEngine>((ref) {
  // Keep engine alive for app lifetime
  ref.keepAlive();

  final engine = FinancialIntelligenceEngine();

  final database = ref.watch(databaseProvider);
  final supabase = ref.watch(supabaseProvider);

  // Initialize once, safely
  engine.initialize(
    database: database,
    supabase: supabase,
  );

  // Cleanup on dispose (only when app truly shuts down)
  ref.onDispose(() => engine.dispose());

  return engine;
});

// ============================================================
// BUDGET INTELLIGENCE
// ============================================================

/// Budget intelligence for specific budget
final budgetIntelligenceProvider =
    FutureProvider.family<BudgetIntelligence, String>(
  (ref, budgetId) async {
    final engine = ref.watch(intelligenceEngineProvider);
    return engine.analyzeBudget(budgetId: budgetId);
  },
);

/// Force refresh budget intelligence
final refreshBudgetIntelligenceProvider =
    Provider.family<void, String>(
  (ref, budgetId) {
    final engine = ref.read(intelligenceEngineProvider);

    // Invalidate cache first
    engine.invalidateBudget(budgetId);

    // Then force provider refresh
    ref.invalidate(budgetIntelligenceProvider(budgetId));
  },
);

// ============================================================
// CATEGORY INTELLIGENCE
// ============================================================

/// Predict category for expense
final categoryPredictionProvider =
    FutureProvider.family<CategoryPrediction, CategoryPredictionParams>(
  (ref, params) async {
    final engine = ref.watch(intelligenceEngineProvider);

    return engine.predictCategory(
      title: params.title,
      merchant: params.merchant,
      amount: params.amount,
    );
  },
);

/// Parameters for category prediction
class CategoryPredictionParams {
  final String title;
  final String? merchant;
  final int? amount;

  CategoryPredictionParams({
    required this.title,
    this.merchant,
    this.amount,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryPredictionParams &&
          title == other.title &&
          merchant == other.merchant &&
          amount == other.amount;

  @override
  int get hashCode => Object.hash(title, merchant, amount);
}

// ============================================================
// SPENDING INTELLIGENCE
// ============================================================

/// Spending intelligence for user
final spendingIntelligenceProvider =
    FutureProvider.family<SpendingIntelligence, SpendingParams>(
  (ref, params) async {
    final engine = ref.watch(intelligenceEngineProvider);

    return engine.analyzeSpending(
      userId: params.userId,
      scope: params.scope,
    );
  },
);

/// Parameters for spending analysis
class SpendingParams {
  final String userId;
  final AnalysisScope scope;

  SpendingParams({
    required this.userId,
    this.scope = AnalysisScope.last30Days,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SpendingParams &&
          userId == other.userId &&
          scope == other.scope;

  @override
  int get hashCode => Object.hash(userId, scope);
}

// ============================================================
// CACHE STATS
// ============================================================

/// Cache statistics provider
final cacheStatsProvider = Provider((ref) {
  final engine = ref.watch(intelligenceEngineProvider);
  return engine.getCacheStats();
});

// ============================================================
// PERFORMANCE METRICS
// ============================================================

/// Performance metrics provider
final performanceMetricsProvider = Provider((ref) {
  final engine = ref.watch(intelligenceEngineProvider);
  return engine.getAverageMetrics();
});
