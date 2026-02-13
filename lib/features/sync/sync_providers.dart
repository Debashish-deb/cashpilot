/// Sync Orchestrator Provider
/// Provides the SyncOrchestrator as a Riverpod provider
library;

import 'package:cashpilot/core/providers/app_providers.dart' show databaseProvider, secureStorageProvider, sharedPreferencesProvider;
import 'package:cashpilot/data/drift/app_database.dart' show ConflictData;
import 'package:cashpilot/features/sync/orchestrator/sync_orchestrator.dart' show SyncOrchestrator, SyncOrchestratorResult, SyncReason;
import 'package:cashpilot/features/sync/services/data_repair_service.dart' show DataRepairService;
import 'package:cashpilot/features/sync/services/outbox_service.dart' show OutboxService;
import 'package:cashpilot/features/sync/services/sync_checkpoint_service.dart' show SyncCheckpointService;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/auth_service.dart';
import '../../services/device_info_service.dart';
import '../../services/sync/conflict_service.dart';
import '../../core/sync/sync_state_machine.dart';
import '../../features/analytics/services/forecasting_engine.dart';
import '../../features/analytics/services/confidence_engine.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Export SyncReason for use by all sync triggers
export 'orchestrator/sync_orchestrator.dart' show SyncReason, SyncOrchestratorResult;

/// Provider for the SyncOrchestrator
final syncOrchestratorProvider = Provider<SyncOrchestrator>((ref) {
  final db = ref.watch(databaseProvider);
  final prefs = ref.watch(sharedPreferencesProvider);
  final secureStorage = ref.watch(secureStorageProvider);
  
  final orchestrator = SyncOrchestrator(
    ref: ref,
    db: db,
    authService: AuthService(),
    deviceInfoService: DeviceInfoService(),
    prefs: prefs,
    secureStorage: secureStorage,
  );
  
  // NOTE: Initialization is handled by SyncEngine or manually when needed
  // to avoid modifying other providers during build.
  
  ref.onDispose(() {
    orchestrator.dispose();
  });
  
  return orchestrator;
});

/// Provider for triggering a sync via the unified contract
/// Usage: await ref.read(requestSyncProvider(SyncReason.authLogin).future)
final requestSyncProvider = FutureProvider.family<SyncOrchestratorResult, SyncReason>((ref, reason) async {
  final orchestrator = ref.watch(syncOrchestratorProvider);
  return await orchestrator.requestSync(reason);
});

/// DEPRECATED: Use requestSyncProvider instead
/// Legacy provider for direct sync - still works but prefers requestSync
final performSyncProvider = FutureProvider<SyncOrchestratorResult>((ref) async {
  final orchestrator = ref.watch(syncOrchestratorProvider);
  return await orchestrator.performFullSync();
});

/// Provider for the DataRepairService
final dataRepairServiceProvider = Provider<DataRepairService>((ref) {
  final db = ref.watch(databaseProvider);
  return DataRepairService(db);
});

/// Sync State Machine Provider
final syncStateMachineProvider = Provider<SyncStateMachine>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SyncStateMachine(prefs: prefs);
});

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
