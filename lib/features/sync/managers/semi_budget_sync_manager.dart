import 'package:cashpilot/features/sync/services/sync_checkpoint_service.dart' show SyncCheckpointService;
import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import 'base_sync_manager.dart';
import '../../../data/drift/app_database.dart';
import '../../../services/auth_service.dart';
import '../../../services/device_info_service.dart';
import 'package:cashpilot/features/sync/services/sync_checkpoint_service.dart';

class SemiBudgetSyncManager implements BaseSyncManager<SemiBudget> {
  final AppDatabase db;
  final AuthService authService;
  final SyncCheckpointService checkpointService;

  SemiBudgetSyncManager(this.db, this.authService, this.checkpointService);

  @override
  Future<void> syncUp(String id) async {
    final sb = await (db.select(db.semiBudgets)..where((s) => s.id.equals(id))).getSingleOrNull();
    if (sb == null) return;

    try {
      // Check if parent budget exists - if not, stay dirty for batch sync
      final parentBudget = await authService.client
          .from('budgets')
          .select('id')
          .eq('id', sb.budgetId)
          .maybeSingle();
      
      if (parentBudget == null) {
        debugPrint('[SemiBudgetSyncManager] Parent budget ${sb.budgetId} not on server, keeping ${sb.id} dirty');
        return; // Stay dirty - batch sync will handle it
      }

      final existing = await authService.client
          .from('semi_budgets')
          .select('revision')
          .eq('id', sb.id)
          .maybeSingle();

      // CONFLICT DETECTION: Don't overwrite if remote is newer
      if (existing != null) {
        final remoteRevision = (existing['revision'] as num?)?.toInt() ?? 0;
        if (remoteRevision > sb.revision) {
          debugPrint('[SemiBudgetSyncManager] CONFLICT: Remote ${sb.id} has higher revision');
          
          // Mark as conflict and pull remote version
          await (db.update(db.semiBudgets)..where((s) => s.id.equals(sb.id)))
              .write(const SemiBudgetsCompanion(syncState: Value('conflict')));
          await syncDown(id);
          return;
        }
      }

      final deviceId = await deviceInfoService.getDeviceId();
      final data = {
        'id': sb.id,
        'budget_id': sb.budgetId,
        'name': sb.name,
        'limit_amount': sb.limitAmount,
        'priority': sb.priority,
        'icon_name': sb.iconName,
        'color_hex': sb.colorHex,
        'parent_category_id': sb.parentCategoryId, // Added
        'is_subcategory': sb.isSubcategory, // Added
        'suggested_percent': sb.suggestedPercent, // Added
        'sort_order': sb.displayOrder, // Map displayOrder to sort_order
        // CRITICAL FIX: Increment revision before push
        'revision': sb.revision + 1,
        'is_deleted': sb.isDeleted,
        'created_at': sb.createdAt.toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'last_modified_by_device_id': deviceId,
      };

      await authService.client.from('semi_budgets').upsert(data);
      
      // Mark as clean and update local revision
      await (db.update(db.semiBudgets)..where((s) => s.id.equals(sb.id)))
          .write(SemiBudgetsCompanion(
            syncState: const Value('clean'),
            revision: Value(sb.revision + 1),
          ));
      
      debugPrint('[SemiBudgetSyncManager] Synced ${sb.id} up + marked clean');
      
      // CRITICAL: After semi-budget syncs, immediately attempt to sync its dirty expenses
      // This resolves the race condition where expenses failed because semi-budget wasn't on server yet.
      final dirtyExpenses = await (db.select(db.expenses)
        ..where((e) => e.semiBudgetId.equals(sb.id))
        ..where((e) => e.syncState.equals('dirty'))).get();
      
      if (dirtyExpenses.isNotEmpty) {
        debugPrint('[SemiBudgetSyncManager] Found ${dirtyExpenses.length} pending expenses. Chaining sync...');
        
        for (final expense in dirtyExpenses) {
           try {
              final deviceId = await deviceInfoService.getDeviceId();
              final expenseData = {
                'id': expense.id,
                'budget_id': expense.budgetId,
                'semi_budget_id': expense.semiBudgetId,
                'category_id': expense.categoryId,
                'entered_by': expense.enteredBy,
                'title': expense.title,
                'amount': expense.amount,
                'currency': expense.currency,
                'date': expense.date.toIso8601String(),
                'notes': expense.notes,
                'payment_method': expense.paymentMethod,
                'account_id': expense.accountId,
                'receipt_url': expense.receiptUrl,
                'merchant_name': expense.merchantName,
                'is_recurring': expense.isRecurring,
                'recurring_id': expense.recurringId,
                'revision': expense.revision + 1,
                'is_deleted': expense.isDeleted,
                'created_at': expense.createdAt.toIso8601String(),
                'updated_at': DateTime.now().toIso8601String(),
                'last_modified_by_device_id': deviceId,
              };

              await authService.client.from('expenses').upsert(expenseData);

              await (db.update(db.expenses)..where((e) => e.id.equals(expense.id)))
                .write(ExpensesCompanion(
                  syncState: const Value('clean'),
                  revision: Value(expense.revision + 1),
                ));
              
              debugPrint('[SemiBudgetSyncManager] Chained sync success: Expense ${expense.id}');
           } catch (e) {
             debugPrint('[SemiBudgetSyncManager] Chained sync failed for ${expense.id}: $e');
           }
        }
      }

    } catch (e) {
      debugPrint('[SemiBudgetSyncManager] Failed to sync ${sb.id} up: $e');
    }
  }

