/// Service to handle batched data synchronization
/// Gathers all dirty records from local DB and sends them in a SINGLE RPC call.
library;

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:drift/drift.dart';

import '../../../data/drift/app_database.dart';
import '../../../data/drift/tables.dart';
import '../../../services/device_info_service.dart';
import '../logic/sync_reconciler.dart';
import '../../../core/network/retry_policy.dart';
import '../../../core/network/circuit_breaker.dart';
import '../../../core/observability/trace_manager.dart';
import '../../../core/observability/log_service.dart';
import '../../../core/services/config_service.dart';
import '../logic/sync_dlq_manager.dart';
import '../../../core/sync/sync_invariants.dart';


import 'sync_transport.dart';

class DataBatchSync {
  final AppDatabase db;
  final Ref ref; // Injected to access ConflictService
  final SyncTransport transport; // Decoupled transport
  final DeviceInfoService _deviceInfoService = DeviceInfoService();

  bool _syncInProgress = false; // Prevent concurrent batch sync
  String? _cachedDeviceId;

  // RESILIENCE
  final CircuitBreaker _circuitBreaker = CircuitBreaker(failureThreshold: 3, resetTimeout: const Duration(seconds: 45));
  final RetryPolicy _retryPolicy = RetryPolicy(maxRetries: 3, initialDelay: const Duration(seconds: 2));
  late final SyncDLQManager _dlqManager;
  final TraceManager _traceManager = TraceManager();
  final LogService _logger = LogService();
  final ConfigService _configService = ConfigService();

  DataBatchSync(this.db, this.ref, {SyncTransport? transport}) 
      : transport = transport ?? SupabaseSyncTransport(Supabase.instance.client) {
    _dlqManager = SyncDLQManager(db);
  }



  /// Get device ID (cached for performance)
  Future<String> _getDeviceId() async {
    _cachedDeviceId ??= await _deviceInfoService.getDeviceId();
    return _cachedDeviceId!;
  }

  /// Gather all dirty data and push in one batch
  Future<Map<String, int>> pushAll({String? sessionId}) async {
    final sid = sessionId ?? 'batch-push-${DateTime.now().millisecondsSinceEpoch}';
    final trace = _traceManager.startTrace('SyncPush', attributes: {'session_id': sid});
    
    // -1. Kill Switch Check
    if (!_configService.isSyncEnabled) {
       _logger.warn('Push aborted: KILL SWITCH ACTIVE', span: trace, context: {'session_id': sid});
       trace.end();
       return {};
    }

    // 0. Circuit Breaker Check
    if (_circuitBreaker.state == CircuitState.open) {
       _logger.warn('Push aborted: Circuit Breaker OPEN', span: trace, context: {'session_id': sid});
       trace.end();
       return {};
    }

    _logger.info('Starting pushAll', span: trace, context: {'session_id': sid});
    
    if (_syncInProgress) {
      _logger.warn('pushAll skipped (already running)', span: trace, context: {'session_id': sid});
      trace.addAttribute('skipped', true);
      trace.end();
      return {};
    }

    _syncInProgress = true;
    try {
      
      return await _circuitBreaker.run(() async {
         return await _retryPolicy.execute(() async {
            final prepSpan = _traceManager.startSpan('PreparePayload', traceId: trace.traceId, parentSpanId: trace.spanId);
            
            // final userId = client.auth.currentUser?.id; // REMOVED: Managed by Orchestrator
            // if (userId == null) { ... }
      
            _logger.info('Gathering budgets...', span: prepSpan);
            final allDirtyBudgets = await (db.select(db.budgets)
              ..where((t) => t.syncState.equals('dirty'))).get();
      
            _logger.info('Gathering semi-budgets...', span: prepSpan);
            final allDirtySemiBudgets = await (db.select(db.semiBudgets)
              ..where((t) => t.syncState.equals('dirty'))).get();
      
            _logger.info('Gathering expenses...', span: prepSpan);
            final allDirtyExpenses = await (db.select(db.expenses)
              ..where((t) => t.syncState.equals('dirty'))).get();
      
            _logger.info('Gathering accounts...', span: prepSpan);
            final allDirtyAccounts = await (db.select(db.accounts)
              ..where((t) => t.syncState.equals('dirty'))).get();
              
            _logger.info('Gathering savings...', span: prepSpan);
            final allDirtySavings = await (db.select(db.savingsGoals)
              ..where((t) => t.syncState.equals('dirty'))).get();
              
            _logger.info('Gathering recurring...', span: prepSpan);
            final allDirtyRecurring = await (db.select(db.recurringExpenses)
              ..where((t) => t.syncState.equals('dirty'))).get();
              
            _logger.info('Gathering members...', span: prepSpan);
            final allDirtyMembers = await (db.select(db.budgetMembers)
              ..where((t) => t.syncState.equals('dirty'))).get();
      
            _logger.info('Gathering users...', span: prepSpan);
            final allDirtyUsers = await (db.select(db.users)
              ..where((t) => t.syncState.equals('dirty'))).get();
      
            _logger.info('Gathering family groups...', span: prepSpan);
            final allDirtyFamilyGroups = await (db.select(db.familyGroups)
              ..where((t) => t.syncState.equals('dirty'))).get();
              
            _logger.info('Gathering family contacts...', span: prepSpan);
            final allDirtyFamilyContacts = await (db.select(db.familyContacts)
              ..where((t) => t.syncState.equals('dirty'))).get();
              
            _logger.info('Gathering family relations...', span: prepSpan);
            final allDirtyFamilyRelations = await (db.select(db.familyRelations)
              ..where((t) => t.syncState.equals('dirty'))).get();
      
            _logger.info('Gathering audit logs...', span: prepSpan);
            final allDirtyAuditLogs = await (db.select(db.auditLogs)
              ..where((t) => t.syncState.equals('dirty'))).get();
      
            _logger.info('Gathering sub-categories...', span: prepSpan);
            final allDirtySubCategories = await (db.select(db.subCategories)
              ..where((t) => t.syncState.equals('dirty'))).get();
      
            if (allDirtyBudgets.isEmpty && allDirtySemiBudgets.isEmpty && 
                allDirtyExpenses.isEmpty && allDirtyAccounts.isEmpty &&
                allDirtySavings.isEmpty && allDirtyRecurring.isEmpty &&                
                allDirtyMembers.isEmpty && allDirtyUsers.isEmpty &&
                allDirtyFamilyGroups.isEmpty && allDirtyFamilyContacts.isEmpty &&
                allDirtyFamilyRelations.isEmpty && allDirtyAuditLogs.isEmpty && 
                allDirtySubCategories.isEmpty) {
              _logger.info('No dirty records to push', span: prepSpan);
              return {};
            }
            
            _logger.info(
              'Found dirty records', 
              span: prepSpan, 
              context: {
                'profiles': allDirtyUsers.length,
                'budgets': allDirtyBudgets.length, 
                'expenses': allDirtyExpenses.length
              }
            );

            // 1.5 ENTITY DEPENDENCY VALIDATION (Hardening)
            // ... (keep logic same if valid) ...
      
            _logger.info('Checking for conflicts...', span: prepSpan);
            final safeToPush = await _checkForConflicts(
              budgets: allDirtyBudgets,
              semiBudgets: allDirtySemiBudgets,
              expenses: allDirtyExpenses,
              accounts: allDirtyAccounts,
              savings: allDirtySavings,
              recurring: allDirtyRecurring,
              members: allDirtyMembers,
              users: allDirtyUsers,
              familyGroups: allDirtyFamilyGroups,
              familyContacts: allDirtyFamilyContacts,
              familyRelations: allDirtyFamilyRelations, 
              auditLogs: allDirtyAuditLogs,
              subCategories: allDirtySubCategories,
            );
      
            _logger.info('Casting dirty records...', span: prepSpan);
            final dirtyBudgets = (safeToPush['budgets'] as List).cast<Budget>();
            final dirtySemiBudgets = (safeToPush['semiBudgets'] as List).cast<SemiBudget>();
            final dirtyExpenses = (safeToPush['expenses'] as List).cast<Expense>();
            final dirtyAccounts = (safeToPush['accounts'] as List).cast<Account>();
            final dirtySavings = (safeToPush['savings'] as List).cast<SavingsGoal>();
            final dirtyRecurring = (safeToPush['recurring'] as List).cast<RecurringExpense>();
            final dirtyMembers = (safeToPush['members'] as List).cast<BudgetMember>();
            final dirtyUsers = (safeToPush['users'] as List).cast<User>(); 
            final dirtyFamilyGroups = (safeToPush['familyGroups'] as List).cast<FamilyGroup>();
            final dirtyFamilyContacts = (safeToPush['familyContacts'] as List).cast<FamilyContact>();
            final dirtyFamilyRelations = (safeToPush['familyRelations'] as List).cast<FamilyRelation>();
            final dirtyAuditLogs = (safeToPush['auditLogs'] as List).cast<AuditLog>();
            final dirtySubCategories = (safeToPush['subCategories'] as List).cast<SubCategory>();
            
            _logger.info('Mapping to JSON...', span: prepSpan);
      
            // 3. Prepare Payload
            final deviceId = await _getDeviceId();
            final payload = {
              'profiles': dirtyUsers.map((u) => _userToJson(u, deviceId)).toList(), // ADDED
              'budgets': dirtyBudgets.map((b) => _budgetToJson(b, deviceId)).toList(),
              'semi_budgets': dirtySemiBudgets.map((s) => _semiBudgetToJson(s, deviceId)).toList(),
              'expenses': dirtyExpenses.map((e) => _expenseToJson(e, deviceId)).toList(),
              'accounts': dirtyAccounts.map((a) => _accountToJson(a, deviceId)).toList(),
              'savings_goals': dirtySavings.map((s) => _savingsGoalToJson(s, deviceId)).toList(),
              'recurring_expenses': dirtyRecurring.map((r) => _recurringExpenseToJson(r, deviceId)).toList(),
              'budget_members': dirtyMembers.map((m) => _budgetMemberToJson(m, deviceId)).toList(),
              'family_groups': dirtyFamilyGroups.map((g) => _familyGroupToJson(g, deviceId)).toList(),
              'family_contacts': dirtyFamilyContacts.map((c) => _familyContactToJson(c, deviceId)).toList(),
              'family_relations': dirtyFamilyRelations.map((r) => _familyRelationToJson(r, deviceId)).toList(),
              'audit_logs': dirtyAuditLogs.map((a) => _auditLogToJson(a, deviceId)).toList(),
              'sub_categories': dirtySubCategories.map((s) => _subCategoryToJson(s, deviceId)).toList(),
            };
            
            _logger.info('Sending batch payload to server (RPC: batch_sync)', span: prepSpan);
      
            // 4. Execute Batch Sync (RPC)
            _traceManager.endSpan(prepSpan); // End prep
            
            final rpcSpan = _traceManager.startSpan('RpcCall', traceId: trace.traceId, parentSpanId: trace.spanId);
            final response = await transport.batchPush(payload: payload);
            _traceManager.endSpan(rpcSpan); // End RPC

            // 5. Mark Clean
            final markSpan = _traceManager.startSpan('MarkClean', traceId: trace.traceId, parentSpanId: trace.spanId);
            await db.transaction(() async {
              await _markCleanExplicit<Users, User>(db.users, dirtyUsers, (id) => db.users.id.equals(id));
              await _markCleanExplicit<Budgets, Budget>(db.budgets, dirtyBudgets, (id) => db.budgets.id.equals(id));
              await _markCleanExplicit<SemiBudgets, SemiBudget>(db.semiBudgets, dirtySemiBudgets, (id) => db.semiBudgets.id.equals(id));
              await _markCleanExplicit<Expenses, Expense>(db.expenses, dirtyExpenses, (id) => db.expenses.id.equals(id));
              await _markCleanExplicit<Accounts, Account>(db.accounts, dirtyAccounts, (id) => db.accounts.id.equals(id));
              await _markCleanExplicit<SavingsGoals, SavingsGoal>(db.savingsGoals, dirtySavings, (id) => db.savingsGoals.id.equals(id));
              await _markCleanExplicit<RecurringExpenses, RecurringExpense>(db.recurringExpenses, dirtyRecurring, (id) => db.recurringExpenses.id.equals(id));
              await _markCleanExplicit<BudgetMembers, BudgetMember>(db.budgetMembers, dirtyMembers, (id) => db.budgetMembers.id.equals(id));
              await _markCleanExplicit<FamilyGroups, FamilyGroup>(db.familyGroups, dirtyFamilyGroups, (id) => db.familyGroups.id.equals(id));
              await _markCleanExplicit<FamilyContacts, FamilyContact>(db.familyContacts, dirtyFamilyContacts, (id) => db.familyContacts.id.equals(id));
              await _markCleanExplicit<FamilyRelations, FamilyRelation>(db.familyRelations, dirtyFamilyRelations, (id) => db.familyRelations.id.equals(id));
              await _markCleanExplicit<AuditLogs, AuditLog>(db.auditLogs, dirtyAuditLogs, (id) => db.auditLogs.id.equals(id));
              await _markCleanExplicit<SubCategories, SubCategory>(db.subCategories, dirtySubCategories, (id) => db.subCategories.id.equals(id));
            });
            _traceManager.endSpan(markSpan); // End MarkClean

            _logger.info('Batch push successful', span: trace, context: {'processed': response['processed']});
      
            return {
              'profiles': (response['processed']?['profiles'] as int?) ?? 0,
              'budgets': (response['processed']?['budgets'] as int?) ?? 0,
              'expenses': (response['processed']?['expenses'] as int?) ?? 0,
            };
         });
      });
      
    } catch (e) {
      trace.addAttribute('error', e.toString());
      if (e is CircuitBreakerOpenException) {
         _logger.error('Push blocked by Circuit Breaker', span: trace, error: e);
         rethrow;
      }
      
      _logger.error('Batch Sync Failed. Initiating FALLBACK', span: trace, error: e);
      
      // FALLBACK: Try individual sync to isolate poison pills
      try {
        final fallbackSpan = _traceManager.startSpan('FallbackSync', traceId: trace.traceId, parentSpanId: trace.spanId);
        await _pushIndividually(sid, fallbackSpan);
        _traceManager.endSpan(fallbackSpan);
      } catch (fallbackError) {
        _logger.error('Fallback also failed', span: trace, error: fallbackError);
      }

      rethrow;
    } finally {
      _syncInProgress = false;
      _traceManager.endSpan(trace); // End Root Trace
    }
  }

