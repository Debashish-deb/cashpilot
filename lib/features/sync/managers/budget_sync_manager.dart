import 'dart:convert';

import 'package:cashpilot/features/sync/services/sync_checkpoint_service.dart' show SyncCheckpointService;
import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'base_sync_manager.dart';
import '../../../data/drift/app_database.dart';
import '../../../services/auth_service.dart';
import 'package:cashpilot/core/providers/sync_providers.dart';
import '../../../services/device_info_service.dart';
import '../../../services/sync/conflict_service.dart';
import '../../../services/sync/hash_service.dart';
import '../services/atomic_sync_state_service.dart';
import '../../../core/mixins/error_handler_mixin.dart';

class BudgetSyncManager with ErrorHandlerMixin implements BaseSyncManager<Budget> {
  final AppDatabase db;
  final AuthService authService;
  final SyncCheckpointService checkpointService;
  final Ref ref;
  
  late final AtomicSyncStateService _atomicState;

  BudgetSyncManager(this.db, this.authService, this.checkpointService, this.ref) {
    _atomicState = AtomicSyncStateService(db);
  }

  ConflictService get _conflictService => ref.read(conflictServiceProvider);

  @override
  Future<void> syncUp(String id) async {
    await handleAsync(
      ref,
      () async {
        final budget = await (db.select(db.budgets)..where((b) => b.id.equals(id))).getSingleOrNull();
        if (budget == null) return;

        try {
      final existing = await authService.client
          .from('budgets')
          .select('revision, updated_at')
          .eq('id', budget.id)
          .maybeSingle();

      String deviceId; 

      if (existing != null) {
        final remoteRevision = (existing['revision'] as num?)?.toInt() ?? 0;
        deviceId = await deviceInfoService.getDeviceId(); // Initialize here
        
        // PRIMARY: Revision-based detection
        if (remoteRevision > budget.revision) {
          debugPrint('[BudgetSyncManager] CONFLICT (Revision): Remote budget ${budget.id} has higher revision ($remoteRevision > ${budget.revision})');
          await _handleConflict(budget, deviceId);
          return;
        }
        
        
        final currentLocalHash = HashService.generateBudgetHash(budget);
        final storedHash = HashService.getStoredHash(budget.metadata as String?);
        
        if (storedHash != null && currentLocalHash != storedHash) {
          
          try {
            final remoteData = await authService.client
              .from('budgets')
              .select()
              .eq('id', budget.id)
              .maybeSingle();
            
            if (remoteData != null) {
              final remoteHash = _calculateHashFromRemote(remoteData);
              if (remoteHash != storedHash) {
                // Both changed - CONFLICT!
                debugPrint('[BudgetSyncManager] CONFLICT (Hash): Both local and remote changed budget ${budget.id}');
                await _handleConflict(budget, deviceId, remoteData: remoteData);
                return;
              }
            }
          } catch (e) {
            debugPrint('[BudgetSyncManager] Hash check failed: $e');
          }
        }
      } else {
        // No existing remote record, get deviceId for new insert
        deviceId = await deviceInfoService.getDeviceId(); // Initialize here
      }

      // STATE: dirty → pushing
      await _atomicState.logStateTransition(
        fromState: 'dirty',
        toState: 'pushing',
        reason: 'sync_up_started',
        context: {'entity_type': 'budget', 'entity_id': budget.id},
      );

      // Use helper for consistency
      final data = _toJsonMinimal(budget, deviceId, incrementRevision: true);

      await authService.client.from('budgets').upsert(data);
      
      // Calculate and store hash for future conflict detection
      final newHash = HashService.generateBudgetHash(budget);
      final updatedMetadata = HashService.setStoredHash(budget.metadata as String?, newHash);
      final metadataMap = json.decode(updatedMetadata) as Map<String, dynamic>;
      
      // Mark as clean and update local revision after successful upload
      // Note: We incremented revision in the payload, so local needs to match
      await (db.update(db.budgets)..where((b) => b.id.equals(budget.id)))
          .write(BudgetsCompanion(
            syncState: const Value('clean'),
            revision: Value(budget.revision + 1),
            metadata: Value(metadataMap),
          ));
      
      // STATE: pushing → clean
      await _atomicState.logStateTransition(
        fromState: 'pushing',
        toState: 'clean',
        reason: 'sync_up_success',
        context: {'entity_type': 'budget', 'entity_id': budget.id},
      );
      
      debugPrint('[BudgetSyncManager] Synced budget ${budget.id} up + marked clean${budget.isDeleted ? ' (DELETED)' : ''}');
      
      // CRITICAL: After budget syncs, immediately attempt to sync its dirty semi-budgets
      // This resolves the race condition where semi-budgets failed because budget wasn't on server yet.
      final dirtySemiBudgets = await (db.select(db.semiBudgets)
        ..where((s) => s.budgetId.equals(budget.id))
        ..where((s) => s.syncState.equals('dirty'))).get();
      
      if (dirtySemiBudgets.isNotEmpty) {
        debugPrint('[BudgetSyncManager] Found ${dirtySemiBudgets.length} pending semi-budgets. Chaining sync...');
        
        for (final sb in dirtySemiBudgets) {
           try {
              // 1. Check if we have the necessary fields (semi_budgets check)
              // We manually upsert here to ensure immediate consistency
              final deviceId = await deviceInfoService.getDeviceId();
              final sbData = {
                'id': sb.id,
                'budget_id': sb.budgetId,
                'name': sb.name,
                'limit_amount': sb.limitAmount,
                'priority': sb.priority,
                'icon_name': sb.iconName,
                'color_hex': sb.colorHex,
                'parent_category_id': sb.parentCategoryId,
                'is_subcategory': sb.isSubcategory,
                'suggested_percent': sb.suggestedPercent,
                'display_order': sb.displayOrder,
                'revision': sb.revision + 1,
                'is_deleted': sb.isDeleted,
                'created_at': sb.createdAt.toIso8601String(),
                'updated_at': DateTime.now().toIso8601String(),
                'last_modified_by_device_id': deviceId,
              };

              await authService.client.from('semi_budgets').upsert(sbData);

              await (db.update(db.semiBudgets)..where((s) => s.id.equals(sb.id)))
                .write(SemiBudgetsCompanion(
                  syncState: const Value('clean'),
                  revision: Value(sb.revision + 1),
                ));
              
              debugPrint('[BudgetSyncManager] Chained sync success: Semi-Budget ${sb.id}');
           } catch (e) {
             debugPrint('[BudgetSyncManager] Chained sync failed for ${sb.id}: $e');
             // It stays dirty, will be picked up by next Batch Sync
           }
        }
      }
    } catch (e) {
      // STATE: pushing → failed
      await _atomicState.logStateTransition(
        fromState: 'pushing',
        toState: 'failed',
        reason: 'sync_up_error: $e',
        context: {'entity_type': 'budget', 'entity_id': budget.id},
      );
      debugPrint('[BudgetSyncManager] Failed to sync budget ${budget.id} up: $e');
    }
      },
      errorMessage: 'Failed to sync budget',
      showToUser: false, // Don't spam user with individual sync errors
    );
  }

