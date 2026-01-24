/// CashPilot Core Providers
/// Riverpod providers for app-wide state management
library;

import 'dart:async';

import 'package:cashpilot/core/constants/app_constants.dart' show AppConstants, AppLanguage, AppThemeMode;
import 'package:cashpilot/core/services/navigation_service.dart' show NavigationService;
import 'package:cashpilot/core/sync/idempotency_tracker.dart' show IdempotencyTracker;
import 'package:cashpilot/data/drift/encrypted_database.dart' show EncryptedDatabaseExecutor;
import 'package:cashpilot/services/security/key_manager.dart' show keyManagerProvider, KeyType;
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:cashpilot/data/drift/app_database.dart';
import '../../services/auth_service.dart';
import '../../services/currency_converter_service.dart';
import '../services/data/export_service.dart';
import '../constants/app_routes.dart';
import '../router/app_router.dart';
import '../../features/receipt/services/receipt_learning_service.dart';
import '../../features/barcode/services/barcode_learning_service.dart';

// ============================================================
// INTERNAL: PREFS WRITE SERIALIZER (ENTERPRISE HARDENING)
// Prevents rapid toggles / multiple async writes from racing.
// ============================================================

class _PrefsWriteQueue {
  Future<void> _tail = Future.value();

  Future<T> run<T>(Future<T> Function() action) {
    final completer = Completer<T>();
    _tail = _tail.then((_) async {
      try {
        final result = await action();
        completer.complete(result);
      } catch (e, st) {
        completer.completeError(e, st);
      }
    });
    return completer.future;
  }
}

// ============================================================
// DATABASE PROVIDER
// ============================================================

/// Provides the Drift database instance
/// Database encryption is initialized lazily on first access
final databaseProvider = Provider<AppDatabase>((ref) {
  // Ensure encryption is initialized before creating database
  _ensureEncryptionInitialized();
  
  // Create encrypted database connection (same as _openConnection in app_database.dart)
  final db = AppDatabase(EncryptedDatabaseExecutor.openEncryptedConnection(() async {
    // Get key from KeyManager
    final keyManager = ref.read(keyManagerProvider);
    await keyManager.initialize();
    final keyBytes = await keyManager.getKey(KeyType.backupKey);
    if (keyBytes == null) return null;
    
    // Convert to hex string for SQLCipher
    return keyBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }));
  ref.onDispose(() => db.close());
  return db;
});

/// One-time encryption initialization guard
bool _encryptionInitialized = false;

void _ensureEncryptionInitialized() {
  if (_encryptionInitialized) return;
  
  // Initialize SQLCipher synchronously (only runs once)
  // This is deferred from main() to avoid blocking app startup
  EncryptedDatabaseExecutor.initializeSync();
  _encryptionInitialized = true;
}

// ============================================================
// AUTH SERVICE PROVIDER
// ============================================================

/// Provides the AuthService instance for Supabase authentication
final authServiceProvider = Provider<AuthService>((ref) {
  return authService;
});

/// Provides Supabase client instance
final supabaseProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});


// ============================================================
// NAVIGATION SERVICE PROVIDER
// ============================================================

/// Provides the centralized NavigationService
final navigationServiceProvider = Provider<NavigationService>((ref) {
  final router = ref.watch(routerProvider);
  return NavigationService(router);
});


// ============================================================
// EXPORT SERVICE PROVIDER
// ============================================================

/// Provides the ExportService
final exportServiceProvider = Provider<ExportService>((ref) {
  final db = ref.watch(databaseProvider);
  return ExportService(db);
});

// ============================================================
// ML LEARNING SERVICE PROVIDERS
// ============================================================

/// Provides Receipt Learning Service for tracking user corrections
final receiptLearningServiceProvider = Provider((ref) {
  // Service will use Supabase directly for learning events
  return ReceiptLearningService();
});

/// Provides Barcode Learning Service for tracking user corrections
final barcodeLearningServiceProvider = Provider((ref) {
  // Service will use Supabase directly for learning events
  return BarcodeLearningService();
});

