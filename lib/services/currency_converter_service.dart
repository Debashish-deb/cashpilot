library;

import 'dart:convert';
import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// ============================================================
// CONFIGURATION
// ============================================================

const _cacheKey = 'currency_rates_snapshot_v5';
const _cacheTTL = Duration(hours: 12);
const _timeout = Duration(seconds: 10);

const _supportedCurrencies = {
  'USD', 'EUR', 'GBP', 'BDT', 'JPY', 'SEK', 'NOK', 'DKK'
};

const _offlineFallbackRates = {
  'USD': {'EUR': 0.92, 'GBP': 0.79, 'BDT': 109.5},
  'EUR': {'USD': 1.09, 'GBP': 0.86, 'BDT': 118.0},
};

Map<String, double> _sanitizeRates(Map<dynamic, dynamic> rawRates) {
  final sanitized = <String, double>{};
  
  rawRates.forEach((key, value) {
    try {
      final currency = key.toString();
      
      // Skip if not in supported currencies
      if (!_supportedCurrencies.contains(currency)) {
        return;
      }
      
      // Convert value to double safely
      double? rate;
      if (value is num) {
        rate = value.toDouble();
      } else if (value is String) {
        rate = double.tryParse(value);
      }
      
      // Only add valid positive rates
      if (rate != null && rate > 0 && rate.isFinite) {
        sanitized[currency] = rate;
      }
    } catch (e) {
      debugPrint('[CurrencyConverter] Failed to parse rate for $key: $e');
      // Continue processing other rates
    }
  });
  
  return sanitized;
}

// ============================================================
// DOMAIN MODEL
// ============================================================

class ExchangeRatesSnapshot {
  final String baseCurrency;
  final Map<String, double> rates;
  final DateTime timestamp;
  final String source;

  const ExchangeRatesSnapshot({
    required this.baseCurrency,
    required this.rates,
    required this.timestamp,
    required this.source,
  });

  bool get isExpired => DateTime.now().difference(timestamp) > _cacheTTL;
  
  bool get isValid => rates.isNotEmpty && _supportedCurrencies.contains(baseCurrency);

  double? getRate(String targetCurrency) {
    if (baseCurrency == targetCurrency) return 1.0;
    return rates[targetCurrency];
  }

  Map<String, dynamic> toJson() => {
    'base': baseCurrency,
    'rates': rates,
    'timestamp': timestamp.toIso8601String(),
    'source': source,
  };

  factory ExchangeRatesSnapshot.fromJson(Map<String, dynamic> json) {
    return ExchangeRatesSnapshot(
      baseCurrency: json['base'] as String,
      rates: Map<String, double>.from(
        (json['rates'] as Map).map(
          (k, v) => MapEntry(k as String, (v as num).toDouble()),
        ),
      ),
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
      source: json['source'] as String,
    );
  }
}

// ============================================================
// DATA SOURCES ABSTRACTIONS
// ============================================================

abstract class ExchangeRateDataSource {
  Future<ExchangeRatesSnapshot> fetchRates(String baseCurrency);
}

class ExchangerateApiSource implements ExchangeRateDataSource {
  @override
  Future<ExchangeRatesSnapshot> fetchRates(String baseCurrency) async {
    try {
      final response = await http.get(
        Uri.parse('https://api.exchangerate-api.com/v4/latest/$baseCurrency'),
      ).timeout(_timeout);

      if (response.statusCode != 200) {
        throw Exception('Exchangerate-API failed with status ${response.statusCode}');
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      
      // Validate response structure
      if (!data.containsKey('rates') || data['rates'] is! Map) {
        debugPrint('[ExchangerateApiSource] Invalid response structure: ${response.body}');
        throw Exception('Invalid API response structure');
      }
      
      final rates = _sanitizeRates(data['rates'] as Map);
      
      if (rates.isEmpty) {
        throw Exception('No valid exchange rates found in response');
      }
      
      return ExchangeRatesSnapshot(
        baseCurrency: data['base'] as String,
        rates: rates,
        timestamp: DateTime.now(),
        source: 'exchangerate-api',
      );
    } catch (e) {
      debugPrint('[ExchangerateApiSource] Error fetching rates: $e');
      rethrow;
    }
  }
}

class FrankfurterApiSource implements ExchangeRateDataSource {
  @override
  Future<ExchangeRatesSnapshot> fetchRates(String baseCurrency) async {
    try {
      final response = await http.get(
        Uri.parse('https://api.frankfurter.app/latest?from=$baseCurrency'),
      ).timeout(_timeout);

      if (response.statusCode != 200) {
        throw Exception('Frankfurter API failed with status ${response.statusCode}');
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      
      // Validate response structure
      if (!data.containsKey('rates') || data['rates'] is! Map) {
        debugPrint('[FrankfurterApiSource] Invalid response structure: ${response.body}');
        throw Exception('Invalid API response structure');
      }
      
      final rates = _sanitizeRates(data['rates'] as Map);
      
      if (rates.isEmpty) {
        throw Exception('No valid exchange rates found in response');
      }
      
      return ExchangeRatesSnapshot(
        baseCurrency: baseCurrency,
        rates: rates,
        timestamp: DateTime.now(),
        source: 'frankfurter',
      );
    } catch (e) {
      debugPrint('[FrankfurterApiSource] Error fetching rates: $e');
      rethrow;
    }
  }
}

class OfflineFallbackSource implements ExchangeRateDataSource {
  @override
  Future<ExchangeRatesSnapshot> fetchRates(String baseCurrency) async {
    return ExchangeRatesSnapshot(
      baseCurrency: baseCurrency,
      rates: _sanitizeRates(_offlineFallbackRates[baseCurrency] ?? {}),
      timestamp: DateTime.now(),
      source: 'offline',
    );
  }
}

// ============================================================
// CACHE MANAGER
// ============================================================

class ExchangeRateCache {
  final String cacheKey;