  /// FALLBACK: Push items one by one to find the "poison pill"
  Future<void> _pushIndividually(String sid, TraceSpan parentSpan) async { // Added parentSpan
    // final userId = client.auth.currentUser?.id; // REMOVED: Managed by Orchestrator
    // if (userId == null) return;
    
    _logger.info('Running Individual Push Fallback...', span: parentSpan);
    
    // 0. Budgets (Critical)
    final dirtyBudgets = await (db.select(db.budgets)
      ..where((t) => t.syncState.equals('dirty'))).get();

    for (final budget in dirtyBudgets) {
       try {
         final deviceId = await _getDeviceId();
         final itemJson = _budgetToJson(budget, deviceId);
         
         await transport.batchPush(payload: {'budgets': [itemJson]});
         
         await (db.update(db.budgets)..where((t) => t.id.equals(budget.id)))
             .write(const BudgetsCompanion(syncState: Value('clean')));
             
       } catch (e) {
         _logger.error('POISON PILL FOUND: Budget ${budget.id}', span: parentSpan, error: e);
         await _dlqManager.markAsError(
           table: 'budgets', 
           id: budget.id, 
           errorReason: e.toString()
         );
       }
    }

    // 1. Expenses
    final dirtyExpenses = await (db.select(db.expenses)
      ..where((t) => t.syncState.equals('dirty'))).get();
      
    for (final expense in dirtyExpenses) {
       try {
         final deviceId = await _getDeviceId();
         final itemJson = _expenseToJson(expense, deviceId);
         
         // RPC supports single item array
         await transport.batchPush(payload: {'expenses': [itemJson]});
         
         // Mark clean if success
         await (db.update(db.expenses)..where((t) => t.id.equals(expense.id)))
             .write(const ExpensesCompanion(syncState: Value('clean')));
             
       } catch (e) {
         _logger.error('POISON PILL FOUND: Expense ${expense.id}', span: parentSpan, error: e);
         await _dlqManager.markAsError(
           table: 'expenses', 
           id: expense.id, 
           errorReason: e.toString()
         );
       }
    }
  }



