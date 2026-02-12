import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/auth_service.dart';
import '../../core/providers/app_providers.dart';
import '../../core/providers/sync_providers.dart';
import '../../services/device_info_service.dart';
import '../../features/subscription/providers/subscription_providers.dart';

import 'managers/expense_sync_manager.dart';
import 'managers/budget_sync_manager.dart';
import 'managers/account_sync_manager.dart';
import 'managers/semi_budget_sync_manager.dart';
import 'managers/category_sync_manager.dart';
import 'managers/savings_goal_sync_manager.dart';
import 'managers/budget_member_sync_manager.dart';

// DEPRECATED: syncManagerProvider removed. Use syncOrchestratorProvider instead.
// final syncManagerProvider = ...

enum SyncStatus { idle, syncing, success, error }

class SyncResult {
  final SyncStatus status;
  final String? message;
  final int itemsSynced;
  final DateTime? lastSyncTime;

  SyncResult({
    required this.status,
    this.message,
    this.itemsSynced = 0,
    this.lastSyncTime,
  });
}

class SyncProgress {
  final String phase;
  final int processed;
  final int total;

  const SyncProgress({
    required this.phase,
    required this.processed,
    required this.total,
  });
}

final syncProgressProvider =
    StateProvider<SyncProgress?>((ref) => null);

/// ---------------------------------------------------------------------------
/// REALTIME CONNECTION STATUS
/// ---------------------------------------------------------------------------
enum RealtimeConnectionStatus { 
  disconnected, 
  connecting, 
  connected, 
  error 
}

final realtimeStatusProvider = StateProvider<RealtimeConnectionStatus>(
  (ref) => RealtimeConnectionStatus.disconnected,
);

// _SyncQueueItem removed (Persistence upgrade)

/// ---------------------------------------------------------------------------
/// SYNC MANAGER (STRUCTURE PRESERVED)
/// ---------------------------------------------------------------------------
class SyncManager {
  final Ref ref;

  late final ExpenseSyncManager expenseSync;
  late final BudgetSyncManager budgetSync;
  late final AccountSyncManager accountSync;
  late final SemiBudgetSyncManager semiBudgetSync;
  late final SavingsGoalSyncManager savingsGoalSync;
  late final CategorySyncManager categorySync;
  late final BudgetMemberSyncManager budgetMemberSync;

  RealtimeChannel? _realtimeChannel;
  bool _isSyncing = false;
  bool _realtimePaused = false; // Flag to temporarily pause realtime sync
  
  /// Callback for external listeners (Orchestrator) to handle settings updates
  void Function()? onSettingsChanged;

  SyncManager(this.ref) {
    final db = ref.read(databaseProvider);
    final prefs = ref.read(sharedPreferencesProvider);
    final checkpointService = ref.read(syncCheckpointServiceProvider);

    expenseSync = ExpenseSyncManager(db, authService, checkpointService, ref);
    budgetSync = BudgetSyncManager(db, authService, checkpointService, ref);
    accountSync = AccountSyncManager(db, authService, checkpointService);
    semiBudgetSync = SemiBudgetSyncManager(db, authService, checkpointService);
    savingsGoalSync = SavingsGoalSyncManager(db, authService, checkpointService);
    categorySync = CategorySyncManager(db, authService, checkpointService);
    budgetMemberSync = BudgetMemberSyncManager(db, authService, checkpointService);
  }

  /// -------------------------------------------------------------------------
  /// GETTERS (UNCHANGED)
  /// -------------------------------------------------------------------------
  ExpenseSyncManager get expenses => expenseSync;
  BudgetSyncManager get budgets => budgetSync;
  AccountSyncManager get accounts => accountSync;
  SemiBudgetSyncManager get semiBudgets => semiBudgetSync;
  SavingsGoalSyncManager get savingsGoals => savingsGoalSync;
  CategorySyncManager get categories => categorySync;
  BudgetMemberSyncManager get budgetMembers => budgetMemberSync;

