library;

import 'package:cashpilot/core/constants/default_categories.dart' show industrialCategories;
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart';


import 'tables.dart';
import '../../core/constants/app_constants.dart';
import '../../services/device_info_service.dart';
import '../../core/sync/vector_clock.dart';
import '../../core/tier/tier_guard.dart';
// import '../../core/sync/record_state_machine.dart'; // Ghost feature removed
// import '../../core/sync/persistent_mutation_queue.dart'; // Ghost feature removed

import 'connection.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [ 
  Users,
  Budgets,
  SemiBudgets,
  Accounts,
  Expenses,
  BudgetMembers,
  ActivityLogs,
  AuditLogs,
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
  Conflicts,
  SubCategories,
  AuditEvents,
  OutboxEvents,
  CategoryLearning,
  SyncRecoveryState,
  SyncOperationsLog,
  SyncStateTransitions,
  FamilyGroups,
  FamilyContacts,
  FamilyRelations,
  KnowledgeArticles,
  FinancialTips,
  Assets,
  Liabilities,
  ValuationHistory,
  LedgerEvents,
  BudgetHealthSnapshots,
  CanonicalLedger,
  UserConsents,
  FinancialIngestionLogs,
])
class AppDatabase extends _$AppDatabase {
  // Default constructor uses platform-specific connection
  AppDatabase() : super(connect());

  // Executor constructor for advanced usage (testing, etc.)
  AppDatabase.executor(super.e);

  // For testing
  AppDatabase.forTesting(super.e);

  final DeviceInfoService _deviceInfoService = DeviceInfoService();

  // Helper to safely serialize Drift Companions to JSON
  Map<String, dynamic> _serializeCompanion(UpdateCompanion companion) {
    return companion.toColumns(true).map((key, expression) {
      Object? value;
      if (expression is Variable) {
        value = expression.value;
      } else if (expression is Constant) {
        value = expression.value;
      } else {
        value = expression.toString();
      }

      if (value is DateTime) {
        return MapEntry(key, value.toIso8601String());
      }
      return MapEntry(key, value);
    });
  }

  // ============================================================
  // KNOWLEDGE BASE OPERATIONS (V12)
  // ============================================================

  Future<List<KnowledgeArticleData>> getDriftArticles({
    String? topic,
    List<String>? tags,
    String? languageCode,
    String? localeCode,
    int limit = 10,
    int offset = 0,
  }) {
    var query = select(knowledgeArticles)..where((t) => t.isDeleted.equals(false));

    if (topic != null) {
      query = query..where((t) => t.topic.equals(topic));
    }

    final lang = languageCode ?? localeCode;
    if (lang != null) {
      query = query..where((t) => t.languageCode.equals(lang));
    }

    if (tags != null && tags.isNotEmpty) {
      for (final tag in tags) {
        query = query..where((t) => t.tags.like('%"$tag"%'));
      }
    }
    
    return (query..limit(limit, offset: offset)).get();
  }

