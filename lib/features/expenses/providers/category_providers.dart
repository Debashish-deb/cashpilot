
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/drift/app_database.dart';
import '../../../core/providers/app_providers.dart';

/// Watch all main categories
final allCategoriesProvider = StreamProvider<List<Category>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllCategories();
});

/// Watch subcategories for a specific category
final subCategoriesProvider = StreamProvider.family<List<SubCategory>, String>((ref, categoryId) {
  final db = ref.watch(databaseProvider);
  return db.watchSubCategoriesByCategoryId(categoryId);
});

/// Watch all categories as a list (for dropdowns)
final categoriesListProvider = FutureProvider<List<Category>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.getCategories();
});
/// Watch all subcategories
final allSubCategoriesProvider = StreamProvider<List<SubCategory>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllSubCategories();
});