  /// -------------------------------------------------------------------------
  /// INITIALIZE (UNCHANGED SIGNATURE)
  /// -------------------------------------------------------------------------
  Timer? _periodicSyncTimer;

  void initialize() {
    setupRealtime();
    _replayOfflineQueue();
    // _startPeriodicSync(); // HANDLED BY SYNC ORCHESTRATOR NOW
    _listenToAuthChanges(); // NEW: Listen for login events
  }

  /// Listen to auth state changes and trigger initial sync on sign in
  void _listenToAuthChanges() {
    authService.authStateChanges.listen((event) {
      if (event.event == AuthChangeEvent.signedIn) {
        _log(' SyncManager: User signed in - checking profile before sync');
        // Setup realtime on login (was skipped during initialize if not authenticated)
        setupRealtime();
        // Delay slightly to ensure DB and services are ready
        Future.delayed(const Duration(milliseconds: 500), () async {
          if (authService.isAuthenticated) {
            // Check if profile exists before syncing
            final hasProfile = await _checkProfileExists();
            if (hasProfile) {
              _log(' SyncManager: Profile found - triggering initial sync');
              performSync();
            } else {
              _log(' SyncManager: No profile yet - waiting for profile setup');
              // Will sync after profile is created (triggered by auth flow)
            }
          }
        });
      }
    });
  }
  
  /// Check if user profile exists in Supabase
  Future<bool> _checkProfileExists() async {
    try {
      final userId = authService.currentUser?.id;
      if (userId == null) return false;
      
      final response = await authService.client
          .from('profiles')
          .select('id')
          .eq('id', userId)
          .maybeSingle();
      
      return response != null;
    } catch (e) {
      _log(' SyncManager: Profile check failed: $e');
      return false;
    }
  }

  /// -------------------------------------------------------------------------
  /// REALTIME PAUSE/RESUME (For bulk operations like currency conversion)
  /// -------------------------------------------------------------------------
  
  /// Pause incoming realtime sync. Use during bulk operations to prevent
  /// cloud data from overwriting local changes.
  void pauseRealtime() {
    _realtimePaused = true;
    _log(' REALTIME: Paused by request');
  }
  
  /// Resume incoming realtime sync after bulk operation completes.
  void resumeRealtime() {
    _realtimePaused = false;
    _log(' REALTIME: Resumed by request');
  }
  
  /// Check if realtime is currently paused
  bool get isRealtimePaused => _realtimePaused;

  /// -------------------------------------------------------------------------
  /// DISPOSE
  /// -------------------------------------------------------------------------
  void dispose() {
    _periodicSyncTimer?.cancel();
    _reconnectTimer?.cancel();
    _debounceSyncTimer?.cancel();
    _realtimeChannel?.unsubscribe();
    _realtimeChannel = null;
    _log('🔌 SyncManager: Disposed');
  }



  /// Safe logger
  void _log(String message) {
    if (kDebugMode) {
      debugPrint(message);
    }
  }

  /// -------------------------------------------------------------------------
  /// INSTANT SYNC (NEW - trigger immediately on local changes)
  /// -------------------------------------------------------------------------
  Timer? _debounceSyncTimer;
  
  /// Call this when local data changes to trigger an immediate sync
  void syncNow({String? table}) {
    // Debounce to avoid rapid-fire syncs
    _debounceSyncTimer?.cancel();
    _debounceSyncTimer = Timer(const Duration(milliseconds: 300), () {
      if (!_isSyncing && authService.isAuthenticated) {
        _log('⚡ SyncManager: Instant sync triggered${table != null ? ' for $table (Promoted to Full Batch)' : ''}');
        // Always Force Full Batch Sync
        performSync(); 
        /* 
        if (table != null) {
          _syncTable(table);
        } else {
          performSync();
        }
        */
      }
    });
  }
  

  
  /// Sync a specific expense immediately (for use after adding/editing)
  Future<void> syncExpenseNow(String expenseId) async {
    if (!authService.isAuthenticated) return;
    try {
      await expenseSync.syncUp(expenseId);
      _log('⚡ Expense $expenseId synced instantly');
    } catch (e) {
      _log(' Instant expense sync failed: $e');
    }
  }
  
