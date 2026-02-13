/// CashPilot Expense Providers
/// Riverpod providers for expense state management
library;

import 'package:flutter/material.dart' show DateTimeRange;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:drift/drift.dart' show Value;
import '../../../data/drift/app_database.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/logging/logger.dart';
import '../../../core/services/error_reporter.dart';
import '../../../features/receipt/models/receipt_data.dart';
import '../../../features/receipt/services/duplicate_detector.dart';
import '../../sync/sync_providers.dart';

import '../../../domain/usecases/expenses/create_expense_usecase.dart';
import '../../../domain/usecases/expenses/update_expense_usecase.dart';
import '../../../domain/usecases/expenses/delete_expense_usecase.dart';
import 'expense_repository_provider.dart';



// ============================================================
// EXPENSE LIST PROVIDERS
// ============================================================

/// Stream of expenses for a specific budget
final expensesByBudgetProvider = StreamProvider.family<List<Expense>, String>((ref, budgetId) {
  final db = ref.watch(databaseProvider);
  return db.watchExpensesByBudgetId(budgetId);
});

/// Stream of expenses for a specific semi-budget (category)
final expensesBySemiBudgetProvider = StreamProvider.family<List<Expense>, String>((ref, semiBudgetId) {
  final db = ref.watch(databaseProvider);
  return db.watchExpensesBySemiBudgetId(semiBudgetId);
});

/// Stream of expenses for a specific account
final expensesByAccountProvider = StreamProvider.family<List<Expense>, String>((ref, accountId) {
  final db = ref.watch(databaseProvider);
  return db.watchExpensesByAccountId(accountId);
});

/// Recent expenses for the current user (Real-time updates)
final recentExpensesProvider = StreamProvider<List<Expense>>((ref) {
  final db = ref.watch(databaseProvider);
  final userId = ref.watch(currentUserIdProvider);
  
  if (userId == null) {
    return Stream.value([]);
  }
  
  return db.watchRecentExpenses(userId, limit: 50);
});

/// All expenses for analytics (Higher limit)
final allExpensesProvider = StreamProvider<List<Expense>>((ref) {
  final db = ref.watch(databaseProvider);
  final userId = ref.watch(currentUserIdProvider);
  
  if (userId == null) return Stream.value([]);
  
  // Use a high limit for analytics to ensure reports are accurate
  return db.watchRecentExpenses(userId, limit: 10000);
});

// ============================================================
// DATE RANGE & FILTER PROVIDERS (NEW - for scalability)
// ============================================================

/// Date range presets for expense filtering
enum DateRangePreset {
  today,
  yesterday,
  thisWeek,
  lastWeek,
  thisMonth,
  lastMonth,
  thisQuarter,
  lastQuarter,
  thisYear,
  lastYear,
  custom,
  all,
}

/// Current date range preset
final expenseDateRangePresetProvider = StateProvider<DateRangePreset>(
  (ref) => DateRangePreset.thisMonth,
);

/// Custom date range (for custom preset)
final customExpenseDateRangeProvider = StateProvider<DateTimeRange?>(
  (ref) => null,
);