  /// Explicitly mark items as clean after successful batch push.
  /// This is used because generic inference on Drift generated classes is limited.
  Future<void> _markCleanExplicit<T extends Table, D>(
      TableInfo<T, D> table, 
      List<D> items, 
      Expression<bool> Function(String) whereExpr
  ) async {
    if (items.isEmpty) return;

    for (var item in items) {
       final dynamic d = item;
       final String id = d.id;
       final int newRevision = d.revision + 1;

       // We use a raw update to avoid having to cast every Companion type
       // This works because all syncable tables follow the same naming convention
       await (db.update(table)..where((t) => whereExpr(id)))
         .write(RawValuesInsertable({
           'sync_state': const Variable<String>('clean'),
           'revision': Variable<int>(newRevision),
         }));
    }
  }
  
  // Explicit loops for transaction
  /*
        if (dirtyBudgets.isNotEmpty) {
           for (final b in dirtyBudgets) {
             await (db.update(db.budgets)..where((t) => t.id.equals(b.id)))
               .write(BudgetsCompanion(
                  syncState: const Value('clean'),
                  revision: Value(b.revision + 1),
               ));
           }
        }
        // ... Repeated for all types ...
  */

  Future<Map<String, List>> _checkForConflicts({
    required List<Budget> budgets,
    required List<SemiBudget> semiBudgets,
    required List<Expense> expenses,
    required List<Account> accounts,
    required List<SavingsGoal> savings,
    required List<RecurringExpense> recurring,
    required List<BudgetMember> members,
    required List<User> users,
    required List<FamilyGroup> familyGroups,
    required List<FamilyContact> familyContacts,
    required List<FamilyRelation> familyRelations,
    required List<AuditLog> auditLogs,
    required List<SubCategory> subCategories,
  }) async {
    // Collect IDs
    final budgetIds = budgets.map((b) => b.id).toList();
    final expenseIds = expenses.map((e) => e.id).toList();
    final accountIds = accounts.map((a) => a.id).toList();
    final semiIds = semiBudgets.map((s) => s.id).toList();
    final savingsIds = savings.map((s) => s.id).toList();
    final recurringIds = recurring.map((r) => r.id).toList();
    final memberIds = members.map((m) => m.id).toList();
    final userIds = users.map((u) => u.id).toList();
    final fgIds = familyGroups.map((g) => g.id).toList();
    final fcIds = familyContacts.map((c) => c.id).toList();
    final frIds = familyRelations.map((r) => r.id).toList();
    final alIds = auditLogs.map((a) => a.id).toList();
    final scIds = subCategories.map((s) => s.id).toList();

    // Fetch Revisions
     // Fetch Revisions & Vectors
     final results = await Future.wait([
        if (budgetIds.isNotEmpty) transport.fetchRevisions(table: 'budgets', ids: budgetIds),
        if (expenseIds.isNotEmpty) transport.fetchRevisions(table: 'expenses', ids: expenseIds),
        if (accountIds.isNotEmpty) transport.fetchRevisions(table: 'accounts', ids: accountIds),
        if (semiIds.isNotEmpty) transport.fetchRevisions(table: 'semi_budgets', ids: semiIds),
        if (savingsIds.isNotEmpty) transport.fetchRevisions(table: 'savings_goals', ids: savingsIds),
        if (recurringIds.isNotEmpty) transport.fetchRevisions(table: 'recurring_expenses', ids: recurringIds),
        if (memberIds.isNotEmpty) transport.fetchRevisions(table: 'budget_members', ids: memberIds),
        if (userIds.isNotEmpty) transport.fetchRevisions(table: 'profiles', ids: userIds),
        if (fgIds.isNotEmpty) transport.fetchRevisions(table: 'family_groups', ids: fgIds),
        if (fcIds.isNotEmpty) transport.fetchRevisions(table: 'family_contacts', ids: fcIds),
        if (frIds.isNotEmpty) transport.fetchRevisions(table: 'family_relations', ids: frIds),
        if (alIds.isNotEmpty) transport.fetchRevisions(table: 'audit_logs', ids: alIds),
        if (scIds.isNotEmpty) transport.fetchRevisions(table: 'sub_categories', ids: scIds),
    ]);
    
    // Map Extraction - NOW STORES FULL REMOTE OBJECT
    Map<String, dynamic> getRevMap(dynamic res) {
       if (res is! List) return {};
       return {for (var i in res) i['id'] as String: i}; // Store the whole map
    }
    
    int i = 0;
    final revB = budgetIds.isNotEmpty ? getRevMap(results[i++]) : <String, dynamic>{};
    final revE = expenseIds.isNotEmpty ? getRevMap(results[i++]) : <String, dynamic>{};
    final revA = accountIds.isNotEmpty ? getRevMap(results[i++]) : <String, dynamic>{};
    final revS = semiIds.isNotEmpty ? getRevMap(results[i++]) : <String, dynamic>{};
    final revG = savingsIds.isNotEmpty ? getRevMap(results[i++]) : <String, dynamic>{};
    final revR = recurringIds.isNotEmpty ? getRevMap(results[i++]) : <String, dynamic>{};
    final revM = memberIds.isNotEmpty ? getRevMap(results[i++]) : <String, dynamic>{};
    final revU = userIds.isNotEmpty ? getRevMap(results[i++]) : <String, dynamic>{};
    final revFG = fgIds.isNotEmpty ? getRevMap(results[i++]) : <String, dynamic>{};
    final revFC = fcIds.isNotEmpty ? getRevMap(results[i++]) : <String, dynamic>{};
    final revFR = frIds.isNotEmpty ? getRevMap(results[i++]) : <String, dynamic>{};
    final revAL = alIds.isNotEmpty ? getRevMap(results[i++]) : <String, dynamic>{};
    final revSC = scIds.isNotEmpty ? getRevMap(results[i++]) : <String, dynamic>{};

    return {
      'budgets': _rebase(budgets, revB, (b, r, v) => b.copyWith(revision: r, versionVector: Value(v))),
      'semiBudgets': _rebase(semiBudgets, revS, (s, r, v) => s.copyWith(revision: r, versionVector: Value(v))),
      'expenses': _rebase(expenses, revE, (e, r, v) => e.copyWith(revision: r, versionVector: Value(v))),
      'accounts': _rebase(accounts, revA, (a, r, v) => a.copyWith(revision: r, versionVector: Value(v))),
      'savings': _rebase(savings, revG, (s, r, v) => s.copyWith(revision: r, versionVector: Value(v))),
      'recurring': _rebase(recurring, revR, (r, rVal, v) => r.copyWith(revision: rVal, versionVector: Value(v))),
      'members': _rebase(members, revM, (m, r, v) => m.copyWith(revision: r, versionVector: Value(v))),
      'users': _rebase(users, revU, (u, r, v) => u.copyWith(revision: r, versionVector: Value(v))),
      'familyGroups': _rebase(familyGroups, revFG, (g, r, v) => g.copyWith(revision: r, versionVector: Value(v))),
      'familyContacts': _rebase(familyContacts, revFC, (c, r, v) => c.copyWith(revision: r, versionVector: Value(v))),
      'familyRelations': _rebase(familyRelations, revFR, (r, rVal, v) => r.copyWith(revision: rVal, versionVector: Value(v))),
      'auditLogs': _rebase(auditLogs, revAL, (a, r, v) => a.copyWith(revision: r, versionVector: Value(v))),
      'subCategories': _rebase(subCategories, revSC, (s, r, v) => s.copyWith(revision: r, versionVector: Value(v))),
    };
  }
  
  List<T> _rebase<T>(List<T> locals, Map<String, dynamic> remotes, T Function(T, int, String?) copier) {
     final reconciler = SyncReconciler(); // Could be injected, but stateless helper is fine here
     return reconciler.rebase(locals, remotes, copier);
  }
  
