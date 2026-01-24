import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/drift/app_database.dart';

final reportsServiceProvider = Provider<ReportsService>((ref) {
  return ReportsService();
});

class ReportsService {
  
  /// Aggregate expenses by category for pie chart
  /// Returns a map of Category Name -> Total Amount
  Map<String, double> aggregateByCategory(List<Expense> expenses, List<Category> categories) {
    final categoryMap = {for (var c in categories) c.id: c};
    final Map<String, double> totals = {};

    for (var e in expenses) {
      String name = 'Uncategorized';
      if (e.categoryId != null) {
        final cat = categoryMap[e.categoryId];
        if (cat != null) {
          name = cat.name;
        }
      }
      totals[name] = (totals[name] ?? 0) + e.amount;
    }
    
    // Sort by value descending
    return Map.fromEntries(
      totals.entries.toList()..sort((a, b) => b.value.compareTo(a.value))
    );
  }

  /// prepare data for trends chart
  /// Returns a list of daily totals for the given range, ensuring 0 for days with no expenses
  List<MapEntry<DateTime, double>> prepareTrendData(List<Expense> expenses, DateTime start, DateTime end) {
    final Map<DateTime, double> dailyTotals = {};
    
    // Initialize all days with 0
    // Limit loop to avoid infinite if end is far future, though UI shouldn't allow it
    int days = end.difference(start).inDays + 1;
    if (days > 365 * 2) days = 365 * 2; // Safety cap

    for (int i = 0; i < days; i++) {
        final date = DateTime(start.year, start.month, start.day).add(Duration(days: i));
        dailyTotals[date] = 0.0;
    }

    // Sum expenses
    for (var e in expenses) {
      final dateKey = DateTime(e.date.year, e.date.month, e.date.day);
      if (dailyTotals.containsKey(dateKey)) {
        dailyTotals[dateKey] = (dailyTotals[dateKey] ?? 0) + e.amount;
      }
    }

    return dailyTotals.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
  }
}
