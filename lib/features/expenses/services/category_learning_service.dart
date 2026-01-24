/// Category Learning Service
/// Stores and retrieves user's category selection patterns for personalized predictions
library;

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../../data/drift/app_database.dart';

class CategoryLearningService {
  final AppDatabase _db;
  static const _uuid = Uuid();
  
  CategoryLearningService(this._db);
  
  /// Learn from user's category selection
  /// Stores pattern and boosts confidence for future predictions
  Future<void> learnPattern({
    required String merchant,
    required String selectedCategory,
  }) async {
    // Normalize merchant name (lowercase, remove special chars)
    final pattern = _normalizeMerchant(merchant);
    
    // Check if pattern already exists
    final existing = await (_db.select(_db.categoryLearning)
      ..where((t) => t.merchantPattern.equals(pattern) & t.categoryName.equals(selectedCategory))
    ).getSingleOrNull();
    
    if (existing != null) {
      // Update existing: increment usage, update timestamp, boost confidence
      final newUsageCount = existing.usageCount + 1;
      final newBoost = _calculateBoost(newUsageCount);
      
      await (_db.update(_db.categoryLearning)
        ..where((t) => t.id.equals(existing.id)))
        .write(CategoryLearningCompanion(
          usageCount: Value(newUsageCount),
          confidenceBoost: Value(newBoost),
          lastUsedAt: Value(DateTime.now()),
        ));
    } else {
      // Create new learning entry
      final entry = CategoryLearningCompanion.insert(
        id: _uuid.v4(),
        merchantPattern: pattern,
        categoryName: selectedCategory,
        lastUsedAt: DateTime.now(),
      );
      
      await _db.into(_db.categoryLearning).insert(entry);
    }
  }
  
  /// Get learned patterns for a merchant
  /// Returns map of category -> confidence boost
  Future<Map<String, int>> getLearnedBoosts(String merchant) async {
    final pattern = _normalizeMerchant(merchant);
    
    final results = await (_db.select(_db.categoryLearning)
      ..where((t) => t.merchantPattern.like('%$pattern%'))
      ..orderBy([(t) => OrderingTerm.desc(t.usageCount)])
    ).get();
    
    final boosts = <String, int>{};
    for (final result in results) {
      boosts[result.categoryName] = result.confidenceBoost;
    }
    
    return boosts;
  }
  
  /// Get top learned category for exact merchant match
  Future<String?> getTopLearnedCategory(String merchant) async {
    final pattern = _normalizeMerchant(merchant);
    
    final result = await (_db.select(_db.categoryLearning)
      ..where((t) => t.merchantPattern.equals(pattern))
      ..orderBy([(t) => OrderingTerm.desc(t.usageCount)])
      ..limit(1)
    ).getSingleOrNull();
    
    return result?.categoryName;
  }
  
  /// Clear old learning data (cleanup - keep last 90 days)
  Future<int> cleanupOldPatterns() async {
    final cutoff = DateTime.now().subtract(const Duration(days: 90));
    
    return await (_db.delete(_db.categoryLearning)
      ..where((t) => t.lastUsedAt.isSmallerThanValue(cutoff))
    ).go();
  }
  
  /// Get all learned patterns (for debugging/export)
  Future<List<CategoryLearningData>> getAllPatterns() async {
    return await _db.select(_db.categoryLearning).get();
  }
  
  /// Normalize merchant name for consistent matching
  String _normalizeMerchant(String merchant) {
    return merchant
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), '') // Remove special chars
        .replaceAll(RegExp(r'\s+'), ' ') // Normalize spaces
        .trim();
  }
  
  /// Calculate confidence boost based on usage count
  /// More usage = higher confidence (max +30)
  int _calculateBoost(int usageCount) {
    if (usageCount == 1) return 10;
    if (usageCount == 2) return 15;
    if (usageCount >= 3 && usageCount < 5) return 20;
    if (usageCount >= 5 && usageCount < 10) return 25;
    return 30; // Max boost for 10+ uses
  }
}
