import 'dart:async';

import 'package:cashpilot/services/subscription_service.dart' show subscriptionService;
import 'package:flutter/foundation.dart' show debugPrint, defaultTargetPlatform, kDebugMode, kReleaseMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cashpilot/core/services/bootstrap_service.dart';
import 'package:cashpilot/services/auth_service.dart';
import 'package:cashpilot/services/sync_engine.dart';
import 'package:cashpilot/services/encryption_service.dart';
import 'package:cashpilot/services/crash_reporting_service.dart';
import 'package:cashpilot/services/notification_service.dart';
import 'package:cashpilot/core/managers/analytics_manager.dart';
import 'package:cashpilot/core/managers/network_manager.dart';

import 'l10n/app_localizations.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/accent_colors.dart';
import 'core/providers/app_providers.dart';
import 'core/router/app_router.dart';
import 'features/analytics/providers/analytics_providers.dart';

import 'ui/widgets/lock_screen.dart';
import 'ui/widgets/security/privacy_guard.dart';
import 'ui/widgets/common/error_boundary.dart';

// ===============================================================
// APP ENTRY
// ===============================================================

Future<void> main() async {
  await BootstrapService.run(const CashPilotApp());
}

// APP ROOT

class CashPilotApp extends ConsumerStatefulWidget {
  const CashPilotApp({super.key});

  @override
  ConsumerState<CashPilotApp> createState() => _CashPilotAppState();
}