// ============================================================
// SHARED PREFERENCES PROVIDER
// ============================================================

/// Provides SharedPreferences instance (must be initialized first)
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden in main');
});

/// Internal shared write queue so all notifiers serialize writes.
final _prefsWriteQueueProvider = Provider<_PrefsWriteQueue>((ref) {
  final q = _PrefsWriteQueue();
  return q;
});

// ============================================================
// THEME PROVIDER
// ============================================================

/// Current theme mode state
final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, AppThemeMode>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final queue = ref.watch(_prefsWriteQueueProvider);
  return ThemeModeNotifier(prefs, queue);
});

class ThemeModeNotifier extends StateNotifier<AppThemeMode> {
  final SharedPreferences _prefs;
  final _PrefsWriteQueue _queue;
  StreamSubscription? _authSubscription;
  static const _key = 'theme_mode';

  ThemeModeNotifier(this._prefs, this._queue) : super(_loadTheme(_prefs)) {
    _setupAuthListener();
    // Try initial sync (if logged in)
    _syncFromCloud();
  }

  static AppThemeMode _loadTheme(SharedPreferences prefs) {
    final value = prefs.getString(_key);
    // Strong default: "light" fallback if missing/invalid.
    return AppThemeMode.fromString(value ?? 'light');
  }

  Future<void> setTheme(AppThemeMode mode) async {
    if (state == mode) return;
    state = mode;

    // Serialize writes to avoid races from multiple UI triggers.
    await _queue.run(() async {
      await _prefs.setString(_key, mode.value);
    });
    
    // Sync change to cloud
    try {
      await _syncToCloud();
      _log('ThemeModeNotifier: Synced $mode to cloud');
    } catch (e) {
      _log('ThemeModeNotifier: Sync failed: $e');
    }
  }

  void _log(String msg) {
    if (kDebugMode) debugPrint(msg);
  }

  void toggleTheme() {
    final modes = AppThemeMode.values;
    final currentIndex = modes.indexOf(state);
    final nextIndex = (currentIndex + 1) % modes.length;
    // Fire-and-forget is fine; state updates immediately.
    unawaited(setTheme(modes[nextIndex]));
  }
  
  // --- CLOUD SYNC LOGIC ---

  void _setupAuthListener() {
    try {
      _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
        if (data.event == AuthChangeEvent.signedIn) {
          _syncFromCloud();
        }
      });
    } catch (_) {
      // Supabase might not be initialized in tests
    }
  }

  Future<void> _syncToCloud() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      // We need to fetch current metadata to merge (avoid overwriting other keys)
      // Or we can rely on Postgres jsonb_set if we write a custom RPC, but fetch-merge is safer here
      final resp = await Supabase.instance.client
          .from('profiles')
          .select('metadata')
          .eq('id', user.id)
          .maybeSingle();
          
      final currentMetadata = (resp?['metadata'] as Map?) ?? {};
      final newMetadata = Map<String, dynamic>.from(currentMetadata);
      newMetadata['theme_mode'] = state.value;

      await Supabase.instance.client
          .from('profiles')
          .update({
            'metadata': newMetadata,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', user.id);
    } catch (e) {
      // Silent fail (offline)
    }
  }

  Future<void> _syncFromCloud() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final resp = await Supabase.instance.client
          .from('profiles')
          .select('metadata')
          .eq('id', user.id)
          .maybeSingle();

      if (resp != null) {
        final metadata = (resp['metadata'] as Map?) ?? {};
        final cloudValue = metadata['theme_mode'] as String?;
        if (cloudValue != null) {
          final mode = AppThemeMode.fromString(cloudValue);
          if (mode != state) {
            state = mode;
            await _prefs.setString(_key, mode.value);
          }
        } else {
           // Cloud has no value, push local
           await _syncToCloud();
        }
      }
    } catch (e) {
      // Silent fail
    }
  }
  
  /// Manual refresh from SharedPreferences (after batch sync)
  void refreshFromPrefs() {
    final mode = _loadTheme(_prefs);
    _log('ThemeModeNotifier: refreshFromPrefs current=$state new=$mode val=${_prefs.getString(_key)}');
    if (state != mode) {
      state = mode;
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}

// ============================================================
// LANGUAGE PROVIDER
// ============================================================

/// Current language state
final languageProvider =
    StateNotifierProvider<LanguageNotifier, AppLanguage>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final queue = ref.watch(_prefsWriteQueueProvider);
  return LanguageNotifier(prefs, queue);
});

