import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/sync/services/outbox_service.dart';
import '../../features/sync/services/conflict_service.dart';
import '../../features/analytics/services/forecasting_engine.dart';
import '../../features/analytics/services/confidence_engine.dart';
import 'app_providers.dart';

/// Outbox Service Provider
final outboxServiceProvider = Provider<OutboxService>((ref) {
  final db = ref.watch(databaseProvider);
  return OutboxService(db);
});

/// Conflict Service Provider
final conflictServiceProvider = Provider<ConflictService>((ref) {
  final db = ref.watch(databaseProvider);
  return ConflictService(db);
});

/// Forecasting Engine Provider
final forecastingEngineProvider = Provider<ForecastingEngine>((ref) {
  final db = ref.watch(databaseProvider);
  return ForecastingEngine(db);
});

/// Confidence Engine Provider
final confidenceEngineProvider = Provider<ConfidenceEngine>((ref) {
  return ConfidenceEngine();
});