class _CashPilotAppState extends ConsumerState<CashPilotApp>
    with WidgetsBindingObserver {

  StreamSubscription<String?>? _notificationSubscription;
  bool _servicesInitialized = false;

  /// Debounce resume-triggered sync
  DateTime? _lastResumeSync;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _notificationSubscription =
        notificationService.payloadStream.listen((payload) {
      if (payload != null && mounted) {
        if (kDebugMode) debugPrint('🔔 Navigating to payload: $payload');
        ref.read(routerProvider).push(payload);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeServicesDeferred();
    });
  }

  // DEFERRED INITIALIZATION

  Future<void> _initializeServicesDeferred() async {
    if (_servicesInitialized || !mounted) return;
    _servicesInitialized = true;

    // 🎯 Analytics Manager (moved from AppManager for faster startup)
    try {
      await analyticsManager.initialize();
      if (kDebugMode) debugPrint('[Main] Analytics initialized');
    } catch (e) {
      if (kDebugMode) debugPrint('[Main] Analytics init failed: $e');
    }

    // (Subscription service already initialized in AppManager.initialize())

    //  Network manager
    try {
      ref.read(networkManagerProvider).initialize();
    } catch (e) {
      if (kDebugMode) debugPrint('[Main] Network init failed: $e');
    }

    //  Sync engine
    try {
      ref.read(syncEngineProvider).initialize();
    } catch (e) {
      if (kDebugMode) debugPrint('[Main] Sync engine init failed: $e');
    }

    // 🔒 SECURITY: Configure Logout Wipe
    // Wires up the "Strict Data Isolation" contract
    try {
      final db = ref.read(databaseProvider);
      final prefs = ref.read(sharedPreferencesProvider);
      
      AuthService().onDataWipe = () async {
        if (kDebugMode) debugPrint('🔒 [Security] Executing Strict Data Wipe...');
        
        // 1. Wipe Database (Business Data)
        await db.wipeAllData();
        
        // 2. Wipe Encryption Keys (Crypto-shredding)
        await encryptionService.deleteAllKeys();
        
        // 3. Wipe Preferences (Session, Settings, Onboarding)
        await prefs.clear();
        
        if (kDebugMode) debugPrint('🔒 [Security] Wipe Complete. Device is clean.');
      };
    } catch (e) {
      if (kDebugMode) debugPrint('[Main] Security wipe configuration failed: $e');
    }

    // 4️⃣ Initial sync with 100ms delay (prioritize UI rendering)
    Future.delayed(const Duration(milliseconds: 100), () async {
      if (!mounted) return;
      
      try {
        final network = ref.read(networkManagerProvider);
        final authService = AuthService();

        if (authService.isAuthenticated && network.isOnline) {
          final hasProfile = await _checkProfileExists();
          if (hasProfile) {
            if (kDebugMode) {
              debugPrint('[Main] Authenticated + profile exists → initial sync');
            }
            ref.read(syncEngineProvider).performSync().then((_) {
              // Sync completed successfully
            }).catchError((e) {
              if (kDebugMode) debugPrint('[Main] Initial sync failed: $e');
              return null; // Prevent unhandled error
            });
          } else {
            if (kDebugMode) {
              debugPrint('[Main] Profile not ready, sync deferred');
            }
          }
        }
      } catch (e) {
        if (kDebugMode) debugPrint('[Main] Initial sync logic error: $e');
      }
    });


    try {
      final db = ref.read(databaseProvider);
      analyticsManager.onAppStarted(db);
    } catch (e) {
      if (kDebugMode) debugPrint('[Main] Analytics app start failed: $e');
    }

 
    try {
      ref.read(insightEngineProvider).initialize();
    } catch (e) {
      if (kDebugMode) debugPrint('[Main] Insight engine init failed: $e');
    }

    if (kDebugMode) debugPrint('[Main] Deferred services initialized');
  }

  /// Check if user profile exists before sync
  Future<bool> _checkProfileExists() async {
    try {
      final authService = AuthService();
      final userId = authService.currentUser?.id;
      if (userId == null) return false;

      final response = await authService.client
          .from('profiles')
          .select('id')
          .eq('id', userId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      if (kDebugMode) debugPrint('[Main] Profile check failed: $e');
      return false;
    }
  }

  // ===============================================================
  // LIFECYCLE
  // ===============================================================

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _notificationSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // NOTE: Auto-lock is handled by LockScreen widget's WidgetsBindingObserver
    // Do NOT call authManager.handleAppLifecycleChange here to avoid conflicts

    if (state == AppLifecycleState.resumed) {
      final now = DateTime.now();
      if (_lastResumeSync == null ||
          now.difference(_lastResumeSync!) > const Duration(seconds: 10)) {
        _lastResumeSync = now;

        if (kDebugMode) debugPrint('🔄 App Resumed → Sync & Subscription check');

        // Refresh core services
        ref.read(networkManagerProvider).initialize();
        ref.read(syncEngineProvider).performSync();
        
        // Refresh subscription tier
        if (subscriptionService.isInitialized) {
          try {
            subscriptionService.sync();
            subscriptionService.checkExpirations();
          } catch (e) {
            if (kDebugMode) debugPrint('⚠️ Resume subscription check failed: $e');
          }
        }
      } else {
        if (kDebugMode) debugPrint('⏭️ Resume sync skipped (debounced)');
      }
    }

    if (state == AppLifecycleState.paused) {
      if (kDebugMode) debugPrint('⏸️ App paused');
    }
  }

  // ===============================================================
  // UI ROOT
  // ===============================================================

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final router = ref.watch(routerProvider);
    final language = ref.watch(languageProvider);
    final accentConfig = ref.watch(accentConfigProvider);

    final userId = ref.watch(currentUserIdProvider);
    if (userId != null) {
      try {
        crashReporter.setUserId(userId);
      } catch (_) {}
    }

    final flutterThemeMode =
        themeMode == AppThemeMode.dark ? ThemeMode.dark : ThemeMode.light;

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,

      theme: AppTheme.lightTheme(accentConfig.primary),
      darkTheme: AppTheme.darkTheme(accentConfig.primary),
      themeMode: flutterThemeMode,

      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: Locale(language.code),

      themeAnimationDuration: const Duration(milliseconds: 400),
      themeAnimationCurve: Curves.easeInOutCubic,

      routerConfig: router,

      scrollBehavior: const _AppScrollBehavior(),


      builder: (context, child) {
        return ErrorBoundary(
          child: PrivacyGuard(
            child: LockScreen(
              child: MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(
                    MediaQuery.of(context)
                        .textScaler
                        .scale(1.0)
                        .clamp(0.85, 1.3),
                  ),
                ),
                child: child ?? const SizedBox.shrink(),
              ),
            ),
          ),
        );
      },
    );
  }
}


// ===============================================================
// PLATFORM-CORRECT SCROLL BEHAVIOR
// ===============================================================

class _AppScrollBehavior extends MaterialScrollBehavior {
  const _AppScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return defaultTargetPlatform == TargetPlatform.iOS
        ? const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          )
        : const ClampingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          );
  }

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child; // Disable Android glow
  }
}