class LanguageNotifier extends StateNotifier<AppLanguage> {
  final SharedPreferences _prefs;
  final _PrefsWriteQueue _queue;
  StreamSubscription? _authSubscription;
  static const _key = 'language';

  LanguageNotifier(this._prefs, this._queue) : super(_loadLanguage(_prefs)) {
    // Synchronize global Intl locale on startup
    Intl.defaultLocale = state.code;
    _setupAuthListener();
    _syncFromCloud();
  }

  static AppLanguage _loadLanguage(SharedPreferences prefs) {
    final value = prefs.getString(_key);
    // Default to English if missing/invalid.
    return AppLanguage.fromCode(value ?? 'en');
  }

  Future<void> setLanguage(AppLanguage language) async {
    if (state == language) return;
    state = language;
    Intl.defaultLocale = language.code;

    await _queue.run(() async {
      await _prefs.setString(_key, language.code);
    });
    
    // Sync change to cloud
    try {
      await _syncToCloud();
      _log('LanguageNotifier: Synced ${language.code} to cloud');
    } catch (e) {
      _log('LanguageNotifier: Sync failed: $e');
    }
  }

  void _log(String msg) {
    if (kDebugMode) debugPrint(msg);
  }
  
  // --- CLOUD SYNC LOGIC ---

  void _setupAuthListener() {
    try {
      _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
        if (data.event == AuthChangeEvent.signedIn) {
          _syncFromCloud();
        }
      });
    } catch (_) {
      // Supabase might not be initialized in tests
    }
  }

  Future<void> _syncToCloud() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      await Supabase.instance.client
          .from('profiles')
          .update({
            'language_preference': state.code,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', user.id);
    } catch (e) {
      // Silent fail (offline)
    }
  }

  Future<void> _syncFromCloud() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final resp = await Supabase.instance.client
          .from('profiles')
          .select('language_preference')
          .eq('id', user.id)
          .maybeSingle();

      if (resp != null) {
        final cloudValue = resp['language_preference'] as String?;
        if (cloudValue != null) {
          final language = AppLanguage.fromCode(cloudValue);
          if (language != state) {
            state = language;
            Intl.defaultLocale = language.code;
            await _prefs.setString(_key, language.code);
          }
        } else {
           // Cloud has no value, push local
           await _syncToCloud();
        }
      }
    } catch (e) {
      // Silent fail
    }
  }

  /// Manual refresh from SharedPreferences
  void refreshFromPrefs() {
    final language = _loadLanguage(_prefs);
    if (state != language) {
      state = language;
      Intl.defaultLocale = language.code;
    }
  }
  
  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}

// ============================================================
// CURRENCY PROVIDER
// ============================================================

/// Current selected currency
final currencyProvider =
    StateNotifierProvider<CurrencyNotifier, String>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final queue = ref.watch(_prefsWriteQueueProvider);
  return CurrencyNotifier(prefs, queue);
});

class CurrencyNotifier extends StateNotifier<String> {
  final SharedPreferences _prefs;
  final _PrefsWriteQueue _queue;
  StreamSubscription? _authSubscription;
  static const _key = 'currency';

  CurrencyNotifier(this._prefs, this._queue) : super(_loadCurrency(_prefs)) {
    _setupAuthListener();
    _syncFromCloud();
  }

