import '../../../data/drift/app_database.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

class AuditLogger {
  final AppDatabase _db;

  AuditLogger(this._db);

  /// Logs an entity change to the central audit log
  Future<void> log({
    required String entityType,
    required String entityId,
    required String action,
    required String userId,
    String? oldValue,
    String? newValue,
    Map<String, dynamic>? metadata,
  }) async {
    final auditLog = AuditLogsCompanion(
      id: Value(const Uuid().v4()),
      entityType: Value(entityType),
      entityId: Value(entityId),
      action: Value(action),
      userId: Value(userId),
      oldValue: Value(oldValue),
      newValue: Value(newValue),
      metadata: Value(metadata ?? {}),
      createdAt: Value(DateTime.now()),
      syncState: const Value('dirty'),
    );
    await _db.into(_db.auditLogs).insert(auditLog);
  }
}