  ExchangeRateCache({String? customKey}) : cacheKey = customKey ?? _cacheKey;

  Future<void> saveSnapshot(ExchangeRatesSnapshot snapshot) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(cacheKey, json.encode(snapshot.toJson()));
      debugPrint('[ExchangeRateCache] Snapshot saved successfully');
    } catch (e) {
      debugPrint('[ExchangeRateCache] Failed to save snapshot: $e');
    }
  }

  Future<ExchangeRatesSnapshot?> loadSnapshot() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(cacheKey);
      
      if (raw == null) return null;
      
      final jsonData = json.decode(raw) as Map<String, dynamic>;
      final snapshot = ExchangeRatesSnapshot.fromJson(jsonData);
      
      // Validate the loaded snapshot
      if (!snapshot.isValid || snapshot.rates.isEmpty) {
        debugPrint('[ExchangeRateCache] Loaded snapshot is invalid, clearing cache');
        await clearCache();
        return null;
      }
      
      return snapshot;
    } catch (e) {
      debugPrint('[ExchangeRateCache] Failed to decode cache: $e');
      // Clear corrupted cache
      await clearCache();
      return null;
    }
  }
  
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(cacheKey);
      debugPrint('[ExchangeRateCache] Cache cleared');
    } catch (e) {
      debugPrint('[ExchangeRateCache] Failed to clear cache: $e');
    }
  }
}

// ============================================================
// MAIN SERVICE
// ============================================================

class CurrencyConverterService {
  ExchangeRatesSnapshot? _snapshot;
  Future<void>? _refreshLock;
  
  final ExchangeRateCache _cache;
  final List<ExchangeRateDataSource> _dataSources;

  CurrencyConverterService({
    ExchangeRateCache? cache,
    List<ExchangeRateDataSource>? dataSources,
  }) : _cache = cache ?? ExchangeRateCache(),
       _dataSources = dataSources ?? [
         ExchangerateApiSource(),
         FrankfurterApiSource(),
         OfflineFallbackSource(),
       ];

  ExchangeRatesSnapshot? get currentSnapshot => _snapshot;

  // ============================================================
  // INITIALIZATION
  // ============================================================

  Future<void> initialize() async {
    await loadCachedSnapshot();
    
    // If cache is expired or invalid, try to refresh silently
    if (_snapshot == null || _snapshot!.isExpired || !_snapshot!.isValid) {
      await _refreshSilently();
    }
  }

  Future<void> loadCachedSnapshot() async {
    try {
      final cached = await _cache.loadSnapshot();
      if (cached == null) {
        debugPrint('[CurrencyConverter] No cached rates found');
        return; // Changed from return null to return for Future<void>
      }

      // Check if rates are stale (older than 48 hours)
      final now = DateTime.now();
      final age = now.difference(cached.timestamp);
      
      if (age > const Duration(hours: 48)) {
        debugPrint('[CurrencyConverter] ⚠️  Cached rates are ${age.inHours}h old (stale)');
        // Still use them but trigger background refresh
        _refreshSilently();
      } else {
        debugPrint('[CurrencyConverter] Using cached rates (${age.inHours}h old)');
      }

      // Validate the loaded snapshot before assigning
      if (cached.isValid && _supportedCurrencies.contains(cached.baseCurrency)) {
        _snapshot = cached;
      } else {
        debugPrint('[CurrencyConverter] Cached snapshot is invalid or for unsupported currency, clearing cache');
        await _cache.clearCache();
        _snapshot = null; // Ensure _snapshot is null if cached is invalid
      }
    } catch (e) {
      debugPrint('[CurrencyConverter] Error loading cache: $e');
      await _cache.clearCache(); // Clear cache on error
      _snapshot = null; // Ensure _snapshot is null on error
    }
  }