  static String _loadCurrency(SharedPreferences prefs) {
    final saved = prefs.getString(_key);
    final normalized = _normalizeCurrency(saved);
    return normalized ?? AppConstants.defaultCurrency;
  }

  /// Normalize to uppercase 3-letter currency codes where possible.
  /// Returns null if invalid.
  static String? _normalizeCurrency(String? raw) {
    if (raw == null) return null;
    final v = raw.trim().toUpperCase();
    // Accept standard 3-letter currency codes. (You can expand to a whitelist later.)
    if (v.length == 3) return v;
    return null;
  }

  Future<void> setCurrency(String currency) async {
    final normalized = _normalizeCurrency(currency) ?? AppConstants.defaultCurrency;
    if (state == normalized) return;

    state = normalized;

    await _queue.run(() async {
      await _prefs.setString(_key, normalized);
    });
    
    await _syncToCloud();
  }
  
  // --- CLOUD SYNC LOGIC ---

  void _setupAuthListener() {
    try {
      _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
        if (data.event == AuthChangeEvent.signedIn) {
          _syncFromCloud();
        }
      });
    } catch (_) {}
  }

  Future<void> _syncToCloud() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      // Fetch current metadata to merge (currency is stored in metadata JSONB)
      final resp = await Supabase.instance.client
          .from('profiles')
          .select('metadata')
          .eq('id', user.id)
          .maybeSingle();
          
      final currentMetadata = (resp?['metadata'] as Map?) ?? {};
      final newMetadata = Map<String, dynamic>.from(currentMetadata);
      newMetadata['currency'] = state;

      await Supabase.instance.client
          .from('profiles')
          .update({
            'metadata': newMetadata,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', user.id);
    } catch (_) {}
  }

  Future<void> _syncFromCloud() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final resp = await Supabase.instance.client
          .from('profiles')
          .select('metadata')
          .eq('id', user.id)
          .maybeSingle();

      if (resp != null) {
        final metadata = (resp['metadata'] as Map?) ?? {};
        final cloudCurrency = metadata['currency'] as String?;
        final normalized = _normalizeCurrency(cloudCurrency);
        
        if (normalized != null && normalized != state) {
          state = normalized;
          await _prefs.setString(_key, normalized);
        } else if (normalized == null) {
          // Cloud empty, push local
          await _syncToCloud();
        }
      }
    } catch (_) {}
  }
  
  /// Manual refresh from SharedPreferences
  void refreshFromPrefs() {
    final currency = _loadCurrency(_prefs);
    if (state != currency) {
      state = currency;
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}

// ============================================================
// CURRENCY CONVERTER SERVICE PROVIDER
// ============================================================

/// Provides the CurrencyConverterService singleton
final currencyConverterServiceProvider =
    Provider<CurrencyConverterService>((ref) {
  final service = CurrencyConverterService();

  // Enterprise safety: keep it lazy, but ensure cached load doesn't throw upstream.
  // Also prevents repeated loads if provider rebuilt (rare, but safe).
  unawaited(_safeLoadRates(service));

  return service;
});

Future<void> _safeLoadRates(CurrencyConverterService service) async {
  try {
    await service.loadCachedSnapshot();
  } catch (_) {
    // Intentionally swallow: app must not crash due to cache corruption.
    // (Service should expose diagnostics/telemetry if you have it.)
  }
}

// ============================================================
// USER PROVIDER
// ============================================================

/// Current user ID (for local usage, before cloud auth)
final currentUserIdProvider =
    StateNotifierProvider<CurrentUserIdNotifier, String?>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final queue = ref.watch(_prefsWriteQueueProvider);
  return CurrentUserIdNotifier(prefs, queue);
});

class CurrentUserIdNotifier extends StateNotifier<String?> {
  final SharedPreferences _prefs;
  final _PrefsWriteQueue _queue;
  static const _key = 'current_user_id';

  CurrentUserIdNotifier(this._prefs, this._queue) : super(_load(_prefs));

