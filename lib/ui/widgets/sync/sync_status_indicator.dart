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

/// Offline Mode Banner - Full-width banner for offline state
class OfflineModeBanner extends ConsumerWidget {
  const OfflineModeBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivity = ref.watch(connectivityStreamProvider);
    
    return connectivity.when(
      data: (status) {
        if (status != ConnectivityResult.none) return const SizedBox.shrink();
        
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.amber.shade100,
          child: Row(
            children: [
              Icon(Icons.wifi_off_rounded, color: Colors.amber.shade900, size: 16),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Working offline',
                  style: TextStyle(
                    color: Colors.amber.shade900,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(), // Don't show while loading
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

/// Sync Progress Indicator - Shows sync in progress
class SyncProgressIndicator extends StatefulWidget {
  final bool isSyncing;

  const SyncProgressIndicator({
    super.key,
    required this.isSyncing,
  });

  @override
  State<SyncProgressIndicator> createState() => _SyncProgressIndicatorState();
}

class _SyncProgressIndicatorState extends State<SyncProgressIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isSyncing) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          RotationTransition(
            turns: _controller,
            child: const Icon(
              Icons.sync,
              size: 14,
              color: Colors.blue,
            ),
          ),
          const SizedBox(width: 6),
          const Text(
            'Syncing',
            style: TextStyle(
              fontSize: 12,
              color: Colors.blue,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Realtime Status Indicator
/// Shows a small dot indicating realtime connection status
class RealtimeStatusIndicator extends ConsumerWidget {
  const RealtimeStatusIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(realtimeStatusProvider);
    
    // Only show if connected or creating a connection (to avoid noise)
    // or if error
    if (status == RealtimeConnectionStatus.disconnected) return const SizedBox.shrink();

    Color color;
    switch (status) {
      case RealtimeConnectionStatus.connected:
        color = Colors.green;
        break;
      case RealtimeConnectionStatus.connecting:
        color = Colors.amber;
        break;
      case RealtimeConnectionStatus.error:
        color = Colors.red;
        break;
      case RealtimeConnectionStatus.disconnected:
        color = Colors.grey;
        break;
    }

    return Container(
      width: 8,
      height: 8,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

/// Sync Status Widget - Combines all sync indicators
class SyncStatusWidget extends ConsumerWidget {
  const SyncStatusWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncResult = ref.watch(syncStatusProvider);
    final isSyncing = syncResult.status == SyncStatus.syncing;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const RealtimeStatusIndicator(),
          const SyncStatusIndicator(),
          const SyncConflictBadge(),
          SyncProgressIndicator(isSyncing: isSyncing),
        ],
      ),
    );
  }
}
