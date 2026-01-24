import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../data/drift/app_database.dart';
import '../core/providers/app_providers.dart';
import '../features/sync/sync_providers.dart';

// ============================================================
// DOMAIN MODELS
// ============================================================

class CurrencyMigrationResult {
  final String fromCurrency;
  final String toCurrency;
  final double exchangeRate;
  final MigrationStats stats;
  final DateTime timestamp;

  const CurrencyMigrationResult({
    required this.fromCurrency,
    required this.toCurrency,
    required this.exchangeRate,
    required this.stats,
    required this.timestamp,
  });

  int get budgetsConverted => stats.budgetsConverted;
  int get expensesConverted => stats.expensesConverted;
  int get accountsConverted => stats.accountsConverted;
  int get categoriesConverted => stats.categoriesConverted;
  int get recurringExpensesConverted => stats.recurringExpensesConverted;
  int get totalItemsConverted => stats.totalItemsConverted;
}

class MigrationStats {
  final int accountsConverted;
  final int budgetsConverted;
  final int expensesConverted;
  final int categoriesConverted;
  final int recurringExpensesConverted;

  const MigrationStats({
    this.accountsConverted = 0,
    this.budgetsConverted = 0,
    this.expensesConverted = 0,
    this.categoriesConverted = 0,
    this.recurringExpensesConverted = 0,
  });

  int get totalItemsConverted =>
      accountsConverted +
      budgetsConverted +
      expensesConverted +
      categoriesConverted +
      recurringExpensesConverted;

  MigrationStats copyWith({
    int? accountsConverted,
    int? budgetsConverted,
    int? expensesConverted,
    int? categoriesConverted,
    int? recurringExpensesConverted,
  }) {
    return MigrationStats(
      accountsConverted: accountsConverted ?? this.accountsConverted,
      budgetsConverted: budgetsConverted ?? this.budgetsConverted,
      expensesConverted: expensesConverted ?? this.expensesConverted,
      categoriesConverted: categoriesConverted ?? this.categoriesConverted,
      recurringExpensesConverted: recurringExpensesConverted ?? this.recurringExpensesConverted,
    );
  }
}

// ============================================================
// DATA MIGRATORS
// ============================================================

abstract class DataMigrator {
  Future<MigrationStats> migrate(
    AppDatabase db,
    String fromCurrency,
    String toCurrency,
    double exchangeRate,
    String userId,
  );
}

class AccountMigrator implements DataMigrator {
  @override
  Future<MigrationStats> migrate(
    AppDatabase db,
    String fromCurrency,
    String toCurrency,
    double exchangeRate,
    String userId,
  ) async {
    int convertedCount = 0;
    
    final accounts = await db.getAllAccounts(userId);
    
    for (final account in accounts) {
      if (account.currency == fromCurrency) {
        final newBalance = (account.balance * exchangeRate).round();
        
        await (db.update(db.accounts)
          ..where((t) => t.id.equals(account.id))
        ).write(AccountsCompanion(
          currency: Value(toCurrency),
          balance: Value(newBalance),
          revision: Value(account.revision + 1),
          updatedAt: Value(DateTime.now()),
        ));
        
        convertedCount++;
        debugPrint('   Converted account: ${account.name} ${account.balance} -> $newBalance $toCurrency');
      }
    }
    
    return MigrationStats(accountsConverted: convertedCount);
  }
}

class BudgetMigrator implements DataMigrator {
  @override
  Future<MigrationStats> migrate(
    AppDatabase db,
    String fromCurrency,
    String toCurrency,
    double exchangeRate,
    String userId,
  ) async {
    int convertedCount = 0;
    
    // Fetch all non-deleted budgets
    final budgets = await (db.select(db.budgets)
      ..where((t) => t.isDeleted.equals(false))
    ).get();
    
    debugPrint('🔧 Budget Migration: Found ${budgets.length} budgets');
    debugPrint('🔧 Converting from $fromCurrency to $toCurrency at rate $exchangeRate');
    
    for (final budget in budgets) {
      debugPrint('   Budget: ${budget.title}, currency: ${budget.currency}, limit: ${budget.totalLimit}');
      
      final newLimit = budget.totalLimit != null 
          ? (budget.totalLimit! * exchangeRate).round() 
          : null;
      
      await (db.update(db.budgets)
        ..where((t) => t.id.equals(budget.id))
      ).write(BudgetsCompanion(
        currency: Value(toCurrency),
        totalLimit: Value(newLimit),
        revision: Value(budget.revision + 1),
        updatedAt: Value(DateTime.now()),
        syncState: const Value('dirty'),
      ));
      
      convertedCount++;
      debugPrint('   ✅ Converted: ${budget.title} ${budget.totalLimit} -> $newLimit $toCurrency');
    }
    
    return MigrationStats(budgetsConverted: convertedCount);
  }
}

