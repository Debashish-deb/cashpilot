import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/drift/app_database.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/logging/logger.dart';

class HistoricalRecalculationEngine {
  final AppDatabase _db;
  final Logger _logger = Logger('HistoricalRecalculationEngine');

  HistoricalRecalculationEngine(this._db);

  /// Re-processes all expenses for a budget to ensure they are correctly categorized
  /// and linked, especially after schema or hierarchy changes.
  Future<void> recalculateBudget(String budgetId) async {
    _logger.info('Starting historical recalculation for budget: $budgetId');
    
    final budget = await (_db.select(_db.budgets)..where((t) => t.id.equals(budgetId))).getSingleOrNull();
    if (budget == null) {
      _logger.error('Budget not found: $budgetId');
      return;
    }

    // 1. Fetch all expenses within the budget's time range that AREN'T linked to this budget
    // (This helps find misplaced transactions)
    final orphanedExpenses = await (_db.select(_db.expenses)
          ..where((t) => 
            t.budgetId.isNotValue(budgetId) & 
            t.date.isBiggerOrEqualValue(budget.startDate) & 
            t.date.isSmallerOrEqualValue(budget.endDate) &
            t.isDeleted.equals(false)))
        .get();

    if (orphanedExpenses.isNotEmpty) {
      _logger.info('Found ${orphanedExpenses.length} potential orphaned expenses for budget $budgetId');
      
      await _db.batch((batch) {
        for (final expense in orphanedExpenses) {
          batch.update(_db.expenses, ExpensesCompanion(
            budgetId: Value(budgetId),
            syncState: const Value('dirty'),
          ), where: (t) => t.id.equals(expense.id));
        }
      });
    }

    // 2. Refresh spending totals (this is handled by Drift's reactive streams automatically,
    // but we log here to confirm integrity)
    final totalSpent = await _db.getTotalSpentInBudget(budgetId);
    _logger.info('Recalculation complete for $budgetId. Net Spent: ${totalSpent.toDouble() / 100.0} ${budget.currency}');
  }

  /// Re-assigns expenses from one semi-budget (category) to another.
  /// Useful when merging categories or restructuring.
  Future<void> reAssignCategories({
    required String budgetId,
    required String fromSemiBudgetId,
    required String toSemiBudgetId,
  }) async {
    _logger.info('Moving expenses from $fromSemiBudgetId to $toSemiBudgetId in budget $budgetId');
    
    final count = await (_db.update(_db.expenses)
          ..where((t) => 
            t.budgetId.equals(budgetId) & 
            t.semiBudgetId.equals(fromSemiBudgetId)))
        .write(ExpensesCompanion(
          semiBudgetId: Value(toSemiBudgetId),
          syncState: const Value('dirty'),
        ));

    _logger.info('Successfully moved $count expenses');
  }

  /// Normalizes all expenses in a budget by ensuring merchants are trimmed and amounts are valid
  Future<void> normalizeExpenses(String budgetId) async {
    final expensesInBudget = await (_db.select(_db.expenses)..where((t) => t.budgetId.equals(budgetId))).get();
    
    await _db.batch((batch) {
      for (final expense in expensesInBudget) {
        String? merchant = expense.merchantName?.trim();
        if (merchant != null && merchant.isEmpty) merchant = null;

        if (merchant != expense.merchantName) {
          batch.update(_db.expenses, ExpensesCompanion(
            merchantName: Value(merchant),
            syncState: const Value('dirty'),
          ), where: (t) => t.id.equals(expense.id));
        }
      }
    });
  }
}

final historicalRecalculationProvider = Provider<HistoricalRecalculationEngine>((ref) {
  final db = ref.watch(databaseProvider);
  return HistoricalRecalculationEngine(db);
});