/// Calculate actual date range from preset
final actualExpenseDateRangeProvider = Provider<DateTimeRange>((ref) {
  final preset = ref.watch(expenseDateRangePresetProvider);
  final custom = ref.watch(customExpenseDateRangeProvider);
  
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  
  switch (preset) {
    case DateRangePreset.today:
      return DateTimeRange(
        start: today,
        end: today.add(const Duration(days: 1)),
      );
      
    case DateRangePreset.yesterday:
      final yesterday = today.subtract(const Duration(days: 1));
      return DateTimeRange(start: yesterday, end: today);
      
    case DateRangePreset.thisWeek:
      final weekStart = today.subtract(Duration(days: now.weekday - 1));
      return DateTimeRange(start: weekStart, end: today.add(const Duration(days: 1)));
      
    case DateRangePreset.lastWeek:
      final lastWeekEnd = today.subtract(Duration(days: now.weekday));
      final lastWeekStart = lastWeekEnd.subtract(const Duration(days: 6));
      return DateTimeRange(start: lastWeekStart, end: lastWeekEnd);
      
    case DateRangePreset.thisMonth:
      final monthStart = DateTime(now.year, now.month, 1);
      return DateTimeRange(start: monthStart, end: today.add(const Duration(days: 1)));
      
    case DateRangePreset.lastMonth:
      final lastMonthStart = DateTime(now.year, now.month - 1, 1);
      final lastMonthEnd = DateTime(now.year, now.month, 1);
      return DateTimeRange(start: lastMonthStart, end: lastMonthEnd);
      
    case DateRangePreset.thisQuarter:
      final quarter = ((now.month - 1) / 3).floor();
      final quarterStart = DateTime(now.year, quarter * 3 + 1, 1);
      return DateTimeRange(start: quarterStart, end: today.add(const Duration(days: 1)));
      
    case DateRangePreset.lastQuarter:
      final quarter = ((now.month - 1) / 3).floor();
      final lastQuarterStart = DateTime(now.year, (quarter - 1) * 3 + 1, 1);
      final lastQuarterEnd = DateTime(now.year, quarter * 3 + 1, 1);
      return DateTimeRange(start: lastQuarterStart, end: lastQuarterEnd);
      
    case DateRangePreset.thisYear:
      final yearStart = DateTime(now.year, 1, 1);
      return DateTimeRange(start: yearStart, end: today.add(const Duration(days: 1)));
      
    case DateRangePreset.lastYear:
      final lastYearStart = DateTime(now.year - 1, 1, 1);
      final lastYearEnd = DateTime(now.year, 1, 1);
      return DateTimeRange(start: lastYearStart, end: lastYearEnd);
      
    case DateRangePreset.custom:
      if (custom != null) return custom;
      // Fallback to this month
      final monthStart = DateTime(now.year, now.month, 1);
      return DateTimeRange(start: monthStart, end: today.add(const Duration(days: 1)));
      
    case DateRangePreset.all:
      // Return very wide range
      return DateTimeRange(
        start: DateTime(2020, 1, 1),
        end: DateTime(2030, 12, 31),
      );
  }
});

/// Filtered expenses by date range
final filteredExpensesByDateProvider = Provider<AsyncValue<List<Expense>>>((ref) {
  // Use allExpensesProvider for accurate reports (instead of recentExpensesProvider which has limit 50)
  final recentExpenses = ref.watch(allExpensesProvider);
  final dateRange = ref.watch(actualExpenseDateRangeProvider);
  
  return recentExpenses.whenData((expenses) {
    return expenses.where((e) =>
      (e.date.isAfter(dateRange.start) || e.date.isAtSameMomentAs(dateRange.start)) &&
      (e.date.isBefore(dateRange.end) || e.date.isAtSameMomentAs(dateRange.end))
    ).toList();
  });
});

/// Grouped expenses by year-month
final groupedExpensesByMonthProvider = Provider<AsyncValue<Map<String, List<Expense>>>>((ref) {
  final filteredExpenses = ref.watch(filteredExpensesByDateProvider);
  
  return filteredExpenses.whenData((expenses) {
    final grouped = <String, List<Expense>>{};
    
    for (final expense in expenses) {
      final key = '${expense.date.year}-${expense.date.month.toString().padLeft(2, '0')}';
      grouped.putIfAbsent(key, () => []).add(expense);
    }
    
    // Sort keys descending (newest first)
    final sortedGroups = <String, List<Expense>>{};
    final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
    
    for (final key in sortedKeys) {
      sortedGroups[key] = grouped[key]!;
    }
    
    return sortedGroups;
  });
});

/// Grouped expenses by week
final groupedExpensesByWeekProvider = Provider<AsyncValue<Map<String, List<Expense>>>>((ref) {
  final filteredExpenses = ref.watch(filteredExpensesByDateProvider);
  
  return filteredExpenses.whenData((expenses) {
    final grouped = <String, List<Expense>>{};
    
    for (final expense in expenses) {
      // Calculate week of year
      final dayOfYear = expense.date.difference(DateTime(expense.date.year, 1, 1)).inDays;
      final weekOfYear = ((dayOfYear) / 7).ceil();
      final key = '${expense.date.year}-W${weekOfYear.toString().padLeft(2, '0')}';
      grouped.putIfAbsent(key, () => []).add(expense);
    }
    
    // Sort keys descending
    final sortedGroups = <String, List<Expense>>{};
    final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
    
    for (final key in sortedKeys) {
      sortedGroups[key] = grouped[key]!;
    }
    
    return sortedGroups;
  });
});

