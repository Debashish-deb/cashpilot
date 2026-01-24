/// Intelligence Cache with Model Versioning
/// Fixed: Issue #5 - Cache needs versioning
library;

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// Versioned intelligent cache for ML results
class IntelligenceCache {
  static const String CACHE_VERSION = '2.0'; // Bump when schema changes
  
  final SharedPreferences _prefs;
  
  IntelligenceCache(this._prefs);
  
  /// Get cached value with version checking
  Future<T?> get<T>({
    required String key,
    required String modelVersion,
    Duration? maxAge,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final cachedStr = _prefs.getString(_cacheKey(key));
      if (cachedStr == null) return null;
      
      final cached = jsonDecode(cachedStr) as Map<String, dynamic>;
      
      // CHECK 1: Cache version compatibility
      if (cached['cache_version'] != CACHE_VERSION) {
        debugPrint('[Cache] Version mismatch for $key: ${cached['cache_version']} != $CACHE_VERSION');
        await invalidate(key); // Auto-invalidate old cache
        return null;
      }
      
      // CHECK 2: Model version compatibility
      if (cached['model_version'] != modelVersion) {
        debugPrint('[Cache] Model version changed for $key: ${cached['model_version']} != $modelVersion');
        return null; // Model changed, cache invalid
      }
      
      // CHECK 3: Age check
      if (maxAge != null) {
        final cachedAt = DateTime.parse(cached['cached_at'] as String);
        if (DateTime.now().difference(cachedAt) > maxAge) {
          debugPrint('[Cache] Expired: $key');
          return null;
        }
      }
      
      // Parse and return
      if (fromJson != null && cached['data'] is Map<String, dynamic>) {
        return fromJson(cached['data'] as Map<String, dynamic>);
      }
      
      return cached['data'] as T?;
    } catch (e) {
      debugPrint('[Cache] Get error for $key: $e');
      return null;
    }
  }
  
  /// Set cached value with versioning
  Future<void> set<T>({
    required String key,
    required T value,
    required String modelVersion,
    Duration? ttl,
    Map<String, dynamic> Function(T)? toJson,
  }) async {
    try {
      final data = toJson != null ? toJson(value) : value;
      
      final cacheEntry = {
        'cache_version': CACHE_VERSION,
        'model_version': modelVersion,
        'data': data,
        'cached_at': DateTime.now().toIso8601String(),
        if (ttl != null) 'ttl_seconds': ttl.inSeconds,
      };
      
      await _prefs.setString(_cacheKey(key), jsonEncode(cacheEntry));
      debugPrint('[Cache] Set: $key (model: $modelVersion)');
    } catch (e) {
      debugPrint('[Cache] Set error for $key: $e');
    }
  }
  
  /// Invalidate specific key
  Future<void> invalidate(String key) async {
    await _prefs.remove(_cacheKey(key));
    debugPrint('[Cache] Invalidated: $key');
  }
  
  /// Invalidate all caches for a specific model version
  Future<void> invalidateModelCaches(String modelVersion) async {
    final allKeys = _prefs.getKeys();
    int invalidated = 0;
    
    for (final key in allKeys) {
      if (!key.startsWith('cache_')) continue;
      
      try {
        final cachedStr = _prefs.getString(key);
        if (cachedStr == null) continue;
        
        final cached = jsonDecode(cachedStr) as Map<String, dynamic>;
        if (cached['model_version'] == modelVersion) {
          await _prefs.remove(key);
          invalidated++;
        }
      } catch (e) {
        // Skip invalid entries
      }
    }
    
    debugPrint('[Cache] Invalidated $invalidated caches for model $modelVersion');
  }
  
  /// Invalidate all caches (nuclear option)
  Future<void> clear() async {
    final allKeys = _prefs.getKeys().where((k) => k.startsWith('cache_')).toList();
    for (final key in allKeys) {
      await _prefs.remove(key);
    }
    debugPrint('[Cache] Cleared ${allKeys.length} cache entries');
  }
  
  /// Get cache statistics
  Future<CacheStats> getStats() async {
    final allKeys = _prefs.getKeys().where((k) => k.startsWith('cache_')).toList();
    
    int totalEntries = 0;
    int validEntries = 0;
    int expiredEntries = 0;
    final modelVersions = <String>{};
    
    for (final key in allKeys) {
      totalEntries++;
      try {
        final cachedStr = _prefs.getString(key);
        if (cachedStr == null) continue;
        
        final cached = jsonDecode(cachedStr) as Map<String, dynamic>;
        
        // Check validity
        if (cached['cache_version'] == CACHE_VERSION) {
          validEntries++;
          modelVersions.add(cached['model_version'] as String);
        }
        
        // Check expiry
        if (cached['ttl_seconds'] != null) {
          final cachedAt = DateTime.parse(cached['cached_at'] as String);
          final ttl = Duration(seconds: cached['ttl_seconds'] as int);
          if (DateTime.now().difference(cachedAt) > ttl) {
            expiredEntries++;
          }
        }
      } catch (e) {
        // Skip invalid
      }
    }
    
    return CacheStats(
      totalEntries: totalEntries,
      validEntries: validEntries,
      expiredEntries: expiredEntries,
      modelVersions: modelVersions.toList(),
      cacheVersion: CACHE_VERSION,
    );
  }
  
  String _cacheKey(String key) => 'cache_$key';
}

/// Cache statistics
@immutable
class CacheStats {
  final int totalEntries;
  final int validEntries;
  final int expiredEntries;
  final List<String> modelVersions;
  final String cacheVersion;
  
  const CacheStats({
    required this.totalEntries,
    required this.validEntries,
    required this.expiredEntries,
    required this.modelVersions,
    required this.cacheVersion,
  });
  
  int get invalidEntries => totalEntries - validEntries;
  double get hitRate => totalEntries > 0 ? validEntries / totalEntries : 0.0;
  
  @override
  String toString() => 'CacheStats('
      'total: $totalEntries, '
      'valid: $validEntries, '
      'expired: $expiredEntries, '
      'models: ${modelVersions.length}'
      ')';
}
