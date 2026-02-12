/// Network Manager
/// Handles connectivity changes and triggers sync/reconnect logic
library;

import 'dart:async';
import 'package:cashpilot/features/sync/sync_providers.dart' show syncOrchestratorProvider;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cashpilot/features/sync/orchestrator/sync_orchestrator.dart';

/// Provider for NetworkManager
final networkManagerProvider = Provider<NetworkManager>((ref) {
  return NetworkManager(ref);
});

class NetworkManager {
  final Ref ref;
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  
  // Debounce rapid changes (e.g., wifi -> mobile -> wifi)
  Timer? _debounceTimer;

  NetworkManager(this.ref);

  /// Synchronous check for online status (best effort)
  bool get isOnline {
    // If we haven't received a status yet, assume true (or check synchronous cache if available)
    // ConnectivityPlus API is async, but we can track the last known state.
    return _lastKnownState != ConnectivityResult.none;
  }
  
  ConnectivityResult _lastKnownState = ConnectivityResult.other; // Assume connected initially


  /// Initialize network listener
  void initialize() {
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      _handleConnectivityChange(results);
    });
    
    // Check initial state
    _connectivity.checkConnectivity().then(_handleConnectivityChange);
  }

  /// Handle connectivity updates
  void _handleConnectivityChange(List<ConnectivityResult> results) {
    final result = results.isEmpty ? ConnectivityResult.none : results.first;
    _lastKnownState = result;
    
    if (result == ConnectivityResult.none) {
      // Disconnected
      _debouncedLog('🔌 Network: Disconnected');
      // Potentially pause realtime or sync queues
      // ref.read(syncManagerProvider).pauseRealtime(); // Optional
    } else {
      // Connected (Mobile, Wifi, Ethernet, etc.)
      _debouncedLog('🌐 Network: Connected (${result.name})');
      
      // Trigger reconnection logic
      _triggerReconnect();
    }
  }

  void _triggerReconnect() {
    // Debounce to prevent multiple triggers during network switching
    if (_debounceTimer?.isActive ?? false) return;
    
    _debounceTimer = Timer(const Duration(seconds: 2), () {
      _log('[NetworkManager] Network stable - Triggering Sync');
      
      // Use the unified trigger with networkReconnected reason
      ref.read(syncOrchestratorProvider).requestSync(SyncReason.networkReconnected);
    });
  }

  void dispose() {
    _subscription?.cancel();
    _debounceTimer?.cancel();
  }
  
  /// Safe logger
  void _log(String message) {
    if (kDebugMode) {
      debugPrint(message);
    }
  }
  
  void _debouncedLog(String message) {
     if (kDebugMode) {
      debugPrint(message);
    }
  }
}
