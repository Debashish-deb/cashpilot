/// Unified Intelligence Cache
/// High-performance caching layer for Financial Intelligence Engine
library;

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef Serializer<T> = Map<String, dynamic> Function(T value);
typedef Deserializer<T> = T Function(Map<String, dynamic> json);

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
  
  SharedPreferences? _prefs;

  /// Default TTL
  static const defaultTTL = Duration(minutes: 5);

  /// Maximum cache size (entries)
  static const maxSize = 1000;

  Timer? _cleanupTimer;

  DateTime _now() => DateTime.now();

  /// Check if cache has valid entry


  Future<void> initialize({SharedPreferences? prefs}) async {
    _prefs = prefs ?? await SharedPreferences.getInstance();
  }

  /// Check if cache has valid entry (memory only)
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
  /// Get value from cache (memory first, then disk)
  Future<T?> get<T>(String key, {
    Deserializer<T>? deserializer,
    String? modelVersion,
  }) async {
    // 1. Check Memory (ignore modelVersion for memory? Or store it in entry?)
    // For simplicity, memory cache is assumed valid for current session.
    // Ideally _CacheEntry should store modelVersion too.
    final entry = _store[key];
    if (entry != null && !entry.isExpired) {
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
    
    // 2. Check Disk (if Deserializer provided)
    if (_prefs != null && deserializer != null) {
      try {
        final cachedStr = _prefs!.getString('cache_$key');
        if (cachedStr != null) {
          final cached = jsonDecode(cachedStr) as Map<String, dynamic>;
          
          // Check expiry
          final expiry = DateTime.parse(cached['expiry'] as String);
          if (DateTime.now().isAfter(expiry)) {
            await _prefs!.remove('cache_$key');
            _misses++;
            return null;
          }

          // Check model version
          if (modelVersion != null && cached['model_version'] != modelVersion) {
            await _prefs!.remove('cache_$key');
             _misses++;
            return null;
          }
          
          final value = deserializer(cached['data'] as Map<String, dynamic>);
          
          // Hydrate memory cache
          _store[key] = _CacheEntry<T>(
            value: value,
            expiry: expiry,
            cost: cached['cost'] as int? ?? 1,
          );
          
          _hits++; // Count disk hit as hit?
          return value;
        }
      } catch (e) {
        debugPrint('[IntelligenceCache] Disk read error: $e');
      }
    }

    if (entry != null) {
         _store.remove(key);
         _evictions++;
    }
    _misses++;
    return null;
  }

  /// Set value in cache
  /// Set value in cache
  Future<void> set<T>(String key, T value, {
    Duration? ttl, 
    int cost = 1,
    Serializer<T>? serializer,
    String? modelVersion,
  }) async {
    // Proactive small batch cleanup
    _cleanupExpiredBatch(limit: 5);

    if (_store.length >= maxSize) {
      _evictLRU();
    }

    final expiry = _now().add(ttl ?? defaultTTL);

    _store[key] = _CacheEntry<T>(
      value: value,
      expiry: expiry,
      cost: cost,
    );
    
    // Persist if serializer provided
    if (_prefs != null && serializer != null) {
      try {
        final data = serializer(value);
        final entry = {
          'data': data,
          'expiry': expiry.toIso8601String(),
          'cost': cost,
          'model_version': modelVersion,
          // 'type': T.toString(), // Optional type check support
        };
        await _prefs!.setString('cache_$key', jsonEncode(entry));
      } catch (e) {
        debugPrint('[IntelligenceCache] Disk write error: $e');
      }
    }
  }

  /// Invalidate specific key (memory and disk)
  Future<void> invalidate(String key) async {
    if (_store.remove(key) != null) {
      _evictions++;
    }
    
    if (_prefs != null) {
      await _prefs!.remove('cache_$key');
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
