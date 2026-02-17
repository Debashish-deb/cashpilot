import 'dart:async';

class CacheManager {
  static final CacheManager _instance = CacheManager._internal();
  factory CacheManager() => _instance;
  CacheManager._internal();

  final Map<String, CacheEntry> _memoryCache = {};

  /// Get value from cache
  T? get<T>(String key) {
    final entry = _memoryCache[key];
    if (entry == null) return null;

    if (entry.isExpired) {
      _memoryCache.remove(key);
      return null;
    }

    return entry.value as T;
  }

  /// Set value in cache with TTL
  void set(String key, dynamic value, {Duration ttl = const Duration(minutes: 5)}) {
    _memoryCache[key] = CacheEntry(
      value: value,
      expiry: DateTime.now().add(ttl),
    );
  }

  /// Invalidate a specific key
  void invalidate(String key) {
    _memoryCache.remove(key);
  }

  /// Invalidate all keys matching a pattern
  void invalidatePattern(String pattern) {
    _memoryCache.removeWhere((key, _) => key.contains(pattern));
  }

  /// Clear all cache
  void clear() {
    _memoryCache.clear();
  }
}

class CacheEntry {
  final dynamic value;
  final DateTime expiry;

  CacheEntry({required this.value, required this.expiry});

  bool get isExpired => DateTime.now().isAfter(expiry);
}
