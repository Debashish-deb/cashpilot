import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../../data/drift/app_database.dart';
import '../../../core/providers/app_providers.dart';
import '../../sync/services/outbox_service.dart';

final categoryControllerProvider = Provider((ref) => CategoryController(ref));

class CategoryController {
  final Ref _ref;
  final _uuid = const Uuid();

  CategoryController(this._ref);

  AppDatabase get _db => _ref.read(databaseProvider);
  OutboxService get _outbox => OutboxService(_db);

  /// Create a new category
  Future<String> createCategory({
    required String name,
    required String type, // 'expense' or 'income'
    String? iconName,
    String? colorHex,
    String? parentId,
  }) async {
    final id = _uuid.v4();
    
    await _db.insertCategory(CategoriesCompanion(
      id: Value(id),
      name: Value(name),
      type: Value(type),
      iconName: Value(iconName),
      colorHex: Value(colorHex),
      parentId: Value(parentId),
      isSystem: const Value(false),
      syncState: const Value('dirty'), 
      versionVector: const Value(null),
    ));
    
    // OutboxService usage removed - DataBatchSync will pick up dirty record.
    return id;
  }

  /// Update an existing category
  Future<void> updateCategory({
    required String id,
    String? name,
    String? iconName,
    String? colorHex,
    String? parentId,
  }) async {
    final existing = await (_db.select(_db.categories)..where((t) => t.id.equals(id))).getSingleOrNull();
    if (existing == null) throw Exception('Category not found');

    await _db.updateCategory(CategoriesCompanion(
      id: Value(id),
      name: Value(name ?? existing.name),
      iconName: Value(iconName ?? existing.iconName),
      colorHex: Value(colorHex ?? existing.colorHex),
      parentId: Value(parentId ?? existing.parentId),
      updatedAt: Value(DateTime.now()),
      syncState: const Value('dirty'), // Critical: Mark dirty for sync
      revision: Value(existing.revision + 1), // Increment local revision
    ));
  }

  /// Delete a category (soft delete)
  /// FIX: Now handles children by cascade soft-deleting them
  Future<void> deleteCategory(String id) async {
    // Step 1: Find all children of this category
    final children = await (_db.select(_db.categories)
      ..where((t) => t.parentId.equals(id) & t.isDeleted.equals(false)))
      .get();
    
    // Step 2: Cascade delete children first (recursive)
    for (final child in children) {
      await deleteCategory(child.id);
    }
    
    // Step 3: Soft delete the parent
    await (_db.update(_db.categories)..where((t) => t.id.equals(id)))
        .write(const CategoriesCompanion(
          isDeleted: Value(true),
          syncState: Value('dirty'), // Critical: Mark dirty for sync
          updatedAt: Value.absent(), // handled by default or trigger
    ));
    
    debugPrint('✅ Category $id deleted (+ ${children.length} children)');
  }

  /// Merge source category into target category
  /// Transfers expenses and children, then soft-deletes source.
  Future<void> mergeCategories(String sourceId, String targetId) async {
    await _db.mergeCategories(sourceId, targetId);
    
    // Mark source as deleted for sync
    await (_db.update(_db.categories)..where((t) => t.id.equals(sourceId)))
        .write(const CategoriesCompanion(
          isDeleted: Value(true),
          syncState: Value('dirty'),
    ));
  }
}

