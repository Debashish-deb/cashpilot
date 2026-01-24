/// CashPilot Typed Error System
/// Provides structured error handling for better UX and debugging
library;

import 'package:flutter/foundation.dart';

/// Error codes for categorizing errors
enum AppErrorCode {
  // Network
  networkOffline,
  networkTimeout,
  networkServerError,
  
  // Auth
  authInvalidCredentials,
  authSessionExpired,
  authUnauthorized,
  authUserNotFound,
  
  // Database
  dbReadError,
  dbWriteError,
  dbNotFound,
  dbConstraintViolation,
  
  // Sync
  syncConflict,
  syncFailed,
  syncOffline,
  
  // Validation
  validationInvalidInput,
  validationMissingRequired,
  validationOutOfRange,
  
  // Subscription
  subscriptionRequired,
  subscriptionExpired,
  subscriptionLimitReached,
  
  // General
  unknown,
  cancelled,
  permissionDenied,
}

/// Severity levels for error handling
enum AppErrorSeverity {
  /// User can retry - show simple message
  recoverable,
  
  /// Requires user action - show action dialog
  actionRequired,
  
  /// Critical - may need app restart
  critical,
  
  /// Informational - just log, don't show
  silent,
}

/// Structured error class for consistent error handling
class AppError implements Exception {
  final AppErrorCode code;
  final String message;
  final String? technicalDetails;
  final Object? cause;
  final StackTrace? stackTrace;
  final AppErrorSeverity severity;
  final DateTime timestamp;

  AppError({
    required this.code,
    required this.message,
    this.technicalDetails,
    this.cause,
    this.stackTrace,
    this.severity = AppErrorSeverity.recoverable,
  }) : timestamp = DateTime.now();

  /// Factory constructors for common error types
  
  factory AppError.network({
    String message = 'Unable to connect. Please check your internet connection.',
    Object? cause,
    StackTrace? stackTrace,
  }) {
    return AppError(
      code: AppErrorCode.networkOffline,
      message: message,
      technicalDetails: cause?.toString(),
      cause: cause,
      stackTrace: stackTrace,
    );
  }

  factory AppError.timeout({
    String message = 'Request timed out. Please try again.',
    Object? cause,
    StackTrace? stackTrace,
  }) {
    return AppError(
      code: AppErrorCode.networkTimeout,
      message: message,
      technicalDetails: cause?.toString(),
      cause: cause,
      stackTrace: stackTrace,
    );
  }

  factory AppError.authFailed({
    String message = 'Authentication failed. Please sign in again.',
    Object? cause,
    StackTrace? stackTrace,
  }) {
    return AppError(
      code: AppErrorCode.authInvalidCredentials,
      message: message,
      technicalDetails: cause?.toString(),
      cause: cause,
      stackTrace: stackTrace,
      severity: AppErrorSeverity.actionRequired,
    );
  }

  factory AppError.sessionExpired({
    String message = 'Your session has expired. Please sign in again.',
    Object? cause,
    StackTrace? stackTrace,
  }) {
    return AppError(
      code: AppErrorCode.authSessionExpired,
      message: message,
      technicalDetails: cause?.toString(),
      cause: cause,
      stackTrace: stackTrace,
      severity: AppErrorSeverity.actionRequired,
    );
  }

  factory AppError.notFound({
    String message = 'The requested item was not found.',
    String? technicalDetails,
    Object? cause,
    StackTrace? stackTrace,
  }) {
    return AppError(
      code: AppErrorCode.dbNotFound,
      message: message,
      technicalDetails: technicalDetails ?? cause?.toString(),
      cause: cause,
      stackTrace: stackTrace,
    );
  }

  factory AppError.syncFailed({
    String message = 'Sync failed. Your changes are saved locally.',
    Object? cause,
    StackTrace? stackTrace,
  }) {
    return AppError(
      code: AppErrorCode.syncFailed,
      message: message,
      technicalDetails: cause?.toString(),
      cause: cause,
      stackTrace: stackTrace,
    );
  }

  factory AppError.validation({
    required String message,
    String? technicalDetails,
  }) {
    return AppError(
      code: AppErrorCode.validationInvalidInput,
      message: message,
      technicalDetails: technicalDetails,
      severity: AppErrorSeverity.recoverable,
    );
  }

  factory AppError.logic({
    required String message,
    Object? cause,
    StackTrace? stackTrace,
  }) {
    return AppError(
      code: AppErrorCode.unknown,
      message: message,
      technicalDetails: cause?.toString(),
      cause: cause,
      stackTrace: stackTrace,
      severity: AppErrorSeverity.critical,
    );
  }