  static String? _load(SharedPreferences prefs) {
    final v = prefs.getString(_key);
    return _normalizeUserId(v);
  }

  static String? _normalizeUserId(String? raw) {
    if (raw == null) return null;
    final v = raw.trim();
    if (v.isEmpty) return null;
    // Keep permissive: Supabase IDs / UUIDs / local IDs.
    if (v.length < 6) return null; // basic sanity
    return v;
  }

  Future<void> setUserId(String? userId) async {
    final normalized = _normalizeUserId(userId);

    if (state == normalized) return;
    state = normalized;

    await _queue.run(() async {
      if (normalized != null) {
        await _prefs.setString(_key, normalized);
      } else {
        await _prefs.remove(_key);
      }
    });
  }

  /// Clear the current user ID (sign out)
  Future<void> clearUserId() async {
    await setUserId(null);
  }
}

// ============================================================
// ONBOARDING PROVIDER
// ============================================================

/// Whether onboarding has been completed
final onboardingCompleteProvider =
    StateNotifierProvider<OnboardingNotifier, bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final queue = ref.watch(_prefsWriteQueueProvider);
  return OnboardingNotifier(prefs, queue);
});

class OnboardingNotifier extends StateNotifier<bool> {
  final SharedPreferences _prefs;
  final _PrefsWriteQueue _queue;
  static const _key = 'onboarding_complete';

  OnboardingNotifier(this._prefs, this._queue)
      : super(_prefs.getBool(_key) ?? false);

  Future<void> setComplete(bool complete) async {
    if (state == complete) return;
    state = complete;

    await _queue.run(() async {
      await _prefs.setBool(_key, complete);
    });
  }
}

// ============================================================
// NAVIGATION STATE
// ============================================================

/// Current bottom navigation index
final bottomNavIndexProvider = StateProvider<int>((ref) => 0);

// ============================================================
// SECURITY PROVIDERS
// ============================================================

/// Whether biometric lock is enabled
final biometricEnabledProvider =
    StateNotifierProvider<BiometricNotifier, bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final queue = ref.watch(_prefsWriteQueueProvider);
  return BiometricNotifier(prefs, queue);
});

class BiometricNotifier extends StateNotifier<bool> {
  final SharedPreferences _prefs;
  final _PrefsWriteQueue _queue;
  static const _key = 'biometric_enabled';

  BiometricNotifier(this._prefs, this._queue)
      : super(_prefs.getBool(_key) ?? false);

  Future<void> setEnabled(bool enabled) async {
    if (state == enabled) return;
    state = enabled;

    // Save locally first (for offline support)
    await _queue.run(() async {
      await _prefs.setBool(_key, enabled);
    });

    // Sync to cloud (best effort)
    await _syncToCloud();
  }

  Future<void> _syncToCloud() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return; // No cloud sync for offline/guest users

      // Fetch current metadata
      final response = await Supabase.instance.client
          .from('profiles')
          .select('metadata')
          .eq('id', user.id)
          .single();

      final Map<String, dynamic> metadata = 
          Map<String, dynamic>.from(response['metadata'] ?? {});

      // Update biometric setting
      metadata['biometric_enabled'] = state;

      // Write back
      await Supabase.instance.client
          .from('profiles')
          .update({'metadata': metadata})
          .eq('id', user.id);
    } catch (e) {
      // Non-fatal: local preference still saved
    }
  }

  Future<void> _syncFromCloud() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final response = await Supabase.instance.client
          .from('profiles')
          .select('metadata')
          .eq('id', user.id)
          .single();

      final metadata = response['metadata'] as Map<String, dynamic>?;
      if (metadata?['biometric_enabled'] != null) {
        final cloudValue = metadata!['biometric_enabled'] as bool;
        if (cloudValue != state) {
          state = cloudValue;
          await _queue.run(() async {
            await _prefs.setBool(_key, cloudValue);
          });
        }
      }
    } catch (e) {
      // Non-fatal: keep local value
    }
  }
  /// Manual refresh from SharedPreferences
  void refreshFromPrefs() {
    final enabled = _prefs.getBool(_key) ?? false;
    if (state != enabled) {
      state = enabled;
    }
  }
}

