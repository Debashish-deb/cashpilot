/// Error handler mixin for consistent error handling across the app
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/error_provider.dart';

/// Mixin for handling async operations with consistent error handling
mixin ErrorHandlerMixin {
  // ---------------------------------------------------------------------------
  // CORE ERROR HANDLING
  // ---------------------------------------------------------------------------

  Future<T?> handleAsync<T>(
    Ref ref,
    Future<T> Function() operation, {
    String? errorMessage,
    ErrorSeverity severity = ErrorSeverity.error,
    bool showToUser = true,
  }) async {
    try {
      return await operation();
    } catch (e, stackTrace) {
      _handleException(
        ref,
        e,
        stackTrace,
        errorMessage: errorMessage,
        severity: severity,
        showToUser: showToUser,
      );
      return null;
    }
  }

  Future<Result<T>> handleAsyncResult<T>(
    Ref ref,
    Future<T> Function() operation, {
    String? errorMessage,
    bool showToUser = true,
  }) async {
    try {
      final result = await operation();
      return Result.success(result);
    } catch (e, stackTrace) {
      final message = _resolveMessage(e, errorMessage);
      _handleException(
        ref,
        e,
        stackTrace,
        errorMessage: errorMessage,
        severity: ErrorSeverity.error,
        showToUser: showToUser,
      );
      return Result.failure(message);
    }
  }

  // ---------------------------------------------------------------------------
  // INTERNAL HELPERS (non-breaking)
  // ---------------------------------------------------------------------------

  void _handleException(
    Ref ref,
    Object error,
    StackTrace stackTrace, {
    String? errorMessage,
    required ErrorSeverity severity,
    required bool showToUser,
  }) {
    final message = _resolveMessage(error, errorMessage);
    final details = _extractDetails(error);

    if (showToUser) {
      ref.addError(
        message,
        severity: severity,
        details: details,
        stackTrace: stackTrace,
      );
    }

    if (kDebugMode) {
      debugPrint('[ErrorHandler] $message');
      if (details != null) {
        debugPrint('Details: $details');
      }
      debugPrint(stackTrace.toString());
    }
  }

  String _resolveMessage(Object error, String? override) {
    if (override != null) return override;

    if (error is AuthException) {
      return 'Authentication failed';
    } else if (error is PostgrestException) {
      return 'Database operation failed';
    } else {
      return 'An unexpected error occurred';
    }
  }

  String? _extractDetails(Object error) {
    if (error is AuthException) {
      return error.message;
    }
    if (error is PostgrestException) {
      return error.message;
    }
    return error.toString();
  }

  // ---------------------------------------------------------------------------
  // SAFE UTILITIES
  // ---------------------------------------------------------------------------

  /// Safe division to prevent divide-by-zero, NaN, or Infinity
  double safeDivide(
    num numerator,
    num denominator, {
    double fallback = 0.0,
  }) {
    if (numerator.isNaN ||
        numerator.isInfinite ||
        denominator == 0 ||
        denominator.isNaN ||
        denominator.isInfinite) {
      return fallback;
    }

    final result = numerator / denominator;
    return result.isNaN || result.isInfinite ? fallback : result;
  }

  /// Safe percentage calculation
  double safePercentage(
    num part,
    num total, {
    double fallback = 0.0,
  }) {
    return safeDivide(part * 100, total, fallback: fallback);
  }

  /// Safe list access
  T? safeListAccess<T>(List<T>? list, int index) {
    if (list == null || index < 0 || index >= list.length) {
      return null;
    }
    return list[index];
  }

  /// Safe map access
  V? safeMapAccess<K, V>(Map<K, V>? map, K key) {
    if (map == null) return null;
    return map[key];
  }
}
