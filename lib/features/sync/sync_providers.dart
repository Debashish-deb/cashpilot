/// Sync Orchestrator Provider
/// Provides the SyncOrchestrator as a Riverpod provider
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import '../../services/auth_service.dart';
import '../../services/device_info_service.dart';
import 'services/data_repair_service.dart';
import 'orchestrator/sync_orchestrator.dart';

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
