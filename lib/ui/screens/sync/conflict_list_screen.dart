import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cashpilot/data/drift/app_database.dart';
import 'package:cashpilot/services/sync/conflict_service.dart';
import 'package:go_router/go_router.dart';
import 'package:cashpilot/l10n/app_localizations.dart';
import 'conflict_detail_screen.dart';

/// Screen showing all unresolved sync conflicts
class ConflictListScreen extends ConsumerWidget {
  const ConflictListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final conflictsAsync = ref.watch(conflictListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsSyncConflicts),
      ),
      body: conflictsAsync.when(
        data: (conflicts) {
          if (conflicts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, size: 64, color: Colors.green[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No Conflicts',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'All data is synced successfully',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
            );
          }

          // Group by entity type
          final groupedConflicts = <String, List<Conflict>>{};
          for (final conflict in conflicts) {
            groupedConflicts.putIfAbsent(conflict.entityType, () => []).add(conflict);
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Summary card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber, color: Colors.orange[700], size: 32),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${conflicts.length} Conflicts Detected',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Local and remote versions differ. Choose which to keep.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Grouped conflict lists
              ...groupedConflicts.entries.map((entry) {
                final entityType = entry.key;
                final entityConflicts = entry.value;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      child: Text(
                        '${_capitalizeFirst(entityType)}s (${entityConflicts.length})',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                      ),
                    ),
                    ...entityConflicts.map((conflict) => _ConflictCard(conflict: conflict)),
                    const SizedBox(height: 16),
                  ],
                );
              }),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error loading conflicts: $error'),
        ),
      ),
    );
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}

class _ConflictCard extends StatelessWidget {
  final Conflict conflict;

  const _ConflictCard({required this.conflict});

  @override
  Widget build(BuildContext context) {
    final createdAt = conflict.createdAt;
    final timeAgo = _formatTimeAgo(createdAt);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          _getIconForType(conflict.entityType),
          color: Colors.orange[700],
        ),
        title: Text(
          '${_capitalizeFirst(conflict.entityType)} Conflict',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text('Detected $timeAgo'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          context.push('/sync/conflicts/detail', extra: conflict);
        },
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'expense':
        return Icons.receipt;
      case 'budget':
        return Icons.account_balance_wallet;
      case 'account':
        return Icons.account_balance;
      default:
        return Icons.sync_problem;
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'just now';
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}
