import 'package:flutter/foundation.dart' hide Category;
import 'package:drift/drift.dart';
import 'base_sync_manager.dart';
import '../../../data/drift/app_database.dart';
import '../../../services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CategorySyncManager implements BaseSyncManager<Category> {
  final AppDatabase db;
  final AuthService authService;
  final SharedPreferences prefs;
  static const _syncKey = 'last_categories_sync_iso';

  CategorySyncManager(this.db, this.authService, this.prefs);

  @override
  Future<void> syncUp(String id) async {
    // Categories are currently system-managed (seeded) or read-only on client.
    // If we enable custom categories, we'd implement push here.
  }

  @override
  Future<void> syncDown(String id) async {
      // Implement if needed for single item fetch
  }

  @override
  Future<int> pushChanges() async {
    // Currently, only PULL is supported for categories (System seeded).
    // Future: Scan for is_system=false and push.
    return 0;
  }

  @override
  Future<int> pullChanges() async {
    int count = 0;
    try {
      final lastSyncStr = prefs.getString(_syncKey);
      
      var query = authService.client
          .from('categories')
          .select();
      
      // Incremental sync: only fetch changes since last sync
      if (lastSyncStr != null) {
        query = query.gt('updated_at', lastSyncStr);
      }

      final remoteCategories = await query;
      
      DateTime? maxUpdated;

      for (var data in remoteCategories) {
        await _upsertLocal(data);
        count++;
        
        // Track latest update time
        final updatedAt = DateTime.tryParse(data['updated_at'] ?? '');
        if (updatedAt != null) {
          if (maxUpdated == null || updatedAt.isAfter(maxUpdated)) {
            maxUpdated = updatedAt;
          }
        }
      }
      
      // Save checkpoint if we received data
      if (maxUpdated != null) {
        await prefs.setString(_syncKey, maxUpdated.toIso8601String());
      }
      
      debugPrint('[CategorySyncManager] Synced $count categories from cloud.');
    } catch (e) {
      debugPrint('[CategorySyncManager] Error pulling categories: $e');
    }
    return count;
  }

  Future<void> _upsertLocal(Map<String, dynamic> data) async {
    final categoryId = data['id'] as String;
    final isDeleted = data['is_deleted'] as bool? ?? false;
    
    // CRITICAL FIX: If category is marked as deleted on server, remove it locally
    if (isDeleted) {
      try {
        await (db.delete(db.categories)..where((t) => t.id.equals(categoryId))).go();
        debugPrint('[CategorySyncManager] ✅ Permanently deleted category $categoryId');
        return;
      } catch (e) {
        debugPrint('[CategorySyncManager] ⚠️ Error deleting category $categoryId: $e');
        return;
      }
    }
    
    // Safely convert nameTranslations (could be Map, List, or null)
    Map<String, dynamic>? nameTranslations;
    if (data['name_translations'] is Map) {
      nameTranslations = data['name_translations'] as Map<String, dynamic>;
    }
    
    // Safely convert tags (could be String, List, or null)
    String? tags;
    if (data['tags'] is String) {
      tags = data['tags'] as String;
    } else if (data['tags'] is List) {
      // Convert list to JSON string
      tags = (data['tags'] as List).join(',');
    }
    
    final companion = CategoriesCompanion(
      id: Value(categoryId),
      ownerId: Value(data['owner_id'] as String?),
      name: Value(data['name'] as String),
      nameTranslations: Value(nameTranslations),
      iconName: Value(data['icon_name'] as String?),
      colorHex: Value(data['color_hex'] as String?),
      parentId: Value(data['parent_id'] as String?),
      type: Value(data['type'] as String? ?? 'expense'),
      isSystem: Value(data['is_system'] as bool? ?? true),
      tags: Value(tags),
      revision: Value((data['revision'] as num? ?? 0).toInt()),
      isDeleted: const Value(false), // Never insert with isDeleted=true
      createdAt: Value(DateTime.tryParse(data['created_at'] as String? ?? '') ?? DateTime.now()),
      updatedAt: Value(DateTime.tryParse(data['updated_at'] as String? ?? '') ?? DateTime.now()),
    );
    
    try {
      await db.insertCategory(companion);
    } catch (e) {
      // Use write() instead of replace() for reliable updates
      await (db.update(db.categories)..where((t) => t.id.equals(categoryId)))
          .write(companion);
      debugPrint('[CategorySyncManager] Updated existing category $categoryId from remote');
    }
  }
}
