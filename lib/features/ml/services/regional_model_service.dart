import 'package:flutter/foundation.dart';

/// Regional Model Service - Phase 3
/// Selects optimal ML model based on user's region  
class RegionalModelService {
  /// Detect user's region from currency or locale
  Future<String> detectRegion({String? currency, String? locale}) async {
    try {
      // Priority:
      // 1. Currency code
      // 2. Device locale
      // 3. Fallback to global

      if (currency != null) {
        return _getRegionFromCurrency(currency);
      }

      if (locale != null) {
        return _getRegionFromLocale(locale);
      }

      return 'global';
    } catch (e) {
      debugPrint('[Regional] Failed to detect region: $e');
      return 'global';
    }
  }

  /// Get region from currency code
  String _getRegionFromCurrency(String currency) {
    const currencyMap = {
      'USD': 'us',
      'CAD': 'us',
      'EUR': 'eu',
      'GBP': 'eu',
      'JPY': 'asia',
      'CNY': 'asia',
      'KRW': 'asia',
      'INR': 'asia',
      'AUD': 'global',
    };

    return currencyMap[currency.toUpperCase()] ?? 'global';
  }

  /// Get region from locale
  String _getRegionFromLocale(String locale) {
    final countryCode = locale.split('_').last.toUpperCase();

    const countryMap = {
      'US': 'us',
      'CA': 'us',
      'GB': 'eu',
      'DE': 'eu',
      'FR': 'eu',
      'IT': 'eu',
      'ES': 'eu',
      'JP': 'asia',
      'CN': 'asia',
      'KR': 'asia',
      'IN': 'asia',
    };

    return countryMap[countryCode] ?? 'global';
  }

  /// Get optimal model version for region
  String getModelForRegion({
    required String modelName,
    required String region,
  }) {
    // In Phase 3, we support regional models
    // Format: modelName_region_version
    // e.g., 'receipt_scanner_us_v1.0'

    debugPrint('[Regional] Selected model: ${modelName}_$region');
    return '${modelName}_$region';
  }
}
