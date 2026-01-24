/// CashPilot Database Configuration
/// Main Drift database class with DAOs
library;

import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:cashpilot/core/sync/sync_states.dart';
import 'package:drift/drift.dart';

import '../../services/security/key_manager.dart';
import 'encrypted_database.dart';
import 'tables.dart';
import '../../core/constants/app_constants.dart';
import '../../core/tier/tier_guard.dart';
// import '../../core/sync/record_state_machine.dart'; // Ghost feature removed
// import '../../core/sync/persistent_mutation_queue.dart'; // Ghost feature removed

part 'app_database.g.dart';

@DriftDatabase(tables: [
  Users,
  Budgets,
  SemiBudgets,
  Expenses,
  Accounts,
  BudgetMembers, 
  ActivityLogs,
  SyncQueue,
  RecurringExpenses,
  Subscriptions,
  SavingsGoals,
  Categories,
  Locations,
  GeocodingCache,
  ExpenseLocations,
  RecurringExpenseLocations,
  LocationAnalytics,
  Geofences,
  GeofenceEvents,
  Conflicts,     // NEW: Sync conflict resolution
  AuditEvents,   // NEW: Operation audit trail
  OutboxEvents,  // NEW: Offline event queue
  CategoryLearning, // NEW: ML user pattern learning
  SyncRecoveryState,    // NEW: Atomic sync state persistence
  SyncOperationsLog,    // NEW: Operation idempotency tracking
  SyncStateTransitions, // NEW: State machine audit trail
])
class AppDatabase extends _$AppDatabase {
  AppDatabase(QueryExecutor e) : super(e);

  // For testing
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => AppConstants.databaseVersion;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        
        // MANUALLY CREATE COMPOSITE INDEXES (High Performance)
        // Composite indexes cover both filtering AND sorting
        try {
          // Optimize dashboard recent expenses queries
          await customStatement('CREATE INDEX IF NOT EXISTS idx_expenses_user_date ON expenses (entered_by, date DESC);');
          
          // Optimize budget details expense list
          await customStatement('CREATE INDEX IF NOT EXISTS idx_expenses_budget_date ON expenses (budget_id, date DESC);');
          
          // Optimize category expense list
          await customStatement('CREATE INDEX IF NOT EXISTS idx_expenses_semibudget_date ON expenses (semi_budget_id, date DESC);');
          
          // Optimize budget list
          await customStatement('CREATE INDEX IF NOT EXISTS idx_budgets_owner_date ON budgets (owner_id, end_date ASC);');
        } catch (e) {
          print('Index creation warning: $e');
        }
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // Version 4: Add merchant_name
        if (from < 4) {
          await m.addColumn(expenses, expenses.merchantName);
          await customStatement('CREATE INDEX IF NOT EXISTS idx_expenses_merchant ON expenses(merchant_name);');
        }

        // Version 5: V6 Schema - Add new columns to categories
        if (from < 5) {
          try {
            // Add new columns to categories table
            await customStatement('ALTER TABLE categories ADD COLUMN owner_id TEXT;');
            await customStatement('ALTER TABLE categories ADD COLUMN name_translations TEXT;');
            await customStatement('ALTER TABLE categories ADD COLUMN tags TEXT;');
            debugPrint('[AppDatabase] Migration V5: Added owner_id, name_translations, tags to categories');
          } catch (e) {
            debugPrint('Migration V5 warning (columns may already exist): $e');
          }
        }

        // Version 6: Add syncState to Accounts
        if (from < 6) {
          try {
            await customStatement('ALTER TABLE accounts ADD COLUMN sync_state TEXT DEFAULT \'clean\';');
            debugPrint('[AppDatabase] Migration V6: Added sync_state to accounts');
          } catch (e) {
            debugPrint('Migration V6 warning: $e');
          }
        }