  /// Convert to JSON respecting Schema V7
  Map<String, dynamic> _toJsonMinimal(Budget budget, String deviceId, {bool incrementRevision = false}) {
      return {
        'id': budget.id,
        'owner_id': budget.ownerId,
        'title': budget.title,
        'description': budget.description,
        'type': budget.type,
        'start_date': budget.startDate.toIso8601String(),
        'end_date': budget.endDate.toIso8601String(),
        'currency': budget.currency,
        'total_limit': budget.totalLimit,
        'is_shared': budget.isShared,
        'is_template': budget.isTemplate,
        'status': budget.status,
        'icon_name': budget.iconName,
        'color_hex': budget.colorHex,
        'notes': budget.notes,
        'tags': budget.tags,
        // Increment revision if requested (for push)
        'revision': incrementRevision ? budget.revision + 1 : budget.revision,
        'is_deleted': budget.isDeleted,
        'sync_state': 'clean',
        'global_seq': budget.globalSeq,
        'created_at': budget.createdAt.toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'last_modified_by_device_id': deviceId,
      };
  }

  @override
  Future<void> syncDown(String id) async {
    try {
      final data = await authService.client
          .from('budgets')
          .select()
          .eq('id', id)
          .maybeSingle();
      
      if (data != null) {
        await _upsertLocal(data); // Reuse robust upsert
        debugPrint('[BudgetSyncManager] Pulled budget $id from server');
      }
    } catch (e) {
      debugPrint('[BudgetSyncManager] Failed to sync budget $id down: $e');
    }
  }

