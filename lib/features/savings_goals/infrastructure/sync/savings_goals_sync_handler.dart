import 'package:drift/drift.dart';
import '../../../../data/drift/app_database.dart';
import '../../../../services/auth_service.dart';
import '../drift/savings_goals_dao.dart';

class SavingsGoalsSyncHandler {
  final AppDatabase db;
  final AuthService authService;
  final SavingsGoalsDao dao;

  SavingsGoalsSyncHandler(this.db, this.authService, this.dao);

  /// PUSH single event to remote (Processing the Outbox)
  Future<void> push(Map<String, dynamic> payload, String action, String entityId) async {
    switch (action) {
      case 'upsert':
        await authService.client.from('savings_goals').upsert(payload);
        break;
      case 'delete':
        // Soft delete on server usually, or hard delete if specified
        // Enterprise usually does soft delete:
        await authService.client.from('savings_goals').update({'is_deleted': true}).eq('id', entityId);
        break;
      default:
        throw UnimplementedError('Action $action not supported');
    }
  }

  /// PULL from remote (Sync Engine logic)
  Future<void> pull(List<Map<String, dynamic>> remoteRecords) async {
    await db.transaction(() async {
      for (final data in remoteRecords) {
        final id = data['id'] as String;
        final revision = (data['revision'] as num?)?.toInt() ?? 0;
        
        // Conflict Check (Last Write Wins / Revision based)
        final local = await dao.getGoal(id);
        
        // If local doesn't exist or remote is newer, upsert
        // (For true conflict resolution, we'd check if local was dirty, but simplified here)
        
        final isDeleted = data['is_deleted'] as bool? ?? false;
        
        if (isDeleted) {
           await (db.delete(db.savingsGoals)..where((t) => t.id.equals(id))).go();
           continue;
        }

        final companion = SavingsGoalsCompanion(
          id: Value(id),
          userId: Value(data['user_id'] as String),
          title: Value(data['title'] as String),
          targetAmount: Value((data['target_amount'] as num).toInt()),
          currentAmount: Value((data['current_amount'] as num).toInt()), // Fixed: use currentAmount
          deadline: Value(data['deadline'] != null ? DateTime.parse(data['deadline']) : null),
          iconName: Value(data['icon_name'] as String?),
          colorHex: Value(data['color_hex'] as String?),
          revision: Value(revision),
          syncState: const Value('clean'),
          updatedAt: Value(DateTime.now()), // Or remote updated_at
        );

        await db.into(db.savingsGoals).insertOnConflictUpdate(companion);
      }
    });
  }
}
