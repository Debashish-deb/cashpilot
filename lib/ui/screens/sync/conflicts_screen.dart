import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:drift/drift.dart' show OrderingTerm;
import '../../../core/providers/app_providers.dart';
import '../../../data/drift/app_database.dart';
import '../../../features/sync/services/conflict_service.dart';
import '../../widgets/sync/conflict_resolution_dialog.dart';

/// Conflicts Screen - Shows all unresolved sync conflicts
/// Phase 1: User visibility and resolution for conflicts
class ConflictsScreen extends ConsumerStatefulWidget {
  const ConflictsScreen({super.key});

  @override
  ConsumerState<ConflictsScreen> createState() => _ConflictsScreenState();
}

class _ConflictsScreenState extends ConsumerState<ConflictsScreen> {
  @override
  Widget build(BuildContext context) {
    final db = ref.watch(databaseProvider);
    final conflictService = ConflictService(db);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sync Conflicts'),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => _showHelpDialog(context),
          ),
        ],
      ),
      body: FutureBuilder<List<Conflict>>(
        future: _getOpenConflicts(db),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                  const SizedBox(height: 16),
                  Text('Error loading conflicts: ${snapshot.error}'),
                ],
              ),
            );
          }

          final conflicts = snapshot.data ?? [];

          if (conflicts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 64, color: Colors.green.shade300),
                  const SizedBox(height: 16),
                  const Text(
                    'No conflicts',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'All your data is in sync',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: conflicts.length,
            itemBuilder: (context, index) {
              final conflict = conflicts[index];
              return _ConflictCard(
                conflict: conflict,
                onResolve: () async {
                  await _showResolutionDialog(context, conflict, conflictService);
                  setState(() {}); // Refresh list
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<List<Conflict>> _getOpenConflicts(AppDatabase db) async {
    return await (db.select(db.conflicts)
      ..where((c) => c.status.equals('open'))
      ..orderBy([(c) => OrderingTerm.desc(c.createdAt)]))
      .get();
  }

  Future<void> _showResolutionDialog(
    BuildContext context,
    Conflict conflict,
    ConflictService service,
  ) async {
    // Parse JSON strings
    final localData = Map<String, dynamic>.from(
          const JsonDecoder().convert(conflict.localJson));
    
    final serverData = Map<String, dynamic>.from(
          const JsonDecoder().convert(conflict.remoteJson));
    
    // Extract conflicting fields
    final conflictFields = <String>[];
    for (final key in localData.keys) {
      if (serverData.containsKey(key) && localData[key] != serverData[key]) {
        conflictFields.add(key);
      }
    }
    
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ConflictResolutionDialog(
        entityType: conflict.entityType,
        entityId: conflict.entityId,
        localData: localData,
        serverData: serverData,
        conflictFields: conflictFields,
        conflictId: conflict.id,
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Sync Conflicts'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'What are conflicts?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Conflicts happen when you edit the same item on multiple devices while offline. '
                'We detect these and let you choose which version to keep.',
              ),
              SizedBox(height: 16),
              Text(
                'How to resolve:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                '• Keep Mine - Use the version from this device\n'
                '• Use Server - Use the version from the cloud\n'
                '• Merge Fields - Pick specific values (advanced)',
              ),
              SizedBox(height: 16),
              Text(
                'Why do they appear?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'This protects your data. Without conflict detection, changes could be lost silently. '
                'We show you conflicts so you can make informed decisions.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}

/// Individual conflict card
class _ConflictCard extends StatelessWidget {
  final Conflict conflict;
  final VoidCallback onResolve;

  const _ConflictCard({
    required this.conflict,
    required this.onResolve,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, y \'at\' h:mm a');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.red.shade200, width: 1),
      ),
      child: InkWell(
        onTap: onResolve,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      conflict.entityType.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade900,
                      ),
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Conflicting ${conflict.entityType}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Edited on multiple devices while offline',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.access_time, size: 14, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Text(
                    'Detected ${dateFormat.format(conflict.createdAt)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: onResolve,
                    icon: const Icon(Icons.build, size: 16),
                    label: const Text('RESOLVE'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red.shade700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