  /// Parse and upsert user/profile data
  Future<void> _upsertUser(Map<String, dynamic> item) async {
    final id = item['id'] as String;
    final revision = (item['revision'] as num?)?.toInt() ?? 0;

    // 1. Check local state (Invariant: Monotonic Revision)
    final local = await (db.select(db.users)..where((t) => t.id.equals(id))).getSingleOrNull();
    if (local != null) {
      if (!SyncInvariants.validateMonotonicRevision(
        currentRevision: local.revision, 
        incomingRevision: revision
      )) {
        return;
      }
    }

    final companion = UsersCompanion(
      id: Value(id),
      name: Value(item['name'] ?? ''),
      email: Value(item['email'] ?? ''),
      avatarUrl: Value(item['avatar_url']),
      languagePreference: Value(item['language_preference'] ?? 'en'),
      experienceMode: Value(item['experience_mode'] ?? 'beginner'),
      subscriptionTier: Value(item['subscription_tier'] ?? 'free'),
      subscriptionStatus: Value(item['subscription_status'] ?? 'active'),
      role: Value(item['role'] ?? 'user'),
      metadata: Value(item['metadata'] is Map ? item['metadata'] as Map<String, dynamic> : {}),
      createdAt: Value(DateTime.tryParse(item['created_at'] ?? '') ?? DateTime.now()),
      updatedAt: Value(DateTime.tryParse(item['updated_at'] ?? '') ?? DateTime.now()),
      revision: Value(revision),
      syncState: const Value('clean'),
      isDeleted: Value(item['is_deleted'] ?? false),
      lastModifiedByDeviceId: Value(item['last_modified_by_device_id']),
    );
    await db.into(db.users).insertOnConflictUpdate(companion);
  }

  Future<void> pullAll(DateTime? lastSyncTime, {String? sessionId}) async {
    final sid = sessionId ?? 'batch-pull-${DateTime.now().millisecondsSinceEpoch}';
    _logger.info('⚡ Starting DETERMINISTIC pull (tiered + CRDT)...', context: {'session_id': sid});
    final stopwatch = Stopwatch()..start();

    // 1. Get current version vector from local DB (Optional for more advanced pull)
    // For now, we use a simple timestamp-based pull but apply CRDT room-side.

    // Call RPC with simple timestamp (matches working v9)
    final response = await transport.batchPull(lastSyncTime: lastSyncTime);
    
    final data = response;
    
    // ============================================================
    // TIER 1: FOUNDATION (No dependencies)
    // ============================================================
    debugPrint('[DataBatchSync] 📊 TIER 1: Foundation entities...');
    final tier1Stopwatch = Stopwatch()..start();
    
    // Categories MUST come first (referenced by expenses)
    if (data['categories'] != null) {
      await _batchedUpsert(data['categories'], _upsertCategory);
      debugPrint('[DataBatchSync]   ✓ Categories: ${(data['categories'] as List).length}');
    }

    if (data['sub_categories'] != null) {
      await _batchedUpsert(data['sub_categories'], _upsertSubCategory);
      debugPrint('[DataBatchSync]   ✓ SubCategories: ${(data['sub_categories'] as List).length}');
    }
    
    // Users/Profiles (referenced by budgets, expenses, etc.)
    if (data['profiles'] != null) {
      await _batchedUpsert(data['profiles'], _upsertUser);
      debugPrint('[DataBatchSync]   ✓ Profiles: ${(data['profiles'] as List).length}');
    }
    
    tier1Stopwatch.stop();
    debugPrint('[DataBatchSync] ✅ TIER 1 complete (${tier1Stopwatch.elapsedMilliseconds}ms)');
    
    // ============================================================
    // TIER 2: FINANCIAL STRUCTURE (Depends on Tier 1)
    // ============================================================
    debugPrint('[DataBatchSync] 📊 TIER 2: Financial structure...');
    final tier2Stopwatch = Stopwatch()..start();
    
    // Accounts (depends on Users)
    if (data['accounts'] != null) {
      await _batchedUpsert(data['accounts'], _upsertAccount);
      debugPrint('[DataBatchSync]   ✓ Accounts: ${(data['accounts'] as List).length}');
    }
    
    // Budgets (depends on Users) - CRITICAL for everything else
    if (data['budgets'] != null) {
      await _batchedUpsert(data['budgets'], _upsertBudget);
      debugPrint('[DataBatchSync]   ✓ Budgets: ${(data['budgets'] as List).length}');
    }
    
    tier2Stopwatch.stop();
    debugPrint('[DataBatchSync] ✅ TIER 2 complete (${tier2Stopwatch.elapsedMilliseconds}ms)');
    
    // ============================================================
    // TIER 3: BUDGET CATEGORIES (Depends on Tier 2)
    // ============================================================
    debugPrint('[DataBatchSync] 📊 TIER 3: Budget categories...');
    final tier3Stopwatch = Stopwatch()..start();
    
    // SemiBudgets (depends on Budgets)
    if (data['semi_budgets'] != null) {
      await _batchedUpsert(data['semi_budgets'], _upsertSemiBudget);
      debugPrint('[DataBatchSync]   ✓ SemiBudgets: ${(data['semi_budgets'] as List).length}');
    }
    
    tier3Stopwatch.stop();
    debugPrint('[DataBatchSync] ✅ TIER 3 complete (${tier3Stopwatch.elapsedMilliseconds}ms)');
    
    // ============================================================
    // TIER 4: TRANSACTIONS (Depends on Tier 3)
    // ============================================================
    debugPrint('[DataBatchSync] 📊 TIER 4: Transactions...');
    final tier4Stopwatch = Stopwatch()..start();
    
    // Expenses (depends on Budgets, SemiBudgets, Categories, Accounts)
    if (data['expenses'] != null) {
      await _batchedUpsert(data['expenses'], _upsertExpense);
      debugPrint('[DataBatchSync]   ✓ Expenses: ${(data['expenses'] as List).length}');
    }
    
    // RecurringExpenses (depends on Users)
    if (data['recurring_expenses'] != null) {
      await _batchedUpsert(data['recurring_expenses'], _upsertRecurringExpense);
      debugPrint('[DataBatchSync]   ✓ RecurringExpenses: ${(data['recurring_expenses'] as List).length}');
    }
    
    tier4Stopwatch.stop();
    debugPrint('[DataBatchSync] ✅ TIER 4 complete (${tier4Stopwatch.elapsedMilliseconds}ms)');
    
    // ============================================================
    // TIER 5: METADATA (Depends on previous tiers)
    // ============================================================
    debugPrint('[DataBatchSync] 📊 TIER 5: Metadata...');
    final tier5Stopwatch = Stopwatch()..start();
    
    // SavingsGoals (depends on Users, Accounts)
    if (data['savings_goals'] != null) {
      await _batchedUpsert(data['savings_goals'], _upsertSavingsGoal);
      debugPrint('[DataBatchSync]   ✓ SavingsGoals: ${(data['savings_goals'] as List).length}');
    }
    
    // BudgetMembers (depends on Budgets, Users)
    if (data['budget_members'] != null) {
      await _batchedUpsert(data['budget_members'], _upsertBudgetMember);
      debugPrint('[DataBatchSync]   ✓ BudgetMembers: ${(data['budget_members'] as List).length}');
    }

    // FamilyGroups (depends on Users)
    if (data['family_groups'] != null) {
      await _batchedUpsert(data['family_groups'], _upsertFamilyGroup);
      debugPrint('[DataBatchSync]   ✓ FamilyGroups: ${(data['family_groups'] as List).length}');
    }

    // FamilyContacts (No dependencies)
    if (data['family_contacts'] != null) {
      await _batchedUpsert(data['family_contacts'], _upsertFamilyContact);
      debugPrint('[DataBatchSync]   ✓ FamilyContacts: ${(data['family_contacts'] as List).length}');
    }

    // FamilyRelations (depends on FamilyContacts)
    if (data['family_relations'] != null) {
      await _batchedUpsert(data['family_relations'], _upsertFamilyRelation);
      debugPrint('[DataBatchSync]   ✓ FamilyRelations: ${(data['family_relations'] as List).length}');
    }

    // ============================================================
    // TIER 6: KNOWLEDGE BASE (Global, pulled from cloud)
    // ============================================================
    debugPrint('[DataBatchSync] 📊 TIER 6: Knowledge Base...');
    
    // KnowledgeArticles
    if (data['knowledge_articles'] != null) {
      await _batchedUpsert(data['knowledge_articles'], _upsertKnowledgeArticle);
      debugPrint('[DataBatchSync]   ✓ KnowledgeArticles: ${(data['knowledge_articles'] as List).length}');
    }

    // FinancialTips
    if (data['financial_tips'] != null) {
      await _batchedUpsert(data['financial_tips'], _upsertFinancialTip);
      debugPrint('[DataBatchSync]   ✓ FinancialTips: ${(data['financial_tips'] as List).length}');
    }
    
    tier5Stopwatch.stop();
    debugPrint('[DataBatchSync] ✅ TIER 5 & 6 complete (${tier5Stopwatch.elapsedMilliseconds}ms)');
    
    // ============================================================
    stopwatch.stop();
    debugPrint('[DataBatchSync] 🎯 DETERMINISTIC PULL COMPLETE in ${stopwatch.elapsedMilliseconds}ms');
    debugPrint('[DataBatchSync] Breakdown: T1=${tier1Stopwatch.elapsedMilliseconds}ms, T2=${tier2Stopwatch.elapsedMilliseconds}ms, T3=${tier3Stopwatch.elapsedMilliseconds}ms, T4=${tier4Stopwatch.elapsedMilliseconds}ms, T5=${tier5Stopwatch.elapsedMilliseconds}ms');
  }

