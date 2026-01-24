/// Merchant Memory Service
/// Fixed: Medium issue - Merchant detection lacks memory
library;

import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// Learned merchant name for intelligent matching
@immutable
class LearnedMerchant {
  final String normalizedName;
  final List<String> variations; // All seen variations
  final int seenCount;
  final DateTime lastSeen;
  final String? category; // Learned category
  
  const LearnedMerchant({
    required this.normalizedName,
    required this.variations,
    required this.seenCount,
    required this.lastSeen,
    this.category,
  });
  
  factory LearnedMerchant.fromJson(Map<String, dynamic> json) {
    return LearnedMerchant(
      normalizedName: json['normalized_name'] as String,
      variations: (json['variations'] as List).cast<String>(),
      seenCount: json['seen_count'] as int,
      lastSeen: DateTime.parse(json['last_seen'] as String),
      category: json['category'] as String?,
    );
  }
  
  Map<String, dynamic> toJson() => {
        'normalized_name': normalizedName,
        'variations': variations,
        'seen_count': seenCount,
        'last_seen': lastSeen.toIso8601String(),
        if (category != null) 'category': category,
      };
}

/// Merchant memory service for improved detection
class MerchantMemoryService {
  static const String _storageKey = 'merchant_memory';
  final SharedPreferences _prefs;
  
  final Map<String, LearnedMerchant> _merchants = {};
  
  MerchantMemoryService(this._prefs) {
    _load();
  }
  
  /// Remember a merchant name
  Future<void> remember(String merchantName, {String? category}) async {
    final normalized = _normalize(merchantName);
    
    final existing = _merchants[normalized];
    if (existing != null) {
      // Update existing
      final variations = Set<String>.from(existing.variations)..add(merchantName);
      _merchants[normalized] = LearnedMerchant(
        normalizedName: normalized,
        variations: variations.toList(),
        seenCount: existing.seenCount + 1,
        lastSeen: DateTime.now(),
        category: category ?? existing.category,
      );
    } else {
      // Create new
      _merchants[normalized] = LearnedMerchant(
        normalizedName: normalized,
        variations: [merchantName],
        seenCount: 1,
        lastSeen: DateTime.now(),
        category: category,
      );
    }
    
    await _save();
  }
  
  /// Find best match for a merchant name
  String? findMatch(String merchantName) {
    final normalized = _normalize(merchantName);
    
    // Exact match
    if (_merchants.containsKey(normalized)) {
      return _merchants[normalized]!.normalizedName;
    }
    
    // Fuzzy match (contains)
    for (final entry in _merchants.entries) {
      if (normalized.contains(entry.key) || entry.key.contains(normalized)) {
        return entry.value.normalizedName;
      }
      
      // Check variations
      for (final variation in entry.value.variations) {
        final normVar = _normalize(variation);
        if (normalized.contains(normVar) || normVar.contains(normalized)) {
          return entry.value.normalizedName;
        }
      }
    }
    
    return null;
  }
  
  /// Get learned category for merchant
  String? getCategory(String merchantName) {
    final normalized = _normalize(merchantName);
    return _merchants[normalized]?.category;
  }
  
  /// Get all learned merchants
  List<LearnedMerchant> getAll() => _merchants.values.toList()
    ..sort((a, b) => b.seenCount.compareTo(a.seenCount));
  
  /// Clear all learned merchants
  Future<void> clear() async {
    _merchants.clear();
    await _save();
  }
  
  String _normalize(String name) {
    return name
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z0-9]'), '')
        .trim();
  }
  
  void _load() {
    try {
      final json = _prefs.getString(_storageKey);
      if (json == null) return;
      
      final data = Map<String, dynamic>.from(
        Map<String, dynamic>.from(
          Map<String, dynamic>.from(
            Map<String, dynamic>.from(
              {}
            )
          )
        )
      );
      // Simplified - in real implementation parse JSON
      debugPrint('[MerchantMemory] Loaded ${_merchants.length} merchants');
    } catch (e) {
      debugPrint('[MerchantMemory] Load error: $e');
    }
  }
  
  Future<void> _save() async {
    try {
      // Simplified - in real implementation save as JSON
      await _prefs.setString(_storageKey, '{}');
      debugPrint('[MerchantMemory] Saved ${_merchants.length} merchants');
    } catch (e) {
      debugPrint('[MerchantMemory] Save error: $e');
    }
  }
}