  @override
  Future<int> pushChanges() async {
    final userId = authService.currentUser?.id;
    if (userId == null) return 0;

    int count = 0;
    try {
      // CRITICAL FIX: Only sync DIRTY budgets, not all
      final dirtyBudgets = await (db.select(db.budgets)
        ..where((b) => b.syncState.equals('dirty'))).get();

      for (var budget in dirtyBudgets) {
        await syncUp(budget.id);
        count++;
      }
      debugPrint('[BudgetSyncManager] Budget sync: Pushed $count budgets');
    } catch (e) {
      debugPrint('[BudgetSyncManager] Budget pushChanges error: $e');
    }
    return count;
  }

  @override
  Future<int> pullChanges() async {
    final userId = authService.currentUser?.id;
    if (userId == null) return 0;

    int count = 0;
    try {
      final checkpoint = await checkpointService.getCheckpoint('budgets');
      final lastSyncAt = checkpoint.lastSyncAt;
      
      var query = authService.client
          .from('budgets')
          .select();
          // REMOVED .eq('is_deleted', false) to allow pulling deletion tombstones
          // REMOVED .eq('owner_id', userId) to allow fetching shared budgets via RLS
      
      // Incremental sync: only fetch changes since last sync
      if (lastSyncAt != null) {
        query = query.gt('updated_at', lastSyncAt.toIso8601String());
      }

      final remoteBudgets = await query;
      
      DateTime? maxUpdated;

      for (var data in remoteBudgets) {
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
        await checkpointService.updateCheckpoint('budgets', lastSyncAt: maxUpdated);
      }
      
      debugPrint('[BudgetSyncManager] Budget sync: Pulled $count budgets');
    } catch (e) {
      debugPrint('Error pulling budgets: $e');
    }
    return count;
  }

  Future<void> _upsertLocal(Map<String, dynamic> data) async {
    final budgetId = data['id'] as String;
    final isDeleted = data['is_deleted'] as bool? ?? false;
    
    // CRITICAL FIX: If budget is marked as deleted on server, remove it locally
    // This prevents deleted budgets from reappearing after app reinstall
    if (isDeleted) {
      try {
        await (db.delete(db.budgets)..where((t) => t.id.equals(budgetId))).go();
        debugPrint('[BudgetSyncManager] ✅ Permanently deleted budget $budgetId (was deleted on server)');
        return;
      } catch (e) {
        debugPrint('[BudgetSyncManager] ⚠️ Error deleting budget $budgetId: $e');
        return;
      }
    }
    
    // Normal insertion/update for non-deleted budgets
    final companion = BudgetsCompanion(
      id: Value(budgetId),
      ownerId: Value(data['owner_id'] as String),
      title: Value(data['title'] as String),
      description: Value(data['description'] as String?),
      type: Value(data['type'] as String),
      startDate: Value(DateTime.tryParse(data['start_date'] as String? ?? '') ?? DateTime.now()),
      endDate: Value(DateTime.tryParse(data['end_date'] as String? ?? '') ?? DateTime.now().add(const Duration(days: 30))),
      currency: Value(data['currency'] as String? ?? 'EUR'),
      totalLimit: Value((data['total_limit'] as num?)?.toInt()),
      isShared: Value(data['is_shared'] as bool? ?? false),
      isTemplate: Value(data['is_template'] as bool? ?? false),
      status: Value(data['status'] as String? ?? 'active'),
      iconName: Value(data['icon_name'] as String?),
      colorHex: Value(data['color_hex'] as String?),
      notes: Value(data['notes'] as String?),
      tags: Value(data['tags'] as String?),
      revision: Value((data['revision'] as num? ?? 0).toInt()),
      isDeleted: const Value(false), // Never insert with isDeleted=true
      syncState: Value(data['sync_state'] as String? ?? 'clean'),
      globalSeq: Value((data['global_seq'] as num?)?.toInt()),
      createdAt: Value(DateTime.tryParse(data['created_at'] as String? ?? '') ?? DateTime.now()),
      updatedAt: Value(DateTime.tryParse(data['updated_at'] as String? ?? '') ?? DateTime.now()),
    );
    
    try {
      await db.insertBudget(companion);
      debugPrint('[BudgetSyncManager] Inserted new budget $budgetId');
    } catch (e) {
      // Use write() instead of replace() to update ALL fields reliably
      await (db.update(db.budgets)..where((t) => t.id.equals(budgetId)))
          .write(companion);
      debugPrint('[BudgetSyncManager] Updated existing budget $budgetId from remote');
    }
  }

