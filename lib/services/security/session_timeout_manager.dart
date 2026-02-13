import 'dart:async';
import 'package:cashpilot/core/logging/logger.dart' show LoggerFactory;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';


/// Session Timeout Manager
/// Monitors user activity and automatically locks the app after inactivity
class SessionTimeoutManager {
  static final SessionTimeoutManager _instance = SessionTimeoutManager._internal();
  factory SessionTimeoutManager() => _instance;
  SessionTimeoutManager._internal();

  static const Duration defaultTimeout = Duration(minutes: 5);
  static const Duration clipboardLifetime = Duration(seconds: 30);
  
  final _log = LoggerFactory.getLogger('Security');
  Timer? _timer;
  DateTime _lastActivity = DateTime.now();
  bool _isLocked = false;
  
  // Callback to trigger UI lock
  VoidCallback? onTimeout;

  /// Start monitoring for inactivity
  void start() {
    _resetTimer();
  }

  /// Record user activity to reset the timeout timer
  void recordActivity() {
    _lastActivity = DateTime.now();
    if (_isLocked) return;
    _resetTimer();
  }

  /// Lock session immediately
  void lock() {
    if (_isLocked) return;
    _isLocked = true;
    _timer?.cancel();
    _log.info('Session locked due to timeout or manual lock');
    onTimeout?.call();
    
    // Security: Clear clipboard when locking
    clearClipboard();
  }

  /// Unlock session
  void unlock() {
    _isLocked = false;
    recordActivity();
  }

  /// Clear clipboard to prevent sensitive data leakage
  Future<void> clearClipboard() async {
    try {
      await Clipboard.setData(const ClipboardData(text: ''));
      _log.debug('Securely cleared clipboard');
    } catch (e) {
      _log.error('Failed to clear clipboard', error: e);
    }
  }

  /// Schedule clipboard clearing after a short delay
  void scheduleClipboardClear() {
    Timer(clipboardLifetime, () => clearClipboard());
  }

  void _resetTimer() {
    _timer?.cancel();
    _timer = Timer(defaultTimeout, () {
      lock();
    });
  }

  void stop() {
    _timer?.cancel();
  }
}

/// Provider-ready wrapper or singleton access is fine here
/// UI should listen to activity (e.g. in a wrapper widget)
