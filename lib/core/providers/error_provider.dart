/// Centralized error management for the application
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Error severity levels
enum ErrorSeverity {
  info,
  warning,
  error,
  critical,
}

/// Application error model
class AppError {
  final String message;
  final String? details;
  final ErrorSeverity severity;
  final DateTime timestamp;
  final String? stackTrace;

  /// Internal identity token (non-breaking)
  final String _id = UniqueKey().toString();

  AppError({
    required this.message,
    this.details,
    required this.severity,
    DateTime? timestamp,
    this.stackTrace,
  }) : timestamp = timestamp ?? DateTime.now();

  /// User-friendly message based on severity
  String get userMessage {
    switch (severity) {
      case ErrorSeverity.info:
        return message;
      case ErrorSeverity.warning:
        return '⚠️ $message';
      case ErrorSeverity.error:
        return '❌ $message';
      case ErrorSeverity.critical:
        return '🚨 Critical: $message';
    }
  }

  @override
  String toString() =>
      '[$severity] $message${details != null ? ': $details' : ''}';

  // ------------------------------------------------------------
  // Equality (non-breaking, required for safe removal)
  // ------------------------------------------------------------

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppError && runtimeType == other.runtimeType && _id == other._id;

  @override
  int get hashCode => _id.hashCode;
}

/// Error state notifier
class ErrorNotifier extends StateNotifier<List<AppError>> {
  ErrorNotifier() : super([]);

  static const int _maxErrors = 100;

  /// Add a new error
  void addError(
    String message, {
    ErrorSeverity severity = ErrorSeverity.error,
    String? details,
    StackTrace? stackTrace,
  }) {
    final error = AppError(
      message: message,
      details: details,
      severity: severity,
      stackTrace: stackTrace?.toString(),
    );

    // Soft cap to prevent unbounded growth
    final nextState = [...state, error];
    if (nextState.length > _maxErrors) {
      nextState.removeAt(0);
    }

    state = nextState;

    // Log to console in debug mode
    if (kDebugMode) {
      debugPrint('[AppError] $error');
      if (stackTrace != null &&
          severity == ErrorSeverity.critical) {
        debugPrint(stackTrace.toString());
      }
    }

    // Auto-clear info messages
    if (severity == ErrorSeverity.info) {
      Future.delayed(const Duration(seconds: 5), () {
        if (!mounted) return;
        removeError(error);
      });
    }
  }

  /// Remove a specific error
  void removeError(AppError error) {
    state = state.where((e) => e != error).toList();
  }

  /// Clear all errors
  void clearErrors() {
    state = [];
  }

  /// Clear errors of a specific severity
  void clearBySeverity(ErrorSeverity severity) {
    state = state.where((e) => e.severity != severity).toList();
  }

  /// Get errors by severity
  List<AppError> getBySeverity(ErrorSeverity severity) {
    return state.where((e) => e.severity == severity).toList();
  }

  /// Check if there are any critical errors
  bool get hasCriticalErrors =>
      state.any((e) => e.severity == ErrorSeverity.critical);
}

/// Global error provider
final errorProvider =
    StateNotifierProvider<ErrorNotifier, List<AppError>>((ref) {
  return ErrorNotifier();
});

/// Helper to add errors from anywhere
extension ErrorProviderRef on Ref {
  void addError(
    String message, {
    ErrorSeverity severity = ErrorSeverity.error,
    String? details,
    StackTrace? stackTrace,
  }) {
    read(errorProvider.notifier).addError(
      message,
      severity: severity,
      details: details,
      stackTrace: stackTrace,
    );
  }
}

/// Result type for operations that can fail
class Result<T> {
  final T? data;
  final String? error;
  final bool isSuccess;

  Result.success(this.data)
      : error = null,
        isSuccess = true;

  Result.failure(this.error)
      : data = null,
        isSuccess = false;

  /// Execute a callback if successful
  Result<R> then<R>(R Function(T data) onSuccess) {
    if (isSuccess && data != null) {
      try {
        return Result.success(onSuccess(data as T));
      } catch (e, stack) {
        if (kDebugMode) {
          debugPrint('[Result] Transformation error: $e');
          debugPrint(stack.toString());
        }
        return Result.failure(e.toString());
      }
    }
    return Result.failure(error ?? 'Operation failed');
  }

  /// Execute a callback if failed
  void onError(void Function(String error) callback) {
    if (!isSuccess && error != null) {
      callback(error!);
    }
  }
}
