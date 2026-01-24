/// Authentication Manager
/// Centralized manager for all authentication operations
/// Handles cloud auth, biometric auth, session management, and user sync
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show AppLifecycleState;
import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/auth_service.dart';
import '../../services/biometric_service.dart';
import '../../data/drift/app_database.dart' hide User;
import '../providers/app_providers.dart';

/// AUTH MANAGER - Singleton Pattern

/// Centralized authentication manager
class AuthManager {
  static final AuthManager _instance = AuthManager._internal();
  factory AuthManager() => _instance;
  AuthManager._internal();

  // State
  bool _initialized = false;
  StreamSubscription<AuthState>? _authSubscription;

  // Robustness: avoid duplicate syncs when auth emits multiple events quickly
  bool _syncInProgress = false;
  String? _lastSyncedUserId;
  DateTime? _lastSyncAt;

  // INITIALIZATION

  /// Initialize the auth manager
  Future<void> initialize(Ref ref) async {
    if (_initialized) return;

    // Listen to Supabase auth state changes
    _authSubscription = authService.authStateChanges.listen((data) async {
      await _handleAuthStateChange(ref, data);
    });

    // Check current session on startup
    final session = authService.currentSession;
    if (session != null) {
      await _syncUserToLocal(ref, session.user);
    }

    _initialized = true;
    debugPrint('[AuthManager] Initialized');
  }

  /// Dispose resources
  void dispose() {
    _authSubscription?.cancel();
    _authSubscription = null;
    _initialized = false;
  }

  // CLOUD AUTHENTICATION

  /// Sign up with email and password
  Future<AuthResult> signUpWithEmail({
    required Ref ref,
    required String email,
    required String password,
    String? name,
  }) async {
    try {
      final response = await authService.signUpWithEmail(
        email: email,
        password: password,
        name: name,
      );

      if (response.user != null) {
        await _syncUserToLocal(ref, response.user!);
        return AuthResult.success(userId: response.user!.id);
      }

      return AuthResult.failure(message: 'Sign up failed');
    } catch (e) {
      return AuthResult.failure(message: _parseAuthError(e));
    }
  }

  /// Sign in with email and password
  Future<AuthResult> signInWithEmail({
    required Ref ref,
    required String email,
    required String password,
  }) async {
    try {
      final response = await authService.signInWithEmail(
        email: email,
        password: password,
      );

      if (response.user != null) {
        await _syncUserToLocal(ref, response.user!);
        return AuthResult.success(userId: response.user!.id);
      }

      return AuthResult.failure(message: 'Sign in failed');
    } catch (e) {
      return AuthResult.failure(message: _parseAuthError(e));
    }
  }

  /// Sign in with Google OAuth
  Future<AuthResult> signInWithGoogle() async {
    try {
      final success = await authService.signInWithGoogle();
      if (success) {
        return AuthResult.pending(message: 'Redirecting to Google...');
      }
      return AuthResult.failure(message: 'Google sign in cancelled');
    } catch (e) {
      return AuthResult.failure(message: _parseAuthError(e));
    }
  }

  /// Sign in with Apple OAuth
  Future<AuthResult> signInWithApple() async {
    try {
      final success = await authService.signInWithApple();
      if (success) {
        return AuthResult.pending(message: 'Redirecting to Apple...');
      }
      return AuthResult.failure(message: 'Apple sign in cancelled');
    } catch (e) {
      return AuthResult.failure(message: _parseAuthError(e));
    }
  }

  /// Continue as guest (local-only mode)
  Future<AuthResult> continueAsGuest(Ref ref) async {
    try {
      final db = ref.read(databaseProvider);

      // Robustness: ensure uniqueness even if called twice quickly
      final userId =
          'guest_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecondsSinceEpoch % 100000}';

      await db.insertUser(UsersCompanion(
        id: Value(userId),
        name: const Value('Guest User'),
        email: Value('$userId@local.cashpilot'),
        languagePreference: const Value('en'),
        subscriptionTier: const Value('free'),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ));

      // Set as current user
      await ref.read(currentUserIdProvider.notifier).setUserId(userId);

      // Optional: guest session is considered unlocked for current run
      ref.read(sessionUnlockedProvider.notifier).state = true;

      debugPrint('[AuthManager] Guest user created: $userId');
      return AuthResult.success(userId: userId, isGuest: true);
    } catch (e) {
      return AuthResult.failure(message: 'Failed to create guest account: $e');
    }
  }

  /// Sign out current user
  Future<void> signOut(Ref ref) async {
    try {
      await authService.signOut();
    } catch (e) {
      // Non-fatal: still clear local session state
      debugPrint('[AuthManager] signOut warning: $e');
    }

    await ref.read(currentUserIdProvider.notifier).clearUserId();

    // Reset biometric session
    ref.read(sessionUnlockedProvider.notifier).state = false;

    // Reset sync guards
    _lastSyncedUserId = null;
    _lastSyncAt = null;

    debugPrint('[AuthManager] User signed out');
  }

  // BIOMETRIC AUTHENTICATION

