/// Security Manager
/// Centralized manager for all security operations
/// Handles rate limiting, spam protection, data encryption, and security auditing
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';
import '../../services/encryption_service.dart';

// =============================================================================
// SECURITY MANAGER - Singleton Pattern
// =============================================================================

/// Centralized security manager
class SecurityManager {
  static final SecurityManager _instance = SecurityManager._internal();
  factory SecurityManager() => _instance;
  SecurityManager._internal();

  // Rate limiting storage
  final Map<String, List<DateTime>> _requestLog = {};
  final Map<String, DateTime> _lockoutUntil = {};

  // Failed attempts tracking
  final Map<String, int> _failedAttempts = {};

  // Security configuration
  static const int maxRequestsPerMinute = 60;
  static const int maxLoginAttempts = 5;
  static const Duration lockoutDuration = Duration(minutes: 15);
  static const Duration requestWindowDuration = Duration(minutes: 1);

  // Robustness: hard caps to prevent unbounded memory growth
  static const int _maxStoredActions = 200;       // distinct action keys
  static const int _maxEventsPerAction = 120;     // per-action timestamps cap
  static const int _maxFailedAttemptKeys = 500;   // distinct identifiers

  // Namespacing keys so login lockouts don't collide with action lockouts
  String _actionKey(String action) => 'action::$action';
  String _loginKey(String identifier) => 'login::$identifier';

  // ==========================================================================
  // RATE LIMITING
  // ==========================================================================

  /// Check if action is rate limited
  bool isRateLimited(String action, {int maxRequests = maxRequestsPerMinute}) {
    final key = _actionKey(action);

    // Check lockout first
    final lockout = _lockoutUntil[key];
    if (lockout != null && DateTime.now().isBefore(lockout)) {
      return true;
    }

    // Clean old requests
    _cleanRequestLog(action);

    // Check current request count
    final requests = _requestLog[key] ?? const <DateTime>[];
    return requests.length >= maxRequests;
  }

  /// Record an action for rate limiting
  void recordAction(String action) {
    _cleanRequestLog(action);

    final key = _actionKey(action);
    _requestLog.putIfAbsent(key, () => <DateTime>[]);

    final list = _requestLog[key]!;
    list.add(DateTime.now());

    // Cap list size (prevents memory growth if something spams within window)
    if (list.length > _maxEventsPerAction) {
      list.removeRange(0, list.length - _maxEventsPerAction);
    }

    // Cap number of tracked actions
    if (_requestLog.length > _maxStoredActions) {
      _requestLog.remove(_requestLog.keys.first);
    }
  }

  /// Get remaining requests allowed
  int getRemainingRequests(String action, {int maxRequests = maxRequestsPerMinute}) {
    _cleanRequestLog(action);
    final key = _actionKey(action);

    final requests = _requestLog[key] ?? const <DateTime>[];
    return (maxRequests - requests.length).clamp(0, maxRequests);
  }

  /// Get time until rate limit resets
  Duration? getTimeUntilReset(String action) {
    final key = _actionKey(action);

    final lockout = _lockoutUntil[key];
    if (lockout != null && DateTime.now().isBefore(lockout)) {
      return lockout.difference(DateTime.now());
    }

    _cleanRequestLog(action);
    final requests = _requestLog[key];
    if (requests == null || requests.isEmpty) return null;

    // Oldest event should be at index 0 after cleaning
    final oldestRequest = requests.first;
    final resetTime = oldestRequest.add(requestWindowDuration);
    if (DateTime.now().isBefore(resetTime)) {
      return resetTime.difference(DateTime.now());
    }
    return null;
  }

  void _cleanRequestLog(String action) {
    final key = _actionKey(action);
    final requests = _requestLog[key];
    if (requests == null) return;

    final cutoff = DateTime.now().subtract(requestWindowDuration);
    requests.removeWhere((time) => time.isBefore(cutoff));

    // If empty, free it
    if (requests.isEmpty) {
      _requestLog.remove(key);
    }
  }

  // ==========================================================================
  // LOGIN SECURITY
  // ==========================================================================