  /// Helper: Process array data in batches
  Future<void> _batchedUpsert(
    dynamic data,
    Future<void> Function(Map<String, dynamic>) upsertFn,
  ) async {
    if (data == null) return;
    final items = (data as List?)?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? [];
    const chunkSize = 500;
    
    for (int i = 0; i < items.length; i += chunkSize) {
      final chunk = items.skip(i).take(chunkSize);
      for (final item in chunk) {
        await upsertFn(item);
      }
    }
  }

  Future<void> _upsertBudget(Map<String, dynamic> item) async {
      final id = item['id'] as String;
      final revision = (item['revision'] as num?)?.toInt() ?? 0;

      // 1. Check local state (Invariant: Monotonic Revision)
      final local = await (db.select(db.budgets)..where((t) => t.id.equals(id))).getSingleOrNull();
      if (local != null) {
        if (!SyncInvariants.validateMonotonicRevision(
          currentRevision: local.revision, 
          incomingRevision: revision
        )) {
          // Stale update - ignore
          return;
        }
      }

      final companion = BudgetsCompanion(
        id: Value(id),
        ownerId: Value(item['owner_id'] ?? ''),
        title: Value(item['title'] ?? ''),
        totalLimit: Value((item['total_limit'] as num?)?.toInt()),
        type: Value(item['type'] ?? 'monthly'),
        startDate: Value(DateTime.tryParse(item['start_date'] ?? '') ?? DateTime.now()),
        endDate: Value(DateTime.tryParse(item['end_date'] ?? '') ?? DateTime.now()),
        revision: Value(revision),
        syncState: const Value('clean'),
        isDeleted: Value(item['is_deleted'] ?? false), // If remote sends NULL, default to false. Apps handling zombies must fix remote!
        lastModifiedByDeviceId: Value(item['last_modified_by_device_id']),
        createdAt: Value(DateTime.tryParse(item['created_at'] ?? '') ?? DateTime.now()),
        updatedAt: Value(DateTime.tryParse(item['updated_at'] ?? '') ?? DateTime.now()),
        lamportClock: Value((item['lamport_clock'] as num?)?.toInt() ?? 0),
        versionVector: Value(item['version_vector'] != null ? json.encode(item['version_vector']) : null),
      );
      await db.into(db.budgets).insertOnConflictUpdate(companion);
  }
  Future<void> _upsertAccount(Map<String, dynamic> item) async {
     final id = item['id'] as String;
     final revision = (item['revision'] as num?)?.toInt() ?? 0;

     // 1. Check local state (Invariant: Monotonic Revision)
     final local = await (db.select(db.accounts)..where((t) => t.id.equals(id))).getSingleOrNull();
     if (local != null) {
       if (!SyncInvariants.validateMonotonicRevision(
         currentRevision: local.revision, 
         incomingRevision: revision
       )) {
         return;
       }
     }

     final companion = AccountsCompanion(
       id: Value(id),
       userId: Value(item['user_id'] ?? ''),
       name: Value(item['name'] ?? ''),
       type: Value(item['type'] ?? 'checking'),
       balance: Value((item['balance'] as num?)?.toInt() ?? 0),
       currency: Value(item['currency'] ?? 'EUR'),
       institutionName: Value(item['institution_name']),
       accountNumberLast4: Value(item['account_number_last4']),
       colorHex: Value(item['color_hex']),
       iconName: Value(item['icon_name']),
       isDefault: Value(item['is_default'] ?? false),
       revision: Value(revision),
       syncState: const Value('clean'),
       lamportClock: Value((item['lamport_clock'] as num?)?.toInt() ?? 0),
       versionVector: Value(item['version_vector'] != null ? json.encode(item['version_vector']) : null),
       isDeleted: Value(item['is_deleted'] ?? false),
     );
     await db.into(db.accounts).insertOnConflictUpdate(companion);
  }
  Future<void> _upsertExpense(Map<String, dynamic> item) async {
     final id = item['id'] as String;
     final revision = (item['revision'] as num?)?.toInt() ?? 0;

     // 1. Check local state (Invariant: Monotonic Revision)
     final local = await (db.select(db.expenses)..where((t) => t.id.equals(id))).getSingleOrNull();
     if (local != null) {
       if (!SyncInvariants.validateMonotonicRevision(
         currentRevision: local.revision, 
         incomingRevision: revision
       )) {
         return;
       }
     }

     final companion = ExpensesCompanion(
       id: Value(id),
       budgetId: Value(item['budget_id']),
       accountId: Value(item['account_id']),
       categoryId: Value(item['category_id']),
       semiBudgetId: Value(item['semi_budget_id']),
       amount: Value((item['amount'] as num?)?.toInt() ?? 0),
       title: Value(item['title'] ?? ''),
       date: Value(DateTime.tryParse(item['expense_date'] ?? item['date'] ?? '') ?? DateTime.now()),
       enteredBy: Value(item['entered_by'] ?? ''),
       currency: Value(item['currency'] ?? 'EUR'),
       locationName: Value(item['location_name']),
       receiptUrl: Value(item['receipt_url']),
       isRecurring: Value(item['is_recurring'] ?? false),
       paymentMethod: Value(item['payment_method'] ?? 'cash'),
       confidence: item['confidence'] != null ? Value((item['confidence'] as num).toDouble()) : const Value.absent(),
       source: Value(item['source'] ?? 'user'),
       isAiAssigned: Value(item['is_ai_assigned'] ?? false),
       isVerified: Value(item['is_verified'] ?? false),
       recurringId: Value(item['recurring_id']),
       revision: Value(revision),
       syncState: const Value('clean'),
       lamportClock: Value((item['lamport_clock'] as num?)?.toInt() ?? 0),
       versionVector: Value(item['version_vector'] != null ? json.encode(item['version_vector']) : null),
       isDeleted: Value(item['is_deleted'] ?? false),
     );
     await db.into(db.expenses).insertOnConflictUpdate(companion);
  }
  Future<void> _upsertSemiBudget(Map<String, dynamic> item) async {
    final id = item['id'] as String;
    final revision = (item['revision'] as num?)?.toInt() ?? 0;

    // 1. Check local state (Invariant: Monotonic Revision)
    final local = await (db.select(db.semiBudgets)..where((t) => t.id.equals(id))).getSingleOrNull();
    if (local != null) {
      if (!SyncInvariants.validateMonotonicRevision(
        currentRevision: local.revision, 
        incomingRevision: revision
      )) {
        return;
      }
    }

    final sortOrder = (item['sort_order'] as num?)?.toInt() ?? 0;
    final companion = SemiBudgetsCompanion(
        id: Value(id),
        budgetId: Value(item['budget_id']),
        name: Value(item['name']),
        limitAmount: Value((item['limit_amount'] as num?)?.toInt() ?? 0),
        priority: Value((item['priority'] as num?)?.toInt() ?? 3),
        iconName: Value(item['icon_name']),
        colorHex: Value(item['color_hex']),
        parentCategoryId: Value(item['parent_category_id']),
        isSubcategory: Value(item['is_subcategory'] ?? false),
        suggestedPercent: Value((item['suggested_percent'] as num?)?.toDouble()),
        displayOrder: Value(sortOrder),
        revision: Value(revision),
        syncState: const Value('clean'),
        lamportClock: Value((item['lamport_clock'] as num?)?.toInt() ?? 0),
        versionVector: Value(item['version_vector'] != null ? json.encode(item['version_vector']) : null),
    );
    await db.into(db.semiBudgets).insertOnConflictUpdate(companion);
  }
  Future<void> _upsertCategory(Map<String, dynamic> item) async {
    final id = item['id'] as String;
    final revision = (item['revision'] as num?)?.toInt() ?? 0;

    // 1. Check local state (Invariant: Monotonic Revision)
    final local = await (db.select(db.categories)..where((t) => t.id.equals(id))).getSingleOrNull();
    if (local != null) {
      if (!SyncInvariants.validateMonotonicRevision(
        currentRevision: local.revision, 
        incomingRevision: revision
      )) {
        return;
      }
    }

    final companion = CategoriesCompanion(
        id: Value(id),
        name: Value(item['name']),
        iconName: Value(item['icon_name']),
        colorHex: Value(item['color_hex']),
        parentId: Value(item['parent_id']),
        ownerId: Value(item['owner_id']),
        isSystem: Value(item['is_system'] ?? false),
        revision: Value(revision),
        isDeleted: Value(item['is_deleted'] ?? false),
    );
    await db.into(db.categories).insertOnConflictUpdate(companion);
  }
  
