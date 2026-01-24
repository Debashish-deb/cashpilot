/// Error Manager
/// Centralized manager for all error handling operations
/// Handles error logging, recovery strategies, and user feedback
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../services/crash_reporting_service.dart';

// =============================================================================
// ERROR MANAGER - Singleton Pattern
// =============================================================================

/// Centralized error handling manager
class ErrorManager {
  static final ErrorManager _instance = ErrorManager._internal();
  factory ErrorManager() => _instance;
  ErrorManager._internal();

  // Error history for debugging
  final List<AppError> _errorHistory = [];
  static const int maxErrorHistory = 100;

  // Global error handlers
  final List<ErrorHandler> _handlers = [];

  // Robustness: avoid spamming UI + logs with the same error repeatedly
  final Map<String, DateTime> _recentErrorFingerprints = {};
  static const Duration _dedupeWindow = Duration(seconds: 3);

  // Robustness: prevent snackbar storms
  DateTime? _lastSnackbarAt;
  static const Duration _snackbarCooldown = Duration(milliseconds: 900);

  // ==========================================================================
  // ERROR HANDLING
  // ==========================================================================

  /// Handle an error with categorization and recovery
  Future<ErrorResult> handleError(
    dynamic error, {
    StackTrace? stackTrace,
    ErrorCategory category = ErrorCategory.unknown,
    ErrorSeverity severity = ErrorSeverity.medium,
    String? context,
    bool silent = false,
  }) async {
    final st = stackTrace ?? StackTrace.current;

    final appError = AppError(
      error: error,
      stackTrace: st,
      category: category,
      severity: severity,
      context: context?.trim().isEmpty == true ? null : context,
      timestamp: DateTime.now(),
    );

    // Add to history (always)
    _addToHistory(appError);

    // Dedupe repetitive errors (affects logging/reporting/handlers only)
    final fingerprint = _fingerprint(appError);
    final shouldProcess = _shouldProcessFingerprint(fingerprint);

    if (shouldProcess) {
      // Log the error
      _logError(appError);

      // Report to crash analytics (for non-minor errors)
      if (severity != ErrorSeverity.low) {
        try {
          crashReporter.reportError(error, st);
        } catch (e) {
          debugPrint('Crash reporter failed: $e');
        }
      }

      // Notify registered handlers (isolated; never blocks caller)
      for (final handler in List<ErrorHandler>.from(_handlers)) {
        // Fire-and-forget, but still guarded
        unawaited(_safeInvokeHandler(handler, appError));
      }
    } else {
      // Still useful during development
      if (kDebugMode) {
        debugPrint('🟣 ErrorManager: deduped repeated error (${appError.category.name})');
      }
    }

    // Determine recovery strategy
    final recovery = _determineRecovery(appError);

    return ErrorResult(
      error: appError,
      recovery: recovery,
      userMessage: silent ? null : _getUserMessage(appError),
    );
  }

  /// Handle network errors specifically
  Future<ErrorResult> handleNetworkError(
    dynamic error, {
    StackTrace? stackTrace,
    String? endpoint,
  }) async {
    return handleError(
      error,
      stackTrace: stackTrace,
      category: ErrorCategory.network,
      severity: _getNetworkErrorSeverity(error),
      context: endpoint != null ? 'Endpoint: $endpoint' : null,
    );
  }

  /// Handle database errors specifically
  Future<ErrorResult> handleDatabaseError(
    dynamic error, {
    StackTrace? stackTrace,
    String? operation,
  }) async {
    return handleError(
      error,
      stackTrace: stackTrace,
      category: ErrorCategory.database,
      severity: ErrorSeverity.high,
      context: operation != null ? 'Operation: $operation' : null,
    );
  }

  /// Handle authentication errors specifically
  Future<ErrorResult> handleAuthError(
    dynamic error, {
    StackTrace? stackTrace,
    String? action,
  }) async {
    return handleError(
      error,
      stackTrace: stackTrace,
      category: ErrorCategory.authentication,
      severity: ErrorSeverity.medium,
      context: action != null ? 'Action: $action' : null,
    );
  }

  /// Handle validation errors specifically
  ErrorResult handleValidationError(String message, {String? field}) {
    final error = ValidationError(message: message, field: field);

    final appError = AppError(
      error: error,
      stackTrace: StackTrace.current,
      category: ErrorCategory.validation,
      severity: ErrorSeverity.low,
      context: field,
      timestamp: DateTime.now(),
    );

    _addToHistory(appError);

    // Validation errors should not hit crash reporting

    return ErrorResult(
      error: appError,
      recovery: ErrorRecovery.userAction,
      userMessage: message,
    );
  }

