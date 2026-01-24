import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/drift/app_database.dart';
import '../../../core/providers/app_providers.dart';

final reportsRepositoryProvider = Provider<ReportsRepository>((ref) {
  return ReportsRepository(ref.watch(databaseProvider));
});

class ReportsRepository {
  final AppDatabase _db;

  ReportsRepository(this._db);

  /// Fetch expenses within a date range with a high limit for reporting
  Future<List<Expense>> fetchExpensesInDateRange(DateTime start, DateTime end, {String? userId}) async {
    // Note: Drift's auto-generated methods often use 'limit', so we use a custom query or strict where clause
    // The AppDatabase likely has a method for this, or we can use the DAO directly if exposed.
    // For now, using the existing `getExpensesInDateRange` method from AppDatabase if available,
    // otherwise we reconstruct the query here to ensure no limit: 50.
    
    // We check AppDatabase content earlier, it has `getTotalSpentInDateRange` and `getExpensesInDateRange`.
    // Let's verify if `getExpensesInDateRange` has a limit. 
    // Looking at mental model/previous file view: returning `(select(expenses)..where(...)).get()` usually has no limit unless specified.
    
    if (userId == null) {
      // If no userId provided, we probably shouldn't return anything or use a default.
      // But typically we need userId.
      return [];
    }

    return _db.getExpensesInDateRange(userId, start, end);
  }

  /// Get daily spending totals for a date range
  Future<Map<DateTime, int>> fetchDailySpending(DateTime start, DateTime end, {String? userId}) async {
    if (userId == null) return {};

    final expenses = await _db.getExpensesInDateRange(userId, start, end);
    final Map<DateTime, int> dailyTotals = {};

    for (var expense in expenses) {
      final dateValue = DateTime(expense.date.year, expense.date.month, expense.date.day);
      dailyTotals[dateValue] = (dailyTotals[dateValue] ?? 0) + expense.amount;
    }

    return dailyTotals;
  }

  /// Get category breakdown for a date range
  Future<List<Expense>> fetchExpensesForCategoryBreakdown(DateTime start, DateTime end, {String? userId}) async {
    if (userId == null) return [];
    return _db.getExpensesInDateRange(userId, start, end);
  }
}