        // Version 7: Category Hierarchy & Budget Limits
        if (from < 7) {
          try {
            await customStatement('ALTER TABLE semi_budgets ADD COLUMN parent_category_id TEXT REFERENCES semi_budgets(id) ON DELETE CASCADE;');
            await customStatement('ALTER TABLE semi_budgets ADD COLUMN is_subcategory INTEGER DEFAULT 0;');
            await customStatement('ALTER TABLE semi_budgets ADD COLUMN suggested_percent REAL;');
            await customStatement('ALTER TABLE semi_budgets ADD COLUMN display_order INTEGER DEFAULT 0;');
            
            // Create indexes for performance
            await customStatement('CREATE INDEX IF NOT EXISTS idx_semi_budgets_parent ON semi_budgets(parent_category_id);');
            await customStatement('CREATE INDEX IF NOT EXISTS idx_semi_budgets_hierarchy ON semi_budgets(budget_id, parent_category_id);');
            
            debugPrint('[AppDatabase] Migration V7: Added category hierarchy support');
          } catch (e) {
            debugPrint('Migration V7 warning: $e');
          }
        }

        // Version 8: State Machine Columns for Production Sync
        if (from < 8) {
          try {
            // Add to all syncable tables
            await customStatement('ALTER TABLE budgets ADD COLUMN base_revision INTEGER;');
            await customStatement('ALTER TABLE budgets ADD COLUMN operation_id TEXT;');
            
            await customStatement('ALTER TABLE semi_budgets ADD COLUMN base_revision INTEGER;');
            await customStatement('ALTER TABLE semi_budgets ADD COLUMN operation_id TEXT;');
            
            await customStatement('ALTER TABLE expenses ADD COLUMN base_revision INTEGER;');
            await customStatement('ALTER TABLE expenses ADD COLUMN operation_id TEXT;');
            
            await customStatement('ALTER TABLE accounts ADD COLUMN base_revision INTEGER;');
            await customStatement('ALTER TABLE accounts ADD COLUMN operation_id TEXT;');
            
            await customStatement('ALTER TABLE savings_goals ADD COLUMN base_revision INTEGER;');
            await customStatement('ALTER TABLE savings_goals ADD COLUMN operation_id TEXT;');
            
            await customStatement('ALTER TABLE recurring_expenses ADD COLUMN base_revision INTEGER;');
            await customStatement('ALTER TABLE recurring_expenses ADD COLUMN operation_id TEXT;');
            
            await customStatement('ALTER TABLE users ADD COLUMN base_revision INTEGER;');
            await customStatement('ALTER TABLE users ADD COLUMN operation_id TEXT;');
            
            await customStatement('ALTER TABLE categories ADD COLUMN base_revision INTEGER;');
            await customStatement('ALTER TABLE categories ADD COLUMN operation_id TEXT;');
            
            debugPrint('[AppDatabase] Migration V8: Added state machine columns for production sync');
          } catch (e) {
            debugPrint('Migration V8 warning: $e');
          }
        }

        // Version 9: Add Sync State Tables + Conflict Resolution
        if (from < 9) {
          try {
            await m.createTable(syncRecoveryState);
            await m.createTable(syncOperationsLog);
            await m.createTable(syncStateTransitions);
            debugPrint('[AppDatabase] Migration V9: Added sync state tables');
          } catch (e) {
            debugPrint('Migration V9 warning (tables might exist): $e');
          }
        }