  // ============================================================
  // RATE MANAGEMENT
  // ============================================================

  Future<ExchangeRatesSnapshot> refreshRates(String baseCurrency) async {
    if (!_supportedCurrencies.contains(baseCurrency)) {
      throw ArgumentError('Unsupported currency: $baseCurrency');
    }

    // Check if we already have fresh rates for this base
    if (_snapshot != null &&
        !_snapshot!.isExpired &&
        _snapshot!.baseCurrency == baseCurrency) {
      return _snapshot!;
    }

    // Use lock to prevent concurrent refreshes
    if (_refreshLock != null) {
      return _refreshLock!.then((_) => _snapshot!);
    }

    final completer = Completer<void>();
    _refreshLock = completer.future;

    try {
      _snapshot = await _fetchWithFallback(baseCurrency);
      await _cache.saveSnapshot(_snapshot!);
      
      debugPrint('[CurrencyConverter] Rates refreshed from ${_snapshot!.source}');
      return _snapshot!;
    } catch (e) {
      debugPrint('[CurrencyConverter] All data sources failed: $e');
      rethrow;
    } finally {
      completer.complete();
      _refreshLock = null;
    }
  }

  Future<ExchangeRatesSnapshot> _fetchWithFallback(String baseCurrency) async {
    for (final source in _dataSources) {
      try {
        final snapshot = await source.fetchRates(baseCurrency).timeout(_timeout);
        
        if (snapshot.rates.isNotEmpty) {
          return snapshot;
        }
      } catch (e) {
        debugPrint('[CurrencyConverter] Source ${source.runtimeType} failed: $e');
        // Continue to next source
      }
    }
    
    throw Exception('All exchange rate sources failed');
  }

  Future<void> _refreshSilently() async {
    try {
      if (_snapshot != null) {
        await refreshRates(_snapshot!.baseCurrency);
      }
    } catch (e) {
      // Silent failure - we'll just use cached/stale data
      debugPrint('[CurrencyConverter] Silent refresh failed: $e');
    }
  }

  // ============================================================
  // CONVERSION OPERATIONS
  // ============================================================

  double? convert({
    required double amount,
    required String fromCurrency,
    required String toCurrency,
    int precision = 4,
  }) {
    if (amount == 0) return 0;
    if (fromCurrency == toCurrency) return amount;
    if (_snapshot == null) return null;

    return _convertWithSnapshot(
      amount: amount,
      fromCurrency: fromCurrency,
      toCurrency: toCurrency,
      snapshot: _snapshot!,
      precision: precision,
    );
  }

  double? _convertWithSnapshot({
    required double amount,
    required String fromCurrency,
    required String toCurrency,
    required ExchangeRatesSnapshot snapshot,
    int precision = 4,
  }) {
    final rates = snapshot.rates;
    
    // Direct conversion from base currency
    if (snapshot.baseCurrency == fromCurrency) {
      final rate = rates[toCurrency];
      return rate != null ? _round(amount * rate, precision) : null;
    }
    
    // Cross-currency conversion
    final fromRate = rates[fromCurrency];
    final toRate = rates[toCurrency];
    
    if (fromRate == null || toRate == null) return null;
    
    return _round((amount / fromRate) * toRate, precision);
  }

  Future<double?> getConversionRate(String fromCurrency, String toCurrency) async {
    if (fromCurrency == toCurrency) return 1.0;
    
    try {
      final snapshot = await refreshRates(fromCurrency);
      return _convertWithSnapshot(
        amount: 1.0,
        fromCurrency: fromCurrency,
        toCurrency: toCurrency,
        snapshot: snapshot,
      );
    } catch (e) {
      debugPrint('[CurrencyConverter] Failed to get conversion rate: $e');
      return null;
    }
  }

  /// Aggregates multiple amounts in different currencies into a single target currency
  /// Example: [{amount: 100, currency: 'USD'}, {amount: 50, currency: 'EUR'}] -> Total in GBP
  Future<double> aggregateMultiCurrency({
    required List<({double amount, String currency})> items,
    required String targetCurrency,
  }) async {
    if (items.isEmpty) return 0.0;
    
    // Ensure we have some rates
    if (_snapshot == null || _snapshot!.isExpired) {
      await refreshRates(targetCurrency);
    }

    double total = 0.0;
    for (final item in items) {
      final converted = convert(
        amount: item.amount,
        fromCurrency: item.currency,
        toCurrency: targetCurrency,
      );
      total += converted ?? 0.0; // Fallback to 0 if rate not available
    }
    
    return _round(total, 2);
  }

  // ============================================================
  // UTILITIES
  // ============================================================



  double _round(double value, int precision) {
    final multiplier = pow(10, precision);
    return (value * multiplier).roundToDouble() / multiplier;
  }
}