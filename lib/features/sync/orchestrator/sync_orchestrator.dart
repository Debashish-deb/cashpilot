/// Sync Orchestrator
/// Central coordinator for ALL sync operations
/// 
/// This orchestrator DOES NOT change how individual sync managers work.
/// It simply organizes them into a coordinated flow with proper batching.
library;

import 'dart:async';
import 'package:cashpilot/features/sync/data/data_batch_sync.dart' show DataBatchSync;
import 'package:cashpilot/features/sync/settings/settings_batch_sync.dart' show SettingsBatchSync, SettingsSyncResult;
import 'package:cashpilot/core/theme/accent_colors.dart'; // For refreshing accent color
import 'package:cashpilot/features/sync/sync_manager.dart' show RealtimeConnectionStatus, SyncManager, realtimeStatusProvider;
import 'package:cashpilot/services/device_info_service.dart' show DeviceInfoService;
import 'package:cashpilot/services/subscription_service.dart' show SubscriptionService;
import 'package:cashpilot/services/kill_switch_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/subscription.dart';
import '../../../core/providers/user_mode_provider.dart';
import '../../../data/drift/app_database.dart';
import '../../../services/auth_service.dart';
import '../services/device_gate_service.dart';
import '../services/sync_checkpoint_service.dart';
import '../../../core/providers/app_providers.dart'; // For refreshing settings via ref
import '../../../core/sync/sync_state_machine.dart'; // Formal state machine
import '../../../core/sync/sync_states.dart'; // State enums
import 'package:cashpilot/core/errors/error_taxonomy.dart'; // Error classification

import '../services/atomic_sync_state_service.dart'; // NEW: Atomic persistence
import '../../../core/sync/lamport_clock.dart';

/// Sync Reason - Unified trigger contract
/// All sync requests MUST go through requestSync(reason)
enum SyncReason {
  authLogin,
  authLogout,
  appResume,
  appColdStart,
  networkReconnected,
  realtimeEvent,
  periodic,
  manualUserAction,
  dataChanged,
  forceFull,
}

/// Priority levels for sync batches
enum SyncPriority {
  critical,   // Expenses, accounts (affects balances)
  financial,  // Budgets, categories, semi-budgets
  settings,   // User preferences
  meta,       // Analytics, device info
}

/// Result of a complete sync cycle
class SyncOrchestratorResult {
  final int totalPushed;
  final int totalPulled;
  final int settingsSynced;
  final Duration duration;
  final List<String> errors;
  final Map<String, int> detailsByEntity;
  
  SyncOrchestratorResult({
    required this.totalPushed,
    required this.totalPulled,
    required this.settingsSynced,
    required this.duration,
    required this.errors,
    required this.detailsByEntity,
  });
  
  bool get hasErrors => errors.isNotEmpty;
  int get totalItems => totalPushed + totalPulled + settingsSynced;
  
  @override
  String toString() => 
    'SyncResult(pushed: $totalPushed, pulled: $totalPulled, settings: $settingsSynced, '
    'duration: ${duration.inMilliseconds}ms, errors: ${errors.length})';
}

/// Sync Orchestrator - Coordinates all sync operations
/// 
/// Instead of multiple independent sync triggers, this provides:
/// 1. Single entry point for all syncs
/// 2. Batched settings sync (all profile settings in 1 call)
/// 3. Prioritized sync order
/// 4. Subscription gating
/// 5. Unified error handling
class SyncOrchestrator {
  final Ref ref;
  final AppDatabase db;
  final AuthService authService;
  final DeviceInfoService deviceInfoService;
  final SharedPreferences prefs;
  final FlutterSecureStorage secureStorage; // NEW
  
  // Existing sync manager (we don't change it, just coordinate with it)
  late final SyncManager _syncManager;
  
  // Batched settings sync (NEW - consolidates profile settings)
  late final SettingsBatchSync _settingsBatchSync;

  // Batched data sync (NEW - consolidates data push)
  late final DataBatchSync _dataBatchSync;
  