  // ==========================================================================
  // ERROR RECOVERY
  // ==========================================================================

  ErrorRecovery _determineRecovery(AppError error) {
    switch (error.category) {
      case ErrorCategory.network:
        return ErrorRecovery.retry;
      case ErrorCategory.authentication:
        return ErrorRecovery.reauth;
      case ErrorCategory.database:
        return ErrorRecovery.fallback;
      case ErrorCategory.validation:
        return ErrorRecovery.userAction;
      case ErrorCategory.permission:
        return ErrorRecovery.settings;
      case ErrorCategory.unknown:
        if (error.severity == ErrorSeverity.critical) {
          return ErrorRecovery.restart;
        }
        return ErrorRecovery.ignore;
    }
  }

  String _getUserMessage(AppError error) {
    switch (error.category) {
      case ErrorCategory.network:
        return 'Network error. Please check your connection and try again.';
      case ErrorCategory.authentication:
        return 'Authentication failed. Please sign in again.';
      case ErrorCategory.database:
        return 'Data error. Your data is safe. Please try again.';
      case ErrorCategory.validation:
        return error.error.toString();
      case ErrorCategory.permission:
        return 'Permission required. Please enable it in settings.';
      case ErrorCategory.unknown:
        if (error.severity == ErrorSeverity.critical) {
          return 'Something went wrong. Please restart the app.';
        }
        return 'Something went wrong. Please try again.';
    }
  }

  ErrorSeverity _getNetworkErrorSeverity(dynamic error) {
    final message = error.toString().toLowerCase();

    // More robust mapping (still simple)
    if (message.contains('timeout')) return ErrorSeverity.low;
    if (message.contains('no internet') || message.contains('socket') || message.contains('failed host lookup')) {
      return ErrorSeverity.low;
    }
    if (message.contains('401') || message.contains('403')) return ErrorSeverity.medium;
    if (message.contains('429')) return ErrorSeverity.medium;
    if (message.contains('500') ||
        message.contains('502') ||
        message.contains('503') ||
        message.contains('server')) {
      return ErrorSeverity.high;
    }
    return ErrorSeverity.medium;
  }

  // ==========================================================================
  // ERROR HISTORY
  // ==========================================================================

  void _addToHistory(AppError error) {
    _errorHistory.add(error);
    if (_errorHistory.length > maxErrorHistory) {
      _errorHistory.removeAt(0);
    }
  }

  /// Get recent errors
  List<AppError> getRecentErrors({int limit = 20}) {
    final start = (_errorHistory.length - limit).clamp(0, _errorHistory.length);
    return _errorHistory.sublist(start);
  }

  /// Get errors by category
  List<AppError> getErrorsByCategory(ErrorCategory category) {
    return _errorHistory.where((e) => e.category == category).toList();
  }

  /// Clear error history
  void clearHistory() {
    _errorHistory.clear();
    _recentErrorFingerprints.clear();
  }

  // ==========================================================================
  // LOGGING
  // ==========================================================================

  void _logError(AppError error) {
    final severityIcon = _getSeverityIcon(error.severity);
    debugPrint('$severityIcon [${error.category.name.toUpperCase()}] ${error.error}');

    if (error.context != null) {
      debugPrint('   Context: ${error.context}');
    }

    // Only print stack in debug + for meaningful severity
    if (kDebugMode && error.severity != ErrorSeverity.low) {
      final lines = error.stackTrace.toString().split('\n');
      debugPrint('   Stack: ${lines.take(6).join('\n')}');
    }
  }

