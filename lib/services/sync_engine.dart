import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/sync/sync_manager.dart';
import '../features/sync/sync_providers.dart';
import '../core/providers/error_provider.dart';
import '../core/mixins/error_handler_mixin.dart';

// Re-export types from SyncManager so consumers don't break
export '../features/sync/sync_manager.dart' show SyncStatus, SyncResult;

/// Legacy SyncEngine - Forwarding to new SyncOrchestrator
class SyncEngine with ErrorHandlerMixin {
  final Ref ref;
  SyncEngine(this.ref);

  /// Initialize real-time subscriptions and Orchestrator
  Future<void> initialize() async {
    await handleAsync(
      ref,
      () async {
        // CRITICAL: Initialize Orchestrator (this triggers immediate sync if authenticated)
        final orchestrator = ref.read(syncOrchestratorProvider);
        await orchestrator.initialize();
    
        // Start Orchestrator's Periodic Sync (Batched)
        orchestrator.startPeriodicSync();
      },
      errorMessage: 'Failed to initialize sync',
      severity: ErrorSeverity.critical,
    );
  }

  /// Perform a full 2-way sync (Batched via Orchestrator)
  Future<SyncResult> performSync() async {
    // Notify start
    ref.read(syncStatusProvider.notifier).state = SyncResult(status: SyncStatus.syncing);
    
    try {
      // Delegate to Orchestrator via unified trigger
      final orchestratorResult = await ref.read(syncOrchestratorProvider).requestSync(SyncReason.manualUserAction);
    
      // Map Orchestrator Result -> Legacy SyncResult
      final result = SyncResult(
        status: orchestratorResult.hasErrors ? SyncStatus.error : SyncStatus.success,
        message: orchestratorResult.errors.isNotEmpty ? orchestratorResult.errors.join('\n') : null,
        itemsSynced: orchestratorResult.totalItems,
        lastSyncTime: DateTime.now(),
      );
    
      // Update provider with result
      ref.read(syncStatusProvider.notifier).state = result;
      return result;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('[SyncEngine] Sync failed: $e');
      }
      ref.addError('Sync failed', details: e.toString(), stackTrace: stackTrace);
      final errorResult = SyncResult(status: SyncStatus.error, message: 'Sync failed: $e');
      ref.read(syncStatusProvider.notifier).state = errorResult;
      return errorResult;
    }
  }

  /// Alias for performSync
  Future<SyncResult> syncAll() => performSync();

  /// Sync a single expense immediately
  Future<void> syncExpense(String id) async {
    await ref.read(syncOrchestratorProvider).requestSync(SyncReason.dataChanged);
  }

  /// Sync a single budget immediately
  Future<void> syncBudget(String id) async {
    await ref.read(syncOrchestratorProvider).requestSync(SyncReason.dataChanged);
  }
  
  /// Sync a single semi-budget immediately
  Future<void> syncSemiBudget(String id) async {
    await ref.read(syncOrchestratorProvider).requestSync(SyncReason.dataChanged);
  }

  /// Sync a single account immediately
  Future<void> syncAccount(String id) async {
     await ref.read(syncOrchestratorProvider).requestSync(SyncReason.dataChanged);
  }

  /// Sync a single category immediately
  Future<void> syncCategory(String id) async {
    await ref.read(syncOrchestratorProvider).requestSync(SyncReason.dataChanged);
  }

  /// Sync a single budget member immediately
  Future<void> syncBudgetMember(String id) async {
    await ref.read(syncOrchestratorProvider).requestSync(SyncReason.dataChanged);
  }
}

/// Sync engine provider
final syncEngineProvider = Provider<SyncEngine>((ref) {
  return SyncEngine(ref);
});

/// Current sync status provider
final syncStatusProvider = StateProvider<SyncResult>((ref) {
  return SyncResult(status: SyncStatus.idle);
});

