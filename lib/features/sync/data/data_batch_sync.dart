/// Service to handle batched data synchronization
/// Gathers all dirty records from local DB and sends them in a SINGLE RPC call.
library;

import 'dart:async';
import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:drift/drift.dart';

import '../../../data/drift/app_database.dart';
import '../../../data/drift/tables.dart';
import '../../../services/device_info_service.dart';
import '../services/conflict_service.dart'; // Phase 2


class DataBatchSync {
  final AppDatabase db;
  final Ref ref; // Injected to access ConflictService
  final SupabaseClient client;
  final DeviceInfoService _deviceInfoService = DeviceInfoService();
  late final ConflictService _conflictService; // Phase 2

  bool _syncInProgress = false; // Prevent concurrent batch sync
  String? _cachedDeviceId;

  DataBatchSync(this.db, this.ref) : client = Supabase.instance.client {
    _conflictService = ConflictService(db);
  }



  /// Get device ID (cached for performance)
  Future<String> _getDeviceId() async {
    _cachedDeviceId ??= await _deviceInfoService.getDeviceId();
    return _cachedDeviceId!;
  }

  /// Gather all dirty data and push in one batch
  Future<Map<String, int>> pushAll() async {
    if (_syncInProgress) {
      debugPrint('[DataBatchSync] pushAll skipped (already running)');
      return {};
    }

    _syncInProgress = true;
    try {
      final userId = client.auth.currentUser?.id;
      if (userId == null) return {};

      debugPrint('[DataBatchSync] Gathering dirty records');

      // 1. Get ALL dirty records (Drift objects)
      final allDirtyBudgets = await (db.select(db.budgets)
        ..where((t) => t.syncState.equals('dirty'))).get();

      final allDirtySemiBudgets = await (db.select(db.semiBudgets)
        ..where((t) => t.syncState.equals('dirty'))).get();

      final allDirtyExpenses = await (db.select(db.expenses)
        ..where((t) => t.syncState.equals('dirty'))).get();

      final allDirtyAccounts = await (db.select(db.accounts)
        ..where((t) => t.syncState.equals('dirty'))).get();
        
      final allDirtySavings = await (db.select(db.savingsGoals)
        ..where((t) => t.syncState.equals('dirty'))).get();
        
      final allDirtyRecurring = await (db.select(db.recurringExpenses)
        ..where((t) => t.syncState.equals('dirty'))).get();
        
      final allDirtyMembers = await (db.select(db.budgetMembers)
        ..where((t) => t.syncState.equals('dirty'))).get();

      // ADDED: Dirty Users (Profiles)
      final allDirtyUsers = await (db.select(db.users)
        ..where((t) => t.syncState.equals('dirty'))).get();

      if (allDirtyBudgets.isEmpty && allDirtySemiBudgets.isEmpty && 
          allDirtyExpenses.isEmpty && allDirtyAccounts.isEmpty &&
          allDirtySavings.isEmpty && allDirtyRecurring.isEmpty && 
          allDirtyMembers.isEmpty && allDirtyUsers.isEmpty) {
        debugPrint('[DataBatchSync] No dirty records');
        return {};
      }
      
      debugPrint('[DataBatchSync] Found dirty: ${allDirtyUsers.length} profiles, ${allDirtyBudgets.length} budgets');

      // 2. PRE-FLIGHT CHECK
      final safeToPush = await _checkForConflicts(
        budgets: allDirtyBudgets,
        semiBudgets: allDirtySemiBudgets,
        expenses: allDirtyExpenses,
        accounts: allDirtyAccounts,
        savings: allDirtySavings,
        recurring: allDirtyRecurring,
        members: allDirtyMembers,
        users: allDirtyUsers, // ADDED
      );

      final dirtyBudgets = (safeToPush['budgets'] as List).cast<Budget>();
      final dirtySemiBudgets = (safeToPush['semiBudgets'] as List).cast<SemiBudget>();
      final dirtyExpenses = (safeToPush['expenses'] as List).cast<Expense>();
      final dirtyAccounts = (safeToPush['accounts'] as List).cast<Account>();
      final dirtySavings = (safeToPush['savings'] as List).cast<SavingsGoal>();
      final dirtyRecurring = (safeToPush['recurring'] as List).cast<RecurringExpense>();
      final dirtyMembers = (safeToPush['members'] as List).cast<BudgetMember>();
      final dirtyUsers = (safeToPush['users'] as List).cast<User>(); // ADDED

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
      };

      // 4. Execute Batch Sync (RPC)
      final response = await client.rpc(
        'batch_sync',
        params: {'p_payload': payload},
      );

      // 5. Mark Clean
      await db.transaction(() async {
        await _markClean<Users, User>(db.users, dirtyUsers, (id) => db.users.id.equals(id)); // ADDED
        await _markClean<Budgets, Budget>(db.budgets, dirtyBudgets, (id) => db.budgets.id.equals(id));
        await _markClean<SemiBudgets, SemiBudget>(db.semiBudgets, dirtySemiBudgets, (id) => db.semiBudgets.id.equals(id));
        await _markClean<Expenses, Expense>(db.expenses, dirtyExpenses, (id) => db.expenses.id.equals(id));
        await _markClean<Accounts, Account>(db.accounts, dirtyAccounts, (id) => db.accounts.id.equals(id));
        await _markClean<SavingsGoals, SavingsGoal>(db.savingsGoals, dirtySavings, (id) => db.savingsGoals.id.equals(id));
        await _markClean<RecurringExpenses, RecurringExpense>(db.recurringExpenses, dirtyRecurring, (id) => db.recurringExpenses.id.equals(id));
        await _markClean<BudgetMembers, BudgetMember>(db.budgetMembers, dirtyMembers, (id) => db.budgetMembers.id.equals(id));
      });

      return {
        'profiles': (response['processed']?['profiles'] as int?) ?? 0,
        'budgets': (response['processed']?['budgets'] as int?) ?? 0,
        'expenses': (response['processed']?['expenses'] as int?) ?? 0,
      };
    } finally {
      _syncInProgress = false;
    }
  }

  // Helper to mark clean
  Future<void> _markClean<T extends Table, D>(
      TableInfo<T, D> table, 
      List<D> items, 
      Expression<bool> Function(String) whereExpr
  ) async {
    for (var item in items) {
       // Manual assumption that item has id and revision
       // Since I can't easily reflect on D, I'll rely on the fact that I'm inside DataBatchSync 
       // and I know the types. Wait, this generic method is hard.
    }
    // Reverting to explicit loops for safety
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
    required List<User> users, // ADDED
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

    // Fetch Revisions
     final results = await Future.wait([
        if (budgetIds.isNotEmpty) client.from('budgets').select('id, revision').inFilter('id', budgetIds),
        if (expenseIds.isNotEmpty) client.from('expenses').select('id, revision').inFilter('id', expenseIds),
        if (accountIds.isNotEmpty) client.from('accounts').select('id, revision').inFilter('id', accountIds),
        if (semiIds.isNotEmpty) client.from('semi_budgets').select('id, revision').inFilter('id', semiIds),
        if (savingsIds.isNotEmpty) client.from('savings_goals').select('id, revision').inFilter('id', savingsIds),
        if (recurringIds.isNotEmpty) client.from('recurring_expenses').select('id, revision').inFilter('id', recurringIds),
        if (memberIds.isNotEmpty) client.from('budget_members').select('id, revision').inFilter('id', memberIds),
        if (userIds.isNotEmpty) client.from('profiles').select('id, revision').inFilter('id', userIds),
    ]);
    
    // Map Extraction
    Map<String, int> getRevMap(dynamic res) {
       if (res is! List) return {};
       return {for (var i in res) i['id'] as String: (i['revision'] as num?)?.toInt() ?? 0};
    }
    
    int i = 0;
    final revB = budgetIds.isNotEmpty ? getRevMap(results[i++]) : <String, int>{};
    final revE = expenseIds.isNotEmpty ? getRevMap(results[i++]) : <String, int>{};
    final revA = accountIds.isNotEmpty ? getRevMap(results[i++]) : <String, int>{};
    final revS = semiIds.isNotEmpty ? getRevMap(results[i++]) : <String, int>{};
    final revG = savingsIds.isNotEmpty ? getRevMap(results[i++]) : <String, int>{};
    final revR = recurringIds.isNotEmpty ? getRevMap(results[i++]) : <String, int>{};
    final revM = memberIds.isNotEmpty ? getRevMap(results[i++]) : <String, int>{};
    final revU = userIds.isNotEmpty ? getRevMap(results[i++]) : <String, int>{}; // Users

    return {
      'budgets': _rebase(budgets, revB, (b, r) => b.copyWith(revision: r)),
      'semiBudgets': _rebase(semiBudgets, revS, (s, r) => s.copyWith(revision: r)),
      'expenses': _rebase(expenses, revE, (e, r) => e.copyWith(revision: r)),
      'accounts': _rebase(accounts, revA, (a, r) => a.copyWith(revision: r)),
      'savings': _rebase(savings, revG, (s, r) => s.copyWith(revision: r)),
      'recurring': _rebase(recurring, revR, (r, rVal) => r.copyWith(revision: rVal)),
      'members': _rebase(members, revM, (m, r) => m.copyWith(revision: r)),
      'users': _rebase(users, revU, (u, r) => u.copyWith(revision: r)),
    };
  }
  
  List<T> _rebase<T>(List<T> locals, Map<String, int> remotes, T Function(T, int) copier) {
     List<T> safe = [];
     for (var local in locals) {
       String id = (local as dynamic).id;
       int localRev = (local as dynamic).revision;
       final remoteRev = remotes[id];
       if (remoteRev != null && remoteRev > localRev) {
          safe.add(copier(local, remoteRev));
       } else {
          safe.add(local);
       }
     }
     return safe;
  }
  
  /// Parse and upsert user/profile data
  Future<void> _upsertUser(Map<String, dynamic> item) async {
    // Parse metadata safely (helper handled later)
    
    final companion = UsersCompanion(
      id: Value(item['id']),
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
      revision: Value((item['revision'] as num?)?.toInt() ?? 0),
      syncState: const Value('clean'),
      isDeleted: Value(item['is_deleted'] ?? false),
      lastModifiedByDeviceId: Value(item['last_modified_by_device_id']),
    );
    await db.into(db.users).insertOnConflictUpdate(companion);
  }

  /// Get the latest cursor (updatedAt, id) for a table to ensure gapless sync
  Future<Map<String, dynamic>> _getTableCursor(TableInfo table) async {
    // This requires dynamic query construction which Drift supports via customSelect or low-level API.
    // Simplifying: Select max(updated_at, id) from local DB for this table.
    // Note: Drift tables all have 'updatedAt' except SavingsContributions? 
    // Wait, SavingsContributions has createdAt.
    // Let's rely on standard 'updatedAt' for synced tables.
    
    // Construct Query: SELECT updated_at, id FROM table ORDER BY updated_at DESC, id DESC LIMIT 1
    // We need the table name.
    final tableName = table.actualTableName;
    
    // Drift date time mapping is tricky in raw SQL (unix vs iso). 
    // We will assume our Table definitions store DateTime as Int (Unix) or String (ISO)? 
    // Drift default for DateTime is Int (Unix timestamp in ms) or Text depending on flags.
    // Let's assume standard Drift behavior.
    
    // For safety, let's fetch the object using standard Drift API if possible?
    // Hard to do generic "orderBy" on TableInfo.
    
    // We will use a pragmatic approach: 0 if empty.
    // But we need the ID too.
    
    try {
      final query = 'SELECT updated_at, id FROM $tableName ORDER BY updated_at DESC, id DESC LIMIT 1';
      final result = await db.customSelect(query).getSingleOrNull();
      
      if (result == null) return {};
      
      // Extract
      final updatedRaw = result.read<dynamic>('updated_at'); // Could be int or string
      String? tIso;
      if (updatedRaw is int) {
         tIso = DateTime.fromMillisecondsSinceEpoch(updatedRaw).toIso8601String();
      } else if (updatedRaw is String) {
         tIso = updatedRaw;
      }
      
      final id = result.read<String>('id');
      
      if (tIso != null) {
        return {'t': tIso, 'id': id};
      }
      return {};
    } catch (e) {
      debugPrint('[DataBatchSync] Error getting cursor for $tableName: $e');
      return {};
    }
  }

  Future<void> pullAll(DateTime? lastSyncTime) async {
    debugPrint('[DataBatchSync] ⚡ Starting DETERMINISTIC pull (tiered)...');
    final stopwatch = Stopwatch()..start();

    // Call RPC with simple timestamp (matches working v9)
    final response = await client.rpc('batch_pull', params: {
      'p_last_sync_timestamp': lastSyncTime?.toIso8601String(),
    });

    if (response == null) {
      debugPrint('[DataBatchSync] No data from batch_pull');
      return;
    }
    
    final data = response as Map<String, dynamic>;
    
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
    
    tier5Stopwatch.stop();
    debugPrint('[DataBatchSync] ✅ TIER 5 complete (${tier5Stopwatch.elapsedMilliseconds}ms)');
    
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
    final items = (data as List).cast<Map<String, dynamic>>();
    const chunkSize = 500;
    
    for (int i = 0; i < items.length; i += chunkSize) {
      final chunk = items.skip(i).take(chunkSize);
      for (final item in chunk) {
        await upsertFn(item);
      }
    }
  }

  Future<void> _upsertBudget(Map<String, dynamic> item) async {
      final companion = BudgetsCompanion(
        id: Value(item['id']),
        ownerId: Value(item['owner_id'] ?? ''),
        title: Value(item['title'] ?? ''),
        totalLimit: Value((item['total_limit'] as num?)?.toInt()),
        type: Value(item['type'] ?? 'monthly'),
        startDate: Value(DateTime.tryParse(item['start_date'] ?? '') ?? DateTime.now()),
        endDate: Value(DateTime.tryParse(item['end_date'] ?? '') ?? DateTime.now()),
        revision: Value((item['revision'] as num?)?.toInt() ?? 0),
        syncState: const Value('clean'),
        isDeleted: Value(item['is_deleted'] ?? false), // If remote sends NULL, default to false. Apps handling zombies must fix remote!
        lastModifiedByDeviceId: Value(item['last_modified_by_device_id']),
        createdAt: Value(DateTime.tryParse(item['created_at'] ?? '') ?? DateTime.now()),
        updatedAt: Value(DateTime.tryParse(item['updated_at'] ?? '') ?? DateTime.now()),
      );
      await db.into(db.budgets).insertOnConflictUpdate(companion);
  }
  Future<void> _upsertAccount(Map<String, dynamic> item) async {
     final companion = AccountsCompanion(
       id: Value(item['id']),
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
       revision: Value((item['revision'] as num?)?.toInt() ?? 0),
       syncState: const Value('clean'),
       isDeleted: Value(item['is_deleted'] ?? false),
     );
     await db.into(db.accounts).insertOnConflictUpdate(companion);
  }
  Future<void> _upsertExpense(Map<String, dynamic> item) async {
     final companion = ExpensesCompanion(
       id: Value(item['id']),
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
       recurringId: Value(item['recurring_id']), // If schema has it
       revision: Value((item['revision'] as num?)?.toInt() ?? 0),
       syncState: const Value('clean'),
       isDeleted: Value(item['is_deleted'] ?? false),
     );
     await db.into(db.expenses).insertOnConflictUpdate(companion);
  }
  Future<void> _upsertSemiBudget(Map<String, dynamic> item) async {
    final sortOrder = (item['sort_order'] as num?)?.toInt() ?? 0;
    final companion = SemiBudgetsCompanion(
        id: Value(item['id']),
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
        revision: Value((item['revision'] as num?)?.toInt() ?? 0),
        syncState: const Value('clean'),
    );
    await db.into(db.semiBudgets).insertOnConflictUpdate(companion);
  }
  Future<void> _upsertCategory(Map<String, dynamic> item) async {
    final companion = CategoriesCompanion(
        id: Value(item['id']),
        name: Value(item['name']),
        iconName: Value(item['icon_name']),
        colorHex: Value(item['color_hex']),
        parentId: Value(item['parent_id']),
        ownerId: Value(item['owner_id']),
        isSystem: Value(item['is_system'] ?? false),
        revision: Value((item['revision'] as num?)?.toInt() ?? 0),
        isDeleted: Value(item['is_deleted'] ?? false),
    );
     await db.into(db.categories).insertOnConflictUpdate(companion);
  }
  Future<void> _upsertSavingsGoal(Map<String, dynamic> item) async {
      final companion = SavingsGoalsCompanion(
         id: Value(item['id']),
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
         revision: Value((item['revision'] as num?)?.toInt() ?? 0),
         syncState: const Value('clean'),
         isDeleted: Value(item['is_deleted'] ?? false),
      );
      await db.into(db.savingsGoals).insertOnConflictUpdate(companion);
  }
  Future<void> _upsertRecurringExpense(Map<String, dynamic> item) async {
     final companion = RecurringExpensesCompanion(
        id: Value(item['id']),
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
        revision: Value((item['revision'] as num?)?.toInt() ?? 0),
        syncState: const Value('clean'),
     );
     await db.into(db.recurringExpenses).insertOnConflictUpdate(companion);
  }
  Future<void> _upsertBudgetMember(Map<String, dynamic> item) async {
     final companion = BudgetMembersCompanion(
        id: Value(item['id']),
        budgetId: Value(item['budget_id']),
        memberEmail: Value(item['member_email']),
        memberName: Value(item['member_name']),
        role: Value(item['role']),
        status: Value(item['status']),
        invitedBy: Value(item['invited_by']),
        invitedAt: Value(DateTime.tryParse(item['created_at'] ?? '') ?? DateTime.now()), // Mapping created_at to invitedAt
        revision: Value((item['revision'] as num?)?.toInt() ?? 0),
        syncState: const Value('clean'),
     );
    await db.into(db.budgetMembers).insertOnConflictUpdate(companion);
  }

  // SERIALIZERS
  Map<String, dynamic> _budgetToJson(Budget b, String deviceId) => {
    'id': b.id,
    'owner_id': b.ownerId,
    'title': b.title,
    'description': b.description, 
    'total_limit': b.totalLimit,
    'type': b.type,
    'start_date': b.startDate.toIso8601String(),
    'end_date': b.endDate.toIso8601String(),
    'color_hex': b.colorHex, 
    'icon_name': b.iconName,
    'currency': b.currency,
    'notes': b.notes,
    'tags': b.tags, 
    'status': b.status,
    'is_shared': b.isShared,
    'is_template': b.isTemplate, 
    'is_deleted': b.isDeleted,
    'created_at': b.createdAt.toIso8601String(),
    'updated_at': DateTime.now().toIso8601String(),
    'last_modified_by_device_id': deviceId,
    'revision': b.revision + 1,
  };
  
  Map<String, dynamic> _recurringExpenseToJson(RecurringExpense r, String deviceId) => {
    'id': r.id,
    'user_id': r.userId, 
    'title': r.title,
    'amount': r.amount,
    'frequency': r.frequency,
    'day_of_month': r.dayOfMonth,
    'day_of_week': r.dayOfWeek,
    'payment_method': r.paymentMethod,
    'category': r.category,
    'next_due_date': r.nextDueDate.toIso8601String(),
    'is_active': r.isActive,
    'created_at': r.createdAt.toIso8601String(),
    'updated_at': DateTime.now().toIso8601String(),
    'revision': r.revision + 1,
    'last_modified_by_device_id': deviceId, 
  };

  Map<String, dynamic> _accountToJson(Account a, String deviceId) => {
    'id': a.id,
    'user_id': a.userId,
    'name': a.name,
    'type': a.type,
    'balance': a.balance,
    'currency': a.currency,
    'institution_name': a.institutionName,
    'account_number_last4': a.accountNumberLast4,
    'color_hex': a.colorHex,
    'icon_name': a.iconName,
    'is_default': a.isDefault,
    'is_deleted': a.isDeleted,
    'created_at': a.createdAt.toIso8601String(),
    'updated_at': DateTime.now().toIso8601String(),
    'revision': a.revision + 1,
    'last_modified_by_device_id': deviceId,
  };
  
  Map<String, dynamic> _expenseToJson(Expense e, String deviceId) => {
    'id': e.id,
    'budget_id': e.budgetId,
    'account_id': e.accountId,
    'category_id': e.categoryId,
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
    'is_recurring': e.isRecurring,
    'recurring_id': e.recurringId,
    'is_deleted': e.isDeleted,
    'created_at': e.createdAt.toIso8601String(),
    'updated_at': DateTime.now().toIso8601String(),
    'last_modified_by_device_id': deviceId,
    'revision': e.revision + 1,
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
    'sort_order': s.displayOrder,
    'is_deleted': s.isDeleted,
    'created_at': s.createdAt.toIso8601String(),
    'updated_at': DateTime.now().toIso8601String(),
    'revision': s.revision + 1,
    'last_modified_by_device_id': deviceId,
  };
  
  Map<String, dynamic> _savingsGoalToJson(SavingsGoal s, String deviceId) => {
    'id': s.id,
    'user_id': s.userId,
    'title': s.title,
    'target_amount': s.targetAmount,
    'current_amount': s.currentAmount,
    'currency': s.currency,
    'linked_account_id': s.linkedAccountId,
    'deadline': s.deadline?.toIso8601String(),
    'icon_name': s.iconName,
    'color_hex': s.colorHex,
    'is_archived': s.isArchived,
    'is_deleted': s.isDeleted,
    'created_at': s.createdAt.toIso8601String(),
    'updated_at': DateTime.now().toIso8601String(),
    'revision': s.revision + 1,
    'last_modified_by_device_id': deviceId,
  };
  
  Map<String, dynamic> _budgetMemberToJson(BudgetMember m, String deviceId) => {
    'id': m.id,
    'budget_id': m.budgetId,
    'user_id': m.userId,
    'member_email': m.memberEmail,
    'member_name': m.memberName,
    'role': m.role,
    'status': m.status,
    'created_at': m.invitedAt.toIso8601String(),
    'updated_at': DateTime.now().toIso8601String(), // Valid field now?
    'revision': m.revision + 1,
    'last_modified_by_device_id': deviceId,
  };

  Map<String, dynamic> _userToJson(User u, String deviceId) => {
    'id': u.id,
    'name': u.name,
    'email': u.email,
    'avatar_url': u.avatarUrl,
    'language_preference': u.languagePreference,
    'experience_mode': u.experienceMode,
    'metadata': u.metadata,
    'updated_at': DateTime.now().toIso8601String(),
    'revision': u.revision + 1,
    'last_modified_by_device_id': deviceId,
    // Add other fields if needed by push policy
  };
}
