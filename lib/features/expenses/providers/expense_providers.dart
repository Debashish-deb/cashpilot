/// CashPilot Expense Providers
/// Riverpod providers for expense state management
library;

import 'package:flutter/material.dart' show DateTimeRange;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../data/drift/app_database.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/logging/logger.dart';
import '../../../core/services/error_reporter.dart';
import '../../receipt/services/duplicate_detector.dart';
import '../../sync/services/outbox_service.dart';
import '../../sync/sync_providers.dart' show syncOrchestratorProvider;
import '../../sync/orchestrator/sync_orchestrator.dart' show SyncReason;

const _uuid = Uuid();

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
  // FIXED: Use allExpensesProvider (limit 10k) instead of recentExpensesProvider (limit 50)
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

// ... (existing imports)

class ExpenseController {
  final Ref _ref;
  final Logger _logger = Loggers.expense;
  
  ExpenseController(this._ref);
  
  AppDatabase get _db => _ref.read(databaseProvider);
  String? get _userId => _ref.read(currentUserIdProvider);
  
  // Phase 1: Outbox service for offline-safe writes
  OutboxService get _outbox => OutboxService(_db);

  /// Create expense with DUPLICATE DETECTION
  /// Returns expense ID on success, throws if duplicate detected
  /// Set skipDuplicateCheck=true to force creation (e.g., user confirmed)
  Future<String> createExpense({
    required String budgetId,
    String? semiBudgetId,
    String? categoryId,
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
    if (_userId == null) throw Exception('User not logged in');
    
    _logger.info('Creating expense', context: {
      'title': title,
      'amount': amount,
      'merchant': merchantName,
    });
    
    // DUPLICATE DETECTION: Check for similar recent expenses
    if (!skipDuplicateCheck) {
      final duplicateResult = await DuplicateDetector.checkDuplicate(
        getRecentExpenses: () async {
          final expenses = await _db.getRecentExpensesMaps(_userId!, limit: 50);
          return expenses;
        },
        merchant: merchantName ?? title,
        total: amount / 100.0,
        date: date,
        currency: currency,
        category: categoryId,
        budgetId: budgetId,
      );
      
      if (duplicateResult.isDuplicate) {
        _logger.warning('Duplicate expense detected', context: {
          'confidence': duplicateResult.confidence,
          'reason': duplicateResult.reason,
          'duplicateId': duplicateResult.duplicateId,
        });
        
        errorReporter.addBreadcrumb('Duplicate expense blocked', category: 'expense', data: {
          'confidence': duplicateResult.confidence,
          'reason': duplicateResult.reason,
        });
        
        // Throw exception to let UI handle (show confirmation dialog)
        throw DuplicateExpenseException(
          confidence: duplicateResult.confidence,
          reason: duplicateResult.reason ?? 'Similar expense found',
          existingExpenseId: duplicateResult.duplicateId,
        );
      }
    }
    
    final id = _uuid.v4();
    
    await _db.insertExpense(ExpensesCompanion.insert(
      id: id,
      budgetId: budgetId,
      semiBudgetId: Value(semiBudgetId),
      categoryId: Value(categoryId),
      enteredBy: _userId!,
      title: title,
      amount: amount,
      currency: Value(currency),
      date: date,
      notes: Value(notes),
      paymentMethod: Value(paymentMethod),
      accountId: Value(accountId),
      receiptUrl: Value(receiptUrl),
      barcodeValue: Value(barcodeValue),
      ocrText: Value(ocrText),
      merchantName: Value(merchantName),
      locationName: Value(location),
      tags: Value(tags),
      syncState: const Value('dirty'),
      createdAt: Value(DateTime.now()), 
      updatedAt: Value(DateTime.now()),
    ));
    
    // Phase 1: Queue for sync via outbox
    try {
      await _outbox.queueEvent(
        entityType: 'expense',
        entityId: id,
        operation: 'create',
        payload: {
          'budgetId': budgetId,
          'semiBudgetId': semiBudgetId,
          'categoryId': categoryId,
          'title': title,
          'amount': amount,
          'currency': currency,
          'date': date.toIso8601String(),
          'notes': notes,
          'paymentMethod': paymentMethod,
          'merchantName': merchantName,
        },
        baseRevision: 0,
      );
    } catch (e) {
      _logger.warning('Outbox queue failed', context: {'error': e.toString()}); 
    }
    
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
    // PERFORMANCE FIX: Direct O(1) lookup instead of fetching 1000 expenses
    final existing = await _db.getExpenseById(id);
    if (existing == null) {
      throw Exception('Expense not found: $id');
    }
    
    await _db.updateExpense(ExpensesCompanion(
      id: Value(id),
      budgetId: Value(budgetId ?? existing.budgetId),
      semiBudgetId: Value(semiBudgetId ?? existing.semiBudgetId),
      categoryId: Value(categoryId ?? existing.categoryId),
      enteredBy: Value(existing.enteredBy),
      title: Value(title ?? existing.title),
      amount: Value(amount ?? existing.amount),
      currency: Value(currency ?? existing.currency),
      date: Value(date ?? existing.date),
      notes: Value(notes ?? existing.notes),
      paymentMethod: Value(paymentMethod ?? existing.paymentMethod),
      accountId: Value(accountId ?? existing.accountId),
      merchantName: Value(merchantName ?? existing.merchantName),
      locationName: Value(location ?? existing.locationName),
      tags: Value(tags ?? existing.tags),
      receiptUrl: Value(existing.receiptUrl),
      barcodeValue: Value(existing.barcodeValue),
      ocrText: Value(existing.ocrText),
      isRecurring: Value(existing.isRecurring),
      recurringId: Value(existing.recurringId),
      createdAt: Value(existing.createdAt),
      updatedAt: Value(DateTime.now()),
      revision: Value(existing.revision + 1),
      isDeleted: Value(existing.isDeleted),
      syncState: const Value('dirty'), // Mark as dirty for sync
    ));

    // Phase 1: Queue for sync via outbox
    try {
      await _outbox.queueEvent(
        entityType: 'expense',
        entityId: id,
        operation: 'update',
        payload: {
          if (title != null) 'title': title,
          if (amount != null) 'amount': amount,
          if (notes != null) 'notes': notes,
          if (merchantName != null) 'merchantName': merchantName,
        },
        baseRevision: existing.revision, // Track revision for conflict detection
      );
    } catch (e) {
      print('Outbox queue failed: $e');
    }
    
    // Invalidate providers to force UI update
    _ref.invalidate(recentExpensesProvider);
    
    // Trigger sync immediately after expense update
    try {
      _ref.read(syncOrchestratorProvider).requestSync(SyncReason.manualUserAction);
    } catch (e) {
      print('[ExpenseController] Sync trigger failed: $e');
    }
  }

  Future<void> deleteExpense(String id) async {
    // Get existing for revision
    final existing = await _db.getExpenseById(id);
    if (existing == null) return;
    
    // Mark as deleted in local DB
    await _db.deleteExpense(id);
    
    // Phase 1: Queue deletion via outbox
    try {
      await _outbox.queueEvent(
        entityType: 'expense',
        entityId: id,
        operation: 'delete',
        payload: {'deletedAt': DateTime.now().toIso8601String()},
        baseRevision: existing.revision,
      );
    } catch (e) {
       print('Outbox queue failed: $e');
    }
    
    // Invalidate providers to force UI update
    _ref.invalidate(recentExpensesProvider);
  }
}

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