/// Grouped expenses by category (if categories exist)
final groupedExpensesByCategoryProvider = Provider<AsyncValue<Map<String, List<Expense>>>>((ref) {
  final filteredExpenses = ref.watch(filteredExpensesByDateProvider);
  
  return filteredExpenses.whenData((expenses) {
    final grouped = <String, List<Expense>>{};
    
    for (final expense in expenses) {
      final key = expense.categoryId ?? 'Uncategorized';
      grouped.putIfAbsent(key, () => []).add(expense);
    }
    
    // Sort by total spent (highest first)
    final sortedGroups = <String, List<Expense>>{};
    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) {
        final aTotal = grouped[a]!.fold<int>(0, (sum, e) => sum + e.amount);
        final bTotal = grouped[b]!.fold<int>(0, (sum, e) => sum + e.amount);
        return bTotal.compareTo(aTotal);
      });
    
    for (final key in sortedKeys) {
      sortedGroups[key] = grouped[key]!;
    }
    
    return sortedGroups;
  });
});

/// Bulk selection state for expenses
final selectedExpenseIdsProvider = StateProvider<Set<String>>((ref) => {});

/// Check if any expenses are selected
final hasSelectedExpensesProvider = Provider<bool>((ref) {
  final selected = ref.watch(selectedExpenseIdsProvider);
  return selected.isNotEmpty;
});

/// Get selected expenses from IDs
final selectedExpensesProvider = Provider<List<Expense>>((ref) {
  final selectedIds = ref.watch(selectedExpenseIdsProvider);
  final allExpenses = ref.watch(filteredExpensesByDateProvider);
  
  return allExpenses.when(
    data: (expenses) => expenses.where((e) => selectedIds.contains(e.id)).toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

// Note: Using Flutter's built-in DateTimeRange from 'package:flutter/material.dart'

// ============================================================
// EXPENSE STATS PROVIDERS
// ============================================================

/// Total spent in a budget (Reactive)
final totalSpentInBudgetProvider = StreamProvider.family<int, String>((ref, budgetId) {
  final db = ref.watch(databaseProvider);
  return db.watchTotalSpentInBudget(budgetId);
});

/// Total spent in a semi-budget (category) (Reactive)
final totalSpentInSemiBudgetProvider = StreamProvider.family<int, String>((ref, semiBudgetId) {
  final db = ref.watch(databaseProvider);
  return db.watchTotalSpentInSemiBudget(semiBudgetId);
});

// ============================================================
// TODAY'S SPENDING PROVIDER (Reactive - derived from recentExpenses)
// ============================================================

/// Today's total spending - derived from recentExpenses stream for real-time updates
final todaySpendingProvider = StreamProvider<int>((ref) {
  final recentExpensesStream = ref.watch(recentExpensesProvider.stream);
  
  return recentExpensesStream.map((expenses) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    
    // Filter to today and sum amounts
    return expenses
        .where((e) => e.date.isAfter(todayStart) || e.date.isAtSameMomentAs(todayStart))
        .fold<int>(0, (sum, e) => sum + e.amount);
  });
});

// ============================================================
// THIS MONTH'S SPENDING PROVIDER (Reactive - derived from recentExpenses)
// ============================================================

/// This month's total spending - derived from recentExpenses stream for real-time updates
final thisMonthSpendingProvider = StreamProvider<int>((ref) {
  final recentExpensesStream = ref.watch(recentExpensesProvider.stream);
  
  return recentExpensesStream.map((expenses) {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    
    // Filter to this month and sum amounts
    return expenses
        .where((e) => e.date.isAfter(monthStart) || e.date.isAtSameMomentAs(monthStart))
        .fold<int>(0, (sum, e) => sum + e.amount);
  });
});

// ============================================================
// DAILY SPENDING HISTORY (for Anomaly Detection)
// ============================================================

/// Daily spending history for a budget (last 7 days)
/// Returns list of daily totals in cents
final dailySpendingHistoryProvider = FutureProvider.family<List<int>, String>((ref, budgetId) async {
  final db = ref.watch(databaseProvider);
  
  final now = DateTime.now();
  final List<int> dailyTotals = [];
  
  // Get spending for each of the last 7 days
  for (int i = 6; i >= 0; i--) {
    final day = now.subtract(Duration(days: i));
    final startOfDay = DateTime(day.year, day.month, day.day);
    final endOfDay = startOfDay.add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1));
    
    final total = await db.getTotalSpentInBudgetDateRange(budgetId, startOfDay, endOfDay);
    dailyTotals.add(total);
  }
  
  return dailyTotals;
});

// ============================================================
// REPORTING PROVIDERS
// ============================================================