  /// Sync a specific budget immediately
  Future<void> syncBudgetNow(String budgetId) async {
    if (!authService.isAuthenticated) return;
    try {
      await budgetSync.syncUp(budgetId);
      _log('⚡ Budget $budgetId synced instantly');
    } catch (e) {
      _log(' Instant budget sync failed: $e');
    }
  }

  /// -------------------------------------------------------------------------
  /// FULL SYNC (SIGNATURE UNCHANGED)
  /// -------------------------------------------------------------------------
  
  /// Optional override for performSync (to delegate to Orchestrator)
  Future<SyncResult> Function()? onPerformSync;

  Future<SyncResult> performSync() async {
    // Delegate if override is set
    if (onPerformSync != null) {
      _log(' SyncManager: Delegating sync to Orchestrator');
      return await onPerformSync!();
    }

    if (_isSyncing) {
      return SyncResult(
        status: SyncStatus.idle,
        message: 'Sync already running',
      );
    }

    if (!authService.isAuthenticated) {
      return SyncResult(
        status: SyncStatus.error,
        message: 'Not authenticated',
      );
    }

    _isSyncing = true;
    ref.read(syncProgressProvider.notifier).state =
        const SyncProgress(phase: 'starting', processed: 0, total: 0);

    int total = 0;

    try {
      // ---------------- PUSH ----------------
      ref.read(syncProgressProvider.notifier).state =
          const SyncProgress(phase: 'pushing', processed: 0, total: 6);

      total += await expenseSync.pushChanges();
      total += await budgetSync.pushChanges();
      total += await accountSync.pushChanges();
      total += await semiBudgetSync.pushChanges();
      total += await savingsGoalSync.pushChanges();
      total += await categorySync.pushChanges();
      total += await budgetMemberSync.pushChanges();

      // ---------------- PULL ----------------
      ref.read(syncProgressProvider.notifier).state =
          const SyncProgress(phase: 'pulling', processed: 0, total: 6);

      total += await expenseSync.pullChanges();
      total += await budgetSync.pullChanges();
      total += await accountSync.pullChanges();
      total += await semiBudgetSync.pullChanges();
      total += await savingsGoalSync.pullChanges();
      total += await categorySync.pullChanges();
      total += await budgetMemberSync.pullChanges();

      ref.read(syncProgressProvider.notifier).state =
          SyncProgress(phase: 'completed', processed: total, total: total);

      _log(' Sync completed: $total items synced at ${DateTime.now()}');
      
      return SyncResult(
        status: SyncStatus.success,
        itemsSynced: total,
        lastSyncTime: DateTime.now(),
      );
    } catch (e, st) {
      _log(' Sync failed: $e\n$st');

      ref.read(syncProgressProvider.notifier).state =
          SyncProgress(phase: 'error', processed: total, total: total);

      return SyncResult(
        status: SyncStatus.error,
        message: e.toString(),
      );
    } finally {
      _isSyncing = false;
    }
  }

  /// -------------------------------------------------------------------------
  /// REALTIME WITH RECONNECTION
  /// -------------------------------------------------------------------------
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  Timer? _reconnectTimer;
  
