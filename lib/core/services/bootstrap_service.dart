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
    // 🎯 CRITICAL: Everything must run in the same zone to prevent Zone Mismatch
    await runZonedGuarded(
      () async {
        // 1. Initialize Flutter binding first in this zone
        WidgetsFlutterBinding.ensureInitialized();

        // 2. Redirect Flutter errors to our reporter
        FlutterError.onError = (details) {
          FlutterError.presentError(details);
          errorReporter.reportFlutterError(details);
        };

        // 3. Set production log level
        if (kReleaseMode) {
          Logger.setGlobalLevel(LogLevel.info);
        }

        // 4. Initialize Sentry (without appRunner to stay in this zone)
        await SentryFlutter.init(
          (options) {
            options.dsn = kReleaseMode
                ? 'https://b26a6be0565221ad8a707d4bafea8ff3@o4510645425340416.ingest.de.sentry.io/4510645429338192'
                : '';
            options.environment = kReleaseMode ? 'production' : 'development';
            options.tracesSampleRate = 1.0;
            options.enableAutoSessionTracking = true;
            options.beforeSend = (event, hint) async {
              if (!kReleaseMode || (options.dsn?.isEmpty ?? true)) return null;
              return event;
            };
          },
        );

        // 5. Initialize ErrorReporter
        try {
          await errorReporter.initialize();
          if (kDebugMode) debugPrint('✅ ErrorReporter initialized');
        } catch (e) {
          if (kDebugMode) debugPrint('⚠️ ErrorReporter initialization failed: $e');
        }

        // 6. Custom Error Widget
        ErrorWidget.builder = (FlutterErrorDetails details) {
          if (kDebugMode) return ErrorWidget(details.exception);
          return const SizedBox.shrink();
        };

        // 7. Initialize Core Services (AppManager)
        final sharedPreferences = await AppManager.instance.initialize();

        // 8. Initialize Stripe (STUBBED)
        await stripeService.initialize();

        // 9. Image cache tuning
        PaintingBinding.instance.imageCache.maximumSizeBytes = 100 * 1024 * 1024;
        PaintingBinding.instance.imageCache.maximumSize = 200;

        // 10. Run the App
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
        // Suppress offline errors
        final sError = error.toString();
        final isOffline = sError.contains('SocketException') || 
                         sError.contains('Failed host lookup') ||
                         sError.contains('Network is unreachable') ||
                         sError.contains('AuthRetryableFetchException');

        if (isOffline) {
          if (kDebugMode) debugPrint('⚠️ [Bootstrap] Suppressed offline error: $error');
          return;
        }

        try {
          crashReporter.reportError(error, stackTrace);
          errorReporter.reportException(error, stackTrace: stackTrace);
        } catch (_) {}

        if (kDebugMode) {
          debugPrint('❌ Uncaught error: $error');
          debugPrint(stackTrace.toString());
        }
      },
    );
  }
}