  factory AppError.subscriptionRequired({
    String message = 'This feature requires a Pro subscription.',
  }) {
    return AppError(
      code: AppErrorCode.subscriptionRequired,
      message: message,
      severity: AppErrorSeverity.actionRequired,
    );
  }

  factory AppError.unknown({
    String message = 'Something went wrong. Please try again.',
    Object? cause,
    StackTrace? stackTrace,
  }) {
    return AppError(
      code: AppErrorCode.unknown,
      message: message,
      technicalDetails: cause?.toString(),
      cause: cause,
      stackTrace: stackTrace,
    );
  }

  /// Get user-friendly message based on error code
  String get userMessage {
    switch (code) {
      case AppErrorCode.networkOffline:
        return 'No internet connection';
      case AppErrorCode.networkTimeout:
        return 'Connection timed out';
      case AppErrorCode.networkServerError:
        return 'Server error. Please try again later.';
      case AppErrorCode.authInvalidCredentials:
        return 'Invalid email or password';
      case AppErrorCode.authSessionExpired:
        return 'Session expired. Please sign in again.';
      case AppErrorCode.authUnauthorized:
        return 'You don\'t have permission to do this';
      case AppErrorCode.authUserNotFound:
        return 'Account not found';
      case AppErrorCode.dbReadError:
      case AppErrorCode.dbWriteError:
        return 'Database error. Please try again.';
      case AppErrorCode.dbNotFound:
        return 'Item not found';
      case AppErrorCode.dbConstraintViolation:
        return 'This action conflicts with existing data';
      case AppErrorCode.syncConflict:
        return 'Sync conflict detected';
      case AppErrorCode.syncFailed:
        return 'Sync failed. Changes saved locally.';
      case AppErrorCode.syncOffline:
        return 'Offline. Changes will sync when online.';
      case AppErrorCode.validationInvalidInput:
        return message;
      case AppErrorCode.validationMissingRequired:
        return 'Please fill in all required fields';
      case AppErrorCode.validationOutOfRange:
        return 'Value is out of acceptable range';
      case AppErrorCode.subscriptionRequired:
        return 'Pro subscription required';
      case AppErrorCode.subscriptionExpired:
        return 'Your subscription has expired';
      case AppErrorCode.subscriptionLimitReached:
        return 'You\'ve reached your plan limit';
      case AppErrorCode.cancelled:
        return 'Action cancelled';
      case AppErrorCode.permissionDenied:
        return 'Permission denied';
      case AppErrorCode.unknown:
        return message.isNotEmpty ? message : 'Something went wrong';
    }
  }

  /// Check if this error should be shown to user
  bool get shouldShowToUser => severity != AppErrorSeverity.silent;

  /// Check if this error is recoverable
  bool get isRecoverable => severity == AppErrorSeverity.recoverable;

  /// Log this error with consistent formatting
  void log() {
    if (kDebugMode) {
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('🔴 AppError: ${code.name}');
      debugPrint('   Message: $message');
      if (technicalDetails != null) {
        debugPrint('   Details: $technicalDetails');
      }
      debugPrint('   Severity: ${severity.name}');
      debugPrint('   Time: $timestamp');
      if (stackTrace != null) {
        debugPrint('   Stack: ${stackTrace.toString().split('\n').take(5).join('\n')}');
      }
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    }
  }

  @override
  String toString() => 'AppError($code): $message';
}

/// Extension to convert generic exceptions to AppError
extension ExceptionToAppError on Object {
  AppError toAppError({StackTrace? stackTrace}) {
    if (this is AppError) return this as AppError;
    
    final errorString = toString().toLowerCase();
    
    // Network errors
    if (errorString.contains('socketexception') ||
        errorString.contains('connection refused') ||
        errorString.contains('network is unreachable') ||
        errorString.contains('host lookup') ||
        errorString.contains('no address associated') ||
        errorString.contains('failed host lookup') ||
        errorString.contains('authretryablefetchexception')) {
      return AppError.network(cause: this, stackTrace: stackTrace);
    }
    
    // Timeout errors
    if (errorString.contains('timeout') ||
        errorString.contains('timed out')) {
      return AppError.timeout(cause: this, stackTrace: stackTrace);
    }
    
    // Auth errors
    if (errorString.contains('invalid login') ||
        errorString.contains('invalid credentials') ||
        errorString.contains('wrong password')) {
      return AppError.authFailed(cause: this, stackTrace: stackTrace);
    }
    
    // Session errors
    if (errorString.contains('session expired') ||
        errorString.contains('refresh_token_not_found') ||
        errorString.contains('jwt expired')) {
      return AppError.sessionExpired(cause: this, stackTrace: stackTrace);
    }
    
    // Default: unknown
    return AppError.unknown(
      message: 'An unexpected error occurred',
      cause: this,
      stackTrace: stackTrace,
    );
  }
}
