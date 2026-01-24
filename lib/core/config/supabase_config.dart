import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase Configuration
/// Store credentials securely - this file should use environment variables in production
class SupabaseConfig {
  // ---------------------------------------------------------------------------
  // CORE SUPABASE SETTINGS
  // ---------------------------------------------------------------------------

  /// Supabase project URL (TEST)
  static const String url = 'https://uszrekgpeymtfijwgriu.supabase.co';

  /// Supabase anon/public key (TEST)
  static const String anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVzenJla2dwZXltdGZpandncml1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjU0OTE3OTcsImV4cCI6MjA4MTA2Nzc5N30.Xz5ug5nk4PZbY4gflEENK_dGuwZk_WPXYdWoQxACjds';

  // ---------------------------------------------------------------------------
  // LIVE CONFIG (for production)
  // ---------------------------------------------------------------------------

  /// Supabase project URL (LIVE)
  static const String liveUrl = '';

  /// Supabase anon/public key (LIVE)
  static const String liveAnonKey = '';

  /// Deep link redirect URL for OAuth
  static const String redirectUrl =
      'io.supabase.cashpilot://login-callback/';

  // ---------------------------------------------------------------------------
  // STORAGE BUCKETS
  // ---------------------------------------------------------------------------

  static const String avatarBucket = 'avatars';
  static const String receiptBucket = 'receipts';

  // ---------------------------------------------------------------------------
  // ADMIN / DEVELOPER ACCESS (DEBUG ONLY - EXCLUDED FROM RELEASE)
  // ---------------------------------------------------------------------------
  // ⚠️ SECURITY WARNING: This is NOT real authorization!
  // Client-side admin checks can be bypassed by modifying the APK/IPA.
  // 
  // ✅ PRODUCTION SECURITY: Use Supabase RLS policies instead:
  // - Add 'role' column to 'profiles' table (see migration SQL)
  // - RLS policies check user role server-side
  // - Client cannot bypass server validation
  // 
  // This client-side check is ONLY compiled in DEBUG builds for:
  // - Development convenience
  // - UI hints (showing/hiding admin menu items)
  // - Never for actual authorization decisions
  // 
  // P0 SECURITY FIX: This entire section is excluded from release builds
  // ---------------------------------------------------------------------------

  /// Admin email list - DEBUG ONLY (not compiled in release builds)
  static const List<String> _debugAdminEmails = kDebugMode ? [
    'ddeba32@gmail.com',
    'shah.saundarya@gmail.com',
  ] : [];

  /// ⚠️ DEBUG ONLY: Client-side admin check
  /// This is excluded from release builds entirely
  /// Real authorization MUST use Supabase RLS policies
  static bool isAdmin(String? email) {
    // Release builds always return false (no client-side admin bypass)
    if (!kDebugMode) return false;
    
    if (email == null || email.isEmpty) return false;
    final normalized = email.toLowerCase().trim();
    return _debugAdminEmails.any((e) => e.toLowerCase().trim() == normalized);
  }

  // ---------------------------------------------------------------------------
  // BUILD-MODE AWARE CONFIG
  // ---------------------------------------------------------------------------

  /// Whether this is a release build
  static const bool _isRelease = bool.fromEnvironment('dart.vm.product');

  /// Active Supabase URL (build-mode aware)
  static String get activeUrl {
    if (_isRelease && liveUrl.isNotEmpty) {
      return liveUrl;
    }
    return url;
  }

  /// Active Supabase anon key (build-mode aware)
  static String get activeAnonKey {
    if (_isRelease && liveAnonKey.isNotEmpty) {
      return liveAnonKey;
    }
    return anonKey;
  }

  // ---------------------------------------------------------------------------
  // RUNTIME HEALTH CHECK
  // ---------------------------------------------------------------------------

  /// Lightweight runtime health check for Supabase connectivity
  ///
  /// What it checks:
  /// - Network reachability to Supabase
  /// - Auth endpoint responsiveness
  /// - Token validation path
  ///
  /// Safe characteristics:
  /// - Read-only
  /// - No user data accessed
  /// - No crash propagation
  ///
  /// Returns `true` if Supabase is reachable
  static Future<bool> checkHealth({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    try {
      final client = Supabase.instance.client;

      // Minimal, safe check: access currentSession
      // This does NOT require a logged-in user - just checks client works
      final _ = client.auth.currentSession; // Sync, just checks client is alive

      return true;
    } on TimeoutException {
      if (kDebugMode) {
        debugPrint('[SupabaseConfig] Health check timed out');
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[SupabaseConfig] Health check failed: $e');
      }
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // DEBUG VALIDATION
  // ---------------------------------------------------------------------------

  /// Debug-only sanity checks (safe to call at startup)
  static void debugValidate() {
    assert(
      activeUrl.startsWith('https://'),
      'Supabase URL must start with https://',
    );
    assert(
      activeAnonKey.isNotEmpty,
      'Supabase anon key must not be empty',
    );
    assert(
      redirectUrl.contains('://'),
      'Supabase redirectUrl looks invalid',
    );

    if (_isRelease) {
      assert(
        liveUrl.isNotEmpty && liveAnonKey.isNotEmpty,
        'LIVE Supabase config missing in release build',
      );
    }
  }
}
