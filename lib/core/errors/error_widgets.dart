import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'error_handler.dart';

/// Offline Banner Widget
/// 
/// Shows a banner when the app is offline.
/// Automatically hides when back online.
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(connectivityStatusProvider);
    
    if (status == ConnectivityStatus.online) {
      return const SizedBox.shrink();
    }
    
    return Material(
      elevation: 4,
      color: Colors.orange,
      child: SafeArea(
        bottom: false,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.wifi_off, color: Colors.white, size: 18),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'You are offline. Changes will sync when reconnected.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (status == ConnectivityStatus.checking)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
/// Sync Status Indicator
/// 
/// Shows sync status in app bar or elsewhere.
/// Polished for trust: "Offline", "Syncing", "Up to date".
class SyncStatusIndicator extends ConsumerWidget {
  const SyncStatusIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(connectivityStatusProvider);
    // You might also want to watch a 'isSyncing' provider if available from SyncEngine
    // For now, mapping ConnectivityStatus to trust signals.
    
    Color bgColor;
    Color textColor;
    IconData icon;
    String label;

    switch (status) {
      case ConnectivityStatus.offline:
        // Calm Orange/Grey
        bgColor = Colors.orange.withValues(alpha: 0.15);
        textColor = Colors.orange[800]!;
        icon = Icons.cloud_off_rounded;
        label = 'Offline';
        break;
      case ConnectivityStatus.checking:
      case ConnectivityStatus.online: // Representing "Up to date" or "Online"
        // Calm Green/Blue
        bgColor = Colors.green.withValues(alpha: 0.15);
        textColor = Colors.green[800]!;
        icon = Icons.check_circle_outline_rounded;
        label = 'Up to date';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: textColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: textColor,
            size: 14,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

/// Error Feedback Widget
/// 
/// Shows inline error with retry button
class ErrorFeedback extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final IconData icon;
  final Color color;

  const ErrorFeedback({
    super.key,
    required this.message,
    this.onRetry,
    this.icon = Icons.error_outline,
    this.color = Colors.red,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 48),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color,
              fontSize: 14,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
