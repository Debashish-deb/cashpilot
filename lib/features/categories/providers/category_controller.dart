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
    ));
    
    // Trigger sync with error logging
    // Phase 1: Queue for sync via outbox (instead of direct sync)
    try {
      await _outbox.queueEvent(
        entityType: 'category',
        entityId: id,
        operation: 'create',
        payload: {
          'name': name,
          'type': type,
          'iconName': iconName,
          'colorHex': colorHex,
          'parentId': parentId,
        },
        baseRevision: 0,
      );
    } catch (e) {
      debugPrint('⚠️ Category outbox queue failed for $id: $e');
    }
    
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
    ));

    // Trigger sync with error logging
    // Phase 1: Queue for sync via outbox
    try {
      final revision = existing.revision ?? 0;
      await _outbox.queueEvent(
        entityType: 'category',
        entityId: id,
        operation: 'update',
        payload: {
          if (name != null) 'name': name,
          if (iconName != null) 'iconName': iconName,
          if (colorHex != null) 'colorHex': colorHex,
          if (parentId != null) 'parentId': parentId,
        },
        baseRevision: revision,
      );
    } catch (e) {
      debugPrint('⚠️ Category outbox queue failed for $id: $e');
    }
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
        .write(const CategoriesCompanion(isDeleted: Value(true)));

    // Trigger sync with error logging
    // Phase 1: Queue for sync via outbox
    try {
      final existing = await (_db.select(_db.categories)..where((t) => t.id.equals(id))).getSingleOrNull();
      if (existing != null) {
        final revision = existing.revision;
        await _outbox.queueEvent(
          entityType: 'category',
          entityId: id,
          operation: 'delete',
          payload: {'deletedAt': DateTime.now().toIso8601String()},
          baseRevision: revision,
        );
      }
    } catch (e) {
      debugPrint('⚠️ Category outbox queue failed for $id: $e');
    }
    
    debugPrint('✅ Category $id deleted (+ ${children.length} children)');
  }

  /// Merge source category into target category
  /// Transfers expenses and children, then soft-deletes source.
  Future<void> mergeCategories(String sourceId, String targetId) async {
    await _db.mergeCategories(sourceId, targetId);
    
    // TODO: Queue sync events for affected entities
    // For now, simpler to just mark source as deleted for sync
    try {
      final existing = await (_db.select(_db.categories)..where((t) => t.id.equals(sourceId))).getSingleOrNull();
      if (existing != null) {
         final revision = existing.revision;
         await _outbox.queueEvent(
           entityType: 'category',
           entityId: sourceId,
           operation: 'delete',
           payload: {'mergedInto': targetId, 'deletedAt': DateTime.now().toIso8601String()},
           baseRevision: revision,
         );
      }
    } catch (e) {
      debugPrint('⚠️ Merge outbox queue failed for $sourceId: $e');
    }
  }
}

