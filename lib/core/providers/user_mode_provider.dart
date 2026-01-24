/// ============================================================
/// USER MODE
/// Controls UX depth, tone, explanations, analytics density
/// Now syncs across devices via Supabase!
/// ============================================================
library;

import 'dart:async';
import 'package:cashpilot/core/providers/app_providers.dart'
    show sharedPreferencesProvider;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum UserMode {
  beginner,
  expert,
}

extension UserModeX on UserMode {
  String get storageValue => name;

  static UserMode fromStorage(String? value) {
    switch (value) {
      case 'expert':
        return UserMode.expert;
      case 'beginner':
      default:
        return UserMode.beginner;
    }
  }

  bool get isBeginner => this == UserMode.beginner;
  bool get isExpert => this == UserMode.expert;

  bool get showAdvancedOptions => isExpert;
  bool get showHints => isBeginner;
  bool get showConfidenceScores => isExpert;
  bool get showRawNumbers => isExpert;
  bool get simplifyLanguage => isBeginner;
}

/// ============================================================
/// PROVIDER
/// ============================================================

final userModeProvider =
    StateNotifierProvider<UserModeNotifier, UserMode>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return UserModeNotifier(prefs);
});

class UserModeNotifier extends StateNotifier<UserMode> {
  static const _prefsKey = 'user_mode';
  static const _supabaseTable = 'profiles';
  static const _supabaseColumn = 'experience_mode';

  final SharedPreferences _prefs;
  StreamSubscription? _authSubscription;

  bool _syncInProgress = false;

  UserModeNotifier(this._prefs) : super(_load(_prefs)) {
    debugPrint('📊 UserModeNotifier: Initial load = $state');

    _syncFromCloud();
    _setupAuthListener();

    Future.delayed(const Duration(seconds: 2), _syncFromCloud);
    Future.delayed(const Duration(seconds: 5), _syncFromCloud);
  }

  /// Load synchronously from local storage
  static UserMode _load(SharedPreferences prefs) {
    final stored = prefs.getString(_prefsKey);

    final legacyExpert = prefs.getBool('is_expert_mode');
    if (stored == null && legacyExpert != null) {
      final migrated =
          legacyExpert ? UserMode.expert : UserMode.beginner;
      prefs.setString(_prefsKey, migrated.storageValue);
      prefs.remove('is_expert_mode');
      return migrated;
    }

    return UserModeX.fromStorage(stored);
  }

  void _setupAuthListener() {
    try {
      _authSubscription = Supabase.instance.client.auth
          .onAuthStateChange
          .listen((data) {
        if (!mounted) return;

        final event = data.event;
        debugPrint('📊 UserModeNotifier: Auth event = $event');

        if (event == AuthChangeEvent.signedIn ||
            event == AuthChangeEvent.tokenRefreshed) {
          _syncFromCloud();
        }
      });
    } catch (e) {
      debugPrint(
          '📊 UserModeNotifier: Error setting up auth listener: $e');
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  /// Sync from cloud (single-flight)
  Future<void> _syncFromCloud() async {
    if (_syncInProgress) return;
    _syncInProgress = true;

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final response = await Supabase.instance.client
          .from(_supabaseTable)
          .select(_supabaseColumn)
          .eq('id', user.id)
          .maybeSingle();

      final raw = response?[_supabaseColumn] as String?;
      if (raw == null) {
        if (_prefs.containsKey(_prefsKey)) {
          await _syncToCloud();
        }
        return;
      }

      final cloudMode = UserModeX.fromStorage(raw);

      if (cloudMode == state) return;

      if (state == UserMode.expert &&
          cloudMode == UserMode.beginner) {
        await _syncToCloud();
      } else {
        state = cloudMode;
        await _prefs.setString(_prefsKey, cloudMode.storageValue);
      }
    } catch (e) {
      debugPrint('📊 UserModeNotifier: Cloud sync error: $e');
    } finally {
      _syncInProgress = false;
    }
  }

  /// Sync to cloud (direct update to profiles table)
  Future<void> _syncToCloud() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      // Direct update to profiles.experience_mode
      await Supabase.instance.client
          .from('profiles')
          .update({'experience_mode': state.storageValue})
          .eq('id', user.id);

      debugPrint('📊 UserModeNotifier: Synced ${state.storageValue} to cloud');
    } catch (e) {
      debugPrint('📊 UserMode Notifier: Cloud write failed: $e');
    }
  }

  /// Explicit setter
  Future<void> setMode(UserMode mode) async {
    if (state == mode) return;

    state = mode;
    await _prefs.setString(_prefsKey, mode.storageValue);
    await _syncToCloud();
  }

  /// Toggle helper
  Future<void> toggleMode() async {
    await setMode(
      state == UserMode.beginner ? UserMode.expert : UserMode.beginner,
    );
  }

  /// Reset to safe default
  Future<void> reset() async {
    state = UserMode.beginner;
    await _prefs.remove(_prefsKey);

    if (Supabase.instance.client.auth.currentUser != null) {
      await _syncToCloud();
    }
  }

  /// Manual refresh from SharedPreferences
  void refreshFromPrefs() {
    final mode = _load(_prefs);
    if (state != mode) {
      state = mode;
    }
  }

  /// Manual refresh
  Future<void> refreshFromCloud() async {
    await _syncFromCloud();
  }
}