  void setupRealtime() {
    _realtimeChannel?.unsubscribe();
    _reconnectTimer?.cancel();

    if (!authService.isAuthenticated) {
      _log(' Realtime: Skipping setup - not authenticated');
      ref.read(realtimeStatusProvider.notifier).state = RealtimeConnectionStatus.disconnected;
      return;
    }

    // PREMIUM GATING: Only users with cloud access get realtime sync (Pro, Pro+, or family members)
    // Free users without family access rely on periodic sync only
    try {
      final subscriptionService = ref.read(subscriptionServiceProvider);
      final hasCloudAccess = subscriptionService.hasCloudAccess;
      
      if (!hasCloudAccess) {
        _log(' Realtime: Premium feature - Free users use periodic sync only');
        ref.read(realtimeStatusProvider.notifier).state = RealtimeConnectionStatus.disconnected;
        return;
      }
    } catch (e) {
      _log(' Realtime: Error checking subscription, proceeding anyway: $e');
    }

    // Set connecting status
    ref.read(realtimeStatusProvider.notifier).state = RealtimeConnectionStatus.connecting;
    _log('[Realtime] Connecting...');

    try {
      final client = authService.client;
      
      // Create channel with all table subscriptions
      _realtimeChannel = client
          .channel('public:db_changes')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'expenses',
            callback: (p) => _handleRealtimeEvent(p, 'expenses'),
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'budgets',
            callback: (p) => _handleRealtimeEvent(p, 'budgets'),
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'accounts',
            callback: (p) => _handleRealtimeEvent(p, 'accounts'),
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'semi_budgets',
            callback: (p) => _handleRealtimeEvent(p, 'semi_budgets'),
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'savings_goals',
            callback: (p) => _handleRealtimeEvent(p, 'savings_goals'),
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'categories',
            callback: (p) => _handleRealtimeEvent(p, 'categories'),
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'budget_members',
            callback: (p) => _handleRealtimeEvent(p, 'budget_members'),
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'profiles',
            callback: (p) => _handleRealtimeEvent(p, 'profiles'),
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'user_settings',
            callback: (p) => _handleRealtimeEvent(p, 'user_settings'),
          );

      // Subscribe with improved error handling
      _realtimeChannel!.subscribe((status, error) {
        // Detect Offline Mode (SocketException)
        final isOffline = error != null && 
            (error.toString().contains('SocketException') || 
             error.toString().contains('Failed host lookup'));

        if (isOffline) {
           _log('[Realtime] ⚠️ Offline Mode: Cannot reach server. Will retry automatically.');
           ref.read(realtimeStatusProvider.notifier).state = RealtimeConnectionStatus.disconnected; 
           _attemptReconnect(); // Retry with backoff
           return;
        }

        _log('[Realtime] Status: $status ${error != null ? '- Error: $error' : ''}');
        
        if (status == RealtimeSubscribeStatus.subscribed) {
          // Successfully connected - reset retry counter
          _reconnectAttempts = 0;
          ref.read(realtimeStatusProvider.notifier).state = RealtimeConnectionStatus.connected;
          _log('[Realtime] Connected');
        } else if (status == RealtimeSubscribeStatus.timedOut) {
          _log('[Realtime] Connection timed out');
          ref.read(realtimeStatusProvider.notifier).state = RealtimeConnectionStatus.error;
          _attemptReconnect();
        } else if (status == RealtimeSubscribeStatus.channelError) {
          _log('[Realtime] Channel error - ${error ?? 'Unknown'}');
          ref.read(realtimeStatusProvider.notifier).state = RealtimeConnectionStatus.error;
          _attemptReconnect();
        } else if (status == RealtimeSubscribeStatus.closed) {
          _log('[Realtime] Channel closed');
          ref.read(realtimeStatusProvider.notifier).state = RealtimeConnectionStatus.disconnected;
          // REMOVED _attemptReconnect() here - 'closed' is often intentional
          // Realtime will be re-established on next periodic sync or network change
        }
      });
    } catch (e, stackTrace) {
      final isOffline = e.toString().contains('SocketException') || e.toString().contains('Failed host lookup');
      
      if (isOffline) {
         _log('[Realtime] ⚠️ Setup skipped (Offline Mode)');
         ref.read(realtimeStatusProvider.notifier).state = RealtimeConnectionStatus.disconnected;
         _attemptReconnect();
      } else {
         _log('Realtime: Setup failed with exception: $e');
         _log('Stack trace: $stackTrace');
         ref.read(realtimeStatusProvider.notifier).state = RealtimeConnectionStatus.error;
         _attemptReconnect();
      }
    }
  }
  
  void _attemptReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      _log('Realtime: Max reconnect attempts reached. Will retry on next periodic sync.');
      return;
    }
    
    _reconnectAttempts++;
    final delay = Duration(seconds: _reconnectAttempts * 2); // Exponential backoff: 2s, 4s, 6s, 8s, 10s
    
    _log('🔄 Realtime: Reconnecting in ${delay.inSeconds}s (attempt $_reconnectAttempts/$_maxReconnectAttempts)');
    
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () {
      if (authService.isAuthenticated) {
setupRealtime();
      }
    });
  }

  Future<void> _handleRealtimeEvent(
      PostgresChangePayload payload, String table) async {
    
    // Skip if realtime is paused (e.g., during currency conversion)
    if (_realtimePaused) {
      _log('[Realtime] Paused - skipping incoming $table change');
      return;
    }
    
    // Get device info from the change
    final newRecord = payload.newRecord;
    final remoteDeviceId = newRecord['last_modified_by_device_id'];
    
    // Skip if this is our own change (avoid echo)
    if (remoteDeviceId != null && await deviceInfoService.isOwnDevice(remoteDeviceId)) {
      _log('[Realtime] Ignoring own change on $table');
      return;
    }
    
    // Log the incoming realtime event
    _log('[Realtime] Incoming change on $table from device: ${remoteDeviceId ?? 'unknown'}');
    
    // Immediately pull the specific table that changed
    try {
      switch (table) {
        case 'expenses':
          final count = await expenseSync.pullChanges();
          _log('[Realtime] Pulled $count expenses');
          break;
        case 'budgets':
          final count = await budgetSync.pullChanges();
          _log('[Realtime] Pulled $count budgets');
          break;
        case 'accounts':
          final count = await accountSync.pullChanges();
          _log('[Realtime] Pulled $count accounts');
          break;
        case 'semi_budgets':
          final count = await semiBudgetSync.pullChanges();
          _log('[Realtime] Pulled $count semi-budgets');
          break;
        case 'savings_goals':
          final count = await savingsGoalSync.pullChanges();
          _log('[Realtime] Pulled $count savings goals');
          break;
        case 'categories':
          final count = await categorySync.pullChanges();
          _log('[Realtime] Pulled $count categories');
          break;
        case 'budget_members':
          final count = await budgetMemberSync.pullChanges();
          _log('[Realtime] Pulled $count budget members');
          break;
        // Settings Tables (Delegated via callback)
        case 'profiles':
        case 'user_settings':
          _log('[Realtime] Remote settings changed: $table');
          if (onSettingsChanged != null) {
            onSettingsChanged!();
            // Notify UI
            ref.read(syncProgressProvider.notifier).state = SyncProgress(
              phase: 'realtime_settings',
              processed: 1,
              total: 1,
            );
          }
          break;
      }
      
      // Notify UI that data has been updated
      ref.read(syncProgressProvider.notifier).state = SyncProgress(
        phase: 'realtime_update',
        processed: 1,
        total: 1,
      );
      
    } catch (e) {
      _log('[Realtime] Sync failed for $table: $e');
    }
  }

  // Offline Queue


  Future<void> _replayOfflineQueue() async {
    // Legacy 'sync_queue' (SharedPreferences) removed in favor of DataBatchSync (Drift/DB).
    // DataBatchSync automatically scans for 'dirty' records in the database, 
    // so no separate queue is needed.
    
    // We simply trigger the Orchestrator to check for any pending work.
    if (onPerformSync != null && authService.isAuthenticated) {
      _log(' Checking for pending offline changes (DataBatchSync)...');
      await onPerformSync!();
    }
  }
}
