import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/drift/app_database.dart';
import '../../../core/providers/app_providers.dart';
import '../../../services/sync/conflict_service.dart';

/// Provider for the ConflictService
final conflictServiceProvider = Provider<ConflictService>((ref) {
  final db = ref.watch(databaseProvider);
  return ConflictService(db);
});

/// Stream of all open conflicts
final pendingConflictsProvider = StreamProvider<List<ConflictData>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.conflicts)
        ..where((c) => c.status.equals('open'))
        ..orderBy([(c) => OrderingTerm.desc(c.createdAt)]))
      .watch();
});

/// Count of open conflicts
final conflictCountProvider = StreamProvider<int>((ref) {
  final service = ref.watch(conflictServiceProvider);
  return service.watchOpenConflictCount();
});

/// Provider for a specific conflict by ID
final conflictByIdProvider = StreamProvider.family<ConflictData?, String>((ref, id) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.conflicts)..where((c) => c.id.equals(id))).watchSingleOrNull();
});
