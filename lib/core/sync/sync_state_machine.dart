import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'sync_states.dart';

/// Exception thrown when an invalid state transition is attempted
class InvalidStateTransitionException implements Exception {
  final SyncEngineState from;
  final SyncEngineState to;
  final String reason;

  InvalidStateTransitionException(this.from, this.to, this.reason);

  @override
  String toString() => 'Invalid transition from $from to $to: $reason';
}

/// Logs state transitions for debugging and auditing
class StateTransitionLogger {
  final List<StateTransition> _history = [];
  static const int maxHistorySize = 100;

  void logTransition(StateTransition transition) {
    _history.add(transition);
    
    // Keep history bounded
    if (_history.length > maxHistorySize) {
      _history.removeAt(0);
    }
    
    if (kDebugMode) {
      debugPrint('🔄 [SyncStateMachine] ${transition.from} → ${transition.to}${transition.context != null ? " (${transition.context})" : ""} [${transition.sessionId ?? "no-session"}]');
    }
  }

  List<StateTransition> get history => List.unmodifiable(_history);
  
  void clear() => _history.clear();
}

/// Represents a single state transition in history
class StateTransition {
  final SyncEngineState from;
  final SyncEngineState to;
  final DateTime timestamp;
  final String? context;
  final String? sessionId;

  StateTransition({
    required this.from,
    required this.to,
    required this.timestamp,
    this.context,
    this.sessionId,
  });
}

/// Formal sync state machine with validated transitions
class SyncStateMachine {
  SyncEngineState _currentState;
  final StateTransitionLogger _logger;
  final SharedPreferences _prefs;
  
  // Callback for external logging (e.g. to DB)
  final Future<void> Function(StateTransition transition)? onTransitionLog;
  
  // Stream controller for state changes
  final _stateController = StreamController<SyncEngineState>.broadcast();
  
  SyncStateMachine({
    required SharedPreferences prefs,
    this.onTransitionLog,
    SyncEngineState initialState = SyncEngineState.bootstrap,
  })  : _prefs = prefs,
        _currentState = initialState,
        _logger = StateTransitionLogger() {
    _loadPersistedState();
  }

  /// Current state (read-only)
  SyncEngineState get currentState => _currentState;
  
  /// Stream of state changes
  Stream<SyncEngineState> get stateChanges => _stateController.stream;
  
  /// Transition history
  List<StateTransition> get history => _logger.history;

  /// Attempt to transition to a new state
  /// 
  /// Throws [InvalidStateTransitionException] if transition is not allowed
  Future<void> transition(SyncEngineState to, {String? context, String? sessionId}) async {
    if (!_isValidTransition(_currentState, to)) {
      throw InvalidStateTransitionException(
        _currentState,
        to,
        _getTransitionError(_currentState, to),
      );
    }

    final from = _currentState;
    final transitionRecord = StateTransition(
      from: from,
      to: to,
      timestamp: DateTime.now(),
      context: context,
      sessionId: sessionId,
    );
    
    // 1. Log to valid history
    _logger.logTransition(transitionRecord);
    
    // 2. Perform state change
    _currentState = to;
    _stateController.add(to);
    
    // 3. Persist simple state
    await _persistState();
    
    // 4. External logging (DB)
    if (onTransitionLog != null) {
      try {
        await onTransitionLog!(transitionRecord);
      } catch (e) {
        if (kDebugMode) debugPrint('[SyncStateMachine] External log error: $e');
      }
    }
  }

  /// Check if a transition is valid
  bool canTransitionTo(SyncEngineState to) {
    return _isValidTransition(_currentState, to);
  }