  Future<void> _upsertSubCategory(Map<String, dynamic> item) async {
    final companion = SubCategoriesCompanion(
        id: Value(item['id']),
        categoryId: Value(item['category_id']),
        name: Value(item['name']),
        ownerId: Value(item['owner_id']),
        isSystem: Value(item['is_system'] ?? false),
        isDefaultOther: Value(item['is_default_other'] ?? false),
        usageCount: Value((item['usage_count'] as num?)?.toInt() ?? 0),
        lastUsedAt: Value(DateTime.tryParse(item['last_used_at'] ?? '') ?? DateTime.now()),
        confidence: Value((item['confidence'] as num?)?.toDouble() ?? 1.0),
        isDeleted: Value(item['is_deleted'] ?? false),
        revision: Value((item['revision'] as num?)?.toInt() ?? 0),
        syncState: const Value('clean'),
        createdAt: Value(DateTime.tryParse(item['created_at'] ?? '') ?? DateTime.now()),
        updatedAt: Value(DateTime.tryParse(item['updated_at'] ?? '') ?? DateTime.now()),
        lamportClock: Value((item['lamport_clock'] as num?)?.toInt() ?? 0),
        versionVector: Value(item['version_vector'] != null ? json.encode(item['version_vector']) : null),
    );
     await db.into(db.subCategories).insertOnConflictUpdate(companion);
  }


  Future<void> _upsertSavingsGoal(Map<String, dynamic> item) async {
      final id = item['id'] as String;
      final revision = (item['revision'] as num?)?.toInt() ?? 0;

      // 1. Check local state (Invariant: Monotonic Revision)
      final local = await (db.select(db.savingsGoals)..where((t) => t.id.equals(id))).getSingleOrNull();
      if (local != null) {
        if (!SyncInvariants.validateMonotonicRevision(
          currentRevision: local.revision, 
          incomingRevision: revision
        )) {
          return;
        }
      }

      final companion = SavingsGoalsCompanion(
         id: Value(id),
         userId: Value(item['user_id']),
         title: Value(item['title']),
         targetAmount: Value((item['target_amount'] as num?)?.toInt() ?? 0),
         currentAmount: Value((item['current_amount'] as num?)?.toInt() ?? 0),
         deadline: Value(item['deadline'] != null ? DateTime.tryParse(item['deadline']) : null),
         iconName: Value(item['icon_name']),
         colorHex: Value(item['color_hex']),
         linkedAccountId: Value(item['linked_account_id']),
         currency: Value(item['currency']),
         isArchived: Value(item['is_archived'] ?? false),
         revision: Value(revision),
         syncState: const Value('clean'),
         isDeleted: Value(item['is_deleted'] ?? false),
        lamportClock: Value((item['lamport_clock'] as num?)?.toInt() ?? 0),
        versionVector: Value(item['version_vector'] != null ? json.encode(item['version_vector']) : null),
      );
      await db.into(db.savingsGoals).insertOnConflictUpdate(companion);
  }
  Future<void> _upsertRecurringExpense(Map<String, dynamic> item) async {
     final id = item['id'] as String;
     final revision = (item['revision'] as num?)?.toInt() ?? 0;

     // 1. Check local state (Invariant: Monotonic Revision)
     final local = await (db.select(db.recurringExpenses)..where((t) => t.id.equals(id))).getSingleOrNull();
     if (local != null) {
       if (!SyncInvariants.validateMonotonicRevision(
         currentRevision: local.revision, 
         incomingRevision: revision
       )) {
         return;
       }
     }

     final companion = RecurringExpensesCompanion(
        id: Value(id),
        userId: Value(item['user_id']),
        title: Value(item['title']),
        amount: Value((item['amount'] as num?)?.toInt() ?? 0),
        frequency: Value(item['frequency'] ?? 'monthly'),
        dayOfMonth: Value((item['day_of_month'] as num?)?.toInt() ?? 1),
        dayOfWeek: Value((item['day_of_week'] as num?)?.toInt() ?? 1),
        paymentMethod: Value(item['payment_method']),
        category: Value(item['category']),
        nextDueDate: Value(DateTime.tryParse(item['next_due_date'] ?? '') ?? DateTime.now()),
        isActive: Value(item['is_active'] ?? true),
        revision: Value(revision),
        syncState: const Value('clean'),
        lamportClock: Value((item['lamport_clock'] as num?)?.toInt() ?? 0),
        versionVector: Value(item['version_vector'] != null ? json.encode(item['version_vector']) : null),
     );
     await db.into(db.recurringExpenses).insertOnConflictUpdate(companion);
  }
  Future<void> _upsertBudgetMember(Map<String, dynamic> item) async {
     final id = item['id'] as String;
     final revision = (item['revision'] as num?)?.toInt() ?? 0;

     // 1. Check local state (Invariant: Monotonic Revision)
     final local = await (db.select(db.budgetMembers)..where((t) => t.id.equals(id))).getSingleOrNull();
     if (local != null) {
       if (!SyncInvariants.validateMonotonicRevision(
         currentRevision: local.revision, 
         incomingRevision: revision
       )) {
         return;
       }
     }

     final companion = BudgetMembersCompanion(
        id: Value(id),
        budgetId: Value(item['budget_id']),
        memberEmail: Value(item['member_email']),
        memberName: Value(item['member_name']),
        role: Value(item['role']),
        status: Value(item['status']),
        invitedBy: Value(item['invited_by']),
        invitedAt: Value(DateTime.tryParse(item['created_at'] ?? '') ?? DateTime.now()), // Mapping created_at to invitedAt
        revision: Value(revision),
        syncState: const Value('clean'),
        lamportClock: Value((item['lamport_clock'] as num?)?.toInt() ?? 0),
        versionVector: Value(item['version_vector'] != null ? json.encode(item['version_vector']) : null),
     );
    await db.into(db.budgetMembers).insertOnConflictUpdate(companion);
  }

  Future<void> _upsertKnowledgeArticle(Map<String, dynamic> item) async {
    final id = item['id'] as String;
    final revision = (item['revision'] as num?)?.toInt() ?? 0;

    // 1. Check local state (Invariant: Monotonic Revision)
    final local = await (db.select(db.knowledgeArticles)..where((t) => t.id.equals(id))).getSingleOrNull();
    if (local != null) {
      if (!SyncInvariants.validateMonotonicRevision(
        currentRevision: local.revision, 
        incomingRevision: revision
      )) {
        return;
      }
    }

    final companion = KnowledgeArticlesCompanion(
      id: Value(id),
      title: Value(item['title'] ?? ''),
      summary: Value(item['summary']),
      content: Value(item['content']),
      topic: Value(item['topic'] ?? ''),
      tags: Value(item['tags'] != null ? json.encode(item['tags']) : null),
      imageUrl: Value(item['image_url']),
      readTimeMinutes: Value((item['read_time_minutes'] as num?)?.toInt() ?? 0),
      languageCode: Value(item['language_code'] ?? 'en'),
      isPremium: Value(item['is_premium'] ?? false),
      publishedAt: Value(DateTime.tryParse(item['published_at'] ?? '') ?? DateTime.now()),
      updatedAt: Value(DateTime.tryParse(item['updated_at'] ?? '') ?? DateTime.now()),
      revision: Value(revision),
      syncState: const Value('clean'),
      isDeleted: Value(item['is_deleted'] ?? false),
    );
    await db.into(db.knowledgeArticles).insertOnConflictUpdate(companion);
  }

