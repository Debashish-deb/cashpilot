import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:flutter_stripe/flutter_stripe.dart' hide Card;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:cashpilot/features/ml/services/confidence_optimizer.dart';

// import '../../core/config/stripe_config.dart';
import '../../services/auth_service.dart';
import '../../services/encryption_service.dart';
import '../../services/crash_reporting_service.dart';
import '../../services/notification_service.dart';
import '../../services/subscription_service.dart';
import 'analytics_manager.dart';
import '../../features/ml/services/model_evaluation_service.dart';

/// AppManager
/// Centralized application bootstrapper.
/// Ensures deterministic, fault-tolerant initialization of all core services.
///
/// Design goals:
/// - Fast startup via parallel initialization
/// - Explicit failure boundaries (non-fatal vs fatal)
/// - Predictable lifecycle for analytics, auth, payments, and storage
class AppManager {
  static final AppManager instance = AppManager._internal();

  factory AppManager() => instance;

  AppManager._internal();

  bool _initialized = false;
  bool get isInitialized => _initialized;

  /// Initializes all core application services.
  ///
  /// Returns a [SharedPreferences] instance so it can be injected
  /// into providers at app startup.
  ///
  /// Initialization strategy:
  /// 1. Critical synchronous setup
  /// 2. Parallel initialization of independent services
  /// 3. Graceful degradation for non-critical failures
  Future<SharedPreferences> initialize() async {
    if (_initialized) {
      return SharedPreferences.getInstance();
    }

    try {
      // Binding is now initialized in BootstrapService.run zone

      // PHASE 1: Critical synchronous setup

      _setupErrorHandling();

      // Stripe key setup (STUBBED/REMOVED)
      // Stripe.publishableKey = StripeConfig.publishableKey;

      // PHASE 2: Parallel initialization

      final results = await Future.wait(
        [
          // Orientation lock (fast, synchronous bridge)
          SystemChrome.setPreferredOrientations([
            DeviceOrientation.portraitUp,
            DeviceOrientation.portraitDown,
          ]),

          // Encryption (secure storage / key material)
          _initEncryption(),

          // Authentication (Supabase / session restore)
          _initAuth(),

          // Local persistence
          SharedPreferences.getInstance(),

          // Push & local notifications
          _initNotifications(),
          
          // Analytics deferred to post-frame in main.dart for faster startup
        ],
        eagerError: false,
      );

      final prefs = results[3] as SharedPreferences;

      // PHASE 3: Post-auth initialization (depends on auth)
      
      // Initialize subscription service after auth is ready
      await _initSubscription();

      // PHASE 4: ML Services (optional, non-blocking)
      // Initialize ML services for production-grade learning loops
      _initMLServices(); // Fire and forget - don't block startup
      _initAnalytics(); // Fire and forget - analytics initialization

      _initialized = true;
      debugPrint('[AppManager] Initialized successfully');

      return prefs;
    } catch (e, stack) {
      debugPrint('[AppManager] Initialization failed: $e');
      crashReporter.reportError(e, stack);
      rethrow;
    }
  }

  // SERVICE INITIALIZERS (FAULT-TOLERANT)

  Future<void> _initEncryption() async {
    try {
      await encryptionService.initialize();
    } catch (e) {
      debugPrint('[AppManager] Encryption initialization failed: $e');
      // Non-fatal: app can continue without encrypted storage
    }
  }

  Future<void> _initAuth() async {
    try {
      await authService.initialize();
    } catch (e) {
      debugPrint('[AppManager] Auth initialization failed: $e');
      // Non-fatal: user can re-authenticate later
    }
  }

  Future<void> _initNotifications() async {
    try {
      await notificationService.initialize();
    } catch (e) {
      debugPrint('[AppManager] Notification initialization failed: $e');
      // Non-fatal: notifications are optional
    }
  }

  Future<void> _initAnalytics() async {
    try {
      await analyticsManager.initialize();
    } catch (e) {
      debugPrint('[AppManager] Analytics initialization failed: $e');
      // Non-fatal: events can be dropped safely
    }
  }

  Future<void> _initSubscription() async {
    try {
      await subscriptionService.initialize();
      debugPrint('[AppManager] Subscription service initialized');
    } catch (e) {
      debugPrint('[AppManager] Subscription initialization failed: $e');
      // Non-fatal: defaults to free tier
    }
  }

  /// Initialize ML services for production-grade learning
  /// Non-blocking, fire-and-forget initialization
  void _initMLServices() {
    Future(() async {
      try {
        // ML services are available via Riverpod - just run health check
        debugPrint('[AppManager] ML services ready');
        _runMLHealthCheck();
        
        // Start weekly auto-optimization scheduler
        _scheduleWeeklyOptimization();
      } catch (e) {
        debugPrint('[AppManager] ML services initialization failed: $e');
      }
    });
  }

