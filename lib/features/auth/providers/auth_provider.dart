/// Authentication Providers
/// Riverpod providers for auth state management
library;
import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../services/auth_service.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/providers/user_mode_provider.dart';
import '../../../core/managers/auth_manager.dart';
import '../../../data/drift/app_database.dart' hide User; // Hide Drift's User class
import '../../subscription/providers/subscription_providers.dart';

/// Auth status enum
enum AuthStatus { initial, authenticated, unauthenticated, loading }

/// Auth state model
class AuthState {
  final AuthStatus status;
  final User? user;
  final String? errorMessage;
  final bool isLoading;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
    this.isLoading = false,
  });

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? errorMessage,
    bool? isLoading,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isGuest => status == AuthStatus.unauthenticated;
}

/// Auth state notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final Ref ref;
  
  AuthNotifier(this.ref) : super(const AuthState()) {
    _init();
  }

  void _init() {
    // Listen to auth state changes (triggers on OAuth callback)
    authService.authStateChanges.listen((data) async {
      final event = data.event;
      final session = data.session;
      
      debugPrint('🔐 AuthNotifier: Auth event = $event, hasSession = ${session != null}');
      
      if (session != null) {
        // IMPORTANT: Set user ID FIRST before updating state
        // This ensures router redirect sees the user as logged in
        final currentUserIdNotifier = ref.read(currentUserIdProvider.notifier);
        if (ref.read(currentUserIdProvider) != session.user.id) {
          await currentUserIdNotifier.setUserId(session.user.id);
          debugPrint('🔐 AuthNotifier: Set currentUserId to ${session.user.id}');
        }
        
        // Then sync user data (can happen async)
        _syncUserToLocal(session.user);
        
        // CRITICAL: Unlock session after OAuth login (Google, Apple, etc.)
        // This prevents biometric lock screen from blocking access
        Future.microtask(() {
          ref.read(sessionUnlockedProvider.notifier).state = true;
          debugPrint('🔐 AuthNotifier: Session unlocked after OAuth login');
        });
        
        // Finally update auth state
        state = AuthState(
          status: AuthStatus.authenticated,
          user: session.user,
        );
        debugPrint('🔐 AuthNotifier: State set to authenticated for ${session.user.email}');
      } else {
        state = const AuthState(status: AuthStatus.unauthenticated);
        debugPrint('🔐 AuthNotifier: State set to unauthenticated');
      }
    });

    // Check current session on startup
    final session = authService.currentSession;
    if (session != null) {
      debugPrint('🔐 AuthNotifier: Found existing session for ${session.user.email}');
      
      // Set user ID first
      ref.read(currentUserIdProvider.notifier).setUserId(session.user.id);
      
      // Sync user to local database on app start
      _syncUserToLocal(session.user);
      
      // If existing session, user is already authenticated - unlock session
      // Defer logic to avoid modifying provider during build
      Future.microtask(() {
        ref.read(sessionUnlockedProvider.notifier).state = true;
        debugPrint('🔐 AuthNotifier: Session unlocked for existing session');
      });
      
      state = AuthState(
        status: AuthStatus.authenticated,
        user: session.user,
      );
    } else {
      debugPrint('🔐 AuthNotifier: No existing session found');
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  /// Sign up with email
  Future<bool> signUpWithEmail({
    required String email,
    required String password,
    String? name,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final response = await authService.signUpWithEmail(
        email: email,
        password: password,
        name: name,
      );

      if (response.user != null) {
        // CRITICAL: Set user ID IMMEDIATELY before any async sync operations
        // This prevents race condition where router checks auth before listener fires
        await ref.read(currentUserIdProvider.notifier).setUserId(response.user!.id);
        
        // Sync new user to local database
        await _syncUserToLocal(response.user!);
        
        // CRITICAL: Unlock session after successful signup
        // This prevents biometric lock screen from blocking access
        Future.microtask(() {
          ref.read(sessionUnlockedProvider.notifier).state = true;
          debugPrint('🔐 signUpWithEmail: Session unlocked after successful signup');
        });
        
        state = AuthState(
          status: AuthStatus.authenticated,
          user: response.user,
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Sign up failed',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  /// Sign in with email
  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final response = await authService.signInWithEmail(
        email: email,
        password: password,
      );

      if (response.user != null) {
        // CRITICAL: Set user ID IMMEDIATELY before any async sync operations
        // This ensures the router checks verify the user is logged in *before* 
        // the UI attempts to navigate to /home, preventing a bounce back to /login
        await ref.read(currentUserIdProvider.notifier).setUserId(response.user!.id);
        
        // Sync user to local database
        await _syncUserToLocal(response.user!);
        
        // CRITICAL: Unlock session after successful email/password login
        // This prevents biometric lock screen from blocking access
        Future.microtask(() {
          ref.read(sessionUnlockedProvider.notifier).state = true;
          debugPrint('🔐 signInWithEmail: Session unlocked after successful login');
        });
        
        state = AuthState(
          status: AuthStatus.authenticated,
          user: response.user,
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Sign in failed',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  /// Sign in with Google
  Future<bool> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final success = await authService.signInWithGoogle();
      if (!success) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Google sign in cancelled',
        );
      }
      return success;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  /// Sign in with Apple
  Future<bool> signInWithApple() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final success = await authService.signInWithApple();
      if (!success) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Apple sign in cancelled',
        );
      }
      return success;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await authService.signOut();
    
    // Reset subscription to free tier (prevents tier from persisting to next login)
    await ref.read(subscriptionServiceProvider).resetToFree();
    
    // Clear local user ID to force login screen
    await ref.read(currentUserIdProvider.notifier).clearUserId();
    
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  /// Continue as guest (skip auth)
  Future<bool> continueAsGuest() async {
    state = state.copyWith(isLoading: true);
    
    // Create a local-only guest user
    final db = ref.read(databaseProvider);
    final userId = 'guest_${DateTime.now().millisecondsSinceEpoch}';
    
    try {
      await db.insertUser(UsersCompanion(
        id: Value(userId),
        name: const Value('Guest User'),
        email: Value('$userId@local.cashpilot'),
        languagePreference: const Value('en'),
        subscriptionTier: const Value('free'),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ));
      
      // IMPORTANT: Reset subscription tier to 'free' for guest users
      // This ensures guest users don't inherit Pro Plus tier from previous sessions
      await ref.read(subscriptionServiceProvider).resetToFree();
      
      // Set as current user - this is crucial for router to allow navigation
      await ref.read(currentUserIdProvider.notifier).setUserId(userId);
      
      // Set status as authenticated (as guest)
      state = AuthState(
        status: AuthStatus.authenticated,
        isLoading: false,
      );
      
      debugPrint('Guest user created successfully: $userId (tier: free)');
      return true;
    } catch (e) {
      debugPrint('Error creating guest user: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to create guest account: $e',
      );
      return false;
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  /// Sync user data to local database
  Future<void> _syncUserToLocal(User user) async {
    try {
      final db = ref.read(databaseProvider);
      
      // Get subscription tier from Supabase
      String subscriptionTier = 'free';
      DateTime? subscriptionExpiresAt;
      int ocrUsageCount = 0;
      
      try {
        final profile = await authService.client
            .from('profiles')
            .select('subscription_tier, subscription_expires_at, ocr_usage_count')
            .eq('id', user.id)
            .single()
            .timeout(const Duration(seconds: 5));
        
        subscriptionTier = profile['subscription_tier'] ?? 'free';
        if (profile['subscription_expires_at'] != null) {
          subscriptionExpiresAt = DateTime.tryParse(profile['subscription_expires_at'] as String? ?? '');
        }
        ocrUsageCount = profile['ocr_usage_count'] ?? 0;
        
        // Merge Supabase profile metadata with Auth user metadata if needed
        // For now, allow Auth metadata to take precedence or merge logic here
        // But importantly, ensure we capture it for the local DB

      } catch (e) {
        // Profile might not exist yet, use defaults
        debugPrint('Could not fetch profile, using defaults: $e');
      }

      // Create or update local user record
      await db.insertUser(UsersCompanion(
        id: Value(user.id),
        name: Value(user.userMetadata?['name'] ?? user.userMetadata?['full_name'] ?? user.email?.split('@').first ?? 'User'),
        email: Value(user.email ?? ''),
        languagePreference: Value(user.userMetadata?['language'] ?? 'en'),
        avatarUrl: Value(user.userMetadata?['avatar_url'] ?? user.userMetadata?['picture']),
        subscriptionTier: Value(subscriptionTier),
        subscriptionExpiresAt: Value(subscriptionExpiresAt),
        ocrUsageCount: Value(ocrUsageCount),
        metadata: Value(user.userMetadata), // Persist metadata
        updatedAt: Value(DateTime.now()),
      ));
      
      // CRITICAL: Set current user ID so router and profile know user is logged in
      final currentUserIdNotifier = ref.read(currentUserIdProvider.notifier);
      // Only set if different to avoid router rebuilds
      if (ref.read(currentUserIdProvider) != user.id) {
        await currentUserIdNotifier.setUserId(user.id);
      }
      debugPrint('User synced successfully: ${user.id} (${user.email})');
      
      // Refresh user mode from cloud (sync across devices)
      // Import: import '../../../core/providers/user_mode_provider.dart';
      try {
        await ref.read(userModeProvider.notifier).refreshFromCloud();
        debugPrint('User mode synced from cloud');
      } catch (e) {
        debugPrint('User mode sync failed (non-critical): $e');
      }
      
    } catch (e) {
      // If user already exists, update it
      try {
        final db = ref.read(databaseProvider);
        await db.updateUser(UsersCompanion(
          id: Value(user.id),
          name: Value(user.userMetadata?['name'] ?? user.userMetadata?['full_name'] ?? user.email?.split('@').first ?? 'User'),
          email: Value(user.email ?? ''),
          avatarUrl: Value(user.userMetadata?['avatar_url'] ?? user.userMetadata?['picture']),
          updatedAt: Value(DateTime.now()),
        ));
        
        // CRITICAL: Set current user ID even on update
        final currentUserIdNotifier = ref.read(currentUserIdProvider.notifier);
        if (ref.read(currentUserIdProvider) != user.id) {
          await currentUserIdNotifier.setUserId(user.id);
        }
        debugPrint('User updated successfully: ${user.id}');
        
        // Refresh user mode from cloud (sync across devices)
        try {
          await ref.read(userModeProvider.notifier).refreshFromCloud();
          debugPrint('User mode synced from cloud (after update)');
        } catch (e) {
          debugPrint('User mode sync failed (non-critical): $e');
        }
        
      } catch (updateError) {
        debugPrint('Failed to update user: $updateError');
      }
    }
  }
}

/// Auth state provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});

/// Current user provider
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authProvider).user;
});

/// Is authenticated provider
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAuthenticated;
});

/// Is loading provider
final isAuthLoadingProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isLoading;
});

/// Subscription tier provider
final subscriptionTierProvider = FutureProvider<String>((ref) async {
  return await authService.getSubscriptionTier();
});

// Note: isProProvider is defined in subscription_providers.dart
