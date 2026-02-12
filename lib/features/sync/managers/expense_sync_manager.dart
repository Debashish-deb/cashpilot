import 'dart:convert';

import 'package:cashpilot/features/sync/services/sync_checkpoint_service.dart' show SyncCheckpointService;
import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'base_sync_manager.dart';
import '../../../data/drift/app_database.dart';
import '../../../services/auth_service.dart';
import '../../../services/device_info_service.dart';
import '../../../services/sync/conflict_service.dart';
import '../../../services/sync/hash_service.dart';
import '../services/atomic_sync_state_service.dart'; // NEW: For state tracking
import 'package:cashpilot/core/providers/sync_providers.dart';
import '../../../core/mixins/error_handler_mixin.dart';

class ExpenseSyncManager with ErrorHandlerMixin implements BaseSyncManager<Expense> {
  final AppDatabase db;
  final AuthService authService;
  final SyncCheckpointService checkpointService;
  final Ref ref;
  
  // Atomic state tracking
  late final AtomicSyncStateService _atomicState;

  ExpenseSyncManager(this.db, this.authService, this.checkpointService, this.ref) {
    _atomicState = AtomicSyncStateService(db);
  }

  ConflictService get _conflictService => ref.read(conflictServiceProvider);

  @override
  Future<void> syncUp(String id) async {
    final expense = await (db.select(db.expenses)..where((e) => e.id.equals(id))).getSingleOrNull();
    if (expense == null) return;

    try {
      // Check if semi_budget exists - if not, stay dirty for batch sync
      if (expense.semiBudgetId != null) {
        final remoteSemiBudget = await authService.client
            .from('semi_budgets')
            .select('id')
            .eq('id', expense.semiBudgetId!)
            .maybeSingle();
        
        if (remoteSemiBudget == null) {
          debugPrint('[ExpenseSyncManager] Semi-budget ${expense.semiBudgetId} not on server, keeping expense $id dirty');
          return; // Stay dirty - batch sync will handle it
        }
      }

      // Check remote revision first
      final existing = await authService.client
          .from('expenses')
          .select('revision, updated_at')
          .eq('id', expense.id)
          .maybeSingle();
      
      // CONFLICT DETECTION: Check revision and hash to prevent overwriting newer data
      if (existing != null) {
        final remoteRevision = (existing['revision'] as num?)?.toInt() ?? 0;
        final deviceId = await deviceInfoService.getDeviceId();
        
        // PRIMARY: Revision-based detection
        if (remoteRevision > expense.revision) {
          debugPrint('[ExpenseSyncManager] CONFLICT (Revision): Remote expense ${expense.id} has higher revision ($remoteRevision > ${expense.revision})');
          await _handleConflict(expense, deviceId);
          return;
        }
        
        // SECONDARY: Hash-based detection (for offline scenarios)
        final currentLocalHash = HashService.generateExpenseHash(expense);
        final storedHash = HashService.getStoredHash(expense.metadata as String?);
        
        if (storedHash != null && currentLocalHash != storedHash) {
          // Local changed since last sync - check remote
          try {
            final remoteData = await authService.client
              .from('expenses')
              .select()
              .eq('id', expense.id)
              .maybeSingle();
            
            if (remoteData != null) {
              final remoteHash = _calculateHashFromRemote(remoteData);
              if (remoteHash != storedHash) {
                // Both changed - CONFLICT!
                debugPrint('[ExpenseSyncManager] CONFLICT (Hash): Both local and remote changed expense ${expense.id}');
                await _handleConflict(expense, deviceId, remoteData: remoteData);
                return;
              }
            }
          } catch (e) {
            debugPrint('[ExpenseSyncManager] Hash check failed: $e');
          }
        }
      }
      
      final deviceId = await deviceInfoService.getDeviceId();

      // STATE: dirty → pushing
      await _atomicState.logStateTransition(
        fromState: 'dirty',
        toState: 'pushing',
        reason: 'sync_up_started',
        context: {'entity_type': 'expense', 'entity_id': expense.id},
      );

      // Increment revision before upload to prevent future conflicts
      final data = _toJsonMinimal(expense, deviceId, incrementRevision: true);
      
      await authService.client.from('expenses').upsert(data);
      
      // Calculate and store hash for future conflict detection
      final newHash = HashService.generateExpenseHash(expense);
      final updatedMetadata = HashService.setStoredHash(expense.metadata as String?, newHash);
      final metadataMap = json.decode(updatedMetadata) as Map<String, dynamic>;
      
      // Mark as clean after successful upload
      // Update local revision to match what we just pushed
      await (db.update(db.expenses)..where((e) => e.id.equals(id)))
          .write(ExpensesCompanion(
            syncState: const Value('clean'),
            revision: Value(expense.revision + 1),
            metadata: Value(metadataMap),
          ));
      
      // STATE: pushing → clean
      await _atomicState.logStateTransition(
        fromState: 'pushing',
        toState: 'clean',
        reason: 'sync_up_success',
        context: {'entity_type': 'expense', 'entity_id': expense.id},
      );
      
      debugPrint('[ExpenseSyncManager] Synced expense ${expense.id} up + marked clean');
    } catch (e) {
      // STATE: pushing → failed
      await _atomicState.logStateTransition(
        fromState: 'pushing',
        toState: 'failed',
        reason: 'sync_up_error: $e',
        context: {'entity_type': 'expense', 'entity_id': id},
      );
      debugPrint('[ExpenseSyncManager] Failed to sync expense ${expense.id} up: $e');
    }
  }

