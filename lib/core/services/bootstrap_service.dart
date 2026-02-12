import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../logging/logger.dart';
import '../managers/app_manager.dart';
import '../providers/app_providers.dart';
import '../services/error_reporter.dart';
import '../../services/crash_reporting_service.dart';
import '../../services/stripe_service.dart';

/// BootstrapService handles the initialization of the application.
/// It sets up error reporting, logging, and core services before running the app.
class BootstrapService {
  static Future<void> run(Widget app, {List<Override> overrides = const []}) async {
    // Redirect Flutter errors to our reporter
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      errorReporter.reportFlutterError(details);
    };

    // Initialize Flutter binding
    WidgetsFlutterBinding.ensureInitialized();

    // Custom Error Widget for production (shows a clean error UI instead of gray screen)
    ErrorWidget.builder = (FlutterErrorDetails details) {
      if (kDebugMode) {
        return ErrorWidget(details.exception);
      }
      return const SizedBox.shrink(); // ErrorBoundary will catch and show better UI
    };

    // Initialize ErrorReporter
    try {
      await errorReporter.initialize();
      if (kDebugMode) debugPrint('✅ ErrorReporter initialized');
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ ErrorReporter initialization failed: $e');
    }

    // Set production log level
    if (kReleaseMode) {
      Logger.setGlobalLevel(LogLevel.info);
    }

    // Wrap app with Sentry for error tracking
    await SentryFlutter.init(
      (options) {
        // Sentry DSN for CashPilot error tracking
        options.dsn = kReleaseMode
            ? 'https://b26a6be0565221ad8a707d4bafea8ff3@o4510645425340416.ingest.de.sentry.io/4510645429338192'
            : ''; // Disable in debug mode
        options.environment = kReleaseMode ? 'production' : 'development';
        options.tracesSampleRate = 1.0;
        options.enableAutoSessionTracking = true;

        // Filter out noisy errors
        options.beforeSend = (event, hint) async {
          // Don't send errors in debug mode when DSN is empty
          if (!kReleaseMode || (options.dsn?.isEmpty ?? true)) {
            return null;
          }
          return event;
        };
      },
      appRunner: () => runZonedGuarded(
        () async {
          // Initialize app manager
          final sharedPreferences = await AppManager.instance.initialize();

          // Initialize Stripe (STUBBED)
          await stripeService.initialize();

          // Image cache tuning
          PaintingBinding.instance.imageCache.maximumSizeBytes = 100 * 1024 * 1024;
          PaintingBinding.instance.imageCache.maximumSize = 200;

          runApp(
            ProviderScope(
              overrides: [
                sharedPreferencesProvider.overrideWithValue(sharedPreferences),
                ...overrides,
              ],
              child: app,
            ),
          );
        },
        (error, stackTrace) {
          // Filter out noisy offline errors from logs and crash reporting
          final sError = error.toString();
          final isOffline = sError.contains('SocketException') || 
                           sError.contains('Failed host lookup') ||
                           sError.contains('Network is unreachable') ||
                           sError.contains('AuthRetryableFetchException'); // Supabase Auth retry noise

          if (isOffline) {
            if (kDebugMode) {
              debugPrint('⚠️ [Bootstrap] Suppressed offline error (expected): $error');
            }
            return; // Don't report to Crashlytics/Sentry or print full stack trace
          }

          // Report to both old and new error reporting systems
          try {
            crashReporter.reportError(error, stackTrace);
          } catch (_) {}

          try {
            errorReporter.reportException(error, stackTrace: stackTrace);
          } catch (_) {}

          if (kDebugMode) {
            debugPrint('❌ Uncaught error: $error');
            debugPrint(stackTrace.toString());
          }
        },
      ),
    );
  }
}
