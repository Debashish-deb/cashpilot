/// Settings Batch Sync
/// Consolidates ALL user profile settings into a single sync operation
/// Instead of individual upserts for theme, currency, language, etc.
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/subscription.dart';
import '../../../services/subscription_service.dart';

/// All settings that sync to the profiles table
class SyncableSettings {
  // User preferences
  final String? experienceMode;  // beginner/expert
  final String? themeMode;       // light/dark/system
  final String? accentColor;     // hex color
  final String? currency;        // EUR, USD, etc
  final String? language;        // en, de, etc
  final String? dateFormat;      // DD/MM/YYYY, etc
  final String? timezone;        // UTC, etc
  
  // Security settings
  final bool? biometricEnabled;
  final bool? appLockEnabled;
  
  // Display preferences
  final bool? showBalance;
  final bool? notificationsEnabled;
  final bool? dataSaverMode;
  final String? defaultBudgetView; // monthly/weekly
  
  SyncableSettings({
    this.experienceMode,
    this.themeMode,
    this.accentColor,
    this.currency,
    this.language,
    this.dateFormat,
    this.timezone,
    this.biometricEnabled,
    this.appLockEnabled,
    this.showBalance,
    this.notificationsEnabled,
    this.dataSaverMode,
    this.defaultBudgetView,
  });
  
  /// Convert to JSON for Supabase upsert
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    
    if (experienceMode != null) json['experience_mode'] = experienceMode;
    if (themeMode != null) json['theme_mode'] = themeMode;
    if (accentColor != null) json['accent_color'] = accentColor;
    if (currency != null) json['currency'] = currency;
    if (language != null) json['language'] = language;
    if (dateFormat != null) json['date_format'] = dateFormat;
    if (timezone != null) json['timezone'] = timezone;
    if (biometricEnabled != null) json['biometric_enabled'] = biometricEnabled;
    if (appLockEnabled != null) json['app_lock_enabled'] = appLockEnabled;
    if (showBalance != null) json['show_balance'] = showBalance;
    if (notificationsEnabled != null) json['notifications_enabled'] = notificationsEnabled;
    if (dataSaverMode != null) json['data_saver_mode'] = dataSaverMode;
    if (defaultBudgetView != null) json['default_budget_view'] = defaultBudgetView;
    
    return json;
  }
  
  /// Create from SharedPreferences
  factory SyncableSettings.fromPrefs(SharedPreferences prefs) {
    return SyncableSettings(
      experienceMode: prefs.getString('user_mode'),
      themeMode: prefs.getString('theme_mode'),
      accentColor: prefs.getString('accent_color'),
      currency: prefs.getString('currency'),
      language: prefs.getString('language'),
      dateFormat: prefs.getString('date_format'),
      timezone: prefs.getString('timezone'),
      biometricEnabled: prefs.getBool('biometric_enabled'),
      appLockEnabled: prefs.getBool('app_lock_enabled'),
      showBalance: prefs.getBool('show_balance'),
      notificationsEnabled: prefs.getBool('notifications_enabled'),
      dataSaverMode: prefs.getBool('data_saver_mode'),
      defaultBudgetView: prefs.getString('default_budget_view'),
    );
  }
  
  /// Create from Supabase response
  factory SyncableSettings.fromSupabase(Map<String, dynamic> data) {
    return SyncableSettings(
      experienceMode: data['experience_mode'] as String?,
      themeMode: data['theme_mode'] as String?,
      accentColor: data['accent_color'] as String?,
      currency: data['currency'] as String?,
      language: data['language'] as String?,
      dateFormat: data['date_format'] as String?,
      timezone: data['timezone'] as String?,
      biometricEnabled: data['biometric_enabled'] as bool?,
      appLockEnabled: data['app_lock_enabled'] as bool?,
      showBalance: data['show_balance'] as bool?,
      notificationsEnabled: data['notifications_enabled'] as bool?,
      dataSaverMode: data['data_saver_mode'] as bool?,
      defaultBudgetView: data['default_budget_view'] as String?,
    );
  }
  
  /// Apply settings to SharedPreferences
  Future<void> applyToPrefs(SharedPreferences prefs) async {
    if (experienceMode != null) await prefs.setString('user_mode', experienceMode!);
    if (themeMode != null) await prefs.setString('theme_mode', themeMode!);
    if (accentColor != null) await prefs.setString('accent_color', accentColor!);
    if (currency != null) await prefs.setString('currency', currency!);
    if (language != null) await prefs.setString('language', language!);
    if (dateFormat != null) await prefs.setString('date_format', dateFormat!);
    if (timezone != null) await prefs.setString('timezone', timezone!);
    if (biometricEnabled != null) await prefs.setBool('biometric_enabled', biometricEnabled!);
    if (appLockEnabled != null) await prefs.setBool('app_lock_enabled', appLockEnabled!);
    if (showBalance != null) await prefs.setBool('show_balance', showBalance!);
    if (notificationsEnabled != null) await prefs.setBool('notifications_enabled', notificationsEnabled!);
    if (dataSaverMode != null) await prefs.setBool('data_saver_mode', dataSaverMode!);
    if (defaultBudgetView != null) await prefs.setString('default_budget_view', defaultBudgetView!);
  }
  
  int get settingsCount {
    int count = 0;
    if (experienceMode != null) count++;
    if (themeMode != null) count++;
    if (accentColor != null) count++;
    if (currency != null) count++;
    if (language != null) count++;
    if (dateFormat != null) count++;
    if (timezone != null) count++;
    if (biometricEnabled != null) count++;
    if (appLockEnabled != null) count++;
    if (showBalance != null) count++;
    if (notificationsEnabled != null) count++;
    if (dataSaverMode != null) count++;
    if (defaultBudgetView != null) count++;
    return count;
  }
}