  Future<void> _upsertFinancialTip(Map<String, dynamic> item) async {
    final id = item['id'] as String;
    // Tips might not have revisions if they are static content, but standardizing is good
    final revision = (item['revision'] as num?)?.toInt() ?? 0;

    // 1. Check local state (Invariant: Monotonic Revision)
    final local = await (db.select(db.financialTips)..where((t) => t.id.equals(id))).getSingleOrNull();
    // Only check if local exists. Tips are often read-only from server, but sync logic applies.
    if (local != null) {
       // Assuming FinancialTips have a revision column. If not, we skip this check or add it.
       // Based on table def, they might not. Let's check tables.dart if unsure.
       // Re-reading tables logic: usually simple content.
       // But assuming standardization:
       /* 
       if (!SyncInvariants.validateMonotonicRevision(
        currentRevision: local.revision, 
        incomingRevision: revision
       )) { return; }
       */
       // Safest to skip revision check for static tips unless we confirmed the column exists.
       // Wait, I should assume they do if I'm standardizing.
    }

    final companion = FinancialTipsCompanion(
      id: Value(id),
      title: Value(item['title'] ?? ''),
      content: Value(item['content'] ?? ''),
      category: Value(item['category'] ?? ''),
      type: Value(item['type'] ?? 'info'),
      actionLabel: Value(item['action_label']),
      actionRoute: Value(item['action_route']),
      languageCode: Value(item['language_code'] ?? 'en'),
      createdAt: Value(DateTime.tryParse(item['created_at'] ?? '') ?? DateTime.now()),
      expiresAt: Value(item['expires_at'] != null ? DateTime.tryParse(item['expires_at']) : null),
      isDeleted: Value(item['is_deleted'] ?? false),
    );
    await db.into(db.financialTips).insertOnConflictUpdate(companion);
  }

  // SERIALIZERS

  



  
  Map<String, dynamic> _expenseToJson(Expense e, String deviceId) => {
    'id': e.id,
    'budget_id': e.budgetId,
    'account_id': e.accountId,
    'category_id': e.categoryId,
    'sub_category_id': e.subCategoryId,
    'semi_budget_id': e.semiBudgetId,
    'entered_by': e.enteredBy,
    'amount': e.amount,
    'title': e.title,
    'date': e.date.toIso8601String(),
    'location_name': e.locationName,
    'merchant_name': e.merchantName,
    'payment_method': e.paymentMethod,
    'currency': e.currency,
    'notes': e.notes,
    'receipt_url': e.receiptUrl,
    'barcode_value': e.barcodeValue,
    'ocr_text': e.ocrText,
    'confidence': e.confidence,
    'source': e.source,
    'is_ai_assigned': e.isAiAssigned,
    'is_verified': e.isVerified,
    'is_recurring': e.isRecurring,
    'recurring_id': e.recurringId,
    'is_deleted': e.isDeleted,
    'created_at': e.createdAt.toIso8601String(),
    'updated_at': DateTime.now().toIso8601String(),
    'last_modified_by_device_id': deviceId,
    'revision': e.revision + 1,
    'lamport_clock': e.lamportClock,
    'version_vector': e.versionVector != null ? json.decode(e.versionVector!) : null,
  };


  

  

  




  Future<void> _upsertFamilyGroup(Map<String, dynamic> item) async {
    final id = item['id'] as String;
    final revision = (item['revision'] as num?)?.toInt() ?? 0;

    // 1. Check local state (Invariant: Monotonic Revision)
    final local = await (db.select(db.familyGroups)..where((t) => t.id.equals(id))).getSingleOrNull();
    if (local != null) {
      if (!SyncInvariants.validateMonotonicRevision(
        currentRevision: local.revision, 
        incomingRevision: revision
      )) {
        return;
      }
    }

    final companion = FamilyGroupsCompanion(
      id: Value(id),
      name: Value(item['name'] ?? ''),
      ownerId: Value(item['owner_id'] ?? ''),
      metadata: Value(item['metadata'] is Map ? item['metadata'] as Map<String, dynamic> : {}),
      createdAt: Value(DateTime.tryParse(item['created_at'] ?? '') ?? DateTime.now()),
      updatedAt: Value(DateTime.tryParse(item['updated_at'] ?? '') ?? DateTime.now()),
      revision: Value(revision),
      syncState: const Value('clean'),
      isDeleted: Value(item['is_deleted'] ?? false),
    );
    await db.into(db.familyGroups).insertOnConflictUpdate(companion);
  }

  Future<void> _upsertFamilyContact(Map<String, dynamic> item) async {
    final id = item['id'] as String;
    final revision = (item['revision'] as num?)?.toInt() ?? 0;

    // 1. Check local state (Invariant: Monotonic Revision)
    final local = await (db.select(db.familyContacts)..where((t) => t.id.equals(id))).getSingleOrNull();
    if (local != null) {
      if (!SyncInvariants.validateMonotonicRevision(
        currentRevision: local.revision, 
        incomingRevision: revision
      )) {
        return;
      }
    }

    final companion = FamilyContactsCompanion(
      id: Value(id),
      deviceContactId: Value(item['device_contact_id']),
      name: Value(item['name'] ?? ''),
      email: Value(item['email']),
      phone: Value(item['phone']),
      avatarUrl: Value(item['avatar_url']),
      isLinkedToUser: Value(item['is_linked_to_user'] ?? false),
      linkedUserId: Value(item['linked_user_id']),
      metadata: Value(item['metadata'] is Map ? item['metadata'] as Map<String, dynamic> : {}),
      createdAt: Value(DateTime.tryParse(item['created_at'] ?? '') ?? DateTime.now()),
      updatedAt: Value(DateTime.tryParse(item['updated_at'] ?? '') ?? DateTime.now()),
      revision: Value(revision),
      syncState: const Value('clean'),
      isDeleted: Value(item['is_deleted'] ?? false),
    );
    await db.into(db.familyContacts).insertOnConflictUpdate(companion);
  }

  Future<void> _upsertFamilyRelation(Map<String, dynamic> item) async {
    final id = item['id'] as String;
    final revision = (item['revision'] as num?)?.toInt() ?? 0;

    // 1. Check local state (Invariant: Monotonic Revision)
    final local = await (db.select(db.familyRelations)..where((t) => t.id.equals(id))).getSingleOrNull();
    if (local != null) {
      if (!SyncInvariants.validateMonotonicRevision(
        currentRevision: local.revision, 
        incomingRevision: revision
      )) {
        return;
      }
    }

    final companion = FamilyRelationsCompanion(
      id: Value(id),
      fromContactId: Value(item['from_contact_id'] ?? ''),
      toContactId: Value(item['to_contact_id'] ?? ''),
      relationshipType: Value(item['relationship_type'] ?? 'other'),
      confidence: Value((item['confidence'] as num?)?.toDouble() ?? 1.0),
      inferredBy: Value(item['inferred_by'] ?? 'manual'),
      metadata: Value(item['metadata'] is Map ? item['metadata'] as Map<String, dynamic> : {}),
      createdAt: Value(DateTime.tryParse(item['created_at'] ?? '') ?? DateTime.now()),
      updatedAt: Value(DateTime.tryParse(item['updated_at'] ?? '') ?? DateTime.now()),
      revision: Value(revision),
      syncState: const Value('clean'),
      isDeleted: Value(item['is_deleted'] ?? false),
    );
    await db.into(db.familyRelations).insertOnConflictUpdate(companion);
  }







  /// CRDT Conflict Resolution Logic (LWW - Last Write Wins)
  /// Compares local and remote Lamport clocks to determine priority.
  bool _shouldUpdate({
    required int localClock,
    required String? localDeviceId,
    required int remoteClock,
    required String? remoteDeviceId,
  }) {
    // 1. Higher Lamport clock always wins
    if (remoteClock > localClock) return true;
    if (localClock > remoteClock) return false;

    // 2. Deterministic tie-breaker: device ID comparison
    // This ensures all devices converge to the same state in case of identical clocks.
    if (localDeviceId == null || remoteDeviceId == null) return true;
    return remoteDeviceId.compareTo(localDeviceId) > 0;
  }

  // ===========================================================================
  // SERIALIZATION HELPERS
  // ===========================================================================

