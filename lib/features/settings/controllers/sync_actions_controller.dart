/// Sync Actions Controller
/// Owns: enable/disable cloud sync, manual sync, force full sync, realtime reconnect
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../services/sync_engine.dart';
import '../../../features/sync/sync_providers.dart';
import '../models/operation_result.dart';

class SyncActionsController {
  final Ref ref;
  
  SyncActionsController(this.ref);

  /// Enable or disable cloud sync
  Future<OperationResult<void>> setCloudSyncEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('cloud_sync_enabled', enabled);
      
      if (enabled) {
        // Initialize sync engine and run first sync
        await ref.read(syncEngineProvider).initialize();
        await ref.read(syncEngineProvider).syncAll();
        debugPrint('[SyncActions] Cloud sync enabled, initial sync started');
      } else {
        // Just disable - don't disconnect realtime (user might re-enable quickly)
        debugPrint('[SyncActions] Cloud sync disabled');
      }
      
      return OperationResult.success(message: enabled ? 'Cloud sync enabled' : 'Cloud sync disabled');
    } catch (e) {
      debugPrint('[SyncActions] Error toggling sync: $e');
      return OperationResult.failure(message: 'Failed to toggle sync', error: e);
    }
  }

  /// Check if cloud sync is enabled
  Future<bool> isCloudSyncEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('cloud_sync_enabled') ?? true;
  }

  /// Manual sync trigger (pull + push)
  Future<OperationResult<SyncResult>> manualSync() async {
    try {
      debugPrint('[SyncActions] Manual sync triggered');
      final result = await ref.read(syncEngineProvider).syncAll();
      
      return OperationResult(
        status: result.status == SyncStatus.success 
            ? OperationStatus.success 
            : OperationStatus.failure,
        message: result.message ?? 'Sync completed',
        data: result,
      );
    } catch (e) {
      debugPrint('[SyncActions] Manual sync failed: $e');
      return OperationResult.failure(message: 'Sync failed', error: e);
    }
  }

  /// Force full sync (clear timestamps, pull everything)
  Future<OperationResult<SyncResult>> forceFullSync() async {
    try {
      debugPrint('[SyncActions] Force full sync triggered');
      
      // Clear sync timestamps
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((k) => k.contains('last_') && k.contains('_sync'));
      for (final key in keys) {
        await prefs.remove(key);
      }
      
      // Request full sync via orchestrator
      final orchestrator = ref.read(syncOrchestratorProvider);
      final result = await orchestrator.requestSync(SyncReason.forceFull);
      
      return OperationResult(
        status: result.hasErrors ? OperationStatus.partial : OperationStatus.success,
        message: 'Full sync completed: ${result.totalItems} items',
        data: SyncResult(
          status: result.hasErrors ? SyncStatus.error : SyncStatus.success,
          itemsSynced: result.totalItems,
        ),
      );
    } catch (e) {
      debugPrint('[SyncActions] Force full sync failed: $e');
      return OperationResult.failure(message: 'Full sync failed', error: e);
    }
  }

  /// Reconnect realtime subscriptions
  Future<OperationResult<void>> reconnectRealtime() async {
    try {
      debugPrint('[SyncActions] Reconnecting realtime...');
      // Reinitialize sync engine which re-establishes realtime
      await ref.read(syncEngineProvider).initialize();
      
      return OperationResult.success(message: 'Realtime reconnected');
    } catch (e) {
      debugPrint('[SyncActions] Realtime reconnect failed: $e');
      return OperationResult.failure(message: 'Reconnect failed', error: e);
    }
  }

  /// Get last sync timestamp
  Future<DateTime?> getLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getString('last_full_sync_timestamp');
    return timestamp != null ? DateTime.tryParse(timestamp) : null;
  }
}

/// Provider for SyncActionsController
final syncActionsControllerProvider = Provider<SyncActionsController>((ref) {
  return SyncActionsController(ref);
});
