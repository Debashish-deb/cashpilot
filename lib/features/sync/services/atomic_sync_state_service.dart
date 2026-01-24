import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../../data/drift/app_database.dart';

/// Atomic Sync State Service
/// Replaces SharedPreferences for atomic sync state persistence
/// All operations use Drift transactions for atomicity
class AtomicSyncStateService {
  final AppDatabase db;
  final _uuid = const Uuid();

  AtomicSyncStateService(this.db);

  // ==================== SYNC RECOVERY STATE ====================

  /// Get current sync recovery state
  Future<SyncRecoveryStateData?> getSyncState() async {
    return await (db.select(db.syncRecoveryState)..where((t) => t.id.equals(1))).getSingleOrNull();
  }

  /// Update sync state atomically
  Future<void> updateSyncState({
    required String currentState,
    String? syncReason,
    List<String>? pendingOperations,
    String? lastError,
  }) async {
    await db.transaction(() async {
      final existing = await getSyncState();
      
      if (existing == null) {
        // Create initial state
        await db.into(db.syncRecoveryState).insert(
          SyncRecoveryStateCompanion.insert(
            currentState: currentState,
            updatedAt: DateTime.now(),
            syncReason: Value(syncReason),
            pendingOperations: Value(pendingOperations != null ? jsonEncode(pendingOperations) : null),
            lastError: Value(lastError),
          ),
        );
      } else {
        // Update existing state
        await (db.update(db.syncRecoveryState)..where((t) => t.id.equals(1))).write(
          SyncRecoveryStateCompanion(
            currentState: Value(currentState),
            updatedAt: Value(DateTime.now()),
            syncReason: Value(syncReason),
            pendingOperations: Value(pendingOperations != null ? jsonEncode(pendingOperations) : null),
            lastError: Value(lastError),
          ),
        );
      }
    });
  }

  /// Mark sync as started
  Future<void> markSyncStarted(String reason, List<String> pendingOps) async {
    await updateSyncState(
      currentState: 'syncing',
      syncReason: reason,
      pendingOperations: pendingOps,
    );
  }

  /// Mark sync as completed
  Future<void> markSyncCompleted() async {
    await db.transaction(() async {
      await (db.update(db.syncRecoveryState)..where((t) => t.id.equals(1))).write(
        SyncRecoveryStateCompanion(
          currentState: const Value('idle'),
          lastSyncCompletedAt: Value(DateTime.now()),
          syncStartedAt: const Value(null),
          pendingOperations: const Value(null),
          lastError: const Value(null),
          retryCount: const Value(0),
          updatedAt: Value(DateTime.now()),
        ),
      );
    });
  }

  /// Mark sync as failed
  Future<void> markSyncFailed(String error) async {
    final state = await getSyncState();
    final retryCount = (state?.retryCount ?? 0) + 1;
    
    await updateSyncState(
      currentState: 'error',
      lastError: error,
      pendingOperations: null,
    );
    
    await (db.update(db.syncRecoveryState)..where((t) => t.id.equals(1))).write(
      SyncRecoveryStateCompanion(
        retryCount: Value(retryCount),
      ),
    );
  }

  /// Get interrupted sync state (if app was killed during sync)
  Future<SyncRecoveryStateData?> getInterruptedSyncState() async {
    final state = await getSyncState();
    if (state != null && state.currentState == 'syncing' && state.syncStartedAt != null) {
      // Sync was in progress - this is an interrupted state
      return state;
    }
    return null;
  }

  // ==================== OPERATION LOG (Idempotency) ====================

  /// Check if operation has already been processed
  Future<bool> isOperationProcessed(String operationId) async {
    final result = await (db.select(db.syncOperationsLog)
          ..where((t) => t.operationId.equals(operationId)))
        .getSingleOrNull();
    return result != null && result.status == 'completed';
  }

  /// Log a new operation
  Future<String> logOperation({
    required String entityType,
    required String entityId,
    required String action,
    String? deviceId,
    Map<String, dynamic>? metadata,
  }) async {
    final operationId = _uuid.v4();
    
    await db.into(db.syncOperationsLog).insert(
      SyncOperationsLogCompanion.insert(
        operationId: operationId,
        entityType: entityType,
        entityId: entityId,
        action: action,
        status: 'pending',
        deviceId: Value(deviceId),
        timestamp: DateTime.now(),
        metadata: Value(metadata != null ? jsonEncode(metadata) : null),
      ),
    );
    
    return operationId;
  }

  /// Mark operation as completed
  Future<void> markOperationCompleted(String operationId) async {
    await (db.update(db.syncOperationsLog)..where((t) => t.operationId.equals(operationId)))
        .write(
      SyncOperationsLogCompanion(
        status: const Value('completed'),
        completedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Mark operation as failed
  Future<void> markOperationFailed(String operationId, String error) async {
    await (db.update(db.syncOperationsLog)..where((t) => t.operationId.equals(operationId)))
        .write(
      SyncOperationsLogCompanion(
        status: const Value('failed'),
        errorMessage: Value(error),
        completedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Get recent operations for debugging
  Future<List<SyncOperationLog>> getRecentOperations({int limit = 50}) async {
    return await (db.select(db.syncOperationsLog)
          ..orderBy([(t) => OrderingTerm.desc(t.timestamp)])
          ..limit(limit))
        .get();
  }

  /// Clean up old completed operations (keep last 7 days)
  Future<int> cleanupOldOperations() async {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    return await (db.delete(db.syncOperationsLog)
          ..where((t) => t.completedAt.isSmallerThanValue(cutoff) & t.status.equals('completed')))
        .go();
  }

  // ==================== STATE TRANSITIONS (Audit Trail) ====================

  /// Log a state transition
  Future<void> logStateTransition({
    required String fromState,
    required String toState,
    required String reason,
    String? sessionId,
    Map<String, dynamic>? context,
  }) async {
    await db.into(db.syncStateTransitions).insert(
      SyncStateTransitionsCompanion.insert(
        fromState: fromState,
        toState: toState,
        reason: reason,
        sessionId: Value(sessionId),
        timestamp: DateTime.now(),
        context: Value(context != null ? jsonEncode(context) : null),
      ),
    );
  }

  /// Get transition history for a session
  Future<List<SyncStateTransition>> getSessionTransitions(String sessionId) async {
    return await (db.select(db.syncStateTransitions)
          ..where((t) => t.sessionId.equals(sessionId))
          ..orderBy([(t) => OrderingTerm.asc(t.timestamp)]))
        .get();
  }

  /// Get recent transitions for debugging
  Future<List<SyncStateTransition>> getRecentTransitions({int limit = 100}) async {
    return await (db.select(db.syncStateTransitions)
          ..orderBy([(t) => OrderingTerm.desc(t.timestamp)])
          ..limit(limit))
        .get();
  }

  /// Export sync diagnostics for user support
  Future<Map<String, dynamic>> exportSyncDiagnostics() async {
    final state = await getSyncState();
    final recentOps = await getRecentOperations(limit: 20);
    final recentTransitions = await getRecentTransitions(limit: 50);
    
    return {
      'current_state': state?.toJson(),
      'recent_operations': recentOps.map((op) => op.toJson()).toList(),
      'recent_transitions': recentTransitions.map((t) => t.toJson()).toList(),
      'exported_at': DateTime.now().toIso8601String(),
    };
  }
}
