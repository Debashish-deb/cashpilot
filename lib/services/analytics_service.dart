/// Analytics Service
/// Production analytics using Supabase for event tracking
library;

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  bool _initialized = false;
  SupabaseClient? _client;

  /// Initialize analytics with Supabase client
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      _client = Supabase.instance.client;
      _initialized = true;
      
      if (kDebugMode) {
        debugPrint('[Analytics] Service initialized with Supabase');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Analytics] Failed to initialize: $e');
      }
    }
  }

  /// Log an event to Supabase analytics table
  void logEvent(String name, {Map<String, dynamic>? parameters}) {
    if (!_initialized || _client == null) return;

    try {
      _client!.from('analytics_events').insert({
        'user_id': _client!.auth.currentUser?.id,
        'event_name': name,
        'parameters': parameters ?? {},
        'timestamp': DateTime.now().toIso8601String(),
        'platform': defaultTargetPlatform.name,
      }).then((_) {
        if (kDebugMode) {
          debugPrint('[Analytics] Logged event: $name');
        }
      }).catchError((e) {
        if (kDebugMode) {
          debugPrint('[Analytics] Event log failed: $e');
        }
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Analytics] Error logging event: $e');
      }
    }
  }

  /// Log a screen view to analytics
  void logScreenView(String screenName, {String? screenClass}) {
    logEvent('screen_view', parameters: {
      'screen_name': screenName,
      if (screenClass != null) 'screen_class': screenClass,
    });
  }

  /// Set user properties in analytics
  void setUserProperty(String name, String value) {
    if (!_initialized || _client == null) return;

    try {
      _client!.from('user_properties').upsert({
        'user_id': _client!.auth.currentUser?.id,
        'property_name': name,
        'property_value': value,
        'updated_at': DateTime.now().toIso8601String(),
      }).then((_) {
        if (kDebugMode) {
          debugPrint('[Analytics] Set property: $name = $value');
        }
      }).catchError((e) {
        if (kDebugMode) {
          debugPrint('[Analytics] Property update failed: $e');
        }
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Analytics] Error setting property: $e');
      }
    }
  }

  /// Set user ID for analytics tracking
  void setUserId(String userId) {
    setUserProperty('user_id', userId);
  }

  /// Log a purchase/subscription event
  void logPurchase({
    required String transactionId,
    required double value,
    required String currency,
    String? productId,
    Map<String, dynamic>? parameters,
  }) {
    logEvent('purchase', parameters: {
      'transaction_id': transactionId,
      'value': value,
      'currency': currency,
      if (productId != null) 'product_id': productId,
      if (parameters != null) ...parameters,
    });
  }

  /// Check if analytics is enabled
  bool get isEnabled => _initialized && _client != null;
}

/// Global instance
final analyticsService = AnalyticsService();
