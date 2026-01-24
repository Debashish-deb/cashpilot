import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import 'base_sync_manager.dart';
import '../../../data/drift/app_database.dart';
import '../../../services/auth_service.dart';
import '../../../services/device_info_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SavingsGoalSyncManager implements BaseSyncManager<SavingsGoal> {
  final AppDatabase db;
  final AuthService authService;
  final SharedPreferences prefs;
  static const _syncKey = 'last_savings_goals_sync_iso';

  SavingsGoalSyncManager(this.db, this.authService, this.prefs);

  @override
  Future<void> syncUp(String id) async {
    final goal = await (db.select(db.savingsGoals)..where((t) => t.id.equals(id))).getSingleOrNull();
    if (goal == null) return;

    try {
      final existing = await authService.client
          .from('savings_goals')
          .select('revision')
          .eq('id', goal.id)
          .maybeSingle();

      // Don't overwrite if remote is newer
      if (existing != null) {
        final remoteRevision = (existing['revision'] as num?)?.toInt() ?? 0;
        if (remoteRevision > goal.revision) {
          debugPrint('[SavingsGoalSyncManager] Remote savings goal ${goal.id} has higher revision, skipping push');
          return;
        }
      }

      final deviceId = await deviceInfoService.getDeviceId();
      final data = {
        'id': goal.id,
        'user_id': goal.userId,
        'title': goal.title,
        'current_amount': goal.currentAmount,
        'target_amount': goal.targetAmount,
        'icon_name': goal.iconName,
        'color_hex': goal.colorHex,
        'deadline': goal.deadline?.toIso8601String(),
        'is_archived': goal.isArchived,
        'revision': goal.revision,
        'is_deleted': goal.isDeleted,
        'metadata': goal.metadata, 
        'created_at': goal.createdAt.toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'last_modified_by_device_id': deviceId,
      };

      await authService.client.from('savings_goals').upsert(data);
      
      // Mark Clean on Success
      await (db.update(db.savingsGoals)..where((t) => t.id.equals(id))).write(SavingsGoalsCompanion(
        syncState: const Value('clean'),
        revision: Value(goal.revision + 1), // Increment revision locally
      ));
      
      debugPrint('[SavingsGoalSyncManager] Synced savings goal ${goal.id} up');
    } catch (e) {
      debugPrint('[SavingsGoalSyncManager] Failed to sync savings goal ${goal.id} up: $e');
    }
  }

  @override
  Future<void> syncDown(String id) async {}

  @override
  Future<int> pushChanges() async {
    final userId = authService.currentUser?.id;
    if (userId == null) return 0;

    int count = 0;
    try {
      // Filter by DIRTY state
      final localGoals = await (db.select(db.savingsGoals)
        ..where((t) => t.userId.equals(userId) & t.syncState.equals('dirty')))
        .get();
        
      for (var goal in localGoals) {
        await syncUp(goal.id);
        count++;
      }
      if (count > 0) {
        debugPrint('[SavingsGoalSyncManager] Savings goal sync: Pushed $count goals');
      }
    } catch(e) {
      debugPrint('Error pushing savings goals: $e');
    }
    return count;
  }

  @override
  Future<int> pullChanges() async {
    final userId = authService.currentUser?.id;
    if (userId == null) return 0;

    int count = 0;
    try {
      final lastSyncStr = prefs.getString(_syncKey);
      
      var query = authService.client
          .from('savings_goals')
          .select()
          .eq('user_id', userId);
      
      if (lastSyncStr != null) {
        query = query.gt('updated_at', lastSyncStr);
      }

      final remoteGoals = await query;
      DateTime? maxUpdated;

      for (var data in remoteGoals) {
        await _upsertLocal(data);
        count++;
         
        if (data['updated_at'] != null) {
          final updatedAt = DateTime.tryParse(data['updated_at'] as String? ?? '');
          if (updatedAt != null) {
            if (maxUpdated == null || updatedAt.isAfter(maxUpdated)) {
              maxUpdated = updatedAt;
            }
          }
        }
      }
      
      if (maxUpdated != null) {
        await prefs.setString(_syncKey, maxUpdated.toIso8601String());
      }
      
      if (count > 0) {
        debugPrint('[SavingsGoalSyncManager] Savings goal sync: Pulled $count goals');
      }
    } catch (e) {
      debugPrint('Error pulling savings goals: $e');
    }
    return count;
  }

  Future<void> _upsertLocal(Map<String, dynamic> data) async {
    final id = data['id'] as String?;
    final userId = data['user_id'] as String?;
    final title = data['title'] as String?;
    if (id == null || userId == null || title == null) return;
    
    final isDeleted = data['is_deleted'] as bool? ?? false;
    
    if (isDeleted) {
      try {
        await (db.delete(db.savingsGoals)..where((t) => t.id.equals(id))).go();
        debugPrint('[SavingsGoalSyncManager] ✅ Permanently deleted savings goal $id');
        return;
      } catch (e) {
        debugPrint('[SavingsGoalSyncManager] ⚠️ Error deleting savings goal $id: $e');
        return;
      }
    }
    
    final companion = SavingsGoalsCompanion(
      id: Value(id),
      userId: Value(userId),
      title: Value(title),
      currentAmount: Value((data['current_amount'] as num?)?.toInt() ?? 0),
      targetAmount: Value((data['target_amount'] as num?)?.toInt() ?? 0),
      iconName: Value(data['icon_name'] as String?),
      colorHex: Value(data['color_hex'] as String?),
      deadline: Value(data['deadline'] != null ? DateTime.tryParse(data['deadline'] as String? ?? '') : null),
      isArchived: Value(data['is_archived'] as bool? ?? false),
      revision: Value((data['revision'] as num?)?.toInt() ?? 0),
      isDeleted: const Value(false), 
      metadata: Value(data['metadata'] as Map<String, dynamic>?),
      createdAt: Value(DateTime.tryParse(data['created_at'] as String? ?? '') ?? DateTime.now()),
      updatedAt: Value(DateTime.tryParse(data['updated_at'] as String? ?? '') ?? DateTime.now()),
      syncState: const Value('clean'), // Mark clean on pull
    );
    
    try {
      await db.insertSavingsGoal(companion);
    } catch (e) {
      await (db.update(db.savingsGoals)..where((t) => t.id.equals(id)))
          .write(companion);
      debugPrint('[SavingsGoalSyncManager] Updated existing savings goal $id from remote');
    }
  }
}
