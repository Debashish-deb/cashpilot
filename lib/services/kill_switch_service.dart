import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/utils/logger.dart';

/// Kill Switch Service
/// 
/// Allows remote disabling of high-risk features during emergencies.
/// Aligned with Phase 4: Operational Readiness.
class KillSwitchService {
  static final KillSwitchService _instance = KillSwitchService._internal();
  factory KillSwitchService() => _instance;
  KillSwitchService._internal();

  final _client = Supabase.instance.client;
  
  // Local cache of kill switch states
  final Map<String, bool> _killSwitches = {
    'sync_enabled': true,
    'ocr_enabled': true,
    'ai_insights_enabled': true,
    'bank_connectivity_enabled': true,
  };

  bool _initialized = false;

  /// Initialize and fetch remote configuration
  Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      await refresh();
      _initialized = true;
      logger.info('KillSwitchService initialized', category: LogCategory.security);
    } catch (e) {
      logger.error('Failed to initialize KillSwitchService', category: LogCategory.security, error: e);
      // Fail-safe: Stay with default "Enabled" unless explicitly killed
    }
  }

  /// Refresh kill switch states from Supabase
  Future<void> refresh() async {
    try {
      // In a production app, this would fetch from a 'remote_config' or 'kill_switches' table
      // that requires a specific 'admin' role to write to.
      final response = await _client
          .from('system_config')
          .select('key, value, signature')
          .eq('group', 'kill_switches');

      for (var row in response) {
        final String key = row['key'];
        final bool value = row['value'] == 'true';
        _killSwitches[key] = value;
      }
    } catch (e) {
      if (e.toString().contains('PGRST205')) {
        // Table not found - expected in some environments where system_config is not yet deployed
        logger.info('[KillSwitch] Remote config table not found. Using local defaults.');
      } else {
        logger.warning('[KillSwitch] Refresh failed: $e');
      }
    }
  }

  /// Check if a specific feature is enabled (not killed)
  bool isFeatureEnabled(String featureKey) {
    return _killSwitches[featureKey] ?? true;
  }

  /// Explicit checks for high-risk features
  bool get isSyncAllowed => isFeatureEnabled('sync_enabled');
  bool get isOCRAllowed => isFeatureEnabled('ocr_enabled');
  bool get isAIAllowed => isFeatureEnabled('ai_insights_enabled');

  /// Force a kill switch locally (for testing or immediate local gating)
  void setLocalOverride(String featureKey, bool enabled) {
    _killSwitches[featureKey] = enabled;
  }
}

final killSwitchService = KillSwitchService();