/// Expenses in a date range - derived from recentExpenses for consistency
final expensesInRangeProvider = Provider.family<List<Expense>, ({DateTime start, DateTime end})>((ref, range) {
  // Use allExpensesProvider (limit 10k) instead of recentExpensesProvider (limit 50)
  final allExpenses = ref.watch(allExpensesProvider);
  
  return allExpenses.when(
    data: (expenses) => expenses
        .where((e) => 
            (e.date.isAfter(range.start) || e.date.isAtSameMomentAs(range.start)) &&
            (e.date.isBefore(range.end) || e.date.isAtSameMomentAs(range.end)))
        .toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

// ============================================================
// EXPENSE CONTROLLER
// ============================================================

/// Controller for expense mutations
final expenseControllerProvider = Provider((ref) {
  return ExpenseController(ref);
});

class ExpenseController {
  final Ref _ref;
  final Logger _logger = Loggers.expense;

  final CreateExpenseUseCase _createExpenseUseCase;
  final UpdateExpenseUseCase _updateExpenseUseCase;
  final DeleteExpenseUseCase _deleteExpenseUseCase;

  ExpenseController(this._ref)
      : _createExpenseUseCase = CreateExpenseUseCase(_ref.read(expenseRepositoryProvider)),
        _updateExpenseUseCase = UpdateExpenseUseCase(_ref.read(expenseRepositoryProvider)),
        _deleteExpenseUseCase = DeleteExpenseUseCase(_ref.read(expenseRepositoryProvider));

  /// Create expense with DUPLICATE DETECTION
  Future<String> createExpense({
    required String budgetId,
    String? semiBudgetId,
    String? categoryId,
    String? subCategoryId,
    required String title,
    required int amount,
    String currency = 'EUR',
    required DateTime date,
    String? notes,
    String paymentMethod = 'cash',
    String? accountId,
    String? receiptUrl,
    String? barcodeValue,
    String? ocrText,
    String? merchantName,
    String? location,
    String? tags,
    bool skipDuplicateCheck = false,
  }) async {
    final userId = _ref.read(currentUserIdProvider);
    if (userId == null) throw Exception('User not logged in');

    _logger.info('Creating expense', context: {
      'title': title,
      'amount': amount,
      'merchant': merchantName,
    });

    // --- P0 FAMILY SPENDING LIMIT & RBAC CHECK ---
    final db = _ref.read(databaseProvider);
    final member = await db.getBudgetMember(budgetId, userId);
    
    if (member != null) {
      // RBAC: Prevent viewers from creating expenses
      if (member.role == 'viewer') {
        throw Exception('Viewers are not allowed to create expenses');
      }

      // Spending Limit
      if (member.spendingLimit != null) {
        final currentSpent = await db.getMemberSpendingInBudget(budgetId, userId);
        if (currentSpent + amount > member.spendingLimit!) {
          throw Exception('Member spending limit exceeded for this budget');
        }
      }
    }

    if (!skipDuplicateCheck) {
      final db = _ref.read(databaseProvider);
      final recentExpenses = await db.getRecentExpenses(userId, limit: 50);
      
      // Convert history to ReceiptData model
      final history = recentExpenses.map((e) => ReceiptData(
        total: e.amount / 100.0,
        merchantName: e.merchantName,
        date: e.date,
        currencyCode: e.currency,
      )).toList();

      // Convert current attempt to ReceiptData
      final current = ReceiptData(
        total: amount / 100.0,
        merchantName: merchantName ?? title,
        date: date,
        currencyCode: currency,
      );

      final duplicateResult = DuplicateDetector.detect(
        current: current,
        history: history,
      );

      if (duplicateResult.isDuplicate) {
        _logger.warning('Duplicate expense detected', context: {
          'confidence': duplicateResult.confidence,
          'existingId': duplicateResult.matchedReceiptId,
        });
        throw DuplicateExpenseException(
          confidence: duplicateResult.confidence,
          reason: duplicateResult.reason,
          existingExpenseId: duplicateResult.matchedReceiptId,
        );
      }
    }

    final params = CreateExpenseParams(
      budgetId: budgetId,
      semiBudgetId: semiBudgetId,
      categoryId: categoryId,
      subCategoryId: subCategoryId,
      title: title,
      amount: amount,
      currency: currency,
      date: date,
      enteredBy: userId,
      notes: notes,
      paymentMethod: paymentMethod,
      accountId: accountId,
      receiptUrl: receiptUrl,
      barcodeValue: barcodeValue,
      merchantName: merchantName,
      locationName: location,
      tags: tags,
      ocrText: ocrText,
      skipDuplicateCheck: skipDuplicateCheck,
    );

    final id = await _createExpenseUseCase.execute(params);

    // Invalidate providers to force UI update
    _ref.invalidate(recentExpensesProvider);

    // Trigger sync immediately
    try {
      _ref.read(syncOrchestratorProvider).requestSync(SyncReason.manualUserAction);
    } catch (e) {
      _logger.warning('Sync trigger failed', context: {'error': e.toString()});
    }
    
    _logger.info('Expense created successfully', context: {'id': id});
    errorReporter.addBreadcrumb('Expense created', category: 'expense', data: {'id': id});

    return id;
  }

  Future<void> updateExpense({
    required String id,
    String? budgetId,
    String? semiBudgetId,
    String? categoryId,
    String? subCategoryId,
    String? title,
    int? amount,
    String? currency,
    DateTime? date,
    String? notes,
    String? paymentMethod,
    String? accountId,
    String? merchantName,
    String? location,
    String? tags,
  }) async {
    await _updateExpenseUseCase.execute(UpdateExpenseParams(
      id: id,
      budgetId: budgetId,
      categoryId: categoryId,
      subCategoryId: subCategoryId,
      semiBudgetId: semiBudgetId,
      title: title,
      amount: amount,
      currency: currency,
      date: date,
      notes: notes,
      paymentMethod: paymentMethod,
      merchantName: merchantName,
      tags: tags,
    ));

    _ref.invalidate(recentExpensesProvider);

    try {
      _ref.read(syncOrchestratorProvider).requestSync(SyncReason.manualUserAction);
    } catch (e) {
      _logger.warning('Sync trigger failed: $e');
    }
  }

  Future<void> deleteExpense(String id) async {
    await _deleteExpenseUseCase.execute(id);
    _ref.invalidate(recentExpensesProvider);
  }

  /// Toggle reconciliation status (P0 Financial Integrity)
  Future<void> toggleReconciled(String id, bool reconciled) async {
    final db = _ref.read(databaseProvider);
    await db.updateExpense(ExpensesCompanion(
      id: Value(id),
      isReconciled: Value(reconciled),
    ));
    _ref.invalidate(recentExpensesProvider);
  }

  /// Create a split expense across multiple categories
  Future<String> createSplitExpense({
    required String budgetId,
    required String title,
    required int totalAmount,
    required String currency,
    required DateTime date,
    required List<({String semiBudgetId, int amount, String? notes})> splits,
    String? accountId,
    String? merchantName,
    String? notes,
  }) async {
    final userId = _ref.read(currentUserIdProvider);
    if (userId == null) throw Exception('User not logged in');

    _logger.info('Creating split expense', context: {
      'title': title,
      'total': totalAmount,
      'splits': splits.length,
    });

    // Simple validation: Sum of splits must match total
    final sum = splits.fold<int>(0, (prev, element) => prev + element.amount);
    if (sum != totalAmount) {
      throw Exception('Split amounts ($sum) do not match total amount ($totalAmount)');
    }

    final id = await _ref.read(expenseRepositoryProvider).createSplitExpense(
      budgetId: budgetId,
      title: title,
      totalAmount: totalAmount,
      currency: currency,
      date: date,
      enteredBy: userId,
      splits: splits,
      accountId: accountId,
      merchantName: merchantName,
      notes: notes,
    );

    _ref.invalidate(recentExpensesProvider);

    try {
      _ref.read(syncOrchestratorProvider).requestSync(SyncReason.manualUserAction);
    } catch (e) {
      _logger.warning('Sync trigger failed: $e');
    }

    return id;
  }
}

// ============================================================
// RECURRING EXPENSE PROVIDERS
// ============================================================

/// Upcoming bills (Recurring Expenses ordered by due date)
final upcomingBillsProvider = StreamProvider<List<RecurringExpense>>((ref) {
  final db = ref.watch(databaseProvider);
  final userId = ref.watch(currentUserIdProvider);
  
  if (userId == null) return Stream.value([]);
  
  return db.watchRecurringExpenses(userId);
});

// ============================================================
// DUPLICATE EXPENSE EXCEPTION
// ============================================================

/// Exception thrown when a duplicate expense is detected
class DuplicateExpenseException implements Exception {
  final double confidence;
  final String reason;
  final String? existingExpenseId;
  
  const DuplicateExpenseException({
    required this.confidence,
    required this.reason,
    this.existingExpenseId,
  });
  
  @override
  String toString() => 'Possible duplicate: $reason (${(confidence * 100).toStringAsFixed(0)}% match)';
}
