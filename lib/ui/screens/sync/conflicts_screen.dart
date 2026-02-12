import 'dart:convert';
import 'package:cashpilot/services/sync/conflict_service.dart' show ConflictService;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cashpilot/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:drift/drift.dart' show OrderingTerm;
// Added by user instruction
// import 'widgets/create_test_dialog.dart'; // Not used in this file, but added by user instruction
// import 'ab_test_details_screen.dart'; // Not used in this file, but added by user instruction
import '../../../core/providers/app_providers.dart';
import '../../../data/drift/app_database.dart';
import '../../../services/sync/conflict_service.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark; // Added by user instruction
    final l10n = AppLocalizations.of(context)!; // Added by user instruction

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.conflictTitle), // Modified by user instruction (original text, but using l10n)
        backgroundColor: isDark ? Colors.grey.shade900 : const Color(0xFF6750A4), // Modified by user instruction
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => _showHelpDialog(context),
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<List<ConflictData>>(
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
                    Text(l10n.commonErrorMessage(snapshot.error.toString())), // Modified by user instruction (using l10n)
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
                    Text(
                      l10n.conflictNone,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.conflictAllGood,
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
      ),
    );
  }

  Future<List<ConflictData>> _getOpenConflicts(AppDatabase db) async {
    return await (db.select(db.conflicts)
      ..where((c) => c.status.equals('open'))
      ..orderBy([(c) => OrderingTerm.desc(c.createdAt)]))
      .get();
  }

  Future<void> _showResolutionDialog(
    BuildContext context,
    ConflictData conflict,
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
    final l10n = AppLocalizations.of(context)!; // Added by user instruction
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sync Conflicts Help'),
        content: SingleChildScrollView( // Removed const as it contains non-const children
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'What are conflicts?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Sync conflicts occur when the same item is edited on multiple devices while offline.',
              ),
              const SizedBox(height: 16),
              const Text(
                'How to resolve?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                '1. Keep Local: Use the version currently on this device.\n2. Keep Cloud: Discard local changes and use the version from the server.',
              ),
              const SizedBox(height: 16),
              const Text(
                'Why do they occur?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Usually due to concurrent edits on different devices before a sync could complete.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.commonGotIt), // Modified by user instruction (using l10n)
          ),
        ],
      ),
    );
  }
}

/// Individual conflict card
class _ConflictCard extends StatelessWidget {
  final ConflictData conflict;
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