  // Device gate for registration and limits
  late final DeviceGateService _deviceGate;
  
  // Per-table checkpoints
  late final SyncCheckpointService _checkpointService;
  
  
  // State machine for formal sync state management
  late final SyncStateMachine _stateMachine;
  

  
  // Atomic sync state service (NEW - replaces SharedPreferences)
  late final AtomicSyncStateService _atomicSyncState;

  // Lamport Clock for distributed state
  late final LamportClock _lamportClock;
  
  // Constants
  static const String _lastSyncKey = 'last_full_sync_timestamp';

  /// Clear all sync timestamps to force a full sync from scratch
  /// Call this when data appears to be missing
  Future<void> clearSyncTimestamps() async {
    _log('[SyncOrchestrator] Clearing ALL sync timestamps');
    await prefs.remove(_lastSyncKey);
    // Also clear entity-specific timestamps
    await prefs.remove('last_budgets_sync_iso');
    await prefs.remove('last_expenses_sync_iso');
    await prefs.remove('last_accounts_sync_iso');
    await prefs.remove('last_semi_budgets_sync_iso');
    await prefs.remove('last_categories_sync_iso');
    await prefs.remove('last_savings_goals_sync_iso');
    await prefs.remove('last_budget_members_sync_iso');
    await prefs.remove('last_family_groups_sync_iso');
    await prefs.remove('last_family_contacts_sync_iso');
    await prefs.remove('last_family_relations_sync_iso');
    _log('[SyncOrchestrator] All timestamps cleared - next sync will pull ALL data');
  }

  /// Safe logger
  void _log(String message) {
    if (kDebugMode) {
      debugPrint(message);
    }
  }

  // State
  bool _isInitialized = false;
  bool _isSyncing = false;
  DateTime? _lastFullSync;
  StreamSubscription? _authSubscription;
  Timer? _periodicTimer;
  
  // DEBOUNCE STATE - Prevents sync storms
  DateTime? _lastSyncStartedAt;
  SyncReason? _lastSyncReason;
  bool _forceFullQueued = false;
  bool _hasForceFullRun = false; // Throttle: only once per session
  bool _syncScheduled = false; // RE-ENTRANCY GUARD: prevents same-tick duplicate
  static const _debounceWindow = Duration(seconds: 3);
  static const _networkDebounceWindow = Duration(seconds: 10);
  
  // SINGLE-SHOT REASONS - These can only execute ONCE per app session
  static const _singleShotReasons = {
    SyncReason.authLogin,
    SyncReason.appColdStart,
  };
  final Set<SyncReason> _executedReasonsThisSession = {};
  
  // Subscription tier listener
  SubscriptionTier? _lastTier;
  
  SyncOrchestrator({
    required this.ref,
    required this.db,
    required this.authService,
    required this.deviceInfoService,
    required this.prefs,
    required this.secureStorage,
  }) {
    _syncManager = SyncManager(ref);
    _settingsBatchSync = SettingsBatchSync(prefs);
    _dataBatchSync = DataBatchSync(db, ref);
    _deviceGate = DeviceGateService();
    _checkpointService = SyncCheckpointService(secureStorage);
    _atomicSyncState = AtomicSyncStateService(db); // NEW: Atomic state persistence
    
    // Wire up state machine with atomic logging (Phase 2 requirement)
    _stateMachine = SyncStateMachine(
      prefs: prefs, 
      initialState: SyncEngineState.bootstrap,
      onTransitionLog: (t) => _atomicSyncState.logStateTransition(
        fromState: t.from.name,
        toState: t.to.name,
        reason: t.context ?? 'unknown',
        sessionId: t.sessionId,
      ),
    );

    // Initialize Lamport Clock
    _lamportClock = LamportClock(deviceId: ''); // Will be updated after initialize()
  }
  
  /// Initialize the orchestrator
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    // Wire up realtime settings changes
    // Delegate to named method for clarity
    _syncManager.onSettingsChanged = _handleRemoteSettingsUpdate;