/// Whether app lock is enabled
final appLockEnabledProvider =
    StateNotifierProvider<AppLockNotifier, bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final queue = ref.watch(_prefsWriteQueueProvider);
  return AppLockNotifier(prefs, queue);
});

class AppLockNotifier extends StateNotifier<bool> {
  final SharedPreferences _prefs;
  final _PrefsWriteQueue _queue;
  static const _key = 'app_lock_enabled';

  AppLockNotifier(this._prefs, this._queue)
      : super(_prefs.getBool(_key) ?? false);

  Future<void> setEnabled(bool enabled) async {
    if (state == enabled) return;
    state = enabled;

    // Save locally first (for offline support)
    await _queue.run(() async {
      await _prefs.setBool(_key, enabled);
    });

    // Sync to cloud (best effort) - only when user changes setting
    await _syncToCloud();
  }

  Future<void> _syncToCloud() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return; // No cloud sync for offline/guest users

      // Fetch current metadata
      final response = await Supabase.instance.client
          .from('profiles')
          .select('metadata')
          .eq('id', user.id)
          .single();

      final Map<String, dynamic> metadata = 
          Map<String, dynamic>.from(response['metadata'] ?? {});

      // Update app lock setting
      metadata['app_lock_enabled'] = state;

      // Write back
      await Supabase.instance.client
          .from('profiles')
          .update({'metadata': metadata})
          .eq('id', user.id);
    } catch (e) {
      // Non-fatal: local preference still saved
    }
  }

  Future<void> _syncFromCloud() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final response = await Supabase.instance.client
          .from('profiles')
          .select('metadata')
          .eq('id', user.id)
          .single();

      final metadata = response['metadata'] as Map<String, dynamic>?;
      if (metadata?['app_lock_enabled'] != null) {
        final cloudValue = metadata!['app_lock_enabled'] as bool;
        if (cloudValue != state) {
          state = cloudValue;
          await _queue.run(() async {
            await _prefs.setBool(_key, cloudValue);
          });
        }
      }
    } catch (e) {
      // Non-fatal: keep local value
    }
  }
  /// Manual refresh from SharedPreferences
  void refreshFromPrefs() {
    final enabled = _prefs.getBool(_key) ?? false;
    if (state != enabled) {
      state = enabled;
    }
  }
}

/// Whether app is currently locked (needs authentication)
final appLockedProvider = StateProvider<bool>((ref) => false);

/// Auto-lock timeout in seconds (0 = immediate, -1 = never)
final autoLockTimeoutProvider =
    StateNotifierProvider<AutoLockTimeoutNotifier, int>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final queue = ref.watch(_prefsWriteQueueProvider);
  return AutoLockTimeoutNotifier(prefs, queue);
});

class AutoLockTimeoutNotifier extends StateNotifier<int> {
  final SharedPreferences _prefs;
  final _PrefsWriteQueue _queue;
  static const _key = 'auto_lock_timeout';

  AutoLockTimeoutNotifier(this._prefs, this._queue)
      : super(_sanitize(_prefs.getInt(_key) ?? 0)); // Default: immediate

  static int _sanitize(int seconds) {
    // Allow only known values + safe ranges.
    if (seconds == -1) return -1;
    if (seconds < 0) return 0;
    // Upper bound safety (e.g., prevent absurd numbers)
    if (seconds > 3600) return 3600;
    return seconds;
  }

  Future<void> setTimeout(int seconds) async {
    final sanitized = _sanitize(seconds);
    if (state == sanitized) return;
    state = sanitized;

    await _queue.run(() async {
      await _prefs.setInt(_key, sanitized);
    });
  }