  /// Validate state transition based on state machine rules
  bool _isValidTransition(SyncEngineState from, SyncEngineState to) {
    // Always allow staying in same state
    if (from == to) return true;

    // Define valid transitions
    return switch (from) {
      // Bootstrap can go anywhere initially (app starting up)
      SyncEngineState.bootstrap => [
        SyncEngineState.signedOut,
        SyncEngineState.idle,
        SyncEngineState.paused,
        SyncEngineState.ready,      // Direct to ready for immediate sync
        SyncEngineState.prechecks,  // Or prechecks for full flow
      ].contains(to),

      // Signed out can only sign in or pause
      SyncEngineState.signedOut => [
        SyncEngineState.idle,
        SyncEngineState.bootstrap,
      ].contains(to),

      // Idle can start sync or sign out
      SyncEngineState.idle => [
        SyncEngineState.ready,
        SyncEngineState.prechecks,  // Allow direct to prechecks for immediate sync
        SyncEngineState.paused,
        SyncEngineState.signedOut,
        SyncEngineState.waitNetwork,
      ].contains(to),

      // Paused can resume or sign out
      SyncEngineState.paused => [
        SyncEngineState.idle,
        SyncEngineState.signedOut,
      ].contains(to),

      // Wait network can go to ready or idle
      SyncEngineState.waitNetwork => [
        SyncEngineState.ready,
        SyncEngineState.idle,
        SyncEngineState.signedOut,
      ].contains(to),

      // Ready starts prechecks
      SyncEngineState.ready => [
        SyncEngineState.prechecks,
        SyncEngineState.idle,
      ].contains(to),

      // Prechecks can refresh auth, load work, or fail
      SyncEngineState.prechecks => [
        SyncEngineState.authRefresh,
        SyncEngineState.loadWork,
        SyncEngineState.errorAuth,
        SyncEngineState.idle,
      ].contains(to),

      // Auth refresh goes to load work or error
      SyncEngineState.authRefresh => [
        SyncEngineState.loadWork,
        SyncEngineState.errorAuth,
      ].contains(to),

      // Load work goes to push, pull, finalize (no work), or error
      SyncEngineState.loadWork => [
        SyncEngineState.pushOutbox,
        SyncEngineState.pullRemote,
        SyncEngineState.idle,
        SyncEngineState.finalize,   // When nothing to sync
        SyncEngineState.errorFatal, // When error during load
        SyncEngineState.prechecks,  // Retry/loop back
      ].contains(to),

      // Push outbox goes to push batch or backoff
      SyncEngineState.pushOutbox => [
        SyncEngineState.pushBatch,
        SyncEngineState.pullRemote,
        SyncEngineState.backoff,
        SyncEngineState.errorFatal,
      ].contains(to),

      // Push batch can continue pushing, backoff, or go to pull
      SyncEngineState.pushBatch => [
        SyncEngineState.pushBatch, // Continue with next batch
        SyncEngineState.pullRemote,
        SyncEngineState.backoff,
        SyncEngineState.conflictsPending,
        SyncEngineState.errorFatal,
      ].contains(to),

      // Backoff goes back to retry
      SyncEngineState.backoff => [
        SyncEngineState.pushBatch,
        SyncEngineState.pullRemote,
        SyncEngineState.idle,
        SyncEngineState.errorFatal,
      ].contains(to),

      // Pull remote goes to apply or error
      SyncEngineState.pullRemote => [
        SyncEngineState.applyRemote,
        SyncEngineState.backoff,
        SyncEngineState.errorFatal,
      ].contains(to),

      // Apply remote can find conflicts or finalize
      SyncEngineState.applyRemote => [
        SyncEngineState.conflictsPending,
        SyncEngineState.finalize,
        SyncEngineState.errorFatal,
      ].contains(to),

      // Conflicts need resolution
      SyncEngineState.conflictsPending => [
        SyncEngineState.needUser, // Expert mode
        SyncEngineState.finalize, // Auto-resolved
        SyncEngineState.errorFatal,
      ].contains(to),

      // Need user waits for UI
      SyncEngineState.needUser => [
        SyncEngineState.finalize,
        SyncEngineState.idle,
      ].contains(to),

      // Finalize always goes to idle
      SyncEngineState.finalize => [
        SyncEngineState.idle,
      ].contains(to),

      // Error states can retry or go idle
      SyncEngineState.errorAuth => [
        SyncEngineState.idle,
        SyncEngineState.signedOut,
      ].contains(to),

      SyncEngineState.errorFatal => [
        SyncEngineState.idle,
        SyncEngineState.signedOut,
      ].contains(to),
    };
  }

  /// Get human-readable error message for invalid transition
  String _getTransitionError(SyncEngineState from, SyncEngineState to) {
    return switch ((from, to)) {
      (SyncEngineState.signedOut, _) when to != SyncEngineState.idle && to != SyncEngineState.bootstrap =>
        'Cannot sync while signed out',
      
      (_, SyncEngineState.signedOut) when from != SyncEngineState.idle && from != SyncEngineState.errorAuth =>
        'Must be idle before signing out',
      
      (SyncEngineState.pushBatch, SyncEngineState.idle) =>
        'Cannot go idle during active batch push',
      
      (SyncEngineState.pullRemote, SyncEngineState.idle) =>
        'Cannot go idle during remote pull',
      
      _ => 'Invalid state transition',
    };
  }

  /// Persist current state to survive app restarts
  Future<void> _persistState() async {
    await _prefs.setString('sync_state_machine_current', _currentState.name);
  }

  /// Load persisted state on initialization
  void _loadPersistedState() {
    final persisted = _prefs.getString('sync_state_machine_current');
    if (persisted != null) {
      try {
        _currentState = SyncEngineState.values.firstWhere(
          (s) => s.name == persisted,
          orElse: () => SyncEngineState.bootstrap,
        );
        
        if (kDebugMode) {
          debugPrint('📂 [SyncStateMachine] Loaded persisted state: $_currentState');
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('⚠️ [SyncStateMachine] Failed to load persisted state: $e');
        }
      }
    }
  }

  /// Clear transition history
  void clearHistory() {
    _logger.clear();
  }

  /// Dispose resources
  void dispose() {
    _stateController.close();
  }
}
