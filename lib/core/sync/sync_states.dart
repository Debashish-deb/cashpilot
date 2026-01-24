/// Global Sync Engine State
/// Controls the overall sync session lifecycle
enum SyncEngineState {
  /// Initial state: determining if we have auth session
  bootstrap,
  
  /// No authentication, cannot sync
  signedOut,
  
  /// Ready to sync, waiting for trigger
  idle,
  
  /// User disabled sync in settings
  paused,
  
  /// Have work to do but no network
  waitNetwork,
  
  /// Ready to start sync work
  ready,
  
  /// Validating auth token, checking guards
  prechecks,
  
  /// Refreshing expired auth token
  authRefresh,
  
  /// Loading pending work from local DB
  loadWork,
  
  /// Pushing local changes to server
  pushOutbox,
  
  /// Sending current batch to server
  pushBatch,
  
  /// Waiting after transient error (429, network)
  backoff,
  
  /// Pulling remote changes from server
  pullRemote,
  
  /// Applying remote changes to local DB
  applyRemote,
  
  /// Have conflicts that need resolution
  conflictsPending,
  
  /// Waiting for user to resolve conflicts (expert mode)
  needUser,
  
  /// Finalizing sync session (update cursors, metrics)
  finalize,
  
  /// Auth error - session invalid
  errorAuth,
  
  /// Fatal error - schema mismatch or invariant break
  errorFatal,
}

/// Per-record sync state (stored in each syncable table row)
enum RecordSyncState {
  /// Created locally, never synced
  localOnly,
  
  /// Successfully synced with server
  synced,
  
  /// Modified locally, needs push
  dirty,
  
  /// Enqueued in outbox for next sync
  queued,
  
  /// Currently being pushed to server
  inFlight,
  
  /// Server rejected due to conflict
  conflict,
  
  /// User deleted, needs server delete
  deletePending,
  
  /// Soft deleted locally, tombstone set
  deletedLocal,
  
  /// Delete acknowledged by server
  deletedSynced,
  
  /// Fatal error during sync
  error,
}

/// Conflict resolution strategy
enum ConflictResolutionStrategy {
  /// Automatically merge if safe
  autoResolve,
  
  /// Local version wins
  localWins,
  
  /// Remote version wins
  remoteWins,
  
  /// Merge specific fields (user choice in expert mode)
  fieldMerge,
}

/// Realtime subscription state
enum RealtimeState {
  /// Realtime disabled (free tier or logged out)
  off,
  
  /// Connecting to Supabase realtime
  connecting,
  
  /// Connected and listening
  on,
  
  /// Received event, will trigger pull
  pullTrigger,
  
  /// Backoff after connection failure
  backoff,
}

/// Sync session phase (ordered steps)
enum SyncPhase {
  /// 1. Acquire session (auth ok, network ok)
  acquireSession,
  
  /// 2. Push local changes first (offline-first)
  pushOutbox,
  
  /// 3. Pull remote deltas
  pullRemote,
  
  /// 4. Apply and reconcile with local
  applyReconcile,
  
  /// 5. Resolve conflicts (auto or UI)
  resolveConflicts,
  
  /// 6. Finalize (cursors, metrics, schedule next)
  finalize,
}