  /// Available timeout options
  static const Map<int, String> timeoutOptions = {
    0: 'Immediately',
    15: '15 seconds',
    30: '30 seconds',
    60: '1 minute',
    300: '5 minutes',
    -1: 'Never',
  };
}

/// Timestamp when app was last paused
final appPausedTimestampProvider = StateProvider<DateTime?>((ref) => null);

/// Whether cloud sync is enabled
final cloudSyncEnabledProvider =
    StateNotifierProvider<CloudSyncNotifier, bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final queue = ref.watch(_prefsWriteQueueProvider);
  return CloudSyncNotifier(prefs, queue);
});

class CloudSyncNotifier extends StateNotifier<bool> {
  final SharedPreferences _prefs;
  final _PrefsWriteQueue _queue;
  static const _key = 'cloud_sync_enabled';

  CloudSyncNotifier(this._prefs, this._queue)
      : super(_prefs.getBool(_key) ?? true);

  Future<void> setEnabled(bool enabled) async {
    if (state == enabled) return;
    state = enabled;

    await _queue.run(() async {
      await _prefs.setBool(_key, enabled);
    });
  }
  /// Manual refresh from SharedPreferences
  void refreshFromPrefs() {
    final enabled = _prefs.getBool(_key) ?? true;
    if (state != enabled) {
      state = enabled;
    }
  }
}

// ============================================================
// DATE FORMAT PROVIDER
// ============================================================

/// Current date format string
final dateFormatProvider =
    StateNotifierProvider<DateFormatNotifier, String>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final queue = ref.watch(_prefsWriteQueueProvider);
  return DateFormatNotifier(prefs, queue);
});

class DateFormatNotifier extends StateNotifier<String> {
  final SharedPreferences _prefs;
  final _PrefsWriteQueue _queue;
  static const _key = 'date_format';

  DateFormatNotifier(this._prefs, this._queue)
      : super(_prefs.getString(_key) ?? AppConstants.dateFormatLong);

  Future<void> setFormat(String format) async {
    if (state == format) return;
    state = format;

    await _queue.run(() async {
      await _prefs.setString(_key, format);
    });
    
    await _syncToCloud();
  }

  Future<void> _syncToCloud() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final resp = await Supabase.instance.client
          .from('profiles')
          .select('metadata')
          .eq('id', user.id)
          .maybeSingle();

      final currentMetadata = (resp?['metadata'] as Map?) ?? {};
      final newMetadata = Map<String, dynamic>.from(currentMetadata);
      newMetadata['date_format'] = state;

      await Supabase.instance.client
          .from('profiles')
          .update({
            'metadata': newMetadata,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', user.id);
    } catch (_) {}
  }

  /// Manual refresh from SharedPreferences
  void refreshFromPrefs() {
    final format = _prefs.getString(_key) ?? AppConstants.dateFormatLong;
    if (state != format) {
      state = format;
    }
  }
}

// ============================================================
// SHOW BALANCE PROVIDER
// ============================================================

/// Whether to show balance (eye icon)
final showBalanceProvider =
    StateNotifierProvider<ShowBalanceNotifier, bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final queue = ref.watch(_prefsWriteQueueProvider);
  return ShowBalanceNotifier(prefs, queue);
});

class ShowBalanceNotifier extends StateNotifier<bool> {
  final SharedPreferences _prefs;
  final _PrefsWriteQueue _queue;
  static const _key = 'show_balance';

  ShowBalanceNotifier(this._prefs, this._queue)
      : super(_prefs.getBool(_key) ?? true);

  Future<void> setVisible(bool visible) async {
    if (state == visible) return;
    state = visible;

    await _queue.run(() async {
      await _prefs.setBool(_key, visible);
    });

    await _syncToCloud();
  }

  Future<void> _syncToCloud() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final resp = await Supabase.instance.client
          .from('profiles')
          .select('metadata')
          .eq('id', user.id)
          .maybeSingle();

      final currentMetadata = (resp?['metadata'] as Map?) ?? {};
      final newMetadata = Map<String, dynamic>.from(currentMetadata);
      newMetadata['show_balance'] = state;

