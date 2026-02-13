import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/sync/sync_states.dart';
import '../sync_providers.dart';

/// Current sync engine state
final syncEngineStateProvider = StreamProvider<SyncEngineState>((ref) {
  final machine = ref.watch(syncStateMachineProvider);
  return machine.stateChanges;
});

/// Progress percent (0-100) or null if not applicable
final syncProgressProvider = StateProvider<double?>((ref) => null);

/// Last sync error message
final syncErrorProvider = StateProvider<String?>((ref) => null);

/// Is sync currently active?
final isSyncActiveProvider = Provider<bool>((ref) {
  final state = ref.watch(syncEngineStateProvider).value ?? SyncEngineState.idle;
  return state != SyncEngineState.idle && 
         state != SyncEngineState.signedOut && 
         state != SyncEngineState.paused &&
         state != SyncEngineState.bootstrap;
});

/// Combined sync status for UI
class SyncStatus {
  final SyncEngineState state;
  final String? error;
  final double? progress;
  final bool isActive;

  SyncStatus({
    required this.state,
    this.error,
    this.progress,
    required this.isActive,
  });
}

final globalSyncStatusProvider = Provider<SyncStatus>((ref) {
  final state = ref.watch(syncEngineStateProvider).value ?? SyncEngineState.idle;
  final error = ref.watch(syncErrorProvider);
  final progress = ref.watch(syncProgressProvider);
  final isActive = ref.watch(isSyncActiveProvider);

  return SyncStatus(
    state: state,
    error: error,
    progress: progress,
    isActive: isActive,
  );
});
