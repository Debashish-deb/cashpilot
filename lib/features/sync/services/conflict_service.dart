import 'dart:convert';
import '../../../data/drift/app_database.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart';

/// Conflict Service - Manages sync conflicts
/// Uses existing Conflicts table for storage
class ConflictService {
  final AppDatabase _db;
  final _uuid = const Uuid();
  
  ConflictService(this._db);
  
  /// Detect conflict by comparing revisions
  bool detectConflict({
    required int clientRevision,
    required int serverRevision,
  }) {
    return clientRevision != serverRevision;
  }
  
  /// Store conflict using EXISTING Conflicts table
  Future<void> storeConflict({
    required String entityType,
    required String entityId,
    required Map<String, dynamic> localData,
    required Map<String, dynamic> serverData,
  }) async {
    // Calculate diff fields
    final conflictFields = <String>[];
    localData.forEach((key, value) {
      if (serverData[key] != value) {
        conflictFields.add(key);
      }
    });
    
    final conflict = ConflictsCompanion.insert(
      id: _uuid.v4(),
      entityType: entityType,
      entityId: entityId,
      localJson: jsonEncode(localData),
      remoteJson: jsonEncode(serverData),
      diffJson: Value(jsonEncode({'fields': conflictFields})),
    );
    
    await _db.into(_db.conflicts).insert(conflict);
  }
  
  /// Get unresolved conflicts
  Future<List<Conflict>> getUnresolvedConflicts() async {
    return await (_db.select(_db.conflicts)
      ..where((c) => c.status.equals('open')))
      .get();
  }
  
  /// Resolve conflict with user choice
  Future<void> resolveConflict({
    required String conflictId,
    required String resolution, // 'keepLocal', 'useServer', 'merge'
  }) async {
    await (_db.update(_db.conflicts)
      ..where((c) => c.id.equals(conflictId)))
      .write(ConflictsCompanion(
        status: const Value('resolved'),
        resolutionType: Value(resolution),
        resolvedAt: Value(DateTime.now()),
      ));
  }
  
  /// Get conflict count (for UI badge)
  Future<int> getConflictCount() async {
    final result = await (_db.select(_db.conflicts)
      ..where((c) => c.status.equals('open')))
      .get();
    return result.length;
  }
}
