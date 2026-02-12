import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../observability/log_service.dart';

/// Service to handle remote configuration, feature flags, and Kill Switches.
/// fetching from Supabase 'app_config' table or Edge Functions.
class ConfigService {
  static final ConfigService _instance = ConfigService._internal();
  factory ConfigService() => _instance;
  ConfigService._internal();

  final _supabase = Supabase.instance.client;
  final _logger = LogService();

  bool _syncEnabled = true;
  String? _minSupportedVersion;
  
  bool get isSyncEnabled => _syncEnabled;

  /// Fetch latest config from server.
  /// Result is cached in-memory.
  Future<void> fetchConfig() async {
    try {
      // In a real app, this might come from a dedicated 'app_config' table
      // or a remote config service (Firebase Remote Config / Flagsmith).
      // For this implementation, we simulate fetching from a 'global_config' table
      // or assume defaults if table doesn't exist yet.
      
      // Attempt to fetch from 'global_config' table single row
      // We wrap in try/catch in case the table is not deployed yet.
      try {
        final response = await _supabase
            .from('global_config')
            .select()
            .single()
            .timeout(const Duration(seconds: 5));
        
        _syncEnabled = response['sync_enabled'] ?? true;
        _minSupportedVersion = response['min_supported_version'];
        
        _logger.info('Config fetched', context: {
          'sync_enabled': _syncEnabled, 
          'min_version': _minSupportedVersion
        });
        
      } catch (tableError) {
        // Fallback or assume table missing
        _logger.warn('Could not fetch global_config (using defaults)', error: tableError);
        _syncEnabled = true; // Default to ON
      }
      
      await _checkVersion();

    } catch (e) {
      _logger.error('Failed to fetch config', error: e);
    }
  }

  /// Check if current app version is supported.
  Future<bool> _checkVersion() async {
    if (_minSupportedVersion == null) return true;

    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version;

    // Simple string comparison for now (Production should use semver parsing)
    // If current < min, return false
    // Implementation omitted for brevity, logic depends on version format.
    return true; 
  }

  /// Manually force a value (for testing/debug console)
  void setSyncEnabled(bool enabled) {
    _syncEnabled = enabled;
    _logger.info('Sync enabled forced to: $enabled');
  }
}
