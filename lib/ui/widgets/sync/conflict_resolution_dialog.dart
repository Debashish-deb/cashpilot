import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/sync_providers.dart';

/// Conflict Resolution Dialog
/// Allows users to resolve sync conflicts with three strategies:
/// 1. Keep Local - Use offline changes
/// 2. Use Server - Discard local, use server version
/// 3. Merge - Manual field-by-field merge (future)
class ConflictResolutionDialog extends ConsumerWidget {
  final String entityType;
  final String entityId;
  final Map<String, dynamic> localData;
  final Map<String, dynamic> serverData;
  final List<String> conflictFields;
  final String conflictId;

  const ConflictResolutionDialog({
    super.key,
    required this.entityType,
    required this.entityId,
    required this.localData,
    required this.serverData,
    required this.conflictFields,
    required this.conflictId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conflictService = ref.read(conflictServiceProvider);
    
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.orange),
          const SizedBox(width: 12),
          Text('Sync Conflict - ${_formatEntityType(entityType)}'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This $entityType was edited on multiple devices while offline.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            _buildConflictSummary(context),
            const SizedBox(height: 20),
            Text(
              'Choose how to resolve:',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ],
        ),
      ),
      actions: [
        // Keep Local
        TextButton.icon(
          icon: const Icon(Icons.phone_android),
          label: const Text('Keep My Changes'),
          onPressed: () async {
            await conflictService.resolveConflict(
              conflictId: conflictId,
              resolution: 'keep_local',
            );
            if (context.mounted) Navigator.of(context).pop('local');
          },
        ),
        // Use Server
        TextButton.icon(
          icon: const Icon(Icons.cloud),
          label: const Text('Use Server Version'),
          onPressed: () async {
            await conflictService.resolveConflict(
              conflictId: conflictId,
              resolution: 'use_server',
            );
            if (context.mounted) Navigator.of(context).pop('server');
          },
        ),
      ],
    );
  }

  Widget _buildConflictSummary(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Conflicting fields:',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...conflictFields.map((field) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(Icons.edit, size: 16, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$field: "${localData[field]}" → "${serverData[field]}"',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  String _formatEntityType(String type) {
    return type[0].toUpperCase() + type.substring(1);
  }
}

/// Conflict Badge for Sync Status
/// Shows conflict count on sync button
class ConflictBadge extends ConsumerWidget {
  const ConflictBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conflictService = ref.watch(conflictServiceProvider);
    
    return FutureBuilder<int>(
      future: conflictService.getConflictCount(),
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;
        if (count == 0) return const SizedBox.shrink();
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.orange,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );
  }
}
