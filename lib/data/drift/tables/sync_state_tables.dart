import 'package:drift/drift.dart';

/// Sync Recovery State Table
/// Stores the current sync state for crash recovery
/// This replaces SharedPreferences for atomic persistence
@DataClassName('SyncRecoveryStateData')
class SyncRecoveryState extends Table {
  /// Always use row ID 1 (single row table)
  IntColumn get id => integer().autoIncrement()();
  
  /// Current sync state (idle, syncing, reconciling, error)
  TextColumn get currentState => text().withLength(min: 1, max: 50)();
  
  /// Timestamp when sync started
  DateTimeColumn get syncStartedAt => dateTime().nullable()();
  
  /// Timestamp of last successful sync completion
  DateTimeColumn get lastSyncCompletedAt => dateTime().nullable()();
  
  /// Reason for current sync (authLogin, periodic, manual, etc.)
  TextColumn get syncReason => text().withLength(min: 1, max: 50).nullable()();
  
  /// Pending operation IDs (JSON array)
  TextColumn get pendingOperations => text().nullable()();
  
  /// Error message if sync failed
  TextColumn get lastError => text().nullable()();
  
  /// Number of retry attempts
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  
  /// Timestamp of last state transition
  DateTimeColumn get updatedAt => dateTime()();
}

/// Sync Operations Log Table
/// Tracks all sync operations for idempotency and debugging
@DataClassName('SyncOperationLog')
class SyncOperationsLog extends Table {
  /// Unique operation ID (UUID)
  TextColumn get operationId => text().withLength(min: 36, max: 36)();
  
  /// Entity type (expense, budget, category, etc.)
  TextColumn get entityType => text().withLength(min: 1, max: 50)();
  
  /// Entity ID being synced
  TextColumn get entityId => text().withLength(min: 1, max: 255)();
  
  /// Operation action (push, pull, merge, delete)
  TextColumn get action => text().withLength(min: 1, max: 20)();
  
  /// Operation status (pending, completed, failed)
  TextColumn get status => text().withLength(min: 1, max: 20)();
  
  /// Device ID that initiated the operation
  TextColumn get deviceId => text().withLength(min: 1, max: 255).nullable()();
  
  /// Operation timestamp
  DateTimeColumn get timestamp => dateTime()();
  
  /// Completion timestamp
  DateTimeColumn get completedAt => dateTime().nullable()();
  
  /// Error message if failed
  TextColumn get errorMessage => text().nullable()();
  
  /// Metadata (JSON)
  TextColumn get metadata => text().nullable()();
  
  @override
  Set<Column> get primaryKey => {operationId};
}

/// Sync State Transitions Log Table
/// Logs all state machine transitions for debugging and audit trail
@DataClassName('SyncStateTransition')
class SyncStateTransitions extends Table {
  /// Auto-increment ID
  IntColumn get id => integer().autoIncrement()();
  
  /// Previous state
  TextColumn get fromState => text().withLength(min: 1, max: 50)();
  
  /// New state
  TextColumn get toState => text().withLength(min: 1, max: 50)();
  
  /// Reason for transition
  TextColumn get reason => text().withLength(min: 1, max: 255)();
  
  /// Session ID to group related transitions
  TextColumn get sessionId => text().withLength(min: 1, max: 36).nullable()();
  
  /// Timestamp of transition
  DateTimeColumn get timestamp => dateTime()();
  
  /// Additional context (JSON)
  TextColumn get context => text().nullable()();
}
