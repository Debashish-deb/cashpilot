/// CashPilot Category Providers
library;
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/drift/app_database.dart';
import '../../../core/providers/app_providers.dart';

/// Future provider to fetch all available system categories (and custom ones if any)
final allCategoriesProvider = FutureProvider<List<Category>>((ref) async {
  final db = ref.watch(databaseProvider);
  return db.getAllCategories();
});

/// Stream provider for categories (if we want reactive updates when sync happens)
final categoriesStreamProvider = StreamProvider<List<Category>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.select(db.categories).watch();
});

/// Provider to get a category by ID (useful for resolving names)
final categoryByIdProvider = FutureProvider.family<Category?, String>((ref, id) async {
  final db = ref.watch(databaseProvider);
  return (db.select(db.categories)..where((t) => t.id.equals(id))).getSingleOrNull();
});

/// Grouped categories provider (Roots with their children)
/// Returns a Map<Category, List<Category>> where key is parent, value is children
final groupedCategoriesProvider = FutureProvider<Map<Category, List<Category>>>((ref) async {
  final categories = await ref.watch(allCategoriesProvider.future);
  
  final Map<Category, List<Category>> grouped = {};
  
  // First find roots
  final roots = categories.where((c) => c.parentId == null).toList();
  
  for (var root in roots) {
    final children = categories.where((c) => c.parentId == root.id).toList();
    grouped[root] = children;
  }
  
  return grouped;
});

/// Provider for subcategories filtered by category
final subCategoriesByCategoryIdProvider = StreamProvider.family<List<SubCategory>, String>((ref, categoryId) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.subCategories)..where((t) => t.categoryId.equals(categoryId))).watch();
});

// =============================================================================
// CATEGORY SPENDING STATISTICS
// =============================================================================

/// Spending data for a single category
class CategorySpendingStats {
  final String categoryId;
  final String categoryName;
  final String? iconName;
  final String? colorHex;
  final int totalSpentCents;
  final int expenseCount;
  final DateTime? lastExpenseDate;

  const CategorySpendingStats({
    required this.categoryId,
    required this.categoryName,
    this.iconName,
    this.colorHex,
    required this.totalSpentCents,
    required this.expenseCount,
    this.lastExpenseDate,
  });

  double get totalSpent => totalSpentCents / 100.0;
}

/// Provider that aggregates spending per category for current month
final categorySpendingStatsProvider = FutureProvider<Map<String, CategorySpendingStats>>((ref) async {
  final db = ref.watch(databaseProvider);
  
  // Get current month range
  final now = DateTime.now();
  final startOfMonth = DateTime(now.year, now.month, 1);
  final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
  
  // Fetch all expenses for this month
  final expenses = await (db.select(db.expenses)
    ..where((e) => e.isDeleted.equals(false))
    ..where((e) => e.date.isBetweenValues(startOfMonth, endOfMonth)))
    .get();
  
  // Fetch all categories for reference
  final categories = await db.getAllCategories();
  final categoryMap = {for (var c in categories) c.id: c};
  
  // Aggregate expenses by categoryId
  final Map<String, CategorySpendingStats> stats = {};
  
  for (var expense in expenses) {
    final catId = expense.categoryId;
    if (catId == null) continue;
    
    final category = categoryMap[catId];
    if (category == null) continue;
    
    if (stats.containsKey(catId)) {
      final existing = stats[catId]!;
      stats[catId] = CategorySpendingStats(
        categoryId: catId,
        categoryName: category.name,
        iconName: category.iconName,
        colorHex: category.colorHex,
        totalSpentCents: existing.totalSpentCents + expense.amount,
        expenseCount: existing.expenseCount + 1,
        lastExpenseDate: expense.date.isAfter(existing.lastExpenseDate ?? DateTime(1970))
            ? expense.date
            : existing.lastExpenseDate,
      );
    } else {
      stats[catId] = CategorySpendingStats(
        categoryId: catId,
        categoryName: category.name,
        iconName: category.iconName,
        colorHex: category.colorHex,
        totalSpentCents: expense.amount,
        expenseCount: 1,
        lastExpenseDate: expense.date,
      );
    }
  }
  
  return stats;
});

/// Watch all subcategories
final allSubCategoriesProvider = StreamProvider<List<SubCategory>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllSubCategories();
});