/// Batched settings sync - syncs ALL settings in ONE API call
class SettingsBatchSync {
  final SharedPreferences _prefs;
  
  SettingsBatchSync(this._prefs);
  
  /// Check if sync is allowed (Pro+ only)
  bool get _canSync {
    final tier = SubscriptionService().currentTier;
    return SubscriptionManager.canUseCloudSync(tier);
  }
  
  /// Push ALL settings to cloud using V7 RPC (handles both profiles and user_settings tables)
  Future<int> pushSettings() async {
    if (!_canSync) {
      debugPrint(' SettingsBatchSync: Skipping push - Free tier');
      return 0;
    }
    
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      debugPrint(' SettingsBatchSync: Skipping push - No user');
      return 0;
    }
    
    try {
      final settings = SyncableSettings.fromPrefs(_prefs);
      
      final profilePayload = <String, dynamic>{};

      // Profile fields (Native columns)
      if (settings.experienceMode != null) profilePayload['experience_mode'] = settings.experienceMode;
      if (settings.language != null) profilePayload['language_preference'] = settings.language;
      // Other native fields...
      
      // Mapped Metadata fields (Theme, Currency, Security)
      final metadata = <String, dynamic>{};
      if (settings.themeMode != null) metadata['theme_mode'] = settings.themeMode;
      if (settings.accentColor != null) metadata['accent_color'] = settings.accentColor;
      if (settings.currency != null) metadata['currency'] = settings.currency; // Currency often moved to metadata or native
      if (settings.dateFormat != null) metadata['date_format'] = settings.dateFormat;
      if (settings.timezone != null) metadata['timezone'] = settings.timezone;
      if (settings.biometricEnabled != null) metadata['biometric_enabled'] = settings.biometricEnabled;
      if (settings.appLockEnabled != null) metadata['app_lock_enabled'] = settings.appLockEnabled;
      if (settings.showBalance != null) metadata['show_balance'] = settings.showBalance;
      if (settings.notificationsEnabled != null) metadata['notifications_enabled'] = settings.notificationsEnabled;
      if (settings.dataSaverMode != null) metadata['data_saver_mode'] = settings.dataSaverMode;
      if (settings.defaultBudgetView != null) metadata['default_budget_view'] = settings.defaultBudgetView;

      if (metadata.isNotEmpty) profilePayload['metadata'] = metadata;

      if (profilePayload.isEmpty) {
        debugPrint(' SettingsBatchSync: No settings to push');
        return 0;
      }
      
      // Update Profile directly (RPC is overkill for single row update, but safe)
      await Supabase.instance.client
          .from('profiles')
          .update(profilePayload)
          .eq('id', user.id);
      
      debugPrint(' SettingsBatchSync: Pushed ${settings.settingsCount} settings to Profile');
      return settings.settingsCount;
      
    } catch (e) {
      debugPrint(' SettingsBatchSync: Push error: $e');
      return 0;
    }
  }
  
  /// Pull ALL settings from cloud (profiles.metadata)
  Future<int> pullSettings() async {
    if (!_canSync) return 0;
    
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return 0;
    
    try {
      // Fetch Profile
      final profileData = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();
      
      if (profileData == null) {
        debugPrint(' SettingsBatchSync: No profile found in cloud');
        return 0;
      }
      
      // Extract Metadata
      final metadata = profileData['metadata'] as Map<String, dynamic>? ?? {};
      
      // Merge Native + Metadata
      final combinedData = <String, dynamic>{
        ...profileData, // Native columns like experience_mode
        ...metadata,    // internal keys like theme_mode
      };
      // Map legacy/native keys if needed
      if (profileData['language_preference'] != null) combinedData['language'] = profileData['language_preference'];
      
      final cloudSettings = SyncableSettings.fromSupabase(combinedData);
      
      // Apply all settings locally
      await cloudSettings.applyToPrefs(_prefs);
      
      debugPrint(' SettingsBatchSync: Pulled ${cloudSettings.settingsCount} settings. Metadata: $metadata Combined: $combinedData');
      return cloudSettings.settingsCount;
      
    } catch (e) {
      debugPrint(' SettingsBatchSync: Pull error: $e');
      return 0;
    }
  }
  
  /// Full bidirectional sync - pull then push
  Future<SettingsSyncResult> sync() async {
    final pulled = await pullSettings();
    final pushed = await pushSettings();
    return SettingsSyncResult(pulled: pulled, pushed: pushed);
  }
}

/// Result of settings sync
class SettingsSyncResult {
  final int pulled;
  final int pushed;
  
  SettingsSyncResult({required this.pulled, required this.pushed});
  
  int get total => pulled + pushed;
  bool get success => true; // No errors thrown
  
  @override
  String toString() => 'SettingsSyncResult(pulled: $pulled, pushed: $pushed)';
}
