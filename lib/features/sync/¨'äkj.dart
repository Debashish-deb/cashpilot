/// Provides the SyncOrchestrator as a Riverpod provider
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart' show FlutterSecureStorage;

import '../../core/providers/app_providers.dart';
import '../../services/auth_service.dart';
import '../../services/device_info_service.dart';
import 'orchestrator/sync_orchestrator.dart';

/// Provider for the SyncOrchestrator
final syncOrchestratorProvider = Provider<SyncOrchestrator>((ref) {
  final db = ref.watch(databaseProvider);
  final prefs = ref.watch(sharedPreferencesProvider);
  
  final orchestrator = SyncOrchestrator(
    ref: ref,
    db: db,
    authService: AuthService(),
    deviceInfoService: DeviceInfoService(),
    prefs: prefs, secureStorage: FlutterSecureStorage(),
  );

  
  ref.onDispose(() {
    orchestrator.dispose();
  });
  
  return orchestrator;
});


final performSyncProvider = FutureProvider<SyncOrchestratorResult>((ref) async {
  final orchestrator = ref.watch(syncOrchestratorProvider);
  return await orchestrator.performFullSync();
});
