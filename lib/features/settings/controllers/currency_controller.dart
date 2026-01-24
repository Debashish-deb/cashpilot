/// Currency Controller
/// Owns: currency change flow (label-only vs convert), scoped updates, transaction safety
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';

import '../../../data/drift/app_database.dart';
import '../../../core/providers/app_providers.dart';
import '../../sync/sync_providers.dart';
import '../models/operation_result.dart';

enum CurrencyChangeMode {
  labelOnly,   // Just change currency label, keep amounts
  convert,     // Convert amounts using exchange rates
}

enum CurrencyScope {
  personalOnly,    // Only budgets owned by current user
  sharedEditable,  // Shared budgets where user has edit rights
  all,             // All editable budgets
}

class CurrencyController {
  final Ref ref;
  
  CurrencyController(this.ref);

  /// Main currency change flow with proper scoping and transactions
  Future<OperationResult<CurrencyChangeReport>> changeCurrencyFlow({
    required String from,
    required String to,
    required CurrencyChangeMode mode,
    CurrencyScope scope = CurrencyScope.personalOnly,
    double? exchangeRate,
  }) async {
    if (from == to) {
      return OperationResult.success(
        message: 'Currency unchanged',
        data: CurrencyChangeReport(),
      );
    }

    final db = ref.read(databaseProvider);
    final userId = ref.read(currentUserIdProvider);
    
    debugPrint('[CurrencyController] Changing currency $from → $to (mode: ${mode.name}, scope: ${scope.name})');

    try {
      // 1. SAFETY: Pause realtime to prevent incoming syncs during migration
      try {
        ref.read(syncOrchestratorProvider).pauseRealtime();
      } catch (e) {
        debugPrint('[CurrencyController] Warning: Could not pause realtime: $e');
      }

      // Run entire operation in a transaction for rollback safety
      if (userId == null) {
        return OperationResult.failure(message: 'No user logged in');
      }
      
      final report = await db.transaction<CurrencyChangeReport>(() async {
        int budgetsUpdated = 0;
        int accountsUpdated = 0;
        int expensesUpdated = 0;

        // 1. Get editable budgets based on scope
        final editableBudgets = await _getEditableBudgets(db, userId, from, scope);
        
        // 2. Update budgets
        for (final budget in editableBudgets) {
          if (mode == CurrencyChangeMode.convert && exchangeRate != null && budget.totalLimit != null) {
            // Convert amounts
            final newAmount = _safeRound(budget.totalLimit! * exchangeRate);
            await (db.update(db.budgets)..where((b) => b.id.equals(budget.id))).write(
              BudgetsCompanion(
                currency: Value(to),
                totalLimit: Value(newAmount),
                revision: Value(budget.revision + 1),
                updatedAt: Value(DateTime.now()),
                syncState: const Value('dirty'), 
              ),
            );
          } else {
            // Label only
            await (db.update(db.budgets)..where((b) => b.id.equals(budget.id))).write(
              BudgetsCompanion(
                currency: Value(to),
                revision: Value(budget.revision + 1),
                updatedAt: Value(DateTime.now()),
                syncState: const Value('dirty'),
              ),
            );
          }
          budgetsUpdated++;
        }

        // 3. Update accounts (only user-owned)
        final accounts = await (db.select(db.accounts)
          ..where((a) => a.currency.equals(from))
          ..where((a) => a.userId.equals(userId)))
          .get();

        for (final account in accounts) {
          if (mode == CurrencyChangeMode.convert && exchangeRate != null) {
            final newBalance = _safeRound(account.balance * exchangeRate);
            await (db.update(db.accounts)..where((a) => a.id.equals(account.id))).write(
              AccountsCompanion(
                currency: Value(to),
                balance: Value(newBalance),
                revision: Value(account.revision + 1),
                updatedAt: Value(DateTime.now()),
                syncState: const Value('dirty'),
              ),
            );
          } else {
            await (db.update(db.accounts)..where((a) => a.id.equals(account.id))).write(
              AccountsCompanion(
                currency: Value(to),
                revision: Value(account.revision + 1),
                updatedAt: Value(DateTime.now()),
                syncState: const Value('dirty'),
              ),
            );
          }
          accountsUpdated++;
        }

        // 4. Update expenses in updated budgets (if converting)
        if (mode == CurrencyChangeMode.convert && exchangeRate != null) {
          final budgetIds = editableBudgets.map((b) => b.id).toList();
          for (final budgetId in budgetIds) {
            final expenses = await (db.select(db.expenses)
              ..where((e) => e.budgetId.equals(budgetId)))
              .get();

            for (final expense in expenses) {
              final newAmount = _safeRound(expense.amount * exchangeRate);
              await (db.update(db.expenses)..where((e) => e.id.equals(expense.id))).write(
                ExpensesCompanion(
                  amount: Value(newAmount),
                  revision: Value(expense.revision + 1),
                  updatedAt: Value(DateTime.now()),
                  syncState: const Value('dirty'),
                ),
              );
              expensesUpdated++;
            }
          }
        }

        return CurrencyChangeReport(
          budgetsUpdated: budgetsUpdated,
          accountsUpdated: accountsUpdated,
          expensesUpdated: expensesUpdated,
          fromCurrency: from,
          toCurrency: to,
          mode: mode,
        );
      });

      debugPrint('[CurrencyController] ✅ Currency change completed: ${report.budgetsUpdated} budgets, ${report.accountsUpdated} accounts, ${report.expensesUpdated} expenses');
      
      // Trigger instant Sync?
      // ref.read(syncManagerProvider).syncNow();

      return OperationResult.success(
        message: 'Currency changed successfully',
        data: report,
      );
    } catch (e) {
      debugPrint('[CurrencyController] ❌ Currency change failed (rolled back): $e');
      return OperationResult.failure(
        message: 'Currency change failed - no changes made',
        error: e,
      );
    } finally {
      // SAFETY: Resume realtime always
      try {
        ref.read(syncOrchestratorProvider).resumeRealtime();
      } catch (e) {
        debugPrint('[CurrencyController] Warning: Could not resume realtime: $e');
      }
    }
  }
  