      await Supabase.instance.client
          .from('profiles')
          .update({
            'metadata': newMetadata,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', user.id);
    } catch (_) {}
  }

  /// Manual refresh from SharedPreferences
  void refreshFromPrefs() {
    final visible = _prefs.getBool(_key) ?? true;
    if (state != visible) {
      state = visible;
    }
  }
}

// ============================================================
// DATA SAVER PROVIDER
// ============================================================

/// Whether data saver mode is enabled
final dataSaverProvider =
    StateNotifierProvider<DataSaverNotifier, bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final queue = ref.watch(_prefsWriteQueueProvider);
  return DataSaverNotifier(prefs, queue);
});

class DataSaverNotifier extends StateNotifier<bool> {
  final SharedPreferences _prefs;
  final _PrefsWriteQueue _queue;
  static const _key = 'data_saver_mode';

  DataSaverNotifier(this._prefs, this._queue)
      : super(_prefs.getBool(_key) ?? false);

  Future<void> setEnabled(bool enabled) async {
    if (state == enabled) return;
    state = enabled;

    await _queue.run(() async {
      await _prefs.setBool(_key, enabled);
    });

    await _syncToCloud();
  }

  Future<void> _syncToCloud() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final resp = await Supabase.instance.client
          .from('profiles')
          .select('metadata')
          .eq('id', user.id)
          .maybeSingle();

      final currentMetadata = (resp?['metadata'] as Map?) ?? {};
      final newMetadata = Map<String, dynamic>.from(currentMetadata);
      newMetadata['data_saver_mode'] = state;

      await Supabase.instance.client
          .from('profiles')
          .update({
            'metadata': newMetadata,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', user.id);
    } catch (_) {}
  }

  /// Manual refresh from SharedPreferences
  void refreshFromPrefs() {
    final enabled = _prefs.getBool(_key) ?? false;
    if (state != enabled) {
      state = enabled;
    }
  }
}

// ============================================================
// DEFAULT BUDGET VIEW PROVIDER
// ============================================================

/// Default budget view (monthly, weekly, etc.)
final defaultBudgetViewProvider =
    StateNotifierProvider<DefaultBudgetViewNotifier, String>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final queue = ref.watch(_prefsWriteQueueProvider);
  return DefaultBudgetViewNotifier(prefs, queue);
});

class DefaultBudgetViewNotifier extends StateNotifier<String> {
  final SharedPreferences _prefs;
  final _PrefsWriteQueue _queue;
  static const _key = 'default_budget_view';

  DefaultBudgetViewNotifier(this._prefs, this._queue)
      : super(_prefs.getString(_key) ?? 'monthly');

  Future<void> setView(String view) async {
    if (state == view) return;
    state = view;

    await _queue.run(() async {
      await _prefs.setString(_key, view);
    });

    await _syncToCloud();
  }

  Future<void> _syncToCloud() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final resp = await Supabase.instance.client
          .from('profiles')
          .select('metadata')
          .eq('id', user.id)
          .maybeSingle();

      final currentMetadata = (resp?['metadata'] as Map?) ?? {};
      final newMetadata = Map<String, dynamic>.from(currentMetadata);
      newMetadata['default_budget_view'] = state;

      await Supabase.instance.client
          .from('profiles')
          .update({
            'metadata': newMetadata,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', user.id);
    } catch (_) {}
  }

  /// Manual refresh from SharedPreferences
  void refreshFromPrefs() {
    final view = _prefs.getString(_key) ?? 'monthly';
    if (state != view) {
      state = view;
    }
  }
}

// ============================================================
// IDEMPOTENCY TRACKER PROVIDER  
// ============================================================

/// Provider for idempotency tracking service
/// Prevents duplicate operations (payments, sync, etc.)
final idempotencyTrackerProvider = Provider<IdempotencyTracker>((ref) {
  return IdempotencyTracker(ref.read(sharedPreferencesProvider));
});

