import 'dart:async';
import 'package:cashpilot/data/drift/app_database.dart' show AppDatabase;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../core/providers/app_providers.dart';
import '../../../features/sync/services/outbox_service.dart';
import '../../../services/sync_engine.dart';
import '../../../features/sync/sync_manager.dart' show RealtimeConnectionStatus, realtimeStatusProvider;

/// Provider for connectivity status
final connectivityStreamProvider = StreamProvider<ConnectivityResult>((ref) {
  return Connectivity().onConnectivityChanged.map((results) {
    return results.isEmpty ? ConnectivityResult.none : results.first;
  });
});

/// Provider for pending sync count
final pendingSyncCountProvider = FutureProvider<int>((ref) async {
  final db = ref.watch(databaseProvider);
  // Watch sync status to auto-refresh count after sync
  ref.watch(syncStatusProvider);
  return OutboxService(db).getPendingCount();
});

/// Sync Status Indicator - Shows pending offline operations
class SyncStatusIndicator extends ConsumerWidget {
  const SyncStatusIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(pendingSyncCountProvider);

    return pendingAsync.when(
      data: (count) {
        if (count == 0) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_upload_outlined,
                size: 14,
                color: Colors.orange,
              ),
              const SizedBox(width: 6),
              Text(
                '$count',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.orange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}



/// Sync Conflict Badge - Shows conflict count
class SyncConflictBadge extends ConsumerWidget {
  const SyncConflictBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(databaseProvider);

    // TODO: move this to a proper provider similar to pendingAsync
    return FutureBuilder<int>(
      future: _getConflictCount(db),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == 0) {
          return const SizedBox.shrink();
        }

        final count = snapshot.data!;

        return GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/sync/conflicts'),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  size: 14,
                  color: Colors.red,
                ),
                const SizedBox(width: 6),
                Text(
                  '$count',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<int> _getConflictCount(AppDatabase db) async {
    final result = await (db.select(db.conflicts)
      ..where((c) => c.status.equals('open')))
      .get();
    return result.length;
  }
}



/// Realtime & Sync Status Indicator (Combined)
class RealtimeStatusIndicator extends ConsumerStatefulWidget {
  const RealtimeStatusIndicator({super.key});

  @override
  ConsumerState<RealtimeStatusIndicator> createState() => _RealtimeStatusIndicatorState();
}

class _RealtimeStatusIndicatorState extends ConsumerState<RealtimeStatusIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _syncAnimationController;
  bool _showSuccessIcon = false;
  Timer? _successTimer;

  @override
  void initState() {
    super.initState();
    _syncAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
  }

  @override
  void dispose() {
    _syncAnimationController.dispose();
    _successTimer?.cancel();
    super.dispose();
  }

  void _handleSyncStatus(SyncStatus status) {
    if (status == SyncStatus.syncing) {
      if (!_syncAnimationController.isAnimating) {
        _syncAnimationController.repeat();
      }
      _showSuccessIcon = false;
    } else if (status == SyncStatus.success) {
      if (_syncAnimationController.isAnimating) {
        _syncAnimationController.stop();
        setState(() {
          _showSuccessIcon = true;
        });
        _successTimer?.cancel();
        _successTimer = Timer(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _showSuccessIcon = false;
            });
          }
        });
      }
    } else {
      _syncAnimationController.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(realtimeStatusProvider);
    final syncStatus = ref.watch(syncStatusProvider).status;
    
    // Listen to sync status changes to trigger animations
    ref.listen(syncStatusProvider, (previous, next) {
      _handleSyncStatus(next.status);
    });

    Color color;
    String label;
    bool isError = false;

    switch (status) {
      case RealtimeConnectionStatus.connected:
        color = const Color(0xFF10B981); // Emerald 500
        label = 'Realtime';
        break;
      case RealtimeConnectionStatus.connecting:
        color = Colors.amber;
        label = 'Connecting';
        break;
      case RealtimeConnectionStatus.error:
        color = Colors.red;
        label = 'Offline';
        isError = true;
        break;
      case RealtimeConnectionStatus.disconnected:
        // If simply disconnected, show nothing unless we are syncing
        if (syncStatus != SyncStatus.syncing && !_showSuccessIcon) {
          return const SizedBox.shrink();
        }
        color = Colors.blueGrey;
        label = 'Local Only';
        break;
    }

    final isSyncing = syncStatus == SyncStatus.syncing;

    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color.withValues(alpha: 0.15), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isSyncing)
            RotationTransition(
              turns: _syncAnimationController,
              child: Icon(Icons.sync, size: 8, color: color),
            )
          else if (_showSuccessIcon && !isError)
            Icon(Icons.check_circle_rounded, size: 8, color: color)
          else
            Container(
              width: 3.5,
              height: 3.5,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 8,
              color: color,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// Security Badge - Simplified icon-only pill
class SecurityStatusBadge extends StatelessWidget {
  const SecurityStatusBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.blueGrey.withValues(alpha: 0.05),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.blueGrey.withValues(alpha: 0.1), width: 0.5),
      ),
      child: const Icon(
        Icons.lock_outline_rounded,
        size: 8,
        color: Colors.blueGrey,
      ),
    );
  }
}



/// Sync Status Widget - Combines all sync indicators
class SyncStatusWidget extends ConsumerWidget {
  const SyncStatusWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Padding(
      padding: EdgeInsets.zero,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SecurityStatusBadge(),
          RealtimeStatusIndicator(),
          SyncStatusIndicator(), // Pending count
          SyncConflictBadge(),
        ],
      ),
    );
  }
}