  /// Helper for financial rounding (Standard Rounding for now)
  int _safeRound(double value) {
    return value.round();
  }


  /// Get budgets that the user can edit based on scope
  Future<List<Budget>> _getEditableBudgets(
    AppDatabase db,
    String userId,
    String currency,
    CurrencyScope scope,
  ) async {
    switch (scope) {
      case CurrencyScope.personalOnly:
        return (db.select(db.budgets)
          ..where((b) => b.ownerId.equals(userId))
          ..where((b) => b.currency.equals(currency))
          ..where((b) => b.isDeleted.equals(false)))
          .get();
        
      case CurrencyScope.sharedEditable:
        // Get budgets where user is member with editor role
        final memberships = await (db.select(db.budgetMembers)
          ..where((m) => m.userId.equals(userId))
          ..where((m) => m.role.isIn(['owner', 'admin', 'editor']))
          ..where((m) => m.status.equals('active')))
          .get();
        
        final sharedBudgetIds = memberships.map((m) => m.budgetId).toSet();
        
        return (db.select(db.budgets)
          ..where((b) => b.id.isIn(sharedBudgetIds))
          ..where((b) => b.currency.equals(currency))
          ..where((b) => b.isDeleted.equals(false)))
          .get();
        
      case CurrencyScope.all:
        // Personal + shared editable
        final personal = await _getEditableBudgets(db, userId, currency, CurrencyScope.personalOnly);
        final shared = await _getEditableBudgets(db, userId, currency, CurrencyScope.sharedEditable);
        return {...personal, ...shared}.toList();
    }
  }

  /// Get current default currency
  Future<String> getDefaultCurrency() async {
    // Return default currency - can be enhanced to fetch from user settings
    return 'USD';
  }
}

class CurrencyChangeReport {
  final int budgetsUpdated;
  final int accountsUpdated;
  final int expensesUpdated;
  final String? fromCurrency;
  final String? toCurrency;
  final CurrencyChangeMode? mode;

  CurrencyChangeReport({
    this.budgetsUpdated = 0,
    this.accountsUpdated = 0,
    this.expensesUpdated = 0,
    this.fromCurrency,
    this.toCurrency,
    this.mode,
  });

  int get totalUpdated => budgetsUpdated + accountsUpdated + expensesUpdated;
}

/// Provider for CurrencyController
final currencyControllerProvider = Provider<CurrencyController>((ref) {
  return CurrencyController(ref);
});