class ExpenseMigrator implements DataMigrator {
  @override
  Future<MigrationStats> migrate(
    AppDatabase db,
    String fromCurrency,
    String toCurrency,
    double exchangeRate,
    String userId,
  ) async {
    int convertedCount = 0;
    
    // Get all budgets that are being converted
    final budgets = await (db.select(db.budgets)
      ..where((t) => t.currency.equals(toCurrency) & t.isDeleted.equals(false))
    ).get();
    
    for (final budget in budgets) {
      final expenses = await db.getExpensesByBudgetId(budget.id);
      
      for (final expense in expenses) {
        final newAmount = (expense.amount * exchangeRate).round();
        
        await (db.update(db.expenses)
          ..where((t) => t.id.equals(expense.id))
        ).write(ExpensesCompanion(
          amount: Value(newAmount),
          revision: Value(expense.revision + 1),
          updatedAt: Value(DateTime.now()),
        ));
        
        convertedCount++;
      }
    }
    
    return MigrationStats(expensesConverted: convertedCount);
  }
}

class RecurringExpenseMigrator implements DataMigrator {
  @override
  Future<MigrationStats> migrate(
    AppDatabase db,
    String fromCurrency,
    String toCurrency,
    double exchangeRate,
    String userId,
  ) async {
    int convertedCount = 0;
    
    final recurringExpenses = await (db.select(db.recurringExpenses)
      ..where((t) => t.userId.equals(userId))
    ).get();
    
    for (final expense in recurringExpenses) {
      final newAmount = (expense.amount * exchangeRate).round();
      
      await (db.update(db.recurringExpenses)
        ..where((t) => t.id.equals(expense.id))
      ).write(RecurringExpensesCompanion(
        amount: Value(newAmount),
        revision: Value(expense.revision + 1),
        updatedAt: Value(DateTime.now()),
      ));
      
      convertedCount++;
    }
    
    return MigrationStats(recurringExpensesConverted: convertedCount);
  }
}

class CategoryMigrator implements DataMigrator {
  @override
  Future<MigrationStats> migrate(
    AppDatabase db,
    String fromCurrency,
    String toCurrency,
    double exchangeRate,
    String userId,
  ) async {
    int convertedCount = 0;
    
    final semiBudgets = await (db.select(db.semiBudgets)).get();
    
    for (final semiBudget in semiBudgets) {
      final parentBudget = await (db.select(db.budgets)
        ..where((t) => t.id.equals(semiBudget.budgetId))
      ).getSingleOrNull();
      
      if (parentBudget != null && parentBudget.currency == toCurrency) {
        final newLimit = (semiBudget.limitAmount * exchangeRate).round();
        
        await (db.update(db.semiBudgets)
          ..where((t) => t.id.equals(semiBudget.id))
        ).write(SemiBudgetsCompanion(
          limitAmount: Value(newLimit),
          revision: Value(semiBudget.revision + 1),
          updatedAt: Value(DateTime.now()),
        ));
        
        convertedCount++;
      }
    }
    
    return MigrationStats(categoriesConverted: convertedCount);
  }
}

// ============================================================
// MAIN MIGRATION SERVICE
// ============================================================

class CurrencyMigrationService {
  final Ref _ref;
  final List<DataMigrator> _migrators;

  CurrencyMigrationService(
    this._ref, {
    List<DataMigrator>? migrators,
  }) : _migrators = migrators ?? [
          AccountMigrator(),
          BudgetMigrator(),
          ExpenseMigrator(),
          RecurringExpenseMigrator(),
          CategoryMigrator(),
        ];

