import 'package:cashpilot/features/sync/services/outbox_service.dart' show OutboxService;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/drift/app_database.dart';
import '../../services/sync/conflict_service.dart';
import '../../features/analytics/services/forecasting_engine.dart';
import '../../features/analytics/services/confidence_engine.dart';
import 'app_providers.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../features/sync/services/sync_checkpoint_service.dart';

/// Outbox Service Provider
final outboxServiceProvider = Provider<OutboxService>((ref) {
  final db = ref.watch(databaseProvider);
  return OutboxService(db);
});

/// Sync Checkpoint Service Provider
final syncCheckpointServiceProvider = Provider<SyncCheckpointService>((ref) {
  return SyncCheckpointService(const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  ));
});

/// Conflict Service Provider
final conflictServiceProvider = Provider<ConflictService>((ref) {
  final db = ref.watch(databaseProvider);
  return ConflictService(db);
});

final openConflictsProvider = StreamProvider<int>((ref) {
  return ref.watch(conflictServiceProvider).watchOpenConflictCount();
});

final conflictListProvider = FutureProvider<List<ConflictData>>((ref) {
  return ref.watch(conflictServiceProvider).getOpenConflicts();
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