  /// Check if biometric auth is available
  Future<bool> isBiometricAvailable() async {
    return await biometricService.isAvailable();
  }

  /// Check if biometrics are enrolled
  Future<bool> hasBiometricsEnrolled() async {
    return await biometricService.hasBiometricsEnrolled();
  }

  /// Get biometric type description (Face ID, Touch ID, etc.)
  Future<String> getBiometricTypeDescription() async {
    return await biometricService.getBiometricTypeDescription();
  }

  /// Authenticate with biometrics
  Future<BiometricAuthResult> authenticateBiometric({
    required String reason,
    bool biometricOnly = false,
  }) async {
    final result = await biometricService.authenticate(
      reason: reason,
      biometricOnly: biometricOnly,
    );

    return BiometricAuthResult(
      success: result == BiometricResult.success,
      result: result,
      message: biometricService.getErrorMessage(result),
    );
  }

  /// Unlock app with biometrics
  Future<bool> unlockWithBiometrics(Ref ref) async {
    final result = await authenticateBiometric(
      reason: 'Unlock CashPilot to access your financial data',
      biometricOnly: false,
    );

    if (result.success) {
      ref.read(sessionUnlockedProvider.notifier).state = true;
      return true;
    }

    // Robustness: never leave app in "unlocked" state after failure
    ref.read(sessionUnlockedProvider.notifier).state = false;
    return false;
  }

  /// Lock the app (requires biometric to unlock)
  void lockApp(dynamic ref) {
    ref.read(sessionUnlockedProvider.notifier).state = false;
  }

  /// Check if app is currently unlocked
  bool isAppUnlocked(dynamic ref) {
    return ref.read(sessionUnlockedProvider);
  }

  // SESSION MANAGEMENT

  /// Check if user is authenticated (has valid session)
  bool isAuthenticated(dynamic ref) {
    return ref.read(currentUserIdProvider) != null;
  }

  /// Get current user ID
  String? getCurrentUserId(dynamic ref) {
    return ref.read(currentUserIdProvider);
  }

  /// Check if current user is a guest
  bool isGuestUser(dynamic ref) {
    final userId = getCurrentUserId(ref);
    return userId?.startsWith('guest_') ?? false;
  }

  /// Check if user should be prompted for biometric unlock
  bool shouldShowLockScreen(dynamic ref) {
    final appLockEnabled = ref.read(appLockEnabledProvider);
    final biometricEnabled = ref.read(biometricEnabledProvider);
    final isUnlocked = ref.read(sessionUnlockedProvider);

    return appLockEnabled && biometricEnabled && !isUnlocked;
  }

  /// Handle app lifecycle changes for auto-lock
  void handleAppLifecycleChange({
    required dynamic ref,
    required AppLifecycleState state,
  }) {
    final appLockEnabled = ref.read(appLockEnabledProvider);
    final biometricEnabled = ref.read(biometricEnabledProvider);
    final timeout = ref.read(autoLockTimeoutProvider);

    if (!appLockEnabled || !biometricEnabled) return;

    if (state == AppLifecycleState.paused) {
      // Record when app went to background
      ref.read(appPausedTimestampProvider.notifier).state = DateTime.now();
      return;
    }

    if (state == AppLifecycleState.resumed) {
      final pausedAt = ref.read(appPausedTimestampProvider);

      if (timeout == -1) {
        // Never lock automatically
        return;
      }

      if (pausedAt == null) {
        // If we don't know, behave safely: lock immediately for security
        lockApp(ref);
        return;
      }

      if (timeout == 0) {
        // Lock immediately
        lockApp(ref);
        return;
      }

      // Check if timeout has elapsed
      final elapsed = DateTime.now().difference(pausedAt).inSeconds;
      if (elapsed >= timeout) {
        lockApp(ref);
      }
    }
  }

  // PRIVATE HELPERS

  /// Handle auth state changes from Supabase
  Future<void> _handleAuthStateChange(Ref ref, AuthState data) async {
    final session = data.session;
    if (session != null) {
      await _syncUserToLocal(ref, session.user);
    }
  }

