import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import 'base_sync_manager.dart';
import '../../../data/drift/app_database.dart';
import '../../../services/auth_service.dart';
import '../../../services/device_info_service.dart';
import 'package:cashpilot/features/sync/services/sync_checkpoint_service.dart';

class AccountSyncManager implements BaseSyncManager<Account> {
  final AppDatabase db;
  final AuthService authService;
  final SyncCheckpointService checkpointService;
  
  AccountSyncManager(this.db, this.authService, this.checkpointService);

  @override
  Future<void> syncUp(String id) async {
    final account = await (db.select(db.accounts)..where((a) => a.id.equals(id))).getSingleOrNull();
    if (account == null) return;

    try {
      final existing = await authService.client
          .from('accounts')
          .select('revision')
          .eq('id', account.id)
          .maybeSingle();

      // CRITICAL FIX: Don't overwrite if remote is newer
      if (existing != null) {
        final remoteRevision = (existing['revision'] as num?)?.toInt() ?? 0;
        if (remoteRevision > account.revision) {
          debugPrint('[AccountSyncManager] Remote account ${account.id} has higher revision, skipping push');
          return;
        }
      }

      final deviceId = await deviceInfoService.getDeviceId();
      final data = {
        'id': account.id,
        'user_id': account.userId,
        'name': account.name,
        'type': account.type,
        'balance': account.balance,
        'currency': account.currency,
        'icon_name': account.iconName,
        'color_hex': account.colorHex,
        'is_default': account.isDefault,
        'is_deleted': account.isDeleted,
        'revision': account.revision,
        'created_at': account.createdAt.toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'last_modified_by_device_id': deviceId,
      };

      await authService.client.from('accounts').upsert(data);
      debugPrint('[AccountSyncManager] Synced account ${account.id} up');
    } catch (e) {
      debugPrint('[AccountSyncManager] Failed to sync account ${account.id} up: $e');
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
      final accounts = await (db.select(db.accounts)
        ..where((a) => a.userId.equals(userId)))
        .get();

      for (var account in accounts) {
        await syncUp(account.id);
        count++;
      }
      debugPrint('[AccountSyncManager] Account sync: Pushed $count accounts');
    } catch (e) {
      debugPrint('[AccountSyncManager] Account pushChanges error: $e');
    }
    return count;
  }

  @override
  Future<int> pullChanges() async {
    final userId = authService.currentUser?.id;
    if (userId == null) return 0;
    
    int count = 0;
    try {
      final checkpoint = await checkpointService.getCheckpoint('accounts');
      final lastSyncAt = checkpoint.lastSyncAt;
      
      var query = authService.client
          .from('accounts')
          .select()
          .eq('user_id', userId);
      
      // Incremental sync: only fetch changes since last sync
      if (lastSyncAt != null) {
        query = query.gt('updated_at', lastSyncAt.toIso8601String());
      }
          
      final remoteAccounts = await query;
      
      DateTime? maxUpdated;
          
      for (var data in remoteAccounts) {
        await _upsertLocal(data);
        count++;
        
        // Track latest update time
        final updatedAt = DateTime.tryParse(data['updated_at'] ?? '');
        if (updatedAt != null) {
          if (maxUpdated == null || updatedAt.isAfter(maxUpdated)) {
            maxUpdated = updatedAt;
          }
        }
      }
      
      // Save checkpoint if we received data
      if (maxUpdated != null) {
        await checkpointService.updateCheckpoint('accounts', lastSyncAt: maxUpdated);
      }
      
      debugPrint('[AccountSyncManager] Account sync: Pulled $count accounts');
    } catch (e) {
      debugPrint('Error pulling accounts: $e');
    }
    return count;
  }

  Future<void> _upsertLocal(Map<String, dynamic> data) async {
    // Null safety guards
    final id = data['id'] as String?;
    final userId = data['user_id'] as String?;
    final name = data['name'] as String?;
    
    if (id == null || userId == null || name == null) {
      debugPrint('[AccountSyncManager] Account sync: Missing required fields, skipping');
      return;
    }
    
    final isDeleted = data['is_deleted'] as bool? ?? false;
    
    // CRITICAL FIX: If account is marked as deleted on server, remove it locally
    if (isDeleted) {
      try {
        await (db.delete(db.accounts)..where((t) => t.id.equals(id))).go();
        debugPrint('[AccountSyncManager] ✅ Permanently deleted account $id');
        return;
      } catch (e) {
        debugPrint('[AccountSyncManager] ⚠️ Error deleting account $id: $e');
        return;
      }
    }
    
    final companion = AccountsCompanion(
      id: Value(id),
      userId: Value(userId),
      name: Value(name),
      type: Value(data['type'] as String? ?? 'checking'),
      balance: Value((data['balance'] as num?)?.toInt() ?? 0),
      currency: Value(data['currency'] as String? ?? 'EUR'),
      iconName: Value(data['icon_name'] as String?),
      colorHex: Value(data['color_hex'] as String?),
      isDefault: Value(data['is_default'] as bool? ?? false),
      isDeleted: const Value(false), // Never insert with isDeleted=true
      revision: Value((data['revision'] as num?)?.toInt() ?? 0),
      createdAt: Value(DateTime.tryParse(data['created_at'] as String? ?? '') ?? DateTime.now()),
      updatedAt: Value(DateTime.tryParse(data['updated_at'] as String? ?? '') ?? DateTime.now()),
    );
    
    try {
      await db.insertAccount(companion);
    } catch (e) {
      // Use write() instead of replace() for reliable updates with ALL fields
      await (db.update(db.accounts)..where((t) => t.id.equals(id)))
          .write(companion);
      debugPrint('[AccountSyncManager] Updated existing account $id from remote');
    }
  }
}
