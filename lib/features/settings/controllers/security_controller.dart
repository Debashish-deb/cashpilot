/// Security Controller
/// Owns: biometric, app lock, auto-lock timeout
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/auth_service.dart';
import '../../../services/biometric_service.dart';
import '../models/operation_result.dart';

class SecurityController {
  final Ref ref;
  
  SecurityController(this.ref);

  // Keys
  static const _keyBiometric = 'biometric_enabled';
  static const _keyAppLock = 'app_lock_enabled';
  static const _keyAutoLock = 'auto_lock_timeout_seconds';

  /// Enable/disable biometric authentication
  Future<OperationResult<void>> setBiometricEnabled(bool enabled) async {
    try {
      if (enabled) {
        // Verify with biometric before enabling
        final result = await biometricService.authenticate(
          reason: 'Authenticate to enable biometric login',
          biometricOnly: true, // Force biometric for the setup step
        );
        
        if (result != BiometricResult.success) {
          return OperationResult.failure(
            message: biometricService.getErrorMessage(result),
          );
        }
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyBiometric, enabled);
      
      // Sync to cloud (best-effort)
      await _syncSecurityPrefsToCloud();
      
      debugPrint('[Security] Biometric ${enabled ? 'enabled' : 'disabled'}');
      return OperationResult.success(message: 'Biometric ${enabled ? 'enabled' : 'disabled'}');
    } catch (e) {
      debugPrint('[Security] Error: $e');
      return OperationResult.failure(message: 'Failed to update biometric setting', error: e);
    }
  }

  /// Enable/disable app lock
  Future<OperationResult<void>> setAppLockEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyAppLock, enabled);
      
      await _syncSecurityPrefsToCloud();
      
      debugPrint('[Security] App lock ${enabled ? 'enabled' : 'disabled'}');
      return OperationResult.success(message: 'App lock ${enabled ? 'enabled' : 'disabled'}');
    } catch (e) {
      return OperationResult.failure(message: 'Failed to update app lock', error: e);
    }
  }

  /// Set auto-lock timeout in seconds
  Future<OperationResult<void>> setAutoLockTimeout(int seconds) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyAutoLock, seconds);
      
      await _syncSecurityPrefsToCloud();
      
      debugPrint('[Security] Auto-lock timeout set to ${seconds}s');
      return OperationResult.success(message: 'Timeout updated');
    } catch (e) {
      return OperationResult.failure(message: 'Failed to update timeout', error: e);
    }
  }

  /// Get current settings
  Future<SecuritySettings> getSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return SecuritySettings(
      biometricEnabled: prefs.getBool(_keyBiometric) ?? false,
      appLockEnabled: prefs.getBool(_keyAppLock) ?? false,
      autoLockTimeoutSeconds: prefs.getInt(_keyAutoLock) ?? 60,
    );
  }

  /// Check if biometric is available
  Future<bool> isBiometricAvailable() async {
    return biometricService.isAvailable();
  }

  /// Sync security preferences to cloud (non-fatal on failure)
  Future<void> _syncSecurityPrefsToCloud() async {
    try {
      final settings = await getSettings();
      await authService.client.from('user_settings').upsert({
        'user_id': authService.currentUser?.id,
        'biometric_enabled': settings.biometricEnabled,
        'app_lock_enabled': settings.appLockEnabled,
        'auto_lock_seconds': settings.autoLockTimeoutSeconds,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('[Security] Cloud sync failed (non-fatal): $e');
    }
  }
}

class SecuritySettings {
  final bool biometricEnabled;
  final bool appLockEnabled;
  final int autoLockTimeoutSeconds;

  SecuritySettings({
    this.biometricEnabled = false,
    this.appLockEnabled = false,
    this.autoLockTimeoutSeconds = 60,
  });
}

/// Provider
final securityControllerProvider = Provider<SecurityController>((ref) {
  return SecurityController(ref);
});

/// Settings state provider
final securitySettingsProvider = FutureProvider<SecuritySettings>((ref) async {
  return ref.read(securityControllerProvider).getSettings();
});