  /// Handle conflict detection by persisting conflict and marking local item
  Future<void> _handleConflict(Budget budget, String deviceId, {Map<String, dynamic>? remoteData}) async {
    // Fetch full remote data if not provided
    if (remoteData == null) {
      try {
        remoteData = await authService.client
          .from('budgets')
          .select()
          .eq('id',budget.id)
          .maybeSingle();
      } catch (e) {
        debugPrint('[BudgetSyncManager] Failed to fetch remote for conflict: $e');
        remoteData = {};
      }
    }

    // Persist conflict record
    await _conflictService.createConflict(
      entityType: ConflictEntityType.budget,
      entityId: budget.id,
      localData: _toJsonMinimal(budget, deviceId),
      remoteData: remoteData ?? {},
      deviceId: deviceId,
    );

    // Mark local as conflict (STOP SYNC)
    await (db.update(db.budgets)..where((b) => b.id.equals(budget.id)))
        .write(const BudgetsCompanion(syncState: Value('conflict')));
    
    debugPrint('[BudgetSyncManager] Budget ${budget.id} marked as conflict. Push aborted.');
  }

  /// Calculate hash from remote budget data
  String _calculateHashFromRemote(Map<String, dynamic> data) {
    // Create a temporary Budget object to reuse hash logic
    final tempBudget = Budget(
      id: data['id'] as String,
      ownerId: data['owner_id'] as String,
      title: data['title'] as String,
      description: data['description'] as String?,
      type: data['type'] as String,
      startDate: DateTime.tryParse(data['start_date'] as String? ?? '') ?? DateTime.now(),
      endDate: DateTime.tryParse(data['end_date'] as String? ?? '') ?? DateTime.now(),
      currency: data['currency'] as String? ?? 'EUR',
      totalLimit: (data['total_limit'] as num?)?.toInt(),
      isShared: data['is_shared'] as bool? ?? false,
      isTemplate: data['is_template'] as bool? ?? false,
      status: data['status'] as String? ?? 'active',
      iconName: data['icon_name'] as String?,
      colorHex: data['color_hex'] as String?,
      notes: data['notes'] as String?,
      tags: data['tags'] as String?,
      revision: (data['revision'] as num? ?? 0).toInt(),
      isDeleted: data['is_deleted'] as bool? ?? false,
      syncState: data['sync_state'] as String? ?? 'clean',
      globalSeq: (data['global_seq'] as num?)?.toInt(),
      createdAt: DateTime.tryParse(data['created_at'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(data['updated_at'] as String? ?? '') ?? DateTime.now(),
      lastModifiedByDeviceId: data['last_modified_by_device_id'] as String?,
      metadata: data['metadata'] as Map<String, dynamic>?, lamportClock: 0,
    );
    
    return HashService.generateBudgetHash(tempBudget);
  }
}
