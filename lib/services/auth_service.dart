/// Authentication Service
/// Handles all Supabase authentication operations
library;
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/supabase_config.dart';
import '../core/security/secure_local_storage.dart';
import '../core/logging/logger.dart';
import '../core/network/certificate_pinner.dart';

/// Auth service for Supabase authentication
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final Logger _logger = Loggers.auth;
  SupabaseClient? _client;
  bool _initialized = false;

  /// Initialize Supabase
  Future<void> initialize() async {
    if (_initialized) return;

    _logger.info('Initializing Supabase', context: {
      'activeUrl': SupabaseConfig.activeUrl,
      'releaseMode': kReleaseMode,
    });

    // P0 SECURITY: Release builds must use live Supabase config
    assert(
      !kReleaseMode || (SupabaseConfig.liveUrl.isNotEmpty && SupabaseConfig.liveAnonKey.isNotEmpty),
      'FATAL: Release builds must have live Supabase configuration. '
      'Set liveUrl and liveAnonKey in SupabaseConfig or use dart-define.'
    );

    // CRITICAL: Use certificate pinning in production
    final httpClient = kReleaseMode 
        ? await CertificatePinner.getSupabaseClient() 
        : null;

    // CRITICAL: Use activeUrl/activeAnonKey (environment-aware, not hardcoded test values)
    await Supabase.initialize(
      url: SupabaseConfig.activeUrl,
      anonKey: SupabaseConfig.activeAnonKey,
      httpClient: httpClient,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
        localStorage: SecureLocalStorage(),
      ),
      realtimeClientOptions: const RealtimeClientOptions(
        logLevel: RealtimeLogLevel.info,
      ),
    );

    _client = Supabase.instance.client;
    _initialized = true;
    
    _logger.info('Supabase initialized successfully', context: {
      'url': SupabaseConfig.activeUrl,
    });
  }

  /// Get Supabase client
  SupabaseClient get client {
    if (_client == null) {
      throw StateError('AuthService not initialized. Call initialize() first.');
    }
    return _client!;
  }

  /// Check if user is authenticated
  bool get isAuthenticated => client.auth.currentUser != null;

  /// Get current user
  User? get currentUser => client.auth.currentUser;

  /// Get current session
  Session? get currentSession => client.auth.currentSession;

  /// Listen to auth state changes
  Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;

  /// Sign up with email and password
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    String? name,
  }) async {
    final response = await client.auth.signUp(
      email: email,
      password: password,
      data: name != null ? {'name': name} : null,
    );

    // Create profile after signup
    if (response.user != null) {
      await _createUserProfile(response.user!, name);
    }

    return response;
  }

  /// Sign in with email and password
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final response = await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    
    // Ensure profile exists (in case it was created before trigger)
    if (response.user != null) {
      await _ensureProfileExists(response.user!);
    }
    
    return response;
  }
  
  /// Ensure profile exists (idempotent)
  Future<void> _ensureProfileExists(User user) async {
    try {
      await client.from('profiles').upsert({
        'id': user.id,
        'email': user.email,
        'name': user.userMetadata?['name'] ?? user.email?.split('@').first ?? 'User',
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'id').timeout(const Duration(seconds: 5));
    } catch (e) {
      if (kDebugMode) debugPrint('Profile ensure failed (non-critical): $e');
    }
  }

  /// Sign in with Google
  Future<bool> signInWithGoogle() async {
    final response = await client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: SupabaseConfig.redirectUrl,
    );
    return response;
  }

  /// Sign in with Apple
  Future<bool> signInWithApple() async {
    final response = await client.auth.signInWithOAuth(
      OAuthProvider.apple,
      redirectTo: SupabaseConfig.redirectUrl,
    );
    return response;
  }

  /// Callback to wipe local data (DB, Prefs) on logout
  Future<void> Function()? onDataWipe;

  /// Sign out
  /// Executes rigorous data wipe sequence:
  /// 1. Wipe Encryption Keys (Crypto-shredding)
  /// 2. Wipe Local Database (via callback)
  /// 3. Sign out from Supabase
  Future<void> signOut() async {
    _logger.info('Signing out... initiating security wipe.');
    
    try {
      // 1. Crypto-shredding
      // Cyclic dependency if we import encryption service directly? 
      // AuthService is usually lower level. 
      // But EncryptionService is also a singleton service.
      // Ideally this is handled by onDataWipe too, but let's be explicit if possible.
      // We will rely on the callback for DB, but keys we can handle if we import, 
      // OR we just put everything in onDataWipe.
      // Let's rely on onDataWipe for EVERYTHING to ensure proper ordering and dependency management.
      if (onDataWipe != null) {
        await onDataWipe!();
      }
    } catch (e) {
      _logger.error('Data wipe failed during logout', error: e);
      // Proceed to sign out anyway to at least de-auth the session
    }
    
    await client.auth.signOut();
  }

  /// Send password reset email
  Future<void> sendPasswordReset(String email) async {
    await client.auth.resetPasswordForEmail(email);
  }

  /// Update user password
  Future<UserResponse> updatePassword(String newPassword) async {
    return await client.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  /// Update user profile
  Future<UserResponse> updateProfile({
    String? name,
    String? avatarUrl,
  }) async {
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (avatarUrl != null) data['avatar_url'] = avatarUrl;

    return await client.auth.updateUser(
      UserAttributes(data: data),
    );
  }

  /// Delete user account
  /// This flow:
  /// 1. Executes [onPreDelete] (optional) to soft-delete data for cloud sync
  /// 2. Executes full [signOut] which wipes all local data
  Future<void> deleteAccount({Future<void> Function()? onPreDelete}) async {
    _logger.info('Initiating account deletion...');
    
    try {
      if (onPreDelete != null) {
        await onPreDelete();
        _logger.info('Pre-delete cloud sync markers placed.');
        
        // Brief delay to allow sync engine to start pushing if it's active
        // Realistically, sync will resume on next login if we don't wait, 
        // but here we try to be proactive.
        await Future.delayed(const Duration(milliseconds: 500));
      }
    } catch (e) {
      _logger.error('Pre-delete cloud marking failed', error: e);
    }

    await signOut();
  }

  /// Create user profile in database
  Future<void> _createUserProfile(User user, String? name) async {
    try {
      await client.from('profiles').upsert({
        'id': user.id,
        'name': name ?? user.email?.split('@').first ?? 'User',
        'email': user.email,
        'subscription_tier': 'free',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      if (kDebugMode) debugPrint('Error creating profile: $e');
    }
  }

  /// Get user's subscription tier
  /// Returns: 'free', 'pro', or 'pro_plus'
  Future<String> getSubscriptionTier() async {
    if (!isAuthenticated) return 'free';
    
    // Admin users get pro_plus tier (full access)
    if (SupabaseConfig.isAdmin(currentUser?.email)) {
      return 'pro_plus';
    }

    try {
      final response = await client
          .from('profiles')
          .select('subscription_tier')
          .eq('id', currentUser!.id)
          .single();
      return response['subscription_tier'] ?? 'free';
    } catch (e) {
      return 'free';
    }
  }

  /// Check if user has paid subscription (Pro or Pro Plus)
  Future<bool> isPaid() async {
    // Admin users always have Pro access
    if (SupabaseConfig.isAdmin(currentUser?.email)) {
      return true;
    }
    
    final tier = await getSubscriptionTier();
    return tier == 'pro' || tier == 'pro_plus';
  }

  /// Check if user has Pro subscription (Pro or Pro Plus)
  Future<bool> isPro() async {
    // Admin users always have Pro access
    if (SupabaseConfig.isAdmin(currentUser?.email)) {
      return true;
    }
    
    final tier = await getSubscriptionTier();
    return tier == 'pro' || tier == 'pro_plus';
  }

  /// Check if user has Pro Plus subscription (highest tier)
  Future<bool> isProPlus() async {
    if (SupabaseConfig.isAdmin(currentUser?.email)) {
      return true;
    }
    
    final tier = await getSubscriptionTier();
    return tier == 'pro_plus';
  }
  
  /// Check if user is an admin with full access
  bool get isAdmin => SupabaseConfig.isAdmin(currentUser?.email);
}

/// Global auth service instance
final authService = AuthService();