    // Initialize existing sync manager (sets up realtime)
    _syncManager.initialize();
    
    // Initialize KillSwitchService
    await killSwitchService.initialize();
    
    // Listen for future auth changes
    _setupAuthListener();
    
    // Listen for subscription tier changes
    _setupSubscriptionListener();
    
    _isInitialized = true;
    _log('✅ SyncOrchestrator: Initialized');

    // Update Lamport Clock with actual device ID
    final deviceId = await deviceInfoService.getDeviceId();
    _lamportClock.updateDeviceId(deviceId);
    
    // RECOVERY: Check for interrupted sync (app was killed during sync) - USE ATOMIC SERVICE
    final interruptedState = await _atomicSyncState.getInterruptedSyncState();
    if (interruptedState != null) {
      _log('[SyncOrchestrator] Found interrupted sync from ${interruptedState.syncReason}, resuming...');
      // Mark as failed so it retries normally
      await _atomicSyncState.markSyncFailed('app_killed');
    }
    
    // CRITICAL: Check if user is ALREADY authenticated when we initialize
    // This handles first-time login and multi-device scenarios where
    // signedIn event fires BEFORE the orchestrator is initialized
    //
    // PERFORMANCE: Defer sync by 500ms to allow UI to render first
    if (authService.isAuthenticated) {
      _log('[SyncOrchestrator] User already authenticated - scheduling appColdStart sync (+500ms)');
      Future.delayed(const Duration(milliseconds: 500), () {
        unawaited(requestSync(SyncReason.appColdStart));
      });
    }
  }
  
  void _setupAuthListener() {
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      
      if (event == AuthChangeEvent.signedIn || 
          event == AuthChangeEvent.initialSession) {
        // User logged in - trigger sync via unified contract
        _log('[SyncOrchestrator] User authenticated, triggering authLogin sync');
        unawaited(requestSync(SyncReason.authLogin));
      }
    });
  }

  /// Handle settings changes detected by Realtime (from SyncManager)
  /// This ensures local state (Riverpod) stays in sync with Supabase changes
  Future<void> _handleRemoteSettingsUpdate() async {
    _log('[SyncOrchestrator] Handling remote settings update...');
    
    // 1. Pull latest settings from Cloud -> SharedPreferences
    await _settingsBatchSync.pullSettings();
    
    // 2. Refresh ALL providers (Theme, Currency, UserMode, etc.)
    _refreshLocalProviders();
    
    // 3. UserModeNotifier also has its own cloud sync logic, let's refresh it explicitly just in case
    ref.read(userModeProvider.notifier).refreshFromCloud();
  }
  
  /// Helper: Force all setting providers to re-read from SharedPreferences
  /// This bridges the gap between background sync (Prefs update) and UI state (Riverpod)
  void _refreshLocalProviders() {
    _log('[SyncOrchestrator] Refreshing local providers from prefs...');
    
    try {
      ref.read(themeModeProvider.notifier).refreshFromPrefs();
      ref.read(currencyProvider.notifier).refreshFromPrefs();
      ref.read(languageProvider.notifier).refreshFromPrefs();
      ref.read(biometricEnabledProvider.notifier).refreshFromPrefs();
      ref.read(appLockEnabledProvider.notifier).refreshFromPrefs();
      ref.read(cloudSyncEnabledProvider.notifier).refreshFromPrefs();
      // UserMode is special, handled via refreshFromCloud usually, but safe to add if we add refreshFromPrefs there too
      ref.read(userModeProvider.notifier).refreshFromPrefs();
      ref.read(accentColorProvider.notifier).refreshFromPrefs();

      // New settings
      ref.read(dateFormatProvider.notifier).refreshFromPrefs();
      ref.read(showBalanceProvider.notifier).refreshFromPrefs();
      ref.read(dataSaverProvider.notifier).refreshFromPrefs();
      ref.read(defaultBudgetViewProvider.notifier).refreshFromPrefs();
    } catch (e) {
      _log('[SyncOrchestrator] Error refreshing providers: $e');
    }
  }

  
  /// Listen for subscription tier changes
  /// If user upgrades (Free -> Pro/Pro+), trigger immediate sync
  void _setupSubscriptionListener() {
    // Initial tier
    _lastTier = SubscriptionService().currentTier;
    
    Timer.periodic(const Duration(seconds: 30), (_) async {
      final currentTier = SubscriptionService().currentTier;
      
      if (_lastTier != null && _lastTier != currentTier) {
        _log('[SyncOrchestrator] Tier changed (${_lastTier?.value} -> ${currentTier.value})');
        
        // If upgraded from Free -> Paid, trigger force push of local data to cloud
        if (_lastTier == SubscriptionTier.free && currentTier != SubscriptionTier.free) {
           _log('[SyncOrchestrator] Upgrade detected! Triggering manual force push.');
           unawaited(forcePushLocalToCloud());
        }
        
        // If upgraded from Pro -> Pro Plus (more OCR features)
        if (_lastTier == SubscriptionTier.pro && currentTier == SubscriptionTier.proPlus) {
           _log('[SyncOrchestrator] Pro Plus upgrade! Syncing settings.');
           await syncSettingsOnly();
        }

        // If downgraded to Free, stop realtime sync
        if (_lastTier != SubscriptionTier.free && currentTier == SubscriptionTier.free) {
           _log('[SyncOrchestrator] Downgrade detected! Stopping sync operations.');
           stopSync();
        }
        
        _lastTier = currentTier;
      }
    });
  }
  
  /// Start periodic background sync
  void startPeriodicSync({Duration interval = const Duration(minutes: 5)}) {
    _periodicTimer?.cancel();
    _periodicTimer = Timer.periodic(interval, (_) {
      _log('[SyncOrchestrator] Periodic sync triggered');
      unawaited(requestSync(SyncReason.periodic));
    });
    _log('[SyncOrchestrator] Periodic sync started (${interval.inMinutes} min interval)');
  }
  
  /// Stop periodic sync
  void stopPeriodicSync() {
    _periodicTimer?.cancel();
    _periodicTimer = null;
  }
  /// ============================================================
  /// UNIFIED SYNC TRIGGER CONTRACT
  /// ============================================================
  /// 
  /// All components MUST use requestSync() instead of performFullSync()
  /// This prevents sync storms by applying debouncing and priority rules.
  
  /// Request a sync with a specific reason
  /// This is the ONLY entry point for triggering syncs from external components
  Future<SyncOrchestratorResult> requestSync(SyncReason reason) async {
    _log('[SyncOrchestrator] requestSync(reason=${reason.name})');
    
    // RE-ENTRANCY GUARD: Prevents same event-loop-tick duplicates
    // This MUST be checked before any await to prevent race window
    if (_isSyncing || _syncScheduled) {
      // Exception: forceFull queues for after current sync
      if (reason == SyncReason.forceFull) {
        _forceFullQueued = true;
        _log('[SyncOrchestrator] Force-full queued for after current sync');
      }
      _log('[SyncOrchestrator] Skipped (already syncing or scheduled, reason=${reason.name})');
      return SyncOrchestratorResult(
        totalPushed: 0, totalPulled: 0, settingsSynced: 0,
        duration: Duration.zero,
        errors: ['Skipped: already syncing or scheduled'],
        detailsByEntity: {},
      );
    }
    
    // Mark as scheduled IMMEDIATELY (before any await)
    _syncScheduled = true;
    
    // SINGLE-SHOT GUARD: Prevent duplicate execution of one-time reasons
    if (_singleShotReasons.contains(reason) && 
        _executedReasonsThisSession.contains(reason)) {
      _syncScheduled = false;
      _log('[SyncOrchestrator] Ignored duplicate reason=${reason.name} (already executed this session)');
      return SyncOrchestratorResult(
        totalPushed: 0, totalPulled: 0, settingsSynced: 0,
        duration: Duration.zero,
        errors: ['Ignored: already executed this session'],
        detailsByEntity: {},
      );
    }
    
    // HARD BLOCK: Not authenticated
    if (!authService.isAuthenticated) {
      _syncScheduled = false;
      _log('[SyncOrchestrator] Skipped (not authenticated)');
      return SyncOrchestratorResult(
        totalPushed: 0, totalPulled: 0, settingsSynced: 0,
        duration: Duration.zero,
        errors: ['Not authenticated'],
        detailsByEntity: {},
      );
    }
    
    // DEBOUNCE: Check time since last sync
    if (_lastSyncStartedAt != null) {
      final elapsed = DateTime.now().difference(_lastSyncStartedAt!);
      final debounce = reason == SyncReason.networkReconnected 
          ? _networkDebounceWindow 
          : _debounceWindow;
      
      if (elapsed < debounce && reason != SyncReason.forceFull) {
        _log('[SyncOrchestrator] Debounced (${elapsed.inMilliseconds}ms < ${debounce.inMilliseconds}ms, reason=${reason.name})');
        return SyncOrchestratorResult(
          totalPushed: 0, totalPulled: 0, settingsSynced: 0,
          duration: Duration.zero,
          errors: ['Debounced'],
          detailsByEntity: {},
        );
      }
    }
    
    // EXECUTE SYNC
    _lastSyncReason = reason;
    
    // Track single-shot reason execution
    if (_singleShotReasons.contains(reason)) {
      _executedReasonsThisSession.add(reason);
      _log('[SyncOrchestrator] Marked ${reason.name} as executed (single-shot)');
    }
    
    // FORCE-FULL THROTTLE: Only allow once per session
    bool isForce = reason == SyncReason.forceFull || _forceFullQueued;
    if (isForce) {
      if (_hasForceFullRun) {
        _log('[SyncOrchestrator] Force-full already ran this session - downgrading to regular sync');
        isForce = false;
      } else {
        _hasForceFullRun = true;
        _log('[SyncOrchestrator] Force-full sync activated (first time this session)');
      }
    }
    _forceFullQueued = false;
    
    return performFullSync(
      priority: _priorityForReason(reason),
      forceFullSync: isForce,
    );
  }
  
  /// Map SyncReason to SyncPriority
  SyncPriority _priorityForReason(SyncReason reason) {
    switch (reason) {
      case SyncReason.forceFull:
      case SyncReason.authLogin:
      case SyncReason.appColdStart:
      case SyncReason.dataChanged:
        return SyncPriority.critical;
      case SyncReason.networkReconnected:
      case SyncReason.appResume:
        return SyncPriority.financial;
      case SyncReason.realtimeEvent:
      case SyncReason.periodic:
      case SyncReason.manualUserAction:
        return SyncPriority.settings;
      case SyncReason.authLogout:
        return SyncPriority.meta;
    }
  }
  
  /// Check if user can sync (subscription gating)
  bool get _canSync {
    // Admin bypass - always allow sync for admin users
    if (authService.isAdmin) {
      return true;
    }
    
    // Check both tier AND family membership (Free users in Pro+ family can sync)
    final service = SubscriptionService();
    return service.hasCloudAccess;
  }
  
  /// Perform a complete sync cycle
  /// 
  /// Order:
  /// 1. Settings sync (batched - all in 1 call)
  /// 2. Data sync (uses existing SyncManager)
  Future<SyncOrchestratorResult> performFullSync({
    SyncPriority priority = SyncPriority.critical,
    bool forceFullSync = false,
  }) async {
    if (_isSyncing) {
      _log(' SyncOrchestrator: Already syncing, skipping ...');
      return SyncOrchestratorResult(
        totalPushed: 0,
        totalPulled: 0,
        settingsSynced: 0,
        duration: Duration.zero,
        errors: ['Already syncing ...'],
        detailsByEntity: {},
      );
    }
    
    // CRITICAL: Ensure subscription tier is synced from Supabase before checking
    // This fixes the race condition on fresh install where tier is 'free' before sync
    await SubscriptionService().sync();
    
    // P0 OPERATIONAL: Check Kill Switch
    if (!killSwitchService.isSyncAllowed) {
      _log('[SyncOrchestrator] CRITICAL: Sync blocked by remote Kill Switch');
      return SyncOrchestratorResult(
        totalPushed: 0,
        totalPulled: 0,
        settingsSynced: 0,
        duration: Duration.zero,
        errors: ['Sync disabled by administrator'],
        detailsByEntity: {},
      );
    }
    
    if (!_canSync) {
      _log('SyncOrchestrator: Free tier - local only');
      return SyncOrchestratorResult(
        totalPushed: 0,
        totalPulled: 0,
        settingsSynced: 0,
        duration: Duration.zero,
        errors: [],
        detailsByEntity: {},
      );
    }
    
    _isSyncing = true;
    _lastSyncStartedAt = DateTime.now(); // Track for debounce
    final sessionId = const Uuid().v4(); // Unique session ID for synchronization tracking
    final stopwatch = Stopwatch()..start();
    final errors = <String>[];
    final details = <String, int>{};
    int settingsSynced = 0;
    
    // STATE: Transition to prechecks
    await _stateMachine.transition(SyncEngineState.prechecks, context: 'sync start', sessionId: sessionId);
    
    // PERSISTENCE: Mark sync started for app kill recovery (ATOMIC)
    await _atomicSyncState.markSyncStarted(
      _lastSyncReason?.name ?? 'direct',
      [], // Pending operations will be tracked per-entity
    );
    
    try {
      final reasonStr = _lastSyncReason?.name ?? 'direct';
      _log('[SyncOrchestrator] Starting ${priority.name} sync (reason=$reasonStr)');
      
      // ========================================
      // STEP 0: Device Registration Gate
      // STATE: loadWork phase
      // ========================================
      await _stateMachine.transition(SyncEngineState.loadWork, context: 'device gate', sessionId: sessionId);
      final gateResult = await _deviceGate.registerAndCheck();
      if (!gateResult.allowed) {
        _log('[SyncOrchestrator] Device gate blocked: ${gateResult.reason}');
        errors.add('Device limit exceeded: ${gateResult.reason}');
        return SyncOrchestratorResult(
          totalPushed: 0,
          totalPulled: 0,
          settingsSynced: 0,
          duration: stopwatch.elapsed,
          errors: errors,
          detailsByEntity: {},
        );
      }
      _log('[SyncOrchestrator] Device registered (${gateResult.currentDeviceCount}/${gateResult.maxDevices})');
      
      // ========================================
      // STEP 1: Batched Settings Sync
      // ========================================
      // This replaces individual UserMode, Theme, Currency syncs
      // with a SINGLE API call
      if (priority.index <= SyncPriority.settings.index) {
        try {
          final settingsResult = await _settingsBatchSync.sync();
          settingsSynced = settingsResult.total;
          details['settings'] = settingsSynced;
          _log(' SyncOrchestrator: Settings synced (${settingsResult.pulled} pulled, ${settingsResult.pushed} pushed)');
          
          // REFRESH LOCAL PROVIDERS (Important: settingsBatchSync updates PREFS but providers don't auto-watch)
          if (settingsResult.pulled > 0) {
             _refreshLocalProviders();
          }
        } catch (e) {
          errors.add('Settings sync failed: $e');
          _log(' SyncOrchestrator: Settings sync error: $e');
        }
      }
      
      // ========================================
      // STEP 2: Data Sync (PULL-BEFORE-PUSH)
      // ========================================
      // Finance-grade: Always pull first to prevent overwriting newer server data
      
      int pushedCount = 0;
      int pulledCount = 0;
      
      try {
        // --- PHASE 1: PULL FIRST (prevents overwriting newer data) ---
        final lastSyncStr = prefs.getString(_lastSyncKey);
        final lastSync = forceFullSync || lastSyncStr == null 
            ? null 
            : DateTime.tryParse(lastSyncStr);
        
        if (forceFullSync) {
          _log(' SyncOrchestrator: FORCE FULL SYNC - pulling ALL data from server');
          await _checkpointService.clearAllCheckpoints();
        } else if (lastSync == null) {
          _log(' SyncOrchestrator: First sync ever - pulling ALL data from server');
        } else {
          _log(' SyncOrchestrator: Incremental pull - changes since $lastSync');
        }
            
        await _dataBatchSync.pullAll(lastSync, sessionId: sessionId);
        
        // Update global checkpoint
        await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());
        
        // --- PHASE 2: PUSH AFTER PULL (safe now) ---
        // Uses 'batch_sync' RPC to push all dirty data in one transaction
        final batchResult = await _dataBatchSync.pushAll(sessionId: sessionId);
        pushedCount = (batchResult['expenses'] ?? 0) + (batchResult['budgets'] ?? 0); 
        
        _log(' SyncOrchestrator: Data sync completed (Pull first, then Push: $pushedCount records)');
      } catch (e) {
        errors.add('Data sync failed: $e');
        _log(' SyncOrchestrator: Data sync error: $e');
      }
      
      stopwatch.stop();
      _lastFullSync = DateTime.now();
      
      final result = SyncOrchestratorResult(
        totalPushed: pushedCount,
        totalPulled: pulledCount,
        settingsSynced: settingsSynced,
        duration: stopwatch.elapsed,
        errors: errors,
        detailsByEntity: details,
      );
      
      _log('[SyncOrchestrator] Completed in ${stopwatch.elapsedMilliseconds}ms');
      
      // Reset sync flags FIRST (before promotion check)
      _isSyncing = false;
      _syncScheduled = false;
      
      // PROMOTION HOOK: Sync complete → now promote to realtime if eligible
      // This is called AFTER _is Syncing is reset so the guard passes
      _promoteToRealtime(reason: 'sync_complete');
      
      // STATE: Transition to finalize then idle
      await _stateMachine.transition(SyncEngineState.finalize, context: 'complete', sessionId: sessionId);
      await _stateMachine.transition(SyncEngineState.idle, context: 'done', sessionId: sessionId);
      
      // PERSISTENCE: Mark sync completed successfully (ATOMIC)
      await _atomicSyncState.markSyncCompleted();
      
      return result;
      
    } catch (e) {
      // CLASSIFY ERROR using ErrorTaxonomy
      final category = e is Exception 
        ? ErrorTaxonomy.classify(e)
        : ErrorCategory.unknown;
      final policy = ErrorTaxonomy.getRetryPolicy(category);
      
      _log('[SyncOrchestrator] Error during sync (category=$category, shouldRetry=${policy.shouldRetry}): $e');
      
      // STATE: Transition to error state
      await _stateMachine.transition(SyncEngineState.errorFatal, context: 'sync error: $category', sessionId: sessionId);
      await _stateMachine.transition(SyncEngineState.idle, context: 'error recovery', sessionId: sessionId);
      
      // PERSISTENCE: Mark sync failed for retry on next launch (ATOMIC)
      await _atomicSyncState.markSyncFailed('$category: $e');
      
      // ROLLBACK: Revert local dirty state to prevent data corruption/ghosting if error is fatal
      if (category == ErrorCategory.database || category == ErrorCategory.unknown) {
        _log('[SyncOrchestrator] CRITICAL error detected, orchestrating ROLLBACK for session: $sessionId');
        await db.rollbackSyncSession(sessionId);
      }
      
      rethrow;
    } finally {
      // Ensure flags are always reset even on error
      _isSyncing = false;
      _syncScheduled = false;
    }
  }
  
  /// Sync only settings (quick sync for preference changes)
  Future<SettingsSyncResult> syncSettingsOnly() async {
    if (!_canSync) {
      return SettingsSyncResult(pulled: 0, pushed: 0);
    }
    
    return await _settingsBatchSync.sync();
  }
  
  /// Push current local settings to cloud
  Future<int> pushSettings() async {
    if (!_canSync) return 0;
    return await _settingsBatchSync.pushSettings();
  }
  
  /// Pull settings from cloud
  Future<int> pullSettings() async {
    if (!_canSync) return 0;
    return await _settingsBatchSync.pullSettings();
  }

  /// Manually force push all local data to cloud
  /// Used for subscription upgrades or troubleshooting
  Future<SyncOrchestratorResult> forcePushLocalToCloud() async {
    _log('[SyncOrchestrator] Starting manual FORCE PUSH of all local data');
    
    // 1. Reset checkpoints to ensure we pull everything fresh too (optional but safer)
    await _checkpointService.clearAllCheckpoints();
    await prefs.remove(_lastSyncKey);

    // 2. Mark all local records as dirty in the database
    await db.markAllEntitiesAsDirty();

    // 3. Request a full sync with forceFull=true
    return requestSync(SyncReason.forceFull);
  }

  /// Stop all sync operations (realtime and timers)
  /// Used on logout or subscription expiration
  void stopSync() {
    _log('[SyncOrchestrator] Stopping all sync operations');
    stopPeriodicSync();
    _syncManager.pauseRealtime(); // Disconnects or pauses listeners
    _log('[SyncOrchestrator] Sync stopped');
  }
  
  // ============================================================
  // REALTIME PROMOTION HOOK
  // ============================================================
  // 
  // This is the explicit transition from "Sync" to "Steady-State Realtime"
  // Realtime should only attach when: AUTHENTICATED + PREMIUM + IDLE
  
  bool _pendingRealtimeAttach = false;
  
  /// Promote to realtime listeners after sync completes
  /// This is called from: sync completion, tier upgrade, app resume, auth sign-in
  void _promoteToRealtime({required String reason}) {
    // GUARD 1: Must be authenticated
    if (!authService.isAuthenticated) {
      _log('[Realtime] Skipping promotion - not authenticated ($reason)');
      return;
    }
    
    // GUARD 2: Must be premium (Pro or Pro+)
    if (!_canSync) {
      _log('[Realtime] Skipping promotion - premium feature ($reason)');
      return;
    }
    
    // GUARD 3: Must not be syncing (shouldn't happen since we call from completion)
    if (_isSyncing) {
      _log('[Realtime] Delaying promotion - sync in progress ($reason)');
      _pendingRealtimeAttach = true;
      return;
    }
    
    // GUARD 4: Check if already connected
    final currentStatus = ref.read(realtimeStatusProvider);
    if (currentStatus == RealtimeConnectionStatus.connected) {
      _log('[Realtime] Already connected ($reason)');
      return;
    }
    
    if (currentStatus == RealtimeConnectionStatus.connecting) {
      _log('[Realtime] Already connecting ($reason)');
      return;
    }
    
    // PROMOTE: Attach realtime listeners via SyncManager
    _log('[Realtime] Promoting to realtime ($reason)');
    _syncManager.setupRealtime();
    _pendingRealtimeAttach = false;
  }
  
  /// Public method for external callers (tier upgrade, app resume)
  void promoteToRealtime({String reason = 'unknown'}) {
    _promoteToRealtime(reason: reason);
  }
  
  /// Pause incoming realtime sync (e.g. for sensitive bulk operations)
  void pauseRealtime() {
    _log('[SyncOrchestrator] Pausing realtime sync...');
    _syncManager.pauseRealtime();
  }
  
  /// Resume incoming realtime sync
  void resumeRealtime() {
    _log('[SyncOrchestrator] Resuming realtime sync...');
    _syncManager.resumeRealtime();
  }
  
  /// Dispose resources
  void dispose() {
    _authSubscription?.cancel();
    _periodicTimer?.cancel();
    _syncManager.dispose();
    _log('[SyncOrchestrator] Disposed');
  }
}