  Future<CurrencyMigrationResult> migrateTo(String newCurrency) async {
    final currentCurrency = _ref.read(currencyProvider);
    
    if (currentCurrency == newCurrency) {
      throw Exception('Currency is already set to $newCurrency');
    }

    final userId = _ref.read(currentUserIdProvider);
    if (userId == null) {
      throw Exception('No user data found. Please create an account or continue as guest first.');
    }

    debugPrint('[CurrencyMigrationService] Starting migration from $currentCurrency to $newCurrency');

    // Get exchange rate
    final converter = _ref.read(currencyConverterServiceProvider);
    final rate = await converter.getConversionRate(currentCurrency, newCurrency);
    
    if (rate == null) {
      throw Exception(
        'Failed to get exchange rate from $currentCurrency to $newCurrency. '
        'Please check your internet connection and try again.'
      );
    }

    debugPrint('💰 Exchange rate: 1 $currentCurrency = $rate $newCurrency');

    // Pause sync to prevent conflicts
    final orchestrator = _ref.read(syncOrchestratorProvider);
    orchestrator.pauseRealtime();

    try {
      final db = _ref.read(databaseProvider);
      MigrationStats totalStats = const MigrationStats();

      // Execute migration in a transaction
      await db.transaction(() async {
        for (final migrator in _migrators) {
          final stats = await migrator.migrate(
            db,
            currentCurrency,
            newCurrency,
            rate,
            userId,
          );
          
          totalStats = MigrationStats(
            accountsConverted: totalStats.accountsConverted + stats.accountsConverted,
            budgetsConverted: totalStats.budgetsConverted + stats.budgetsConverted,
            expensesConverted: totalStats.expensesConverted + stats.expensesConverted,
            categoriesConverted: totalStats.categoriesConverted + stats.categoriesConverted,
            recurringExpensesConverted: totalStats.recurringExpensesConverted + stats.recurringExpensesConverted,
          );
        }
      });

      // Update system currency preference
      await _ref.read(currencyProvider.notifier).setCurrency(newCurrency);

      debugPrint('[CurrencyMigrationService] Migration completed locally.');
      debugPrint('   📊 Statistics:');
      debugPrint('     Accounts: ${totalStats.accountsConverted}');
      debugPrint('     Budgets: ${totalStats.budgetsConverted}');
      debugPrint('     Expenses: ${totalStats.expensesConverted}');
      debugPrint('     Categories: ${totalStats.categoriesConverted}');
      debugPrint('     Recurring Expenses: ${totalStats.recurringExpensesConverted}');
      debugPrint('     Total: ${totalStats.totalItemsConverted}');

      // Trigger sync to push changes
      await _ref.read(requestSyncProvider(SyncReason.manualUserAction).future);

      // Resume realtime sync
      orchestrator.resumeRealtime();

      return CurrencyMigrationResult(
        fromCurrency: currentCurrency,
        toCurrency: newCurrency,
        exchangeRate: rate,
        stats: totalStats,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      debugPrint('[CurrencyMigrationService] Migration failed: $e');
      orchestrator.resumeRealtime();
      rethrow;
    }
  }

  Future<MigrationStats> calculateImpact(String newCurrency) async {
    final currentCurrency = _ref.read(currencyProvider);
    final userId = _ref.read(currentUserIdProvider);
    
    if (userId == null || currentCurrency == newCurrency) {
      return const MigrationStats();
    }

    final db = _ref.read(databaseProvider);
    MigrationStats stats = const MigrationStats();

    // Calculate counts without performing actual migration
    stats = stats.copyWith(
      accountsConverted: await _countAccountsToMigrate(db, userId, currentCurrency),
      budgetsConverted: await _countBudgetsToMigrate(db, currentCurrency),
    );

    return stats;
  }

  Future<int> _countAccountsToMigrate(AppDatabase db, String userId, String currentCurrency) async {
    final accounts = await db.getAllAccounts(userId);
    return accounts.where((a) => a.currency == currentCurrency).length;
  }

  Future<int> _countBudgetsToMigrate(AppDatabase db, String currentCurrency) async {
    final budgets = await (db.select(db.budgets)
      ..where((t) => t.isDeleted.equals(false))
    ).get();
    
    return budgets.where((b) => b.currency == currentCurrency).length;
  }
}

// ============================================================
// PROVIDERS
// ============================================================

final currencyMigrationServiceProvider = Provider<CurrencyMigrationService>((ref) {
  return CurrencyMigrationService(ref);
});

final migrationImpactProvider = FutureProvider.family<MigrationStats, String>((ref, newCurrency) async {
  final service = ref.read(currencyMigrationServiceProvider);
  return await service.calculateImpact(newCurrency);
});