  @override
  Future<void> syncDown(String id) async {
    try {
      final data = await authService.client
          .from('expenses')
          .select()
          .eq('id', id)
          .maybeSingle();

      if (data != null) {
        await _upsertLocal(data);
        debugPrint('[ExpenseSyncManager] Synced expense $id down');
      }
    } catch (e) {
      debugPrint('[ExpenseSyncManager] Failed to sync expense $id down: $e');
    }
  }

  @override
  Future<int> pushChanges() async {
    debugPrint('[ExpenseSyncManager] pushChanges() called');
    final userId = authService.currentUser?.id;
    if (userId == null) {
      debugPrint('[ExpenseSyncManager] Cannot push expenses: No user ID');
      return 0;
    }

    debugPrint('[ExpenseSyncManager] Pushing expenses for user: $userId');
    
    // CRITICAL FIX: Only push DIRTY expenses, not all
    final dirtyExpenses = await (db.select(db.expenses)
      ..where((e) => e.syncState.equals('dirty'))).get();
    
    debugPrint('[ExpenseSyncManager] Found ${dirtyExpenses.length} dirty expenses to push');
    if (dirtyExpenses.isEmpty) return 0;

    int count = 0;
    
    // NOTE: Granular push via syncUp is safer for conflicts than batched push without checks
    // But since this loop calls syncUp which now has conflict checks, it is SAFE.
    for (var expense in dirtyExpenses) {
       await syncUp(expense.id);
       count++;
    }
    
    debugPrint('[ExpenseSyncManager] Synced $count expenses up');
    return count;
  }
  
  /// Convert expense to JSON with MINIMAL fields (avoids trigger issues)
  /// incrementRevision: Set true when pushing to increment revision for conflict prevention
  Map<String, dynamic> _toJsonMinimal(Expense expense, String deviceId, {bool incrementRevision = false}) {
    return {
      'id': expense.id,
      'budget_id': expense.budgetId,
      'semi_budget_id': expense.semiBudgetId,
      'category_id': expense.categoryId,
      'sub_category_id': expense.subCategoryId,
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
      // Skip: attachments, tags, metadata, location - they cause trigger errors
      'is_recurring': expense.isRecurring,
      'recurring_id': expense.recurringId,
      // CRITICAL FIX: Increment revision on push to prevent overwrite conflicts
      'revision': incrementRevision ? expense.revision + 1 : expense.revision,
      'is_deleted': expense.isDeleted,
      'created_at': expense.createdAt.toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
      'last_modified_by_device_id': deviceId,
    };
  }

