import 'package:cashpilot/features/sync/services/sync_checkpoint_service.dart' show SyncCheckpointService;
import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import 'base_sync_manager.dart';
import '../../../data/drift/app_database.dart';
import '../../../services/auth_service.dart';
import '../../../services/device_info_service.dart';
import 'package:cashpilot/features/sync/services/sync_checkpoint_service.dart';

class BudgetMemberSyncManager implements BaseSyncManager<BudgetMember> {
  final AppDatabase db;
  final AuthService authService;
  final SyncCheckpointService checkpointService;

  BudgetMemberSyncManager(this.db, this.authService, this.checkpointService);

  @override
  Future<void> syncUp(String id) async {
    final member = await (db.select(db.budgetMembers)..where((m) => m.id.equals(id))).getSingleOrNull();
    if (member == null) return;

    try {
      final deviceId = await deviceInfoService.getDeviceId();
      final data = _toJson(member, deviceId);
      await authService.client.from('budget_members').upsert(data);
      
      // Mark CLEAN
      await (db.update(db.budgetMembers)..where((t) => t.id.equals(id))).write(BudgetMembersCompanion(
        syncState: const Value('clean'),
      ));
      
      debugPrint('[BudgetMemberSyncManager] Synced budget member ${member.id} up');
    } catch (e) {
      debugPrint('[BudgetMemberSyncManager] Failed to sync budget member up: $e');
    }
  }

  @override
  Future<void> syncDown(String id) async {
    try {
      final remote = await authService.client
          .from('budget_members')
          .select()
          .eq('id', id)
          .single();
      
      await _upsertLocal(remote);
      debugPrint('[BudgetMemberSyncManager] Synced budget member $id down');
    } catch (e) {
      debugPrint('[BudgetMemberSyncManager] Failed to sync budget member down: $e');
    }
  }

  @override
  Future<int> pushChanges() async {
    // Push only dirty members
    final dirtyMembers = await (db.select(db.budgetMembers)
      ..where((t) => t.syncState.equals('dirty')))
      .get();
      
    int count = 0;
    if (dirtyMembers.isEmpty) return 0;

    for (var m in dirtyMembers) {
        await syncUp(m.id);
        count++;
    }
    
    if (count > 0) {
      debugPrint('[BudgetMemberSyncManager] Budget Members sync: Pushed $count members');
    }
    return count;
  }

  @override
  Future<int> pullChanges() async {
    try {
      final checkpoint = await checkpointService.getCheckpoint('budget_members');
      final lastSyncAt = checkpoint.lastSyncAt;
      var query = authService.client.from('budget_members').select();
      
      if (lastSyncAt != null) {
        query = query.gt('updated_at', lastSyncAt.toIso8601String());
      }
      
      final remote = await query;
      int count = 0;
      
      // Track latest update to save checkpoint
      DateTime? maxUpdatedAt;
      
      for (var data in remote) {
        await _upsertLocal(data);
        count++;
        
        // Track max updated_at
        final updatedAtFunc = data['updated_at'] != null 
            ? DateTime.tryParse(data['updated_at'].toString()) 
            : null;
        if (updatedAtFunc != null && 
            (maxUpdatedAt == null || updatedAtFunc.isAfter(maxUpdatedAt))) {
          maxUpdatedAt = updatedAtFunc;
        }
      }
      
      // Save checkpoint if we received data
      if (maxUpdatedAt != null) {
        await checkpointService.updateCheckpoint('budget_members', lastSyncAt: maxUpdatedAt);
      } else if (remote.isNotEmpty && lastSyncAt == null) {
        // Initial sync fallback: save now if no updated_at column or parsing failed
        await checkpointService.updateCheckpoint('budget_members', lastSyncAt: DateTime.now());
      }
      
      if (count > 0) {
        debugPrint('[BudgetMemberSyncManager] Budget Members sync: Pulled $count members (incremental)');
      }
      return count;
    } catch (e) {
      debugPrint('Error pulling members: $e');
      return 0;
    }
  }

  Map<String, dynamic> _toJson(BudgetMember m, String deviceId) {
    return {
      'id': m.id,
      'budget_id': m.budgetId,
      'user_id': m.userId,
      'member_email': m.memberEmail,
      'member_name': m.memberName,
      'role': m.role,
      'status': m.status,
      'invited_by': m.invitedBy,
      'invited_at': m.invitedAt.toIso8601String(),
      'accepted_at': m.acceptedAt?.toIso8601String(),
      'last_modified_by_device_id': deviceId,
    };
  }

  Future<void> _upsertLocal(Map<String, dynamic> data) async {
    final companion = BudgetMembersCompanion(
      id: Value(data['id'] as String),
      budgetId: Value(data['budget_id'] as String),
      userId: Value(data['user_id'] as String?),
      memberEmail: Value(data['member_email'] as String),
      memberName: Value(data['member_name'] as String?),
      role: Value(data['role'] as String),
      status: Value(data['status'] as String),
      invitedBy: Value(data['invited_by'] as String?),
      invitedAt: Value(DateTime.tryParse(data['invited_at'] as String? ?? '') ?? DateTime.now()),
      acceptedAt: Value(data['accepted_at'] != null 
          ? DateTime.tryParse(data['accepted_at'] as String? ?? '') 
          : null),
      syncState: const Value('clean'), // Mark clean on pull
      revision: Value((data['revision'] as num?)?.toInt() ?? 0),
    );
    
    await db.into(db.budgetMembers).insertOnConflictUpdate(companion);
  }
}