  /// Record a failed login attempt
  void recordFailedLogin(String identifier) {
    final key = _loginKey(identifier);

    _failedAttempts[key] = (_failedAttempts[key] ?? 0) + 1;

    if (_failedAttempts[key]! >= maxLoginAttempts) {
      _lockoutUntil[key] = DateTime.now().add(lockoutDuration);
      debugPrint('🔒 Account locked: $identifier for ${lockoutDuration.inMinutes} minutes');

      logSecurityEvent(
        type: SecurityEventType.loginLocked,
        details: 'Login locked after $maxLoginAttempts failed attempts',
        userId: identifier,
      );
    } else {
      logSecurityEvent(
        type: SecurityEventType.loginFailed,
        details: 'Failed login attempt ${_failedAttempts[key]}/$maxLoginAttempts',
        userId: identifier,
      );
    }

    // Cap number of tracked identifiers
    if (_failedAttempts.length > _maxFailedAttemptKeys) {
      _failedAttempts.remove(_failedAttempts.keys.first);
    }
  }

  /// Record a successful login (clears failed attempts)
  void recordSuccessfulLogin(String identifier) {
    final key = _loginKey(identifier);
    _failedAttempts.remove(key);
    _lockoutUntil.remove(key);

    logSecurityEvent(
      type: SecurityEventType.loginSuccess,
      details: 'Login successful',
      userId: identifier,
    );
  }

  /// Check if login is locked out
  bool isLoginLocked(String identifier) {
    final key = _loginKey(identifier);

    final lockout = _lockoutUntil[key];
    if (lockout == null) return false;

    if (DateTime.now().isAfter(lockout)) {
      // Lockout expired
      _lockoutUntil.remove(key);
      _failedAttempts.remove(key);
      return false;
    }

    return true;
  }

  /// Get lockout remaining time
  Duration? getLockoutRemaining(String identifier) {
    final key = _loginKey(identifier);

    final lockout = _lockoutUntil[key];
    if (lockout == null || DateTime.now().isAfter(lockout)) return null;
    return lockout.difference(DateTime.now());
  }

  /// Get number of failed attempts
  int getFailedAttempts(String identifier) {
    final key = _loginKey(identifier);
    return _failedAttempts[key] ?? 0;
  }

  // ==========================================================================
  // SPAM PROTECTION
  // ==========================================================================

  /// Check if input looks like spam
  bool isSpamInput(String input) {
    if (input.isEmpty) return false;

    // Check for excessive length
    if (input.length > 10000) return true;

    // Check for repeated characters
    if (_hasExcessiveRepeats(input)) return true;

    // Check for suspicious patterns
    if (_hasSuspiciousPatterns(input)) return true;

    return false;
  }

  bool _hasExcessiveRepeats(String input) {
    // More than 10 consecutive identical characters
    final repeatPattern = RegExp(r'(.)\1{9,}');
    return repeatPattern.hasMatch(input);
  }

  bool _hasSuspiciousPatterns(String input) {
    final lowered = input.toLowerCase();

    // Common injection / spam patterns (cheap checks first)
    if (lowered.contains('<script') || lowered.contains('javascript:')) return true;
    if (lowered.contains('onerror') || lowered.contains('onclick')) return true;

    // Social engineering spam phrases
    const spamPatterns = <String>[
      'click here',
      'free money',
      'you won',
      'urgent action',
    ];

    for (final pattern in spamPatterns) {
      if (lowered.contains(pattern)) return true;
    }

    return false;
  }

  /// Sanitize user input
  String sanitizeInput(String input) {
    if (input.isEmpty) return input;

    // Remove potentially dangerous content; keep user text readable
    var sanitized = input;

    // Remove script blocks (case-insensitive, dotall-like)
    sanitized = sanitized.replaceAll(
      RegExp(r'<script\b[^>]*>[\s\S]*?</script>', caseSensitive: false),
      '',
    );

    // Remove all HTML tags
    sanitized = sanitized.replaceAll(RegExp(r'<[^>]+>'), '');

    // Remove javascript: protocol and inline on* handlers
    sanitized = sanitized.replaceAll(RegExp(r'javascript\s*:', caseSensitive: false), '');
    sanitized = sanitized.replaceAll(RegExp(r'on\w+\s*=', caseSensitive: false), '');

    // Normalize excessive whitespace (but keep normal spacing)
    sanitized = sanitized.replaceAll(RegExp(r'\s{3,}'), '  ');

    // Limit length
    if (sanitized.length > 5000) {
      sanitized = sanitized.substring(0, 5000);
    }

    return sanitized.trim();
  }