  @override
  Future<int> pullChanges() async {
    final userId = authService.currentUser?.id;
    if (userId == null) {
      debugPrint('[ExpenseSyncManager] Cannot pull expenses: No user ID');
      return 0;
    }

    debugPrint('[ExpenseSyncManager] Pulling expenses for user: $userId');
    int count = 0;
    try {
      final checkpoint = await checkpointService.getCheckpoint('expenses');
      final lastSyncAt = checkpoint.lastSyncAt;
      debugPrint('[ExpenseSyncManager] Last sync timestamp: ${lastSyncAt ?? "never"}');
      
      var query = authService.client
          .from('expenses')
          .select();
          // REMOVED .eq('entered_by', userId) to allow fetching shared expenses via RLS
      
      // Check if local DB is empty (fresh install)
      final localCount = await db.select(db.expenses).get();
      final isFreshInstall = localCount.isEmpty;
      
      if (isFreshInstall) {
        debugPrint('[ExpenseSyncManager] Fresh install detected - fetching ALL expenses');
        // Don't apply timestamp filter on fresh install
      } else if (lastSyncAt != null) {
        // FIXED: Use gte (>=) instead of gt (>) to include boundary timestamp
        query = query.gte('updated_at', lastSyncAt.toIso8601String());
        debugPrint('[ExpenseSyncManager] Fetching only changes since $lastSyncAt');
      }
      
      debugPrint('[ExpenseSyncManager] Fetching expenses from Supabase...');
      
      final remoteExpenses = await query;
      debugPrint('[ExpenseSyncManager] Received ${remoteExpenses.length} expenses from server');
      
      DateTime? maxUpdated;

      // Drift batch insert could be used here too, but simple loop is safer for logic
      for (var data in remoteExpenses) {
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
      
      // ALWAYS save checkpoint after sync attempt to prevent infinite retries
      if (maxUpdated != null) {
        await checkpointService.updateCheckpoint('expenses', lastSyncAt: maxUpdated);
        debugPrint('[ExpenseSyncManager] Pulled $count expenses successfully');
      } else {
        // Even if no expenses, save current time to prevent re-querying
        await checkpointService.updateCheckpoint('expenses', lastSyncAt: DateTime.now());
        debugPrint('[ExpenseSyncManager] No new expenses to pull - checkpoint saved');
      }
      
    } catch (e, stackTrace) {
      debugPrint('[ExpenseSyncManager] Error pulling expenses: $e');
      debugPrint('Stack trace: $stackTrace');
    }
    return count;
  }

  Future<void> _upsertLocal(Map<String, dynamic> data) async {
    final expenseId = data['id'] as String;
    final isDeleted = data['is_deleted'] as bool? ?? false;
    
    // CRITICAL FIX: If expense is marked as deleted on server, remove it locally
    // This prevents deleted expenses from reappearing after app reinstall
    if (isDeleted) {
      try {
        await (db.delete(db.expenses)..where((t) => t.id.equals(expenseId))).go();
        debugPrint('[ExpenseSyncManager] ✅ Permanently deleted expense $expenseId (was deleted on server)');
        return;
      } catch (e) {
        debugPrint('[ExpenseSyncManager] ⚠️ Error deleting expense $expenseId: $e');
        return;
      }
    }
    
    // Normal insertion/update for non-deleted expenses
    final companion = ExpensesCompanion(
      id: Value(expenseId),
      budgetId: Value(data['budget_id'] as String),
      semiBudgetId: Value(data['semi_budget_id'] as String?),
      categoryId: Value(data['category_id'] as String?),
      subCategoryId: Value(data['sub_category_id'] as String?),
      enteredBy: Value(data['entered_by'] as String),
      title: Value(data['title'] as String),
      amount: Value((data['amount'] as num).toInt()),
      currency: Value(data['currency'] as String? ?? 'EUR'),
      date: Value(DateTime.tryParse(data['date'] as String? ?? '') ?? DateTime.now()),
      notes: Value(data['notes'] as String?),
      paymentMethod: Value(data['payment_method'] as String? ?? 'cash'),
      accountId: Value(data['account_id'] as String?),
      receiptUrl: Value(data['receipt_url'] as String?),
      barcodeValue: Value(data['barcode_value'] as String?),
      ocrText: Value(data['ocr_text'] as String?),
      merchantName: Value(data['merchant_name'] as String?),
      attachments: Value(
        data['attachments'] != null 
          ? (data['attachments'] is String 
              ? data['attachments'] as String
              : jsonEncode(data['attachments']))
          : null
      ),
      locationName: Value(
        data['location_name'] != null 
          ? (data['location_name'] is String 
              ? data['location_name'] as String
              : jsonEncode(data['location_name']))
          : null
      ),
      tags: Value(
        data['tags'] != null 
          ? (data['tags'] is String 
              ? data['tags'] as String
              : jsonEncode(data['tags']))
          : null
      ),
      // Skip metadata for now to avoid type conversion issues
      isRecurring: Value(data['is_recurring'] as bool? ?? false),
      recurringId: Value(data['recurring_id'] as String?),
      revision: Value((data['revision'] as num? ?? 0).toInt()),
      isDeleted: const Value(false), // Never insert with isDeleted=true
      syncState: Value(data['sync_state'] as String? ?? 'clean'),
      globalSeq: Value((data['global_seq'] as num?)?.toInt()),
      createdAt: Value(DateTime.tryParse(data['created_at'] as String? ?? '') ?? DateTime.now()),
      updatedAt: Value(DateTime.tryParse(data['updated_at'] as String? ?? '') ?? DateTime.now()),
    );
    
    try {
      await db.insertExpense(companion);
    } catch (e) {
      // If insert fails (exists), update with ALL fields to ensure complete sync
      // Use write() instead of replace() to update only specified fields
      await (db.update(db.expenses)..where((t) => t.id.equals(expenseId)))
          .write(companion);
      debugPrint('[ExpenseSyncManager] Updated existing expense $expenseId from remote');
    }
  }



  /// Handle conflict by persisting and marking local item
  Future<void> _handleConflict(Expense expense, String deviceId, {Map<String, dynamic>? remoteData}) async {
    // Fetch full remote data if not provided
    if (remoteData == null) {
      try {
        remoteData = await authService.client
          .from('expenses')
          .select()
          .eq('id', expense.id)
          .maybeSingle();
      } catch (e) {
        debugPrint('[ExpenseSyncManager] Failed to fetch remote for conflict: $e');
        remoteData = {};
      }
    }

    // Persist conflict record
    await _conflictService.createConflict(
      entityType: ConflictEntityType.expense,
      entityId: expense.id,
      localData: _toJsonMinimal(expense, deviceId),
      remoteData: remoteData ?? {},
      deviceId: deviceId,
    );

    // Mark local as conflict
    await (db.update(db.expenses)..where((e) => e.id.equals(expense.id)))
        .write(const ExpensesCompanion(syncState: Value('conflict')));
    
    debugPrint('[ExpenseSyncManager] Expense ${expense.id} marked as conflict. Push aborted.');
  }

  /// Calculate hash from remote expense data
  String _calculateHashFromRemote(Map<String, dynamic> data) {
    final tempExpense = Expense(
      id: data['id'] as String,
      budgetId: data['budget_id'] as String,
      semiBudgetId: data['semi_budget_id'] as String?,
      categoryId: data['category_id'] as String?,
      subCategoryId: data['sub_category_id'] as String?,
      enteredBy: data['entered_by'] as String,
      title: data['title'] as String,
      amount: (data['amount'] as num).toInt(),
      currency: data['currency'] as String? ?? 'EUR',
      date: DateTime.tryParse(data['date'] as String? ?? '') ?? DateTime.now(),
      accountId: data['account_id'] as String?,
      merchantName: data['merchant_name'] as String?,
      paymentMethod: data['payment_method'] as String? ?? 'cash',
      receiptUrl: data['receipt_url'] as String?,
      barcodeValue: data['barcode_value'] as String?,
      ocrText: data['ocr_text'] as String?,
      attachments: data['attachments'] as String?,
      notes: data['notes'] as String?,
      locationName: data['location_name'] as String?,
      tags: data['tags'] as String?,
      isRecurring: data['is_recurring'] as bool? ?? false,
      recurringId: data['recurring_id'] as String?,
      metadata: data['metadata'] as Map<String, dynamic>?,
      revision: (data['revision'] as num? ?? 0).toInt(),
      isDeleted: data['is_deleted'] as bool? ?? false,
      syncState: data['sync_state'] as String? ?? 'clean',
      globalSeq: (data['global_seq'] as num?)?.toInt(),
      createdAt: DateTime.tryParse(data['created_at'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(data['updated_at'] as String? ?? '') ?? DateTime.now(),
      lastModifiedByDeviceId: data['last_modified_by_device_id'] as String?,
      confidence: (data['confidence'] as num? ?? 1.0).toDouble(),
      source: data['source'] as String? ?? 'manual',
      isAiAssigned: data['is_ai_assigned'] as bool? ?? false,
      isVerified: data['is_verified'] as bool? ?? true, lamportClock: 0,
    );
    
    return HashService.generateExpenseHash(tempExpense);
  }
}