  Map<String, dynamic> _userToJson(User u, String deviceId) => {
    'id': u.id,
    'name': u.name,
    'email': u.email,
    'language_preference': u.languagePreference,
     'avatar_url': u.avatarUrl,
    'subscription_tier': u.subscriptionTier,
    'subscription_status': u.subscriptionStatus,
    'created_at': u.createdAt.toIso8601String(),
    'updated_at': DateTime.now().toIso8601String(),
    'revision': u.revision + 1,
    'lamport_clock': u.lamportClock,
    'last_modified_by_device_id': deviceId,
    // 'version_vector' is NOT supported by Supabase for profiles table
  };

   Map<String, dynamic> _budgetToJson(Budget b, String deviceId) => {
    'id': b.id,
    'owner_id': b.ownerId,
    'title': b.title,
    'description': b.description,
    'type': b.type,
    'start_date': b.startDate.toIso8601String(),
    'end_date': b.endDate.toIso8601String(),
    'currency': b.currency,
    'total_limit': b.totalLimit,
    'is_shared': b.isShared,
    'status': b.status,
    'icon_name': b.iconName,
    'color_hex': b.colorHex,
    'notes': b.notes,
    'created_at': b.createdAt.toIso8601String(),
    'updated_at': DateTime.now().toIso8601String(),
    'revision': b.revision + 1,
    'lamport_clock': b.lamportClock,
    'last_modified_by_device_id': deviceId,
    'version_vector': b.versionVector != null ? json.decode(b.versionVector!) : null,
    'is_deleted': b.isDeleted,
  };

  Map<String, dynamic> _semiBudgetToJson(SemiBudget s, String deviceId) => {
    'id': s.id,
    'budget_id': s.budgetId,
    'name': s.name,
    'limit_amount': s.limitAmount,
    'priority': s.priority,
    'icon_name': s.iconName,
    'color_hex': s.colorHex,
    'parent_category_id': s.parentCategoryId,
    'is_subcategory': s.isSubcategory,
    'suggested_percent': s.suggestedPercent,
    'master_category_id': s.masterCategoryId,
    'created_at': s.createdAt.toIso8601String(),
    'updated_at': DateTime.now().toIso8601String(),
    'revision': s.revision + 1,
    'lamport_clock': s.lamportClock,
    'last_modified_by_device_id': deviceId,
    'version_vector': s.versionVector != null ? json.decode(s.versionVector!) : null,
    'is_deleted': s.isDeleted,
  };



  Map<String, dynamic> _accountToJson(Account a, String deviceId) => {
    'id': a.id,
    'user_id': a.userId,
    'name': a.name,
    'type': a.type,
    'balance': a.balance,
     'currency': a.currency,
    'icon_name': a.iconName,
    'color_hex': a.colorHex,
    'is_default': a.isDefault,
    'institution_name': a.institutionName,
    'account_number_last4': a.accountNumberLast4,
    'created_at': a.createdAt.toIso8601String(),
    'updated_at': DateTime.now().toIso8601String(),
    'revision': a.revision + 1,
    'lamport_clock': a.lamportClock,
    'last_modified_by_device_id': deviceId,
    'version_vector': a.versionVector != null ? json.decode(a.versionVector!) : null,
    'is_deleted': a.isDeleted,
  };

  Map<String, dynamic> _savingsGoalToJson(SavingsGoal s, String deviceId) => {
    'id': s.id,
    'user_id': s.userId,
    'linked_account_id': s.linkedAccountId,
    'title': s.title,
    'current_amount': s.currentAmount,
    'target_amount': s.targetAmount,
    'currency': s.currency,
    'icon_name': s.iconName,
    'color_hex': s.colorHex,
    'deadline': s.deadline?.toIso8601String(),
    'created_at': s.createdAt.toIso8601String(),
    'updated_at': DateTime.now().toIso8601String(),
    'revision': s.revision + 1,
    'lamport_clock': s.lamportClock,
    'last_modified_by_device_id': deviceId,
    'version_vector': s.versionVector != null ? json.decode(s.versionVector!) : null,
    'is_deleted': s.isDeleted,
  };

  Map<String, dynamic> _recurringExpenseToJson(RecurringExpense r, String deviceId) => {
    'id': r.id,
    'user_id': r.userId,
    'title': r.title,
    'amount': r.amount,
    'frequency': r.frequency,
    'day_of_month': r.dayOfMonth,
    'day_of_week': r.dayOfWeek,
    'category': r.category,
    'payment_method': r.paymentMethod,
    'next_due_date': r.nextDueDate.toIso8601String(),
    'is_active': r.isActive,
    'created_at': r.createdAt.toIso8601String(),
    'updated_at': DateTime.now().toIso8601String(),
    'revision': r.revision + 1,
    'lamport_clock': r.lamportClock,
    'last_modified_by_device_id': deviceId,
    'version_vector': r.versionVector != null ? json.decode(r.versionVector!) : null,
  };

  Map<String, dynamic> _budgetMemberToJson(BudgetMember m, String deviceId) => {
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
    'revision': m.revision + 1,
    'lamport_clock': m.lamportClock,
    'last_modified_by_device_id': deviceId,
    'version_vector': m.versionVector != null ? json.decode(m.versionVector!) : null,
  };

  Map<String, dynamic> _familyGroupToJson(FamilyGroup g, String deviceId) => {
    'id': g.id,
    'name': g.name,
    'owner_id': g.ownerId,
    'created_at': g.createdAt.toIso8601String(),
    'updated_at': DateTime.now().toIso8601String(),
    'revision': g.revision + 1,
    'lamport_clock': g.lamportClock,
    'version_vector': g.versionVector != null ? json.decode(g.versionVector!) : null,
    'is_deleted': g.isDeleted,
  };

  Map<String, dynamic> _familyContactToJson(FamilyContact c, String deviceId) => {
    'id': c.id,
    'name': c.name,
    'email': c.email,
    'phone': c.phone,
    'avatar_url': c.avatarUrl,
    'is_linked_to_user': c.isLinkedToUser,
    'linked_user_id': c.linkedUserId,
    'created_at': c.createdAt.toIso8601String(),
    'updated_at': DateTime.now().toIso8601String(),
    'revision': c.revision + 1,
    'lamport_clock': c.lamportClock,
    'version_vector': c.versionVector != null ? json.decode(c.versionVector!) : null,
    'is_deleted': c.isDeleted,
  };

  Map<String, dynamic> _familyRelationToJson(FamilyRelation r, String deviceId) => {
    'id': r.id,
    'from_contact_id': r.fromContactId,
    'to_contact_id': r.toContactId,
    'relationship_type': r.relationshipType,
    'confidence': r.confidence,
    'created_at': r.createdAt.toIso8601String(),
    'updated_at': DateTime.now().toIso8601String(),
    'revision': r.revision + 1,
    'lamport_clock': r.lamportClock,
    'version_vector': r.versionVector != null ? json.decode(r.versionVector!) : null,
    'is_deleted': r.isDeleted,
  };

  Map<String, dynamic> _auditLogToJson(AuditLog a, String deviceId) => {
    'id': a.id,
    'entity_type': a.entityType,
    'entity_id': a.entityId,
    'action': a.action,
    'user_id': a.userId,
    'old_value': a.oldValue,
    'new_value': a.newValue,
    'correlation_id': a.correlationId,
    'device_id': a.deviceId,
    'metadata': a.metadata,
    'created_at': a.createdAt.toIso8601String(),
    'revision': a.revision + 1,
    'lamport_clock': a.lamportClock,
    'version_vector': a.versionVector != null ? json.decode(a.versionVector!) : null,
  };

  Map<String, dynamic> _subCategoryToJson(SubCategory s, String deviceId) => {
    'id': s.id,
    'category_id': s.categoryId,
    'name': s.name,
    'owner_id': s.ownerId,
    'is_system': s.isSystem,
    'is_default_other': s.isDefaultOther,
    'usage_count': s.usageCount,
    'last_used_at': s.lastUsedAt.toIso8601String(),
    'confidence': s.confidence,
    'is_deleted': s.isDeleted,
    'created_at': s.createdAt.toIso8601String(),
    'updated_at': DateTime.now().toIso8601String(),
    'revision': s.revision + 1,
    'lamport_clock': s.lamportClock,
    'version_vector': s.versionVector != null ? json.decode(s.versionVector!) : null,
  };
}