        // Version 3: Optimization Update
        if (to >= 3) {
          try {
            // Re-create indexes to ensure they exist (safe IF NOT EXISTS)
            await customStatement('CREATE INDEX IF NOT EXISTS idx_expenses_user_date ON expenses (entered_by, date DESC);');
            await customStatement('CREATE INDEX IF NOT EXISTS idx_expenses_budget_date ON expenses (budget_id, date DESC);');
            await customStatement('CREATE INDEX IF NOT EXISTS idx_expenses_semibudget_date ON expenses (semi_budget_id, date DESC);');
            await customStatement('CREATE INDEX IF NOT EXISTS idx_budgets_owner_date ON budgets (owner_id, end_date ASC);');
          } catch (e) {
            debugPrint('Index creation warning: $e');
          }
        }
      },
      beforeOpen: (details) async {
        // Enable foreign keys
        await customStatement('PRAGMA foreign_keys = ON');
      },
    );
  }

  // ============================================================
  // USER OPERATIONS
  // ============================================================

  Future<User?> getUserById(String id) {
    return (select(users)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<User?> getUserByEmail(String email) {
    return (select(users)..where((t) => t.email.equals(email))).getSingleOrNull();
  }

  Future<int> insertUser(UsersCompanion user) {
    return into(users).insert(user);
  }

  Future<bool> updateUser(UsersCompanion user) {
    return update(users).replace(user);
  }

  // ============================================================
  // BUDGET OPERATIONS
  // ============================================================

  Stream<List<Budget>> watchAllBudgets(String userId) {
    return (select(budgets)
          ..where((t) => t.ownerId.equals(userId) & t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  /// Watch budgets owned by user OR shared with user
  Stream<List<Budget>> watchAccessibleBudgets(String userId, String email) {
    final query = select(budgets).join([
      leftOuterJoin(budgetMembers, budgetMembers.budgetId.equalsExp(budgets.id))
    ]);

    query.where(
      budgets.isDeleted.equals(false) &
      (
        budgets.ownerId.equals(userId) |
        budgetMembers.userId.equals(userId) |
        budgetMembers.memberEmail.equals(email)
      )
    );

    query.orderBy([OrderingTerm.desc(budgets.createdAt)]);

    return query.watch().map((rows) {
      // Use toSet() to remove duplicates (if any) and convert back to list
      return rows.map((row) => row.readTable(budgets)).toSet().toList(); 
    });
  }

  Future<List<Budget>> getAllBudgets(String userId) {
    return (select(budgets)
          ..where((t) => t.ownerId.equals(userId) & t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  Future<Budget?> getBudgetById(String id) {
    return (select(budgets)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Stream<Budget?> watchBudgetById(String id) {
    return (select(budgets)..where((t) => t.id.equals(id))).watchSingleOrNull();
  }

  Future<List<Budget>> getActiveBudgets(String userId) {
    final now = DateTime.now();
    return (select(budgets)
          ..where((t) =>
              t.ownerId.equals(userId) &
              t.isDeleted.equals(false) &
              t.startDate.isSmallerOrEqualValue(now) &
              t.endDate.isBiggerOrEqualValue(now))
          ..orderBy([(t) => OrderingTerm.asc(t.endDate)]))
        .get();
  }

  /// Insert a new budget
  Future<int> insertBudget(BudgetsCompanion budget) async {
    // TIER ENFORCEMENT: Check if user can create budget
    final userId = budget.ownerId.value;
    final currentCount = await (select(budgets)
          ..where((t) => t.ownerId.equals(userId) & t.isDeleted.equals(false)))
        .get()
        .then((list) => list.length);
    
    // Get user's subscription tier
    final user = await (select(users)..where((t) => t.id.equals(userId))).getSingleOrNull();
    final tier = user?.subscriptionTier ?? 'free';
    
    final tierValidation = await TierGuard.canCreateBudget(
      tier: tier,
      currentBudgetCount: currentCount,
    );
    
    if (!tierValidation.isAllowed) {
      throw Exception('Tier limit reached: ${tierValidation.reason}');
    }
    
    return await into(budgets).insert(budget);
  }

  Future<bool> updateBudget(BudgetsCompanion budget) async {
    // SYNC STATE: Get current record to check state
    final budgetId = budget.id.value;
    final currentBudget = await (select(budgets)..where((t) => t.id.equals(budgetId))).getSingleOrNull();
    
    if (currentBudget != null) {
      // Mark as dirty directly (State Machine removed as unused feature)
      final updatedBudget = budget.copyWith(
        syncState: const Value('dirty'),
        revision: Value(currentBudget.revision + 1),
      );
      
      // Use update with where clause for partial updates (not replace)
      final rowsAffected = await (update(budgets)..where((t) => t.id.equals(budgetId))).write(updatedBudget);
      return rowsAffected > 0;
    }
    
    return false;
  }

  // ============================================================================
  // DELETE OPERATIONS (Soft Delete with Revision Increment)
  // ============================================================================

  /// Delete budget with CASCADE - marks all related expenses and semi-budgets as deleted
  /// Increments revision to ensure sync propagates the deletion
  Future<int> deleteBudget(String id) async {
  final now = DateTime.now();
  
  // Step 1: Cascade delete all expenses under this budget
  // Using Drift API ensures column name safety and proper updates
  final expensesToDelete = await (select(expenses)..where((t) => t.budgetId.equals(id) & t.isDeleted.not())).get();
  
  await batch((batch) {
    for (final e in expensesToDelete) {
      batch.update(
        expenses,
        ExpensesCompanion(
          isDeleted: const Value(true),
          updatedAt: Value(now),
          revision: Value(e.revision + 1),
          syncState: const Value('dirty'),
        ),
        where: (t) => t.id.equals(e.id),
      );
    }
  });
  debugPrint('[AppDatabase] Cascade deleted ${expensesToDelete.length} expenses for budget $id');
  
  // Step 2: Cascade delete all semi-budgets under this budget
  final semiBudgetsToDelete = await (select(semiBudgets)..where((t) => t.budgetId.equals(id) & t.isDeleted.not())).get();
  
  await batch((batch) {
    for (final s in semiBudgetsToDelete) {
      batch.update(
        semiBudgets,
        SemiBudgetsCompanion(
          isDeleted: const Value(true),
          updatedAt: Value(now),
          revision: Value(s.revision + 1),
        ),
        where: (t) => t.id.equals(s.id),
      );
    }
  });
  debugPrint('[AppDatabase] Cascade deleted ${semiBudgetsToDelete.length} semi-budgets for budget $id');
  
  // Step 3: Soft-delete the budget itself
  final budget = await (select(budgets)..where((t) => t.id.equals(id))).getSingleOrNull();
  if (budget != null) {
    return (update(budgets)..where((t) => t.id.equals(id))).write(BudgetsCompanion(
      isDeleted: const Value(true),
      updatedAt: Value(now),
      revision: Value(budget.revision + 1),
      syncState: const Value('dirty'),
    ));
  }
  return 0;
}

  // ============================================================
  // SEMI-BUDGET (CATEGORY) OPERATIONS
  // ============================================================

  Stream<List<SemiBudget>> watchSemiBudgetsByBudgetId(String budgetId) {
    return (select(semiBudgets)
          ..where((t) => t.budgetId.equals(budgetId) & t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm.asc(t.priority)]))
        .watch();
  }

  Future<List<SemiBudget>> getSemiBudgetsByBudgetId(String budgetId) {
    return (select(semiBudgets)
          ..where((t) => t.budgetId.equals(budgetId) & t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm.asc(t.priority)]))
        .get();
  }

  Future<SemiBudget?> getSemiBudgetById(String id) {
    return (select(semiBudgets)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// Insert a new semi-budget/category
  Future<int> insertSemiBudget(SemiBudgetsCompanion semiBudget) async {
    // TIER ENFORCEMENT: Check if user can add category to budget
    final budgetId = semiBudget.budgetId.value;
    final currentCount = await (select(semiBudgets)
          ..where((t) => t.budgetId.equals(budgetId) & t.isDeleted.equals(false)))
        .get()
        .then((list) => list.length);
    
    // Get budget owner for tier check
    final budget = await (select(budgets)..where((t) => t.id.equals(budgetId))).getSingleOrNull();
    if (budget != null) {
      // Get user's subscription tier
      final user = await (select(users)..where((t) => t.id.equals(budget.ownerId))).getSingleOrNull();
      final tier = user?.subscriptionTier ?? 'free';
      
      final tierValidation = await TierGuard.canAddCategory(
        tier: tier,
        currentCategoryCount: currentCount,
      );
      
      if (!tierValidation.isAllowed) {
        throw Exception('Tier limit reached: ${tierValidation.reason}');
      }
    }
    
    return await into(semiBudgets).insert(semiBudget);
  }

  Future<bool> updateSemiBudget(SemiBudgetsCompanion semiBudget) {
    return update(semiBudgets).replace(semiBudget);
  }

  // ============================================================
  // EXPENSE OPERATIONS
  // ============================================================

  Stream<List<Expense>> watchExpensesByBudgetId(String budgetId) {
    return (select(expenses)
          ..where((t) => t.budgetId.equals(budgetId) & t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .watch();
  }

  Future<List<Expense>> getExpensesByBudgetId(String budgetId) {
    return (select(expenses)
          ..where((t) => t.budgetId.equals(budgetId) & t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .get();
  }

  Stream<List<Expense>> watchExpensesBySemiBudgetId(String semiBudgetId) {
    return (select(expenses)
          ..where((t) => t.semiBudgetId.equals(semiBudgetId) & t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .watch();
  }

  Future<List<Expense>> getRecentExpenses(String userId, {int limit = 10}) {
    return (select(expenses)
          ..where((t) => t.enteredBy.equals(userId) & t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.date)])
          ..limit(limit))
        .get();
  }

  Stream<List<Expense>> watchRecentExpenses(String userId, {int limit = 50}) {
    return (select(expenses)
          ..where((t) => t.enteredBy.equals(userId) & t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.date)])
          ..limit(limit))
        .watch();
  }

  /// Get recent expenses as maps for duplicate detection
  Future<List<Map<String, dynamic>>> getRecentExpensesMaps(String userId, {int limit = 50}) async {
    final result = await (select(expenses)
          ..where((t) => t.enteredBy.equals(userId) & t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.date)])
          ..limit(limit))
        .get();
    
    return result.map((e) => {
      'id': e.id,
      'merchant_name': e.merchantName,
      'amount': e.amount,
      'expense_date': e.date.toIso8601String(),
      'currency_code': e.currency,
      'category_key': e.categoryId,
      'budget_id': e.budgetId,
    }).toList();
  }


  // ============================================================
  // REPORTING & ANALYTICS QUERIES (High Performance)
  // ============================================================

  /// Calculate total spent in a date range directly in SQL
  /// limit memory usage by not creating Expense objects
  Future<int> getTotalSpentInDateRange(String userId, DateTime start, DateTime end) async {
    final result = await (selectOnly(expenses)
          ..addColumns([expenses.amount.sum()])
          ..where(expenses.enteredBy.equals(userId) &
              expenses.isDeleted.equals(false) &
              expenses.date.isBiggerOrEqualValue(start) &
              expenses.date.isSmallerOrEqualValue(end)))
        .getSingle();
    return result.read(expenses.amount.sum()) ?? 0;
  }

  Future<List<Expense>> getExpensesInDateRange(String userId, DateTime start, DateTime end) {
    return (select(expenses)
          ..where((t) => 
            t.enteredBy.equals(userId) & 
            t.isDeleted.equals(false) &
            t.date.isBiggerOrEqualValue(start) &
            t.date.isSmallerOrEqualValue(end))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .get();
  }

  /// Get expenses by user in date range (for spending intelligence)
  Future<List<Expense>> getExpensesByUserInDateRange({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return (select(expenses)
          ..where((t) => 
            t.enteredBy.equals(userId) & 
            t.isDeleted.equals(false) &
            t.date.isBiggerOrEqualValue(startDate) &
            t.date.isSmallerOrEqualValue(endDate))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .get();
  }

  Stream<int> watchTotalSpentInBudget(String budgetId) {
    return (selectOnly(expenses)
          ..addColumns([expenses.amount.sum()])
          ..where(expenses.budgetId.equals(budgetId) & expenses.isDeleted.equals(false)))
        .watchSingle()
        .map((row) => row.read(expenses.amount.sum()) ?? 0);
  }

  /// Get total spent in a budget within a specific date range
  Future<int> getTotalSpentInBudgetDateRange(String budgetId, DateTime start, DateTime end) async {
    final result = await (selectOnly(expenses)
          ..addColumns([expenses.amount.sum()])
          ..where(expenses.budgetId.equals(budgetId) &
              expenses.isDeleted.equals(false) &
              expenses.date.isBiggerOrEqualValue(start) &
              expenses.date.isSmallerOrEqualValue(end)))
        .getSingle();
    return result.read(expenses.amount.sum()) ?? 0;
  }

  Future<int> getTotalSpentInBudget(String budgetId) async {
    final result = await (selectOnly(expenses)
          ..addColumns([expenses.amount.sum()])
          ..where(expenses.budgetId.equals(budgetId) & expenses.isDeleted.equals(false)))
        .getSingle();
    return result.read(expenses.amount.sum()) ?? 0;
  }

  Stream<int> watchTotalSpentInSemiBudget(String semiBudgetId) {
    return (selectOnly(expenses)
          ..addColumns([expenses.amount.sum()])
          ..where(expenses.semiBudgetId.equals(semiBudgetId) & expenses.isDeleted.equals(false)))
        .watchSingle()
        .map((row) => row.read(expenses.amount.sum()) ?? 0);
  }

  Stream<Map<String, int>> watchSemiBudgetSpending(String budgetId) {
    return (selectOnly(expenses)
          ..addColumns([expenses.semiBudgetId, expenses.amount.sum()])
          ..where(expenses.budgetId.equals(budgetId) & 
                 expenses.semiBudgetId.isNotNull() & 
                 expenses.isDeleted.equals(false))
          ..groupBy([expenses.semiBudgetId]))
        .watch()
        .map((rows) {
          final map = <String, int>{};
          for (final row in rows) {
            final id = row.read(expenses.semiBudgetId);
            final amount = row.read(expenses.amount.sum()) ?? 0;
            if (id != null) {
              map[id] = amount;
            }
          }
          return map;
        });
  }

  Future<int> getTotalSpentInSemiBudget(String semiBudgetId) async {
    final result = await (selectOnly(expenses)
          ..addColumns([expenses.amount.sum()])
          ..where(expenses.semiBudgetId.equals(semiBudgetId) & expenses.isDeleted.equals(false)))
        .getSingle();
    return result.read(expenses.amount.sum()) ?? 0;
  }

  Future<int> insertExpense(ExpensesCompanion expense) {
    return into(expenses).insert(expense);
  }

  /// Get a single expense by ID - efficient O(1) lookup
  Future<Expense?> getExpenseById(String id) {
    return (select(expenses)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<bool> updateExpense(ExpensesCompanion expense) {
    return update(expenses).replace(expense);
  }

  Future<int> deleteExpense(String id) {
    return (update(expenses)..where((t) => t.id.equals(id)))
        .write(const ExpensesCompanion(isDeleted: Value(true)));
  }

  // ============================================================
  // ACCOUNT OPERATIONS
  // ============================================================

  Stream<List<Account>> watchAllAccounts() {
    return (select(accounts)
          ..where((t) => t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.isDefault), (t) => OrderingTerm.asc(t.name)]))
        .watch();
  }

  Stream<List<Account>> watchAccountsByUserId(String userId) {
    return (select(accounts)
          ..where((t) => t.userId.equals(userId) & t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.isDefault), (t) => OrderingTerm.asc(t.name)]))
        .watch();
  }

  Future<List<Account>> getAllAccounts(String userId) {
    return (select(accounts)
          ..where((t) => t.userId.equals(userId) & t.isDeleted.equals(false)))
        .get();
  }

  Future<int> insertAccount(AccountsCompanion account) {
    return into(accounts).insert(account);
  }

  Future<bool> updateAccount(AccountsCompanion account) {
    return update(accounts).replace(account);
  }

  Future<int> deleteAccount(String id) {
    return (update(accounts)..where((t) => t.id.equals(id)))
        .write(const AccountsCompanion(isDeleted: Value(true)));
  }

  // ============================================================
  // SYNC QUEUE OPERATIONS
  // ============================================================

  Future<List<SyncQueueData>> getUnsyncedItems() {
    return (select(syncQueue)
          ..where((t) => t.isSynced.equals(false))
          ..orderBy([(t) => OrderingTerm.asc(t.timestamp)]))
        .get();
  }

  Future<int> addToSyncQueue(SyncQueueCompanion item) {
    return into(syncQueue).insert(item);
  }

  Future<int> markAsSynced(int id) {
    return (update(syncQueue)..where((t) => t.id.equals(id)))
        .write(const SyncQueueCompanion(isSynced: Value(true)));
  }

  Future<int> clearSyncedItems() {
    return (delete(syncQueue)..where((t) => t.isSynced.equals(true))).go();
  }

  // ============================================================
  // RECURRING EXPENSE OPERATIONS
  // ============================================================

  Stream<List<RecurringExpense>> watchRecurringExpenses(String userId) {
    return (select(recurringExpenses)
          ..where((t) => t.userId.equals(userId))
          ..orderBy([(t) => OrderingTerm.asc(t.nextDueDate)]))
        .watch();
  }

  Future<List<RecurringExpense>> getActiveRecurringExpenses(String userId) {
    return (select(recurringExpenses)
          ..where((t) => t.userId.equals(userId) & t.isActive.equals(true))
          ..orderBy([(t) => OrderingTerm.asc(t.nextDueDate)]))
        .get();
  }

  Future<int> insertRecurringExpense(RecurringExpensesCompanion expense) {
    return into(recurringExpenses).insert(expense);
  }

  Future<bool> updateRecurringExpense(RecurringExpensesCompanion expense) {
    return update(recurringExpenses).replace(expense);
  }

  Future<int> deleteRecurringExpense(String id) {
    return (delete(recurringExpenses)..where((t) => t.id.equals(id))).go();
  }

  // ============================================================
  // BUDGET MEMBER OPERATIONS (Formerly Family Members)
  // ============================================================

  /// Watch all family members across all budgets owned by this user
  Stream<List<BudgetMember>> watchAllFamilyMembers(String userId) async* {
    // First get all budgets owned by user
    final userBudgets = await getAllBudgets(userId);
    if (userBudgets.isEmpty) {
      yield [];
      return;
    }
    
    final budgetIds = userBudgets.map((b) => b.id).toList();
    
    // Watch members for all those budgets
    yield* (select(budgetMembers)
          ..where((t) => t.budgetId.isIn(budgetIds))
          ..orderBy([(t) => OrderingTerm.desc(t.invitedAt)]))
        .watch();
  }

  Stream<List<BudgetMember>> watchBudgetMembers(String budgetId) {
    return (select(budgetMembers)
          ..where((t) => t.budgetId.equals(budgetId))
          ..orderBy([(t) => OrderingTerm.desc(t.invitedAt)]))
        .watch();
  }

  Future<List<BudgetMember>> getBudgetMembers(String budgetId) {
    return (select(budgetMembers)
          ..where((t) => t.budgetId.equals(budgetId)))
        .get();
  }

  Future<int> insertBudgetMember(BudgetMembersCompanion member) {
    return into(budgetMembers).insert(member);
  }

  Future<bool> updateBudgetMember(BudgetMembersCompanion member) {
    return update(budgetMembers).replace(member);
  }

  Future<int> deleteBudgetMember(String id) {
    return (delete(budgetMembers)..where((t) => t.id.equals(id))).go();
  }
  // ============================================================
  // SAVINGS GOAL OPERATIONS
  // ============================================================

  Future<int> insertSavingsGoal(SavingsGoalsCompanion goal) {
    return into(savingsGoals).insert(goal);
  }

  Future<bool> updateSavingsGoal(SavingsGoalsCompanion goal) {
    return update(savingsGoals).replace(goal);
  }

  Future<int> deleteSavingsGoal(String id) {
    return (update(savingsGoals)..where((t) => t.id.equals(id)))
        .write(const SavingsGoalsCompanion(isDeleted: Value(true)));
  }

  // ============================================================
  // CATEGORY OPERATIONS
  // ============================================================

  Future<int> insertCategory(CategoriesCompanion category) {
    return into(categories).insert(category);
  }

  Future<bool> updateCategory(CategoriesCompanion category) {
    return update(categories).replace(category);
  }

  Future<List<Category>> getAllCategories() {
    return select(categories).get();
  }

  // ============================================================
  // BACKUP MANAGER SUPPORT METHODS
  // ============================================================

  /// Merges [sourceCategoryId] into [targetCategoryId].
  /// 
  /// 1. Updates all expenses using source to use target.
  /// 2. Updates all categories with source as parent to use target as parent.
  /// 3. Soft-deletes the source category.
  Future<void> mergeCategories(String sourceCategoryId, String targetCategoryId) {
    return transaction(() async {
      // 1. Update expenses
      await (update(expenses)..where((e) => e.categoryId.equals(sourceCategoryId)))
          .write(ExpensesCompanion(categoryId: Value(targetCategoryId)));
          
      // 2. Reparent children
      await (update(categories)..where((c) => c.parentId.equals(sourceCategoryId)))
          .write(CategoriesCompanion(parentId: Value(targetCategoryId)));
          
      // 3. Mark source as deleted
      await (update(categories)..where((c) => c.id.equals(sourceCategoryId)))
          .write(const CategoriesCompanion(isDeleted: Value(true)));
    });
  }

  /// Get all expenses for a user
  Future<List<Expense>> getAllExpensesForUser(String userId) {
    return (select(expenses)
          ..where((t) => t.enteredBy.equals(userId) & t.isDeleted.equals(false)))
        .get();
  }

  /// Get semi-budgets for a user (via budgets)
  Future<List<SemiBudget>> getSemiBudgetsForUser(String userId) async {
    return (select(semiBudgets)
          ..where((t) => t.isDeleted.equals(false)))
        .get();
  }

  /// Get semi-budgets for a specific budget
  Future<List<SemiBudget>> getSemiBudgetsForBudget(String budgetId) {
    return (select(semiBudgets)
          ..where((t) => t.budgetId.equals(budgetId) & t.isDeleted.equals(false)))
        .get();
  }

  /// Get savings goals for a user
  Future<List<SavingsGoal>> getSavingsGoals(String userId) {
    return (select(savingsGoals)
          ..where((t) => t.userId.equals(userId) & t.isDeleted.equals(false)))
        .get();
  }

  /// Get recurring expenses for a user
  Future<List<RecurringExpense>> getRecurringExpenses(String userId) {
    return (select(recurringExpenses)
          ..where((t) => t.userId.equals(userId) & t.isActive.equals(true)))
        .get();
  }

  /// Delete all expenses for a user (hard delete for backup restore)
  Future<int> deleteAllExpensesForUser(String userId) async {
    return (delete(expenses)..where((t) => t.enteredBy.equals(userId))).go();
  }

  /// Delete all semi-budgets for a user
  Future<int> deleteAllSemiBudgetsForUser(String userId) async {
    final userBudgets = await getAllBudgets(userId);
    int count = 0;
    for (final budget in userBudgets) {
      count += await (delete(semiBudgets)..where((t) => t.budgetId.equals(budget.id))).go();
    }
    return count;
  }

  /// Delete all budgets for a user
  Future<int> deleteAllBudgetsForUser(String userId) {
    return (delete(budgets)..where((t) => t.ownerId.equals(userId))).go();
  }

  /// Delete all accounts for a user
  Future<int> deleteAllAccountsForUser(String userId) {
    return (delete(accounts)..where((t) => t.userId.equals(userId))).go();
  }

  /// Delete all savings goals for a user
  Future<int> deleteAllSavingsGoalsForUser(String userId) {
    return (delete(savingsGoals)..where((t) => t.userId.equals(userId))).go();
  }

  /// Delete all recurring expenses for a user
  Future<int> deleteAllRecurringExpensesForUser(String userId) {
    return (delete(recurringExpenses)..where((t) => t.userId.equals(userId))).go();
  }
}

LazyDatabase _openConnection() {
  return EncryptedDatabaseExecutor.openEncryptedConnection(() async {
    // Get key from KeyManager
    final keyManager = KeyManager();
    await keyManager.initialize();
    return getEncryptionKeyFromKeyManager(keyManager);
  });
}