  /// Sync user data to local database
  Future<void> _syncUserToLocal(Ref ref, User user) async {
    // Robustness: prevent overlapping sync tasks
    if (_syncInProgress) return;

    // Robustness: ignore rapid duplicate events for same user (common in auth flows)
    final now = DateTime.now();
    if (_lastSyncedUserId == user.id &&
        _lastSyncAt != null &&
        now.difference(_lastSyncAt!).inMilliseconds < 800) {
      return;
    }

    _syncInProgress = true;
    _lastSyncedUserId = user.id;
    _lastSyncAt = now;

    try {
      final db = ref.read(databaseProvider);

      // Get subscription info from Supabase profile
      String subscriptionTier = 'free';
      DateTime? subscriptionExpiresAt;
      int ocrUsageCount = 0;

      try {
        final profile = await authService.client
            .from('profiles')
            .select('subscription_tier, subscription_expires_at, ocr_usage_count')
            .eq('id', user.id)
            .single();

        subscriptionTier = profile['subscription_tier'] ?? 'free';
        if (profile['subscription_expires_at'] != null) {
          subscriptionExpiresAt =
              DateTime.tryParse(profile['subscription_expires_at'] as String? ?? '');
        }
        ocrUsageCount = profile['ocr_usage_count'] ?? 0;
      } catch (e) {
        debugPrint('[AuthManager] Could not fetch profile, using defaults: $e');
      }

      // Build user fields once (consistency between insert/update paths)
      final displayName = user.userMetadata?['name'] ??
          user.userMetadata?['full_name'] ??
          user.email?.split('@').first ??
          'User';

      final avatar = user.userMetadata?['avatar_url'] ??
          user.userMetadata?['picture'];

      final language = user.userMetadata?['language'] ?? 'en';

      // Create or update local user record
      try {
        await db.insertUser(UsersCompanion(
          id: Value(user.id),
          name: Value(displayName),
          email: Value(user.email ?? ''),
          languagePreference: Value(language),
          avatarUrl: Value(avatar),
          subscriptionTier: Value(subscriptionTier),
          subscriptionExpiresAt: Value(subscriptionExpiresAt),
          ocrUsageCount: Value(ocrUsageCount),
          metadata: Value(user.userMetadata),
          updatedAt: Value(DateTime.now()),
        ));
      } catch (e) {
        // If insert fails (likely already exists), update
        await db.updateUser(UsersCompanion(
          id: Value(user.id),
          name: Value(displayName),
          email: Value(user.email ?? ''),
          languagePreference: Value(language),
          avatarUrl: Value(avatar),
          subscriptionTier: Value(subscriptionTier),
          subscriptionExpiresAt: Value(subscriptionExpiresAt),
          ocrUsageCount: Value(ocrUsageCount),
          metadata: Value(user.userMetadata),
          updatedAt: Value(DateTime.now()),
        ));
      }

      // Set current user ID
      final currentId = ref.read(currentUserIdProvider);
      if (currentId != user.id) {
        await ref.read(currentUserIdProvider.notifier).setUserId(user.id);
      }

      debugPrint('[AuthManager] User synced: ${user.id} (${user.email})');
    } catch (e) {
      debugPrint('[AuthManager] Failed to sync user locally: $e');
    } finally {
      _syncInProgress = false;
    }
  }

  /// Parse auth errors into user-friendly messages
  String _parseAuthError(dynamic error) {
    final message = error.toString();

    // Keep your existing mapping, make it slightly more robust
    final lower = message.toLowerCase();

    if (lower.contains('invalid login credentials') ||
        lower.contains('invalid email or password') ||
        lower.contains('wrong password')) {
      return 'Invalid email or password';
    }
    if (lower.contains('email not confirmed') ||
        lower.contains('not confirmed')) {
      return 'Please verify your email address';
    }
    if (lower.contains('user already registered') ||
        lower.contains('already exists') ||
        lower.contains('already registered')) {
      return 'An account with this email already exists';
    }
    if (lower.contains('password') && lower.contains('6')) {
      return 'Password must be at least 6 characters';
    }
    if (lower.contains('weak password')) {
      return 'Password is too weak';
    }
    if (lower.contains('network') ||
        lower.contains('socket') ||
        lower.contains('timeout') ||
        lower.contains('connection')) {
      return 'Network error. Please check your connection';
    }

    return 'Authentication failed. Please try again';
  }
}

// AUTH RESULT MODELS

/// Result of an authentication operation
class AuthResult {
  final AuthResultStatus status;
  final String? userId;
  final String? message;
  final bool isGuest;

  const AuthResult._({
    required this.status,
    this.userId,
    this.message,
    this.isGuest = false,
  });

  factory AuthResult.success({required String userId, bool isGuest = false}) {
    return AuthResult._(
      status: AuthResultStatus.success,
      userId: userId,
      isGuest: isGuest,
    );
  }

  factory AuthResult.failure({required String message}) {
    return AuthResult._(
      status: AuthResultStatus.failure,
      message: message,
    );
  }

  factory AuthResult.pending({String? message}) {
    return AuthResult._(
      status: AuthResultStatus.pending,
      message: message,
    );
  }

  bool get isSuccess => status == AuthResultStatus.success;
  bool get isFailure => status == AuthResultStatus.failure;
  bool get isPending => status == AuthResultStatus.pending;
}

enum AuthResultStatus { success, failure, pending }

/// Result of a biometric authentication operation
class BiometricAuthResult {
  final bool success;
  final BiometricResult result;
  final String message;

  const BiometricAuthResult({
    required this.success,
    required this.result,
    required this.message,
  });
}

// PROVIDERS

/// Session unlock state (persists across widget rebuilds during session)
/// Defaults to false (locked) - user must authenticate on app start if lock is enabled
final sessionUnlockedProvider = StateProvider<bool>((ref) => false);

/// Auth manager provider
final authManagerProvider = Provider<AuthManager>((ref) {
  return AuthManager();
});

/// Global auth manager instance
final authManager = AuthManager();