  @override
  Future<void> syncDown(String id) async {
    try {
      final data = await authService.client
          .from('semi_budgets')
          .select()
          .eq('id', id)
          .maybeSingle();
      
      if (data != null) {
        await _upsertLocal(data);
        debugPrint('[SemiBudgetSyncManager] Pulled $id from server');
      }
    } catch (e) {
      debugPrint('[SemiBudgetSyncManager] Failed to sync $id down: $e');
    }
  }

  @override
  Future<int> pushChanges() async {
    final userId = authService.currentUser?.id;
    if (userId == null) return 0;

    int count = 0;
    try {
      // CRITICAL FIX: Only sync DIRTY semi-budgets
      final dirtySemiBudgets = await (db.select(db.semiBudgets)
        ..where((s) => s.syncState.equals('dirty'))).get();

      for (var sb in dirtySemiBudgets) {
        await syncUp(sb.id);
        count++;
      }
      debugPrint('[SemiBudgetSyncManager] Pushed $count semi-budgets');
    } catch (e) {
      debugPrint('[SemiBudgetSyncManager] pushChanges error: $e');
    }
    return count;
  }

  @override
  Future<int> pullChanges() async {
    final userId = authService.currentUser?.id;
    if (userId == null) return 0;

    int count = 0;
    try {
      final checkpoint = await checkpointService.getCheckpoint('semi_budgets');
      final lastSyncAt = checkpoint.lastSyncAt;
      
      // SemiBudgets don't have owner_id directly usually, they link to budgets.
      // We need to join with budgets table to filter by owner_id.
      var query = authService.client
          .from('semi_budgets')
          .select();
          // REMOVED 'budgets!inner(owner_id)' and .eq('budgets.owner_id', userId) 
          // to allow fetching semi-budgets of shared budgets via RLS
      
      // Incremental sync: only fetch changes since last sync
      if (lastSyncAt != null) {
        query = query.gt('updated_at', lastSyncAt.toIso8601String());
      }

      final remoteSemiBudgets = await query;
      
      DateTime? maxUpdated;

      for (var sb in remoteSemiBudgets) {
        final cleanSb = Map<String, dynamic>.from(sb)..remove('budgets');
        await _upsertLocal(cleanSb);
        count++;
        
        // Track latest update time
        if (cleanSb['updated_at'] != null) {
          final updatedAt = DateTime.tryParse(cleanSb['updated_at'] as String? ?? '');
          if (updatedAt != null) {
            if (maxUpdated == null || updatedAt.isAfter(maxUpdated)) {
              maxUpdated = updatedAt;
            }
          }
        }
      }
      
      // Save checkpoint if we received data
      if (maxUpdated != null) {
        await checkpointService.updateCheckpoint('semi_budgets', lastSyncAt: maxUpdated);
      }
      
      debugPrint('[SemiBudgetSyncManager] Pulled $count semi-budgets');
    } catch (e) {
      debugPrint('[SemiBudgetSyncManager] Error pulling: $e');
    }
    return count;
  }

  Future<void> _upsertLocal(Map<String, dynamic> data) async {
    // Null safety guards
    final id = data['id'] as String?;
    final budgetId = data['budget_id'] as String?;
    final name = data['name'] as String?;
    
    if (id == null || budgetId == null || name == null) {
      debugPrint('[SemiBudgetSyncManager] Missing required fields, skipping');
      return;
    }
    
    final isDeleted = data['is_deleted'] as bool? ?? false;
    
    // CRITICAL FIX: If semi-budget is marked as deleted on server, remove it locally
    // This prevents deleted categories from reappearing after app reinstall
    if (isDeleted) {
      try {
        await (db.delete(db.semiBudgets)..where((t) => t.id.equals(id))).go();
        debugPrint('[SemiBudgetSyncManager] ✅ Permanently deleted semi-budget $id (was deleted on server)');
        return;
      } catch (e) {
        debugPrint('[SemiBudgetSyncManager] ⚠️ Error deleting semi-budget $id: $e');
        return;
      }
    }
    
    // Normal insertion/update for non-deleted semi-budgets
    final companion = SemiBudgetsCompanion(
      id: Value(id),
      budgetId: Value(budgetId),
      name: Value(name),
      limitAmount: Value((data['limit_amount'] as num?)?.toInt() ?? 0),
      priority: Value((data['priority'] as num?)?.toInt() ?? 3),
      iconName: Value(data['icon_name'] as String?),
      colorHex: Value(data['color_hex'] as String?),
      revision: Value((data['revision'] as num?)?.toInt() ?? 0),
      isDeleted: const Value(false), // Never insert with isDeleted=true
      createdAt: Value(DateTime.tryParse(data['created_at'] as String? ?? '') ?? DateTime.now()),
      updatedAt: Value(DateTime.tryParse(data['updated_at'] as String? ?? '') ?? DateTime.now()),
    );
    
    try {
      await db.insertSemiBudget(companion);
    } catch (e) {
      // Use write() instead of replace() for reliable updates
      await (db.update(db.semiBudgets)..where((t) => t.id.equals(id)))
          .write(companion);
      debugPrint('[SemiBudgetSyncManager] Updated existing $id from remote');
    }
  }
}