  /// Run periodic ML health check (weekly)
  void _runMLHealthCheck() {
    Future(() async {
      try {
        // Create service instances
        final modelEval = ModelEvaluationService();
        
        // Evaluate receipt model performance
        final receiptPerf = await modelEval.evaluateReceiptModel('receipt_v1.0');
        
        if (receiptPerf.needsImprovement) {
          debugPrint('[ML] Receipt model needs improvement: ${receiptPerf.acceptanceRate}');
        }

        // Optimize confidence thresholds if needed
        if (receiptPerf.totalScans >= 100) {
          final optimized = await ConfidenceOptimizer.optimizeThresholds(
            getLearningEvents: () async {
              // Get learning events from Supabase
              final response = await Supabase.instance.client
                  .from('receipt_learning_events')
                  .select()
                  .eq('model_version', 'receipt_v1.0');
              return response;
            },
            modelVersion: 'receipt_v1.0',
          );
          
          debugPrint('[ML] Confidence thresholds: high=${optimized.highConfidence}, min=${optimized.minAcceptable}');
        }
      } catch (e) {
        debugPrint('[ML] Health check failed: $e');
      }
    });
  }

  // =========================================================================
  // ML AUTO-OPTIMIZATION (Phase 2)
  // =========================================================================

  /// Schedule weekly optimization to run every Sunday at 2 AM
  void _scheduleWeeklyOptimization() {
    Timer.periodic(const Duration(hours: 24), (timer) async {
      final now = DateTime.now();
      if (now.weekday == DateTime.sunday && now.hour == 2) {
        await _runAutomaticOptimization();
      }
    });
    debugPrint('[ML] Weekly optimization scheduler started');
  }

  /// Run automatic optimization of confidence thresholds
  Future<void> _runAutomaticOptimization() async {
    try {
      debugPrint('[ML] Running automatic optimization...');
      
      final modelEval = ModelEvaluationService();
      final perf = await modelEval.evaluateReceiptModel('receipt_v1.0');
      
      // Only optimize if we have enough data
      if (perf.totalScans < 100) {
        debugPrint('[ML] Not enough data for optimization (${perf.totalScans} < 100)');
        return;
      }
      
      // Fetch learning events from Supabase
      final events = await _fetchLearningEvents('receipt_v1.0');
      
      // Calculate optimal thresholds
      final thresholds = await ConfidenceOptimizer.optimizeThresholds(
        getLearningEvents: () async => events,
        modelVersion: 'receipt_v1.0',
      );
      
      // Save to Supabase ml_config table
      await _saveOptimizedThresholds(thresholds);
      
      debugPrint('[ML] ✅ Optimization complete: high=${thresholds.highConfidence.toStringAsFixed(2)}, min=${thresholds.minAcceptable.toStringAsFixed(2)}');
      
    } catch (e, stackTrace) {
      debugPrint('[ML] ❌ Optimization failed: $e');
      debugPrint('[ML] Stack trace: $stackTrace');
    }
  }

  /// Fetch recent learning events from Supabase
  Future<List<Map<String, dynamic>>> _fetchLearningEvents(String modelVersion) async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('receipt_learning_events')
          .select()
          .eq('model_version', modelVersion)
          .order('timestamp', ascending: false)
          .limit(500);
      
      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('[ML] Failed to fetch learning events: $e');
      return [];
    }
  }

  /// Save optimized thresholds to Supabase ml_config table
  Future<void> _saveOptimizedThresholds(ConfidenceThresholds thresholds) async {
    try {
      final supabase = Supabase.instance.client;
      
      // Upsert high confidence threshold
      await supabase.from('ml_config').upsert({
        'config_key': 'high_confidence_threshold',
        'config_value': {'value': thresholds.highConfidence},
        'model_version': 'receipt_v1.0',
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'config_key');
      
      // Upsert minimum acceptable threshold
      await supabase.from('ml_config').upsert({
        'config_key': 'min_acceptable_threshold',
        'config_value': {'value': thresholds.minAcceptable},
        'model_version': 'receipt_v1.0',
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'config_key');
      
      debugPrint('[ML] Thresholds saved to ml_config table');
    } catch (e) {
      debugPrint('[ML] Failed to save thresholds: $e');
      rethrow;
    }
  }

  // ERROR HANDLING

  void _setupErrorHandling() {
    // Flutter framework errors
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      crashReporter.reportFlutterError(details);
    };

    // Uncaught async / platform errors
    PlatformDispatcher.instance.onError = (error, stack) {
      crashReporter.reportError(error, stack);
      return true; // prevent crash
    };

    // Crash reporter synchronous bootstrap
    crashReporter.initialize();
  }
}