  // ==========================================================================
  // DATA ENCRYPTION
  // ==========================================================================

  /// Encrypt sensitive data
  String encryptData(String plaintext) {
    try {
      if (!encryptionService.isReady) return plaintext; // fail-open locally
      return encryptionService.encryptString(plaintext);
    } catch (e) {
      debugPrint('⚠️ encryptData failed: $e');
      return plaintext;
    }
  }

  /// Decrypt sensitive data
  String decryptData(String ciphertext) {
    try {
      if (!encryptionService.isReady) return ciphertext; // fail-open locally
      return encryptionService.decryptString(ciphertext);
    } catch (e) {
      debugPrint('⚠️ decryptData failed: $e');
      return ciphertext;
    }
  }

  /// Check if encryption is available
  bool get isEncryptionAvailable => encryptionService.isReady;

  // ==========================================================================
  // SECURITY AUDIT
  // ==========================================================================

  final List<SecurityEvent> _securityLog = [];

  /// Log security event
  void logSecurityEvent({
    required SecurityEventType type,
    required String details,
    String? userId,
  }) {
    final event = SecurityEvent(
      type: type,
      details: details,
      userId: userId,
      timestamp: DateTime.now(),
    );

    _securityLog.add(event);

    // Keep only last 1000 events
    if (_securityLog.length > 1000) {
      _securityLog.removeAt(0);
    }

    debugPrint('🔐 Security Event: ${type.name} - $details');
  }

  /// Get recent security events
  List<SecurityEvent> getRecentEvents({int limit = 50}) {
    final start = (_securityLog.length - limit).clamp(0, _securityLog.length);
    return _securityLog.sublist(start);
  }

  // ==========================================================================
  // SESSION SECURITY
  // ==========================================================================

  DateTime? _lastActivity;

  /// Record user activity (for session timeout)
  void recordActivity() {
    _lastActivity = DateTime.now();
  }

  /// Check if session has timed out
  bool hasSessionTimedOut({Duration timeout = const Duration(minutes: 30)}) {
    if (_lastActivity == null) return false;
    return DateTime.now().difference(_lastActivity!) > timeout;
  }

  /// Get time since last activity
  Duration? getTimeSinceLastActivity() {
    if (_lastActivity == null) return null;
    return DateTime.now().difference(_lastActivity!);
  }

  // ==========================================================================
  // DEVICE TRUST
  // ==========================================================================

  /// Check if this device is trusted
  Future<bool> isDeviceTrusted(Ref ref) async {
    final prefs = ref.read(sharedPreferencesProvider);
    return prefs.getBool('device_trusted') ?? false;
  }

  /// Mark device as trusted
  Future<void> trustDevice(Ref ref) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool('device_trusted', true);
    logSecurityEvent(
      type: SecurityEventType.deviceTrusted,
      details: 'Device marked as trusted',
    );
  }

  /// Revoke device trust
  Future<void> revokeDeviceTrust(Ref ref) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.remove('device_trusted');
    logSecurityEvent(
      type: SecurityEventType.deviceRevoked,
      details: 'Device trust revoked',
    );
  }
}

// =============================================================================
// SECURITY MODELS
// =============================================================================

enum SecurityEventType {
  loginSuccess,
  loginFailed,
  loginLocked,
  logoutUser,
  passwordChanged,
  biometricEnabled,
  biometricDisabled,
  rateLimited,
  spamDetected,
  deviceTrusted,
  deviceRevoked,
  dataExported,
  dataDeleted,
  suspiciousActivity,
}

class SecurityEvent {
  final SecurityEventType type;
  final String details;
  final String? userId;
  final DateTime timestamp;

  SecurityEvent({
    required this.type,
    required this.details,
    this.userId,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'details': details,
    'userId': userId,
    'timestamp': timestamp.toIso8601String(),
  };
}

// =============================================================================
// PROVIDERS
// =============================================================================

/// Security manager provider
final securityManagerProvider = Provider<SecurityManager>((ref) {
  return SecurityManager();
});

/// Global security manager instance
final securityManager = SecurityManager();