  Future<KnowledgeArticleData?> getDriftArticleById(String id) async {
    return (select(knowledgeArticles)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<List<KnowledgeArticleData>> searchDriftArticles(String query) {
    return (select(knowledgeArticles)
          ..where((t) => (t.title.like('%$query%') | t.summary.like('%$query%') | t.content.like('%$query%')) & t.isDeleted.equals(false))
          ..limit(20))
        .get();
  }

  Future<List<FinancialTipData>> getDriftFinancialTips({
    String? category,
    String? languageCode,
    String? localeCode,
    int limit = 10,
  }) {
    var query = select(financialTips)..where((t) => t.isDeleted.equals(false));

    if (category != null) {
      query = query..where((t) => t.category.equals(category));
    }

    final lang = languageCode ?? localeCode;
    if (lang != null) {
      query = query..where((t) => t.languageCode.equals(lang));
    }

    return (query..limit(limit)).get();
  }

  @override
  int get schemaVersion => AppConstants.databaseVersion;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        try {
          await m.createAll();
        } catch (e) {
          debugPrint('[AppDatabase] Warning during onCreate (possibly partial initialization): $e');
          // We continue to seeding - if tables exist, seedMasterCategories uses insertOrReplace
        }
        
        // MANUALLY CREATE Master Categories
        await seedMasterCategories();

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

        // Version 10: Family Management System
        if (from < 10) {
          try {
            await m.createTable(familyGroups);
            await m.createTable(familyContacts);
            await m.createTable(familyRelations);
            debugPrint('[AppDatabase] Migration V10: Added family management tables');
          } catch (e) {
            debugPrint('Migration V10 warning: $e');
          }
        }

        // Version 14: Distributed State (Lamport Clocks)
        // Ensure all syncable tables have the clock columns
        if (from < 14) {
          try {
            final tables = [
              'budgets', 'semi_budgets', 'expenses', 'accounts', 
              'savings_goals', 'recurring_expenses', 'budget_members', 'categories',
              'users', 'family_groups', 'family_contacts', 'family_relations'
            ];

            for (final table in tables) {
              await customStatement('ALTER TABLE $table ADD COLUMN lamport_clock INTEGER DEFAULT 0;');
              await customStatement('ALTER TABLE $table ADD COLUMN version_vector TEXT;');
            }
            debugPrint('[AppDatabase] Migration V14: Added distributed state columns');
          } catch (e) {
             debugPrint('Migration V14 warning (columns might exist): $e');
          }
        }


        // Version 11: Enterprise IQ & Audit Logs
        if (from < 11) {
          try {
            await m.addColumn(expenses, expenses.confidence);
            await m.addColumn(expenses, expenses.source);
            await m.addColumn(expenses, expenses.isAiAssigned);
            await m.addColumn(expenses, expenses.isVerified);
            await m.createTable(auditLogs);
            debugPrint('[AppDatabase] Migration V11: Added Enterprise IQ & Audit Logs');
          } catch (e) {
            debugPrint('Migration V11 warning: $e');
          }
        }

        // Version 12: Knowledge Database
        if (from < 12) {
          try {
            await m.createTable(knowledgeArticles);
            await m.createTable(financialTips);
            
            // Create indexes for performance
            await customStatement('CREATE INDEX IF NOT EXISTS idx_knowledge_topic ON knowledge_articles(topic);');
            await customStatement('CREATE INDEX IF NOT EXISTS idx_financial_tips_category ON financial_tips(category);');
            
            debugPrint('[AppDatabase] Migration V12: Added Knowledge Database tables');
          } catch (e) {
             debugPrint('Migration V12 warning: $e');
          }
        }

        // Version 13: Enhanced Observability (Correlation IDs, Severity, deviceId)
        if (from < 13) {
          try {
            // Update AuditLogs
            await customStatement('ALTER TABLE audit_logs ADD COLUMN correlation_id TEXT;');
            await customStatement('ALTER TABLE audit_logs ADD COLUMN device_id TEXT;');
            
            // Update AuditEvents
            await customStatement('ALTER TABLE audit_events ADD COLUMN correlation_id TEXT;');
            await customStatement('ALTER TABLE audit_events ADD COLUMN severity TEXT DEFAULT \'info\';');
            
            debugPrint('[AppDatabase] Migration V13: Enhanced Observability and Correlation IDs');
          } catch (e) {
            debugPrint('Migration V13 warning: $e');
          }
        }

        // Version 15: Financial Operating System Upgrade (Net Worth & Event Ledger)
        if (from < 15) {
          try {
            await m.createTable(assets);
            await m.createTable(liabilities);
            await m.createTable(valuationHistory);
            await m.createTable(ledgerEvents);
            
            // Create indexes for performance
            await customStatement('CREATE INDEX IF NOT EXISTS idx_assets_user ON assets(user_id);');
            await customStatement('CREATE INDEX IF NOT EXISTS idx_liabilities_user ON liabilities(user_id);');
            await customStatement('CREATE INDEX IF NOT EXISTS idx_valuation_entity ON valuation_history(entity_type, entity_id);');
            await customStatement('CREATE INDEX IF NOT EXISTS idx_ledger_timestamp ON ledger_events(timestamp);');
            
            debugPrint('[AppDatabase] Migration V15: Added Financial OS tables (Net Worth & Ledger)');
          } catch (e) {
             debugPrint('Migration V15 warning: $e');
          }
        }

        // Version 16: Behavioral Intelligence (Mood & Social Context)
        if (from < 16) {
          try {
            await m.addColumn(expenses, expenses.mood);
            await m.addColumn(expenses, expenses.socialContext);
            await m.addColumn(liabilities, liabilities.notes);
            debugPrint('[AppDatabase] Migration V16: Added Mood, Social Context, and Liability Notes');
          } catch (e) {
            debugPrint('Migration V16 warning: $e');
          }
        }

        // Version 17: Budget Health Snapshots (Already handled in onCreate)
        if (from < 17) {
          try {
            await m.createTable(budgetHealthSnapshots);
            debugPrint('[AppDatabase] Migration V17: Added Budget Health Snapshots');
          } catch (e) {
            debugPrint('Migration V17 warning: $e');
          }
        }

        // Version 18: Ensure distributed state columns exist (Retroactive fix for V14)
        if (from < 18) {
          try {
            final tables = [
              'budgets', 'semi_budgets', 'expenses', 'accounts',
              'savings_goals', 'recurring_expenses', 'budget_members', 'categories',
              'users', 'family_groups', 'family_contacts', 'family_relations'
            ];

            for (final table in tables) {
              // Try to add columns - will fail silently if they already exist
              try {
                await customStatement('ALTER TABLE $table ADD COLUMN lamport_clock INTEGER DEFAULT 0;');
              } catch (e) {
                // Column already exists, ignore
              }
              try {
                await customStatement('ALTER TABLE $table ADD COLUMN version_vector TEXT;');
              } catch (e) {
                // Column already exists, ignore
              }
            }
            debugPrint('[AppDatabase] Migration V18: Ensured distributed state columns exist');
          } catch (e) {
            debugPrint('Migration V18 warning: $e');
          }
        }

        // Version 19: Category-SemiBudget Link
        if (from < 19) {
          try {
            await customStatement('ALTER TABLE semi_budgets ADD COLUMN master_category_id TEXT REFERENCES categories(id);');
            await customStatement('CREATE INDEX IF NOT EXISTS idx_semi_budgets_master_cat ON semi_budgets(master_category_id);');
            debugPrint('[AppDatabase] Migration V19: Added master_category_id to semi_budgets');
          } catch (e) {
            debugPrint('Migration V19 warning: $e');
          }
        }

        // Version 21: Fintech-Grade Evolution
        if (from < 21) {
          try {
            await m.createTable(canonicalLedger);
            await m.createTable(userConsents);
            await m.createTable(financialIngestionLogs);
            
            // Create essential indexes
            await customStatement('CREATE INDEX IF NOT EXISTS idx_ledger_source ON canonical_ledger(source, source_reference);');
            await customStatement('CREATE INDEX IF NOT EXISTS idx_ledger_user_date ON canonical_ledger(user_id, booking_date);');
            await customStatement('CREATE INDEX IF NOT EXISTS idx_consents_user ON user_consents(user_id, status);');
            
            debugPrint('[AppDatabase] Migration V21: Added Fintech-Grade tables (Ledger, Consents, Ingestion Logs)');
          } catch (e) {
            debugPrint('Migration V21 warning: $e');
          }
        }
      },
      beforeOpen: (details) async {
        // Enable foreign keys
        await customStatement('PRAGMA foreign_keys = ON');
      },
    );
  }

  /// Wipe all data from the database (for secure logout/reset)
  /// P0 SECURITY: Ensures no data remains on device after logout
  Future<void> wipeAllData() async {
    await transaction(() async {
      // Disable FKs to allow arbitrary deletion order
      await customStatement('PRAGMA foreign_keys = OFF');
      try {
        for (final table in allTables) {
          await delete(table).go();
        }
        debugPrint('[AppDatabase] All tables wiped successfully.');
      } finally {
        await customStatement('PRAGMA foreign_keys = ON');
      }
    });
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
    
    // CAUSAL HISTORY: Initialize Version Vector
    final deviceId = await _deviceInfoService.getDeviceId();
    final clock = VectorClock();
    clock.increment(deviceId);
    
    final vectorBudget = budget.copyWith(
      versionVector: Value(clock.toJson()),
      lamportClock: const Value(1), // Initialize scalar clock too
      lastModifiedByDeviceId: Value(deviceId),
    );
    
    return await into(budgets).insert(vectorBudget);
  }

  Future<bool> updateBudget(BudgetsCompanion budget) async {
    // SYNC STATE: Get current record to check state
    final budgetId = budget.id.value;
    final currentBudget = await (select(budgets)..where((t) => t.id.equals(budgetId))).getSingleOrNull();
    
    if (currentBudget != null) {
      // CAUSAL HISTORY: Increment Vector Clock
      final deviceId = await _deviceInfoService.getDeviceId();
      final currentVectorJson = currentBudget.versionVector;
      final clock = VectorClock.fromJson(currentVectorJson ?? '{}');
      clock.increment(deviceId);

      // Mark as dirty directly (State Machine removed as unused feature)
      final updatedBudget = budget.copyWith(
        syncState: const Value('dirty'),
        revision: Value(currentBudget.revision + 1),
        versionVector: Value(clock.toJson()),
        lastModifiedByDeviceId: Value(deviceId),
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

  Stream<List<Expense>> watchAllExpenses(String userId) {
    final query = select(expenses).join([
      innerJoin(budgets, budgets.id.equalsExp(expenses.budgetId)),
    ]);
    query.where(expenses.enteredBy.equals(userId) & 
                expenses.isDeleted.equals(false) &
                budgets.isDeleted.equals(false));
    query.orderBy([OrderingTerm.desc(expenses.date)]);
    
    return query.watch().map((rows) => rows.map((row) => row.readTable(expenses)).toList());
  }

  Future<List<Expense>> getExpenses(String userId) {
    final query = select(expenses).join([
      innerJoin(budgets, budgets.id.equalsExp(expenses.budgetId)),
    ]);
    query.where(expenses.enteredBy.equals(userId) & 
                expenses.isDeleted.equals(false) &
                budgets.isDeleted.equals(false));
    query.orderBy([OrderingTerm.desc(expenses.date)]);
    
    return query.get().then((rows) => rows.map((row) => row.readTable(expenses)).toList());
  }

  Future<List<Expense>> getExpensesByBudgetId(String budgetId) {
    return (select(expenses)
          ..where((t) => t.budgetId.equals(budgetId) & t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .get();
  }

  Stream<List<Expense>> watchExpensesBySemiBudgetId(String semiBudgetId) {
    final query = select(expenses).join([
      innerJoin(budgets, budgets.id.equalsExp(expenses.budgetId)),
    ]);
    query.where(expenses.semiBudgetId.equals(semiBudgetId) & 
                expenses.isDeleted.equals(false) &
                budgets.isDeleted.equals(false));
    query.orderBy([OrderingTerm.desc(expenses.date)]);
    
    return query.watch().map((rows) => rows.map((row) => row.readTable(expenses)).toList());
  }

  Future<List<Expense>> getRecentExpenses(String userId, {int limit = 10}) {
    final query = select(expenses).join([
      innerJoin(budgets, budgets.id.equalsExp(expenses.budgetId)),
    ]);
    query.where(expenses.enteredBy.equals(userId) & 
                expenses.isDeleted.equals(false) &
                budgets.isDeleted.equals(false));
    query.orderBy([OrderingTerm.desc(expenses.date)]);
    query.limit(limit);
    
    return query.get().then((rows) => rows.map((row) => row.readTable(expenses)).toList());
  }

  Stream<List<Expense>> watchRecentExpenses(String userId, {int limit = 50}) {
    final query = select(expenses).join([
      innerJoin(budgets, budgets.id.equalsExp(expenses.budgetId)),
    ]);
    query.where(expenses.enteredBy.equals(userId) & 
                expenses.isDeleted.equals(false) &
                budgets.isDeleted.equals(false));
    query.orderBy([OrderingTerm.desc(expenses.date)]);
    query.limit(limit);
    
    return query.watch().map((rows) => rows.map((row) => row.readTable(expenses)).toList());
  }

  /// Get recent expenses as maps for duplicate detection
  Future<List<Map<String, dynamic>>> getRecentExpensesMaps(String userId, {int limit = 50}) async {
    final query = select(expenses).join([
      innerJoin(budgets, budgets.id.equalsExp(expenses.budgetId)),
    ]);
    query.where(expenses.enteredBy.equals(userId) & 
                expenses.isDeleted.equals(false) &
                budgets.isDeleted.equals(false));
    query.orderBy([OrderingTerm.desc(expenses.date)]);
    query.limit(limit);
    
    final result = await query.get();
    
    return result.map((row) {
      final e = row.readTable(expenses);
      return {
        'id': e.id,
        'merchant_name': e.merchantName,
        'amount': e.amount,
        'expense_date': e.date.toIso8601String(),
        'currency_code': e.currency,
        'category_key': e.categoryId,
        'budgetId': e.budgetId,
      };
    }).toList();
  }


  // ============================================================
  // REPORTING & ANALYTICS QUERIES (High Performance)
  // ============================================================

  /// Calculate total spent in a date range directly in SQL
  /// limit memory usage by not creating Expense objects
  Future<int> getTotalSpentInDateRange(String userId, DateTime start, DateTime end) async {
    final query = selectOnly(expenses).join([
      innerJoin(budgets, budgets.id.equalsExp(expenses.budgetId)),
    ]);
    query.addColumns([expenses.amount.sum()]);
    query.where(expenses.enteredBy.equals(userId) &
                expenses.isDeleted.equals(false) &
                budgets.isDeleted.equals(false) &
                expenses.date.isBiggerOrEqualValue(start) &
                expenses.date.isSmallerOrEqualValue(end));
    
    final result = await query.getSingle();
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

  Future<int> insertExpense(ExpensesCompanion expense) async {
    // CAUSAL HISTORY
    final deviceId = await _deviceInfoService.getDeviceId();
    final clock = VectorClock();
    clock.increment(deviceId);
    
    final vectorExpense = expense.copyWith(
      versionVector: Value(clock.toJson()),
      lamportClock: const Value(1),
      lastModifiedByDeviceId: Value(deviceId),
      syncState: const Value('dirty'), // Ensure it's marked dirty
    );
    
    final id = expense.id.value;
    final res = await into(expenses).insert(vectorExpense);
    
    await logAudit(
      entityType: 'expense',
      entityId: id,
      action: 'create',
      userId: expense.enteredBy.value,
      newValue: jsonEncode(_serializeCompanion(vectorExpense)),
    );
    
    return res;
  }

  /// Get a single expense by ID - efficient O(1) lookup
  Future<Expense?> getExpenseById(String id) {
    return (select(expenses)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<bool> updateExpense(ExpensesCompanion expense) async {
    final id = expense.id.value;
    final old = await getExpenseById(id);
    
    if (old != null) {
       // CAUSAL HISTORY: Increment Vector Clock
       final deviceId = await _deviceInfoService.getDeviceId();
       final currentVectorJson = old.versionVector;
       final clock = VectorClock.fromJson(currentVectorJson ?? '{}');
       clock.increment(deviceId);
              
       final vectorExpense = expense.copyWith(
         syncState: const Value('dirty'),
         revision: Value(old.revision + 1),
         versionVector: Value(clock.toJson()),
         lastModifiedByDeviceId: Value(deviceId),
       );

       final res = await update(expenses).replace(vectorExpense);
    
       if (res) {
         await logAudit(
           entityType: 'expense',
           entityId: id,
           action: 'update',
           userId: old.enteredBy,
           oldValue: jsonEncode(old.toJson()),
           newValue: jsonEncode(_serializeCompanion(vectorExpense)),
         );
       }
       return res;
    }
    return false;
  }

  Future<int> deleteExpense(String id) async {
    final old = await getExpenseById(id);
    final count = await (update(expenses)..where((t) => t.id.equals(id)))
        .write(const ExpensesCompanion(isDeleted: Value(true), syncState: Value('dirty')));
    
    if (count > 0 && old != null) {
      await logAudit(
        entityType: 'expense',
        entityId: id,
        action: 'delete',
        userId: old.enteredBy,
        oldValue: jsonEncode(old.toJson()),
        newValue: null,
      );
    }
    return count;
  }

  // ============================================================
  // ENTERPRISE: AUDIT & ROLLBACK
  // ============================================================

  Future<void> logAudit({
    required String entityType,
    required String entityId,
    required String action,
    required String userId,
    String? oldValue,
    String? newValue,
    String? correlationId,
    Map<String, dynamic>? metadata,
  }) async {
    await into(auditLogs).insert(AuditLogsCompanion.insert(
      id: Uuid().v4(),
      entityType: entityType,
      entityId: entityId,
      action: action,
      userId: userId, 
      oldValue: Value(oldValue),
      newValue: Value(newValue),
      correlationId: Value(correlationId),
      metadata: Value(metadata),
      createdAt: Value(DateTime.now()),
    ));
  }

  /// Rollback local changes for a specific batch/session
  /// Reverts 'dirty' or 'conflict' records back to 'clean' or deletes them if they are local-only
  Future<void> rollbackSyncSession(String sessionId) async {
    debugPrint('[AppDatabase] ROLLBACK triggered for session: $sessionId');
    // Implementation for prototype: Revert all current dirty records in expenses
    // In production, sync status would be more granular (linked to sessionId)
    await customStatement('UPDATE expenses SET sync_state = \'clean\' WHERE sync_state = \'dirty\'');
    await customStatement('UPDATE budgets SET sync_state = \'clean\' WHERE sync_state = \'dirty\'');
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

  /// Seeds demo accounts for a user to "make it happen" on blank screens
  Future<void> seedDemoAccounts(String userId) async {
    await batch((batch) {
      final now = DateTime.now();
      batch.insert(accounts, AccountsCompanion.insert(
        id: const Uuid().v4(),
        userId: userId,
        name: 'Main Bank',
        type: 'checking',
        balance: 245000, // €2,450.00
        currency: const Value('EUR'),
        isDefault: const Value(true),
        syncState: const Value('dirty'),
        createdAt: Value(now),
        updatedAt: Value(now),
      ), mode: InsertMode.insertOrReplace);
      
      batch.insert(accounts, AccountsCompanion.insert(
        id: const Uuid().v4(),
        userId: userId,
        name: 'Emergency Fund',
        type: 'savings',
        balance: 500000, // €5,000.00
        currency: const Value('EUR'),
        isDefault: const Value(false),
        syncState: const Value('dirty'),
        createdAt: Value(now),
        updatedAt: Value(now),
      ), mode: InsertMode.insertOrReplace);

      batch.insert(assets, AssetsCompanion.insert(
        id: const Uuid().v4(),
        userId: userId,
        name: 'Tesla Model 3',
        type: 'vehicle',
        currentValue: 3500000, // €35,000.00
        currency: const Value('EUR'),
        createdAt: Value(now),
        updatedAt: Value(now),
        syncState: const Value('dirty'),
      ), mode: InsertMode.insertOrReplace);
    });
    debugPrint('[Seeding] Demo accounts and assets created for $userId');
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
          ..where((t) => t.budgetId.isIn(budgetIds) & t.status.isNotValue('deleted'))
          ..orderBy([(t) => OrderingTerm.desc(t.invitedAt)]))
        .watch();
  }

  Stream<List<BudgetMember>> watchBudgetMembers(String budgetId) {
    return (select(budgetMembers)
          ..where((t) => t.budgetId.equals(budgetId) & t.status.isNotValue('deleted'))
          ..orderBy([(t) => OrderingTerm.desc(t.invitedAt)]))
        .watch();
  }

  Future<List<BudgetMember>> getBudgetMembers(String budgetId) {
    return (select(budgetMembers)
          ..where((t) => t.budgetId.equals(budgetId)))
        .get();
  }

  Future<int> insertBudgetMember(BudgetMembersCompanion member) async {
    // SYNC LOGIC: Initialize clocks and mark dirty
    final deviceId = await _deviceInfoService.getDeviceId();
    final clock = VectorClock();
    clock.increment(deviceId);
    
    final now = DateTime.now();

    final vectorMember = member.copyWith(
      versionVector: Value(clock.toJson()),
      lamportClock: const Value(1),
      syncState: const Value('dirty'),
      createdAt: Value(now),
      updatedAt: Value(now),
    );

    final id = member.id.value;
    final res = await into(budgetMembers).insert(vectorMember);

    // Ledger Event for Audit/History
    await logLedgerEvent(
      entityType: 'budget_member',
      entityId: id,
      eventType: 'MEMBER_INVITED',
      data: _serializeCompanion(vectorMember),
    );

    return res;
  }

  Future<bool> updateBudgetMember(BudgetMembersCompanion member) async {
    final id = member.id.value;
    final current = await (select(budgetMembers)..where((t) => t.id.equals(id))).getSingleOrNull();

    if (current != null) {
      final deviceId = await _deviceInfoService.getDeviceId();
      final currentVectorJson = current.versionVector;
      final clock = VectorClock.fromJson(currentVectorJson ?? '{}');
      clock.increment(deviceId);

      final updatedMember = member.copyWith(
        versionVector: Value(clock.toJson()),
        revision: Value(current.revision + 1),
        syncState: const Value('dirty'),
        updatedAt: Value(DateTime.now()),
      );

      await (update(budgetMembers)..where((t) => t.id.equals(id))).write(updatedMember);

      await logLedgerEvent(
        entityType: 'budget_member',
        entityId: id,
        eventType: 'MEMBER_UPDATED',
        data: _serializeCompanion(updatedMember),
      );

      return true;
    }
    return false;
  }

  Future<int> deleteBudgetMember(String id) async {
    // SOFT DELETE: Mark as 'deleted' and sync
    final current = await (select(budgetMembers)..where((t) => t.id.equals(id))).getSingleOrNull();
    
    if (current != null) {
      final deviceId = await _deviceInfoService.getDeviceId();
      final currentVectorJson = current.versionVector;
      final clock = VectorClock.fromJson(currentVectorJson ?? '{}');
      clock.increment(deviceId);
      
      final now = DateTime.now();

      final rows = await (update(budgetMembers)..where((t) => t.id.equals(id))).write(BudgetMembersCompanion(
        isDeleted: const Value(true), // Standard soft delete
        status: const Value('deleted'), // Legacy status for backward compat
        updatedAt: Value(now),
        revision: Value(current.revision + 1),
        versionVector: Value(clock.toJson()),
        syncState: const Value('dirty'),
      ));
      
      if (rows > 0) {
        await logLedgerEvent(
          entityType: 'budget_member',
          entityId: id,
          eventType: 'MEMBER_DELETED',
          data: {'deleted_at': now.toIso8601String()},
        );
      }
      return rows;
    }
    return 0;
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
  Future<List<SavingsGoal>> getSavingsGoals(String userId, {bool includeArchived = false}) {
    var query = select(savingsGoals)
          ..where((t) => t.userId.equals(userId) & t.isDeleted.equals(false));
    
    if (!includeArchived) {
      query = query..where((t) => t.isArchived.equals(false));
    }

    return query.get();
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

  // Delete all budgets for a user
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

  // ============================================================
  // NET WORTH OPERATIONS (V15) - ASSETS
  // ============================================================

  Stream<List<Asset>> watchAssets(String userId) {
    return (select(assets)
          ..where((t) => t.userId.equals(userId) & t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.currentValue)]))
        .watch();
  }

  Future<List<Asset>> getAssets(String userId) {
    return (select(assets)
          ..where((t) => t.userId.equals(userId) & t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.currentValue)]))
        .get();
  }

  Future<int> insertAsset(AssetsCompanion asset) async {
    // CAUSAL HISTORY
    final deviceId = await _deviceInfoService.getDeviceId();
    final clock = VectorClock();
    clock.increment(deviceId);
    
    final vectorAsset = asset.copyWith(
      versionVector: Value(clock.toJson()),
      lamportClock: const Value(1),
      syncState: const Value('dirty'), 
    );
    
    final id = asset.id.value;
    final res = await into(assets).insert(vectorAsset);
    
    // Ledger Event
    await logLedgerEvent(
      entityType: 'asset',
      entityId: id,
      eventType: 'ASSET_CREATED',
      data: _serializeCompanion(vectorAsset),
    );
    
    return res;
  }

  Future<bool> updateAsset(AssetsCompanion asset) async {
    final id = asset.id.value;
    final current = await (select(assets)..where((t) => t.id.equals(id))).getSingleOrNull();
    
    if (current != null) {
      final deviceId = await _deviceInfoService.getDeviceId();
      final currentVectorJson = current.versionVector;
      final clock = VectorClock.fromJson(currentVectorJson ?? '{}');
      clock.increment(deviceId);
      
      final updatedAsset = asset.copyWith(
        versionVector: Value(clock.toJson()),
        revision: Value(current.revision + 1),
        syncState: const Value('dirty'),
      );
      
      await (update(assets)..where((t) => t.id.equals(id))).write(updatedAsset);
      
      // Ledger Event
      await logLedgerEvent(
        entityType: 'asset',
        entityId: id,
        eventType: 'ASSET_UPDATED',
        data: _serializeCompanion(updatedAsset),
      );
      
      return true;
    }
    return false;
  }
  
  Future<int> deleteAsset(String id) async {
    final now = DateTime.now();
    final current = await (select(assets)..where((t) => t.id.equals(id))).getSingleOrNull();
    
    if (current != null) {
      final rows = await (update(assets)..where((t) => t.id.equals(id))).write(AssetsCompanion(
        isDeleted: const Value(true),
        updatedAt: Value(now),
        revision: Value(current.revision + 1),
        syncState: const Value('dirty'),
      ));
      
      if (rows > 0) {
        await logLedgerEvent(
          entityType: 'asset',
          entityId: id,
          eventType: 'ASSET_DELETED',
          data: {'deleted_at': now.toIso8601String()},
        );
      }
      return rows;
    }
    return 0;
  }

  // ============================================================
  // NET WORTH OPERATIONS (V15) - LIABILITIES
  // ============================================================

  Stream<List<Liability>> watchLiabilities(String userId) {
    return (select(liabilities)
          ..where((t) => t.userId.equals(userId) & t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.currentBalance)]))
        .watch();
  }

  Future<List<Liability>> getLiabilities(String userId) {
    return (select(liabilities)
          ..where((t) => t.userId.equals(userId) & t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.currentBalance)]))
        .get();
  }

  Future<int> insertLiability(LiabilitiesCompanion liability) async {
    final deviceId = await _deviceInfoService.getDeviceId();
    final clock = VectorClock();
    clock.increment(deviceId);
    
    final vectorLiability = liability.copyWith(
      versionVector: Value(clock.toJson()),
      lamportClock: const Value(1),
      syncState: const Value('dirty'), 
    );
    
    final id = liability.id.value;
    final res = await into(liabilities).insert(vectorLiability);
    
    await logLedgerEvent(
      entityType: 'liability',
      entityId: id,
      eventType: 'LIABILITY_CREATED',
      data: _serializeCompanion(vectorLiability),
    );
    
    return res;
  }

  Future<bool> updateLiability(LiabilitiesCompanion liability) async {
    final id = liability.id.value;
    final current = await (select(liabilities)..where((t) => t.id.equals(id))).getSingleOrNull();
    
    if (current != null) {
      final deviceId = await _deviceInfoService.getDeviceId();
      final currentVectorJson = current.versionVector;
      final clock = VectorClock.fromJson(currentVectorJson ?? '{}');
      clock.increment(deviceId);
      
      final updatedLiability = liability.copyWith(
        versionVector: Value(clock.toJson()),
        revision: Value(current.revision + 1),
        syncState: const Value('dirty'),
      );
      
      await (update(liabilities)..where((t) => t.id.equals(id))).write(updatedLiability);
       
      await logLedgerEvent(
        entityType: 'liability',
        entityId: id,
        eventType: 'LIABILITY_UPDATED',
        data: _serializeCompanion(updatedLiability),
      );
       
      return true;
    }
    return false;
  }

  Future<int> deleteLiability(String id) async {
    final now = DateTime.now();
    final current = await (select(liabilities)..where((t) => t.id.equals(id))).getSingleOrNull();
    
    if (current != null) {
      final rows = await (update(liabilities)..where((t) => t.id.equals(id))).write(LiabilitiesCompanion(
        isDeleted: const Value(true),
        updatedAt: Value(now),
        revision: Value(current.revision + 1),
        syncState: const Value('dirty'),
      ));
      
      if (rows > 0) {
        await logLedgerEvent(
          entityType: 'liability',
          entityId: id,
          eventType: 'LIABILITY_DELETED',
          data: {'deleted_at': now.toIso8601String()},
        );
      }
      return rows;
    }
    return 0;
  }

  // ============================================================
  // VALUATION HISTORY
  // ============================================================

  Future<int> logValuationSnapshot({
    required String entityId,
    required String entityType,
    required int value,
    required DateTime date,
  }) {
    return into(valuationHistory).insert(ValuationHistoryCompanion.insert(
      id: const Uuid().v4(),
      entityType: entityType,
      entityId: entityId,
      value: value,
      date: date,
    ));
  }
  
  Future<List<ValuationHistoryData>> getValuationHistory({
    required String entityId,
    required DateTime start,
    required DateTime end,
  }) {
    return (select(valuationHistory)
          ..where((t) => 
            t.entityId.equals(entityId) & 
            t.date.isBiggerOrEqualValue(start) & 
            t.date.isSmallerOrEqualValue(end))
          ..orderBy([(t) => OrderingTerm.asc(t.date)]))
        .get();
  }

  /// Records the current total net worth for trend analysis
  Future<void> recordNetWorthSnapshot(String userId) async {
    final assetsList = await getAssets(userId);
    final liabilitiesList = await getLiabilities(userId);
    
    int totalCents = 0;
    for (final a in assetsList) {
      totalCents += a.currentValue;
    }
    for (final l in liabilitiesList) {
      totalCents -= l.currentBalance;
    }
    
    await into(valuationHistory).insert(ValuationHistoryCompanion.insert(
      id: const Uuid().v4(),
      entityType: 'net_worth',
      entityId: userId,
      value: totalCents,
      date: DateTime.now(),
    ));
    
    debugPrint('[AppDatabase] Recorded Net Worth Snapshot for $userId: $totalCents cents');
  }

  Future<Asset?> getAssetById(String id) {
    return (select(assets)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<Liability?> getLiabilityById(String id) {
    return (select(liabilities)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// Retrieves net worth history for graphing
  Future<List<ValuationHistoryData>> getNetWorthHistory(String userId, {int days = 30}) {
    final start = DateTime.now().subtract(Duration(days: days));
    return (select(valuationHistory)
          ..where((t) => 
            t.entityType.equals('net_worth') & 
            t.entityId.equals(userId) & 
            t.date.isBiggerOrEqualValue(start))
          ..orderBy([(t) => OrderingTerm.asc(t.date)]))
        .get();
  }

  /// The Core of Event Sourcing (Track D)
  /// Implements hash-chaining to ensure ledger integrity.
  Future<void> logLedgerEvent({
    required String entityType,
    required String entityId,
    required String eventType,
    required Map<String, dynamic> data,
  }) async {
    final deviceId = await _deviceInfoService.getDeviceId();
    final user = await (select(users)..limit(1)).getSingleOrNull();
    final userId = user?.id ?? 'unknown';

    // 1. Fetch the hash of the last event
    final lastEvent = await (select(ledgerEvents)
          ..orderBy([(t) => OrderingTerm.desc(t.timestamp)])
          ..limit(1))
        .getSingleOrNull();
    final String? prevHash = lastEvent?.hash;

    // 2. Prepare event metadata for hashing
    final String currentEventId = const Uuid().v4();
    final DateTime now = DateTime.now();
    
    // 3. Compute hash: sha256(prevHash + eventType + entityId + dataJson)
    final String payload = '$prevHash|$eventType|$entityId|${json.encode(data)}|$now';
    final String currentHash = sha256.convert(utf8.encode(payload)).toString();

    await into(ledgerEvents).insert(LedgerEventsCompanion.insert(
      eventId: currentEventId,
      eventType: eventType,
      entityType: entityType,
      entityId: entityId,
      userId: userId,
      deviceId: Value(deviceId),
      eventData: data,
      timestamp: Value(now),
      previousEventHash: Value(prevHash),
      hash: Value(currentHash),
    ));
    
    debugPrint('[Ledger] Logged $eventType for $entityType:$entityId (Hash: ${currentHash.substring(0, 8)}...)');
  }

  // ============================================================
  // CATEGORY & SUBCATEGORY RETRIEVAL (Phase E)
  // ============================================================

  Stream<List<Category>> watchAllCategories() {
    return (select(categories)..orderBy([(t) => OrderingTerm.asc(t.name)])).watch();
  }

  Future<List<Category>> getCategories() {
    return (select(categories)..orderBy([(t) => OrderingTerm.asc(t.name)])).get();
  }

  Stream<List<SubCategory>> watchSubCategoriesByCategoryId(String categoryId) {
    return (select(subCategories)
          ..where((t) => t.categoryId.equals(categoryId))
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .watch();
  }

  Stream<List<SubCategory>> watchAllSubCategories() {
    return (select(subCategories)..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .watch();
  }

  Future<List<SubCategory>> getSubCategoriesByCategoryId(String categoryId) {
    return (select(subCategories)
          ..where((t) => t.categoryId.equals(categoryId))
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .get();
  }

  /// Seeds master categories and subcategories using industrialCategories as the source of truth.
  Future<void> seedMasterCategories() async {
    await batch((batch) {
      // 1. First Pass: Insert top-level categories
      final topLevels = industrialCategories.where((c) => c.parentKey == null).toList();
      for (final cat in topLevels) {
        final catId = cat.localizationKey.toLowerCase();
        batch.insert(categories, CategoriesCompanion.insert(
          id: catId,
          name: cat.localizationKey, // Uses key as name reference
          iconName: Value(cat.iconName),
          colorHex: Value(cat.colorHex),
          isSystem: const Value(true),
        ), mode: InsertMode.insertOrReplace);
        
        // Add "Other" as first subcategory for every master
        batch.insert(subCategories, SubCategoriesCompanion.insert(
          id: '${catId}_other',
          categoryId: catId,
          name: 'Other',
          isDefaultOther: const Value(true),
          isSystem: const Value(true),
          confidence: const Value(1.0),
          isDeleted: const Value(false),
        ), mode: InsertMode.insertOrReplace);
      }

      // 2. Second Pass: Insert subcategories linked to their parents
      final subCats = industrialCategories.where((c) => c.parentKey != null).toList();
      for (final sub in subCats) {
        final parentId = sub.parentKey!.toLowerCase();
        final subId = sub.localizationKey.toLowerCase();
        batch.insert(subCategories, SubCategoriesCompanion.insert(
          id: subId,
          categoryId: parentId,
          name: sub.localizationKey, // Uses key as name reference
          isDefaultOther: const Value(false),
          isSystem: const Value(true),
          confidence: const Value(1.0),
          isDeleted: const Value(false),
        ), mode: InsertMode.insertOrReplace);
      }
    });

    debugPrint('[Seeding] Master hierarchy populated from industrialCategories.');
  }

  /// Marks ALL synchronization-eligible records as 'dirty' to force a full push to cloud.
  /// Used during subscription upgrades or manual "Force Sync".
  Future<void> markAllEntitiesAsDirty() async {
    await transaction(() async {
      await (update(users)..where((t) => t.id.isNotNull())).write(const UsersCompanion(syncState: Value('dirty')));
      await (update(budgets)..where((t) => t.id.isNotNull())).write(const BudgetsCompanion(syncState: Value('dirty')));
      await (update(semiBudgets)..where((t) => t.id.isNotNull())).write(const SemiBudgetsCompanion(syncState: Value('dirty')));
      await (update(expenses)..where((t) => t.id.isNotNull())).write(const ExpensesCompanion(syncState: Value('dirty')));
      await (update(accounts)..where((t) => t.id.isNotNull())).write(const AccountsCompanion(syncState: Value('dirty')));
      await (update(savingsGoals)..where((t) => t.id.isNotNull())).write(const SavingsGoalsCompanion(syncState: Value('dirty')));
      await (update(recurringExpenses)..where((t) => t.id.isNotNull())).write(const RecurringExpensesCompanion(syncState: Value('dirty')));
      await (update(budgetMembers)..where((t) => t.id.isNotNull())).write(const BudgetMembersCompanion(syncState: Value('dirty')));
      await (update(assets)..where((t) => t.id.isNotNull())).write(const AssetsCompanion(syncState: Value('dirty')));
      await (update(liabilities)..where((t) => t.id.isNotNull())).write(const LiabilitiesCompanion(syncState: Value('dirty')));
      await (update(familyGroups)..where((t) => t.id.isNotNull())).write(const FamilyGroupsCompanion(syncState: Value('dirty')));
      await (update(familyContacts)..where((t) => t.id.isNotNull())).write(const FamilyContactsCompanion(syncState: Value('dirty')));
      await (update(familyRelations)..where((t) => t.id.isNotNull())).write(const FamilyRelationsCompanion(syncState: Value('dirty')));
      await (update(subCategories)..where((t) => t.id.isNotNull())).write(const SubCategoriesCompanion(syncState: Value('dirty')));
    });
    debugPrint('[AppDatabase] All entities marked as dirty for force sync.');
  }
}

// _openConnection removed (replaced by cross-platform connect())