  String _getSeverityIcon(ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.low:
        return '⚪';
      case ErrorSeverity.medium:
        return '🟡';
      case ErrorSeverity.high:
        return '🟠';
      case ErrorSeverity.critical:
        return '🔴';
    }
  }

  // ==========================================================================
  // HANDLER REGISTRATION
  // ==========================================================================

  /// Register an error handler
  void registerHandler(ErrorHandler handler) {
    _handlers.add(handler);
  }

  /// Unregister an error handler
  void unregisterHandler(ErrorHandler handler) {
    _handlers.remove(handler);
  }

  Future<void> _safeInvokeHandler(ErrorHandler handler, AppError appError) async {
    try {
      await handler(appError);
    } catch (e, stack) {
      debugPrint('Error handler failed: $e');
      if (kDebugMode) debugPrintStack(stackTrace: stack);
    }
  }

  // ==========================================================================
  // DEDUPE / THROTTLE
  // ==========================================================================

  String _fingerprint(AppError e) {
    // stable-ish fingerprint: category + severity + message + context
    // (stack trace excluded to allow dedupe across repeated throws)
    final msg = e.error.toString();
    final ctx = e.context ?? '';
    return '${e.category.name}|${e.severity.name}|$msg|$ctx';
  }

  bool _shouldProcessFingerprint(String fingerprint) {
    final now = DateTime.now();
    final last = _recentErrorFingerprints[fingerprint];
    if (last != null && now.difference(last) < _dedupeWindow) {
      return false;
    }
    _recentErrorFingerprints[fingerprint] = now;

    // keep map bounded
    if (_recentErrorFingerprints.length > 200) {
      final keys = _recentErrorFingerprints.keys.take(50).toList();
      for (final k in keys) {
        _recentErrorFingerprints.remove(k);
      }
    }
    return true;
  }

  bool _canShowSnackbar() {
    final now = DateTime.now();
    if (_lastSnackbarAt != null &&
        now.difference(_lastSnackbarAt!) < _snackbarCooldown) {
      return false;
    }
    _lastSnackbarAt = now;
    return true;
  }

  // ==========================================================================
  // UI HELPERS
  // ==========================================================================

  /// Show error snackbar
  void showErrorSnackbar(BuildContext context, String message) {
    try {
      if (!_canShowSnackbar()) return;

      final messenger = ScaffoldMessenger.maybeOf(context);
      if (messenger == null) return;

      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(child: Text(message)),
              ],
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 4),
          ),
        );
    } catch (e) {
      debugPrint('showErrorSnackbar failed: $e');
    }
  }

  /// Show error dialog
  Future<void> showErrorDialog(
    BuildContext context, {
    required String title,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) async {
    try {
      return showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red.shade700),
              const SizedBox(width: 12),
              Flexible(child: Text(title)),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
            if (actionLabel != null && onAction != null)
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  onAction();
                },
                child: Text(actionLabel),
              ),
          ],
        ),
      );
    } catch (e) {
      debugPrint('showErrorDialog failed: $e');
    }
  }

  /// Show retry dialog
  Future<bool> showRetryDialog(
    BuildContext context, {
    required String message,
  }) async {
    try {
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.refresh, color: Colors.orange),
              SizedBox(width: 12),
              Text('Retry?'),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
      return result ?? false;
    } catch (e) {
      debugPrint('showRetryDialog failed: $e');
      return false;
    }
  }
}

// =============================================================================
// ERROR MODELS
// =============================================================================

typedef ErrorHandler = Future<void> Function(AppError error);

enum ErrorCategory {
  network,
  authentication,
  database,
  validation,
  permission,
  unknown,
}

enum ErrorSeverity {
  low,      // Informational, auto-recoverable
  medium,   // User impact, recoverable
  high,     // Significant impact, needs attention
  critical, // App-breaking, needs immediate action
}

enum ErrorRecovery {
  retry,      // Retry the operation
  reauth,     // Re-authenticate user
  fallback,   // Use cached/fallback data
  userAction, // User needs to correct input
  settings,   // Go to settings
  restart,    // Restart the app
  ignore,     // No action needed
}

class AppError {
  final dynamic error;
  final StackTrace stackTrace;
  final ErrorCategory category;
  final ErrorSeverity severity;
  final String? context;
  final DateTime timestamp;

  AppError({
    required this.error,
    required this.stackTrace,
    required this.category,
    required this.severity,
    this.context,
    required this.timestamp,
  });

  @override
  String toString() => '[$category] $error';
}

class ValidationError {
  final String message;
  final String? field;

  ValidationError({required this.message, this.field});

  @override
  String toString() => field != null ? '$field: $message' : message;
}

class ErrorResult {
  final AppError error;
  final ErrorRecovery recovery;
  final String? userMessage;

  ErrorResult({
    required this.error,
    required this.recovery,
    this.userMessage,
  });
}

// =============================================================================
// PROVIDERS & GLOBAL INSTANCE
// =============================================================================

/// Global error manager instance
final errorManager = ErrorManager();
