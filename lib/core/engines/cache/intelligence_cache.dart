/// Unified Intelligence Cache
/// High-performance caching layer for Financial Intelligence Engine
library;

import 'dart:async';
import 'package:flutter/foundation.dart';

/// Cache entry with expiry
class _CacheEntry<T> {
  final T value;
  final DateTime expiry;
  final Type valueType;
  final int cost;

  /// Access metadata
  int hitCount = 0;
  DateTime lastAccess;

  _CacheEntry({
    required this.value,
    required this.expiry,
    this.cost = 1,
  })  : valueType = T,
        lastAccess = DateTime.now();

  bool get isExpired => DateTime.now().isAfter(expiry);

  void markHit() {
    hitCount = hitCount < 1 << 30 ? hitCount + 1 : hitCount;
    lastAccess = DateTime.now();
  }
}

/// Unified cache for all intelligence data
class IntelligenceCache {
  /// In-memory cache storage
  final _store = <String, _CacheEntry>{};

  /// Hot key tracking
  final Map<String, int> _keyHits = {};

  /// Cache statistics
  int _hits = 0;
  int _misses = 0;
  int _evictions = 0;

  /// Default TTL
  static const defaultTTL = Duration(minutes: 5);

  /// Maximum cache size (entries)
  static const maxSize = 1000;

  Timer? _cleanupTimer;

  DateTime _now() => DateTime.now();

  /// Check if cache has valid entry
  bool has(String key) {
    final entry = _store[key];
    if (entry == null) return false;

    if (entry.isExpired) {
      _store.remove(key);
      _evictions++;
      return false;
    }

    return true;
  }

  /// Get value from cache
  T? get<T>(String key) {
    final entry = _store[key];
    if (entry == null || entry.isExpired) {
      if (entry != null) {
        _store.remove(key);
        _evictions++;
      }
      _misses++;
      return null;
    }

    if (entry.valueType != T) {
      if (kDebugMode) {
        debugPrint(
          '[IntelligenceCache] Type mismatch for key "$key". '
          'Expected $T but found ${entry.valueType}',
        );
      }
      _misses++;
      return null;
    }

    entry.markHit();
    _keyHits[key] = (_keyHits[key] ?? 0) + 1;
    _hits++;
    return entry.value as T;
  }

  /// Set value in cache
  void set<T>(String key, T value, {Duration? ttl, int cost = 1}) {
    // Proactive small batch cleanup
    _cleanupExpiredBatch(limit: 5);

    if (_store.length >= maxSize) {
      _evictLRU();
    }

    _store[key] = _CacheEntry<T>(
      value: value,
      expiry: _now().add(ttl ?? defaultTTL),
      cost: cost,
    );
  }

  /// Invalidate specific key
  void invalidate(String key) {
    if (_store.remove(key) != null) {
      _evictions++;
    }
  }

  /// Invalidate keys matching pattern
  void invalidatePattern(String pattern) {
    final keysToRemove = _store.keys
        .where((key) => key.contains(pattern))
        .toList();

    for (final key in keysToRemove) {
      _store.remove(key);
      _evictions++;
    }
  }

  /// Clear all cache
  void clear() {
    _evictions += _store.length;
    _store.clear();
  }

  /// Evict least valuable entry (hybrid LRU + LFU)
  void _evictLRU() {
    if (_store.isEmpty) return;

    String? victimKey;
    double worstScore = double.infinity;

    for (final entry in _store.entries) {
      final ageSeconds = _now().difference(entry.value.lastAccess).inSeconds;
      // Cost-aware scoring: frequency / (age + 1) normalized by cost
      final score = (entry.value.hitCount / (ageSeconds + 1)) / entry.value.cost;

      if (score < worstScore) {
        worstScore = score;
        victimKey = entry.key;
      }

      // Early break for very cold entries that were just initialized
      if (score == 0) break;
    }

    if (victimKey != null) {
      _store.remove(victimKey);
      _keyHits.remove(victimKey);
      _evictions++;
    }
  }

  void _cleanupExpiredBatch({int limit = 10}) {
    int removed = 0;
    final now = _now();
    final keysToRemove = <String>[];

    for (final entry in _store.entries) {
      if (entry.value.expiry.isBefore(now)) {
        keysToRemove.add(entry.key);
        removed++;
        if (removed >= limit) break;
      }
    }

    for (final key in keysToRemove) {
      _store.remove(key);
      _keyHits.remove(key);
      _evictions++;
    }
  }

  /// Get cache statistics
  CacheStats getStats() {
    final total = _hits + _misses;
    final hitRate = total > 0 ? _hits / total : 0.0;

    return CacheStats(
      hits: _hits,
      misses: _misses,
      evictions: _evictions,
      hitRate: hitRate,
      size: _store.length,
      maxSize: maxSize,
    );
  }

  /// Cleanup expired entries
  Future<void> cleanup() async {
    final expiredKeys = <String>[];
    final now = _now();

    for (final entry in _store.entries) {
      if (entry.value.expiry.isBefore(now)) {
        expiredKeys.add(entry.key);
      }
    }

    for (final key in expiredKeys) {
      _store.remove(key);
      _keyHits.remove(key);
      _evictions++;
    }

    if (kDebugMode && expiredKeys.isNotEmpty) {
      debugPrint(
        '[IntelligenceCache] Cleaned ${expiredKeys.length} expired entries',
      );
    }
  }

  /// Get hottest keys currently in cache
  List<String> hottestKeys({int limit = 10}) {
    final entries = _keyHits.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.take(limit).map((e) => e.key).toList();
  }

  /// Start periodic cleanup timer
  void startPeriodicCleanup({
    Duration interval = const Duration(minutes: 1),
  }) {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(interval, (_) => cleanup());
  }

  /// Force stop cleanup and release resources
  void dispose() {
    _cleanupTimer?.cancel();
    _cleanupTimer = null;
    clear();
  }
}

/// Cache statistics
class CacheStats {
  final int hits;
  final int misses;
  final int evictions;
  final double hitRate;
  final int size;
  final int maxSize;

  CacheStats({
    required this.hits,
    required this.misses,
    required this.evictions,
    required this.hitRate,
    required this.size,
    required this.maxSize,
  });

  double get utilizationPercent => size / maxSize;

  @override
  String toString() {
    return 'CacheStats('
        'hits: $hits, '
        'misses: $misses, '
        'hit rate: ${(hitRate * 100).toStringAsFixed(1)}%, '
        'size: $size/$maxSize'
        ')';
  }
}
