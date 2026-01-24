/// Honest Analytics Providers
/// Wired to the new 3-layer architecture (Metrics, Forecast, Narrative)
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/app_providers.dart';
import '../services/metrics_engine.dart';
import '../services/forecast_engine.dart';
import '../services/narrative_engine.dart';
import '../models/analytics_models.dart';

// ===================================
// SERVICE PROVIDERS
// ===================================

/// Metric Engine (Pure Math)
final metricsEngineProvider = Provider<MetricsEngine>((ref) {
  final db = ref.watch(databaseProvider);
  return MetricsEngine(db);
});

/// Forecast Engine (Weighted Logic)
final forecastEngineProvider = Provider<ForecastEngine>((ref) {
  final metrics = ref.watch(metricsEngineProvider);
  return ForecastEngine(metrics);
});

/// Narrative Engine (Honest Text)
final narrativeEngineProvider = Provider<NarrativeEngine>((ref) {
  return NarrativeEngine();
});

// ===================================
// DATA PROVIDERS
// ===================================

/// Forecast for a specific budget
/// Replaces the naive monthEndForecastProvider
final honestForecastProvider = FutureProvider.family<ForecastResult, String>((ref, budgetId) async {
  final engine = ref.watch(forecastEngineProvider);
  
  // Calculate remaining days
  final now = DateTime.now();
  final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
  final daysRemaining = lastDayOfMonth.day - now.day;
  
  return engine.forecastMonthEnd(
    budgetId: budgetId,
    daysRemaining: daysRemaining,
  );
});

/// Honest insights for a budget
final honestInsightsProvider = FutureProvider.family<List<Insight>, ({String budgetId, double limit})>((ref, args) async {
  final engine = ref.watch(forecastEngineProvider);
  return engine.generateInsights(
    budgetId: args.budgetId,
    budgetLimit: args.limit,
  );
});

/// Comprehensive Snapshot (for dashboard charts)
final analyticsSnapshotProvider = FutureProvider.family<MetricsSnapshot, String>((ref, budgetId) async {
  final engine = ref.watch(metricsEngineProvider);
  return engine.getSnapshot(budgetId);
});
