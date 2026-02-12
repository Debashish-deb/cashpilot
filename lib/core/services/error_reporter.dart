/// Error Reporter Service
/// Centralized error reporting with Crashlytics and Sentry integration
library;

import 'package:flutter/foundation.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import '../errors/app_error.dart';

/// Global error reporter instance
final errorReporter = ErrorReporter._();

/// ErrorReporter - Centralized error reporting service
class ErrorReporter {
  ErrorReporter._();

  bool _isInitialized = false;
  bool _crashlyticsEnabled = false;
  bool _sentryEnabled = false;

  /// Initialize error reporting services
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Try to initialize Crashlytics (only if Firebase is set up)
      if (kReleaseMode) {
        try {
          _crashlyticsEnabled = true;
          
          await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
          
          // Pass Flutter errors to Crashlytics
          FlutterError.onError = (errorDetails) {
            FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
          };
          
          // Pass platform errors to Crashlytics
          PlatformDispatcher.instance.onError = (error, stack) {
            FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
            return true;
          };

          debugPrint('[ErrorReporter] ✅ Crashlytics initialized');
        } catch (e) {
          _crashlyticsEnabled = false;
          debugPrint('[ErrorReporter] ℹ️ Crashlytics not available (using Sentry only): $e');
        }
      }

      // Sentry is initialized in main.dart via SentryFlutter.init()
      if (kReleaseMode) {
        _sentryEnabled = true;
        debugPrint('[ErrorReporter] ✅ Sentry enabled');
      }

      _isInitialized = true;
      debugPrint('[ErrorReporter] ✅ Initialized (Crashlytics: $_crashlyticsEnabled, Sentry: $_sentryEnabled)');
    } catch (e) {
      debugPrint('[ErrorReporter] ⚠️ Failed to initialize: $e');
    }
  }

  /// Report an error
  Future<void> report(
    AppError error, {
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) async {
    final effectiveStackTrace = stackTrace ?? error.stackTrace ?? StackTrace.current;

    // Console logging (debug mode or critical errors)
    if (kDebugMode || error.severity == AppErrorSeverity.critical) {
      error.log();
    }

    // Crashlytics reporting (production only)
    if (_crashlyticsEnabled && kReleaseMode) {
      try {
        await FirebaseCrashlytics.instance.recordError(
          error,
          effectiveStackTrace,
          reason: error.message,
          information: [
            'Error Code: ${error.code}',
            'Severity: ${error.severity.name}',
            if (context != null) 'Context: $context',
            if (error.technicalDetails != null) 'Details: ${error.technicalDetails}',
          ],
          fatal: error.severity == AppErrorSeverity.critical,
        );

        // Set custom keys
        await FirebaseCrashlytics.instance.setCustomKey('error_code', error.code.name);
        await FirebaseCrashlytics.instance.setCustomKey('severity', error.severity.name);
        
        if (context != null) {
          for (final entry in context.entries) {
            await FirebaseCrashlytics.instance.setCustomKey(
              'context_${entry.key}',
              entry.value.toString(),
            );
          }
        }
      } catch (e) {
        debugPrint('[ErrorReporter] Failed to report to Crashlytics: $e');
      }
    }

    // Sentry reporting (production only)
    if (_sentryEnabled && kReleaseMode) {
      try {
        await Sentry.captureException(
          error,
          stackTrace: effectiveStackTrace,
          withScope: (scope) {
            scope.setTag('error_code', error.code.name);
            scope.setTag('severity', error.severity.name);
            scope.level = _sentryLevel(error.severity);
            
            if (context != null) {
              scope.setContexts('custom', context);
            }
            
            if (error.technicalDetails != null) {
              scope.setExtra('technical_details', error.technicalDetails!);
            }
          },
        );
      } catch (e) {
        debugPrint('[ErrorReporter] Failed to report to Sentry: $e');
      }
    }
  }

  /// Report a raw exception (converts to AppError)
  Future<void> reportException(
    Object exception, {
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) async {
    final error = _convertToAppError(exception, stackTrace);
    await report(error, stackTrace: stackTrace, context: context);
  }

  /// Report a Flutter specific error
  Future<void> reportFlutterError(FlutterErrorDetails details) async {
    if (kReleaseMode) {
       if (_crashlyticsEnabled) {
         await FirebaseCrashlytics.instance.recordFlutterFatalError(details);
       }
       if (_sentryEnabled) {
         await Sentry.captureException(details.exception, stackTrace: details.stack);
       }
    }
    
    // Convert to AppError for detailed reporting if needed
    final error = AppError.logic(
      cause: details.exception,
      message: details.summary.toString(),
      stackTrace: details.stack,
    );
    await report(error, stackTrace: details.stack);
  }

  /// Convert exception to AppError
  AppError _convertToAppError(Object exception, StackTrace? stackTrace) {
    if (exception is AppError) return exception;

    final errorString = exception.toString().toLowerCase();

    // Network errors
    if (errorString.contains('socket') ||
        errorString.contains('network') ||
        errorString.contains('connection')) {
      return AppError.network(cause: exception, stackTrace: stackTrace);
    }

    // Timeout errors
    if (errorString.contains('timeout')) {
      return AppError.timeout(cause: exception, stackTrace: stackTrace);
    }

    // Auth errors
    if (errorString.contains('auth') ||
        errorString.contains('unauthorized') ||
        errorString.contains('session')) {
      return AppError.authFailed(cause: exception, stackTrace: stackTrace);
    }

    // Default: unknown error
    return AppError.unknown(cause: exception, stackTrace: stackTrace);
  }

  /// Set user context for error reports
  Future<void> setUser(String userId, {String? email, String? name}) async {
    if (_crashlyticsEnabled) {
      await FirebaseCrashlytics.instance.setUserIdentifier(userId);
    }

    if (_sentryEnabled) {
      await Sentry.configureScope((scope) {
        scope.setUser(SentryUser(id: userId, email: email, username: name));
      });
    }
  }

  /// Clear user context
  Future<void> clearUser() async {
    if (_crashlyticsEnabled) {
      await FirebaseCrashlytics.instance.setUserIdentifier('');
    }

    if (_sentryEnabled) {
      await Sentry.configureScope((scope) {
        scope.setUser(null);
      });
    }
  }

  /// Add breadcrumb (navigation trail)
  void addBreadcrumb(String message, {String? category, Map<String, dynamic>? data}) {
    if (_sentryEnabled && kReleaseMode) {
      Sentry.addBreadcrumb(Breadcrumb(
        message: message,
        category: category,
        data: data,
      ));
    }
  }

  /// Convert AppErrorSeverity to Sentry level
  SentryLevel _sentryLevel(AppErrorSeverity severity) {
    return switch (severity) {
      AppErrorSeverity.critical => SentryLevel.fatal,
      AppErrorSeverity.actionRequired => SentryLevel.error,
      AppErrorSeverity.recoverable => SentryLevel.warning,
      AppErrorSeverity.silent => SentryLevel.info,
    };
  }
}
