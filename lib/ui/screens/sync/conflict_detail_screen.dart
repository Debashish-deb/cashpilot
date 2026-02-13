import 'dart:convert';
import 'package:cashpilot/features/sync/sync_providers.dart' show conflictServiceProvider;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cashpilot/data/drift/app_database.dart';
import 'package:cashpilot/services/sync/conflict_service.dart';
import 'package:cashpilot/l10n/app_localizations.dart';

/// Screen showing detailed side-by-side comparison of conflicting versions
class ConflictDetailScreen extends ConsumerWidget {
  final ConflictData conflict;

  const ConflictDetailScreen({super.key, required this.conflict});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final conflictService = ref.read(conflictServiceProvider);

    final localData = jsonDecode(conflict.localJson) as Map<String, dynamic>;
    final remoteData = jsonDecode(conflict.remoteJson) as Map<String, dynamic>;
    final diffs = conflictService.parseDiffs(conflict);

    return Scaffold(
      appBar: AppBar(
        title: Text('${_capitalizeFirst(conflict.entityType)} Conflict'),
      ),
      body: Column(
        children: [
          // Info banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.orange[50],
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange[900]),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'This ${conflict.entityType} was edited locally and remotely. Choose which version to keep.',
                    style: TextStyle(color: Colors.orange[900]),
                  ),
                ),
              ],
            ),
          ),

          // Comparison view
          Expanded(
            child: diffs.isEmpty
                ? Center(child: Text(l10n.syncNoDifferences))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: diffs.length,
                    itemBuilder: (context, index) {
                      final diff = diffs[index];
                      return _DiffRow(diff: diff);
                    },
                  ),
          ),

          // Action buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await _resolveConflict(
                            context,
                            ref,
                            conflictService,
                            ConflictResolution.keepLocal,
                          );
                        },
                        icon: const Icon(Icons.phone_android),
                        label: Text(l10n.syncKeepLocal),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await _resolveConflict(
                            context,
                            ref,
                            conflictService,
                            ConflictResolution.keepRemote,
                          );
                        },
                        icon: const Icon(Icons.cloud),
                        label: Text(l10n.syncKeepRemote),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (conflict.entityType == 'expense')
                  OutlinedButton.icon(
                    onPressed: () async {
                      await _resolveConflict(
                        context,
                        ref,
                        conflictService,
                        ConflictResolution.duplicate,
                      );
                    },
                    icon: const Icon(Icons.content_copy),
                    label: Text(l10n.syncKeepBoth),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _resolveConflict(
    BuildContext context,
    WidgetRef ref,
    ConflictService service,
    ConflictResolution resolution,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    // Show confirmation
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.syncConfirmResolution),
        content: Text(_getConfirmationMessage(resolution)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.commonCancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.commonConfirm),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await service.resolveConflict(
        conflictId: conflict.id,
        resolution: resolution,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.syncResolvedSuccess)),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.syncErrorResolving(e.toString()))),
        );
      }
    }
  }

  String _getConfirmationMessage(ConflictResolution resolution) {
    switch (resolution) {
      case ConflictResolution.keepLocal:
        return 'Keep the local version and overwrite the remote version? Your local changes will be pushed to the server.';
      case ConflictResolution.keepRemote:
        return 'Discard local changes and use the remote version? Your local changes will be lost.';
      case ConflictResolution.duplicate:
        return 'Create a copy of the local version as a new record? Both versions will be kept.';
      default:
        return 'Resolve this conflict?';
    }
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}

class _DiffRow extends StatelessWidget {
  final ConflictDiff diff;

  const _DiffRow({required this.diff});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Field name
            Text(
              _formatFieldName(diff.fieldName),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
            ),
            const SizedBox(height: 12),

            // Local version
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.phone_android, size: 20, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Local',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          diff.localValue ?? '(empty)',
                          style: TextStyle(
                            color: diff.localValue == null ? Colors.grey : Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Remote version
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.cloud, size: 20, color: Colors.green[700]),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Remote',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          diff.remoteValue ?? '(empty)',
                          style: TextStyle(
                            color: diff.remoteValue == null ? Colors.grey : Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatFieldName(String field) {
    // Convert snake_case/camelCase to Title Case
    return field
        .replaceAllMapped(RegExp(r'[A-Z]'), (m) => ' ${m.group(0)}')
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1))
        .join(' ')
        .trim();
  }
}
