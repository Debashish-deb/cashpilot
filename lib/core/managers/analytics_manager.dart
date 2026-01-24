/// Analytics Manager
/// High-level orchestrator for application intelligence and retention logic.
///
/// Responsibilities:
/// 1. Initialize tracking + insight engines
/// 2. Run lifecycle-aware safety checks (EOM, retention)
/// 3. Coordinate insight refresh triggers
/// 4. Emit analytics + notifications safely
/// 5. Bridge to FinancialIntelligenceEngine for ML/analytics integration
library;

import 'dart:async';
import 'dart:ui' show Locale;

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/analytics_tracking_service.dart';
import '../../features/analytics/services/insight_engine.dart';
import '../../services/notification_service.dart';
import '../../data/drift/app_database.dart';
import '../engines/financial_intelligence_engine.dart';
import '../engines/models/intelligence_models.dart';
import 'package:cashpilot/l10n/app_localizations.dart';

class AnalyticsManager {
  static final AnalyticsManager _instance = AnalyticsManager._internal();
  factory AnalyticsManager() => _instance;
  AnalyticsManager._internal();

  bool _initialized = false;
  bool _startupChecksRunning = false;

  AppDatabase? _db;
  
  /// Financial Intelligence Engine connection
  final FinancialIntelligenceEngine _intelligenceEngine = FinancialIntelligenceEngine();

  /// Initialize analytics foundation (no DB required)
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      debugPrint('[AnalyticsManager] Initializing core services');

      await analyticsService.initialize();
      await insightEngine.initialize();

      _initialized = true;
      debugPrint('[AnalyticsManager] Ready');
    } catch (e, stack) {
      debugPrint('[AnalyticsManager] Initialization failed');
      debugPrint('$e');
      debugPrintStack(stackTrace: stack);
      // Non-fatal: analytics must NEVER block the app
    }
  }

  /// Called once UI + database are ready
  Future<void> onAppStarted(AppDatabase db) async {
    _db = db;

    if (_startupChecksRunning) return;
    _startupChecksRunning = true;

    // Fire-and-forget background safety checks
    unawaited(_runStartupChecks());
  }

  // STARTUP CHECKS

  Future<void> _runStartupChecks() async {
    try {
      // Allow app to settle (navigation, first frame, etc.)
      await Future.delayed(const Duration(seconds: 3));

      await _checkEndOfMonthStatus();
    } catch (e, stack) {
      debugPrint('[AnalyticsManager] Startup checks error');
      debugPrint('$e');
      debugPrintStack(stackTrace: stack);
    } finally {
      _startupChecksRunning = false;
    }
  }

  // END-OF-MONTH SAFETY CHECK

  /// End-of-Month Safety Check
  ///
  /// Guarantees:
  /// - Runs at most once per month per user
  /// - Never blocks UI
  /// - Never crashes app
  /// - Emits analytics only after success
  Future<void> _checkEndOfMonthStatus() async {
    if (_db == null) return;

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    final now = DateTime.now();
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0).day;

    // Engage only in final 5 days of month
    if (now.day < lastDayOfMonth - 5) return;

    final prefs = await SharedPreferences.getInstance();
    final checkKey = 'eom_check_${userId}_${now.year}_${now.month}';

    if (prefs.getBool(checkKey) == true) {
      debugPrint('[AnalyticsManager] EOM check already completed for this month');
      return;
    }

    debugPrint('[AnalyticsManager] Running EOM analysis');

    final budgets = await _db!.getActiveBudgets(userId);
    if (budgets.isEmpty) {
      await prefs.setBool(checkKey, true);
      return;
    }

    int overBudgetCount = 0;
    int onTrackCount = 0;

    for (final budget in budgets) {
      final limit = budget.totalLimit;
      if (limit == null || limit <= 0) continue;

      final spent = await _db!.getTotalSpentInBudget(budget.id);
      final usage = spent / limit;

      if (usage > 1.0) {
        overBudgetCount++;
      } else if (usage < 0.95) {
        onTrackCount++;
      }
    }

    await _emitEomNotification(
      overBudgetCount: overBudgetCount,
      onTrackCount: onTrackCount,
    );

    await prefs.setBool(checkKey, true);

    analyticsService.trackEvent(
      AnalyticsEventType.featureUsed,
      {
        'feature': 'end_of_month_check',
        'over_budget_count': overBudgetCount,
        'on_track_count': onTrackCount,
        'month': '${now.year}-${now.month}',
      },
    );
  }

  Future<void> _emitEomNotification({
    required int overBudgetCount,
    required int onTrackCount,
  }) async {
    try {
      // Background process: load default English or fetch user preference if available.
      // For now, defaulting to English to ensure service continuity.
      final l10n = lookupAppLocalizations(const Locale('en'));

      if (overBudgetCount == 0 && onTrackCount > 0) {
        await notificationService.showNotification(
          id: 9001,
          title: 'You’re on track',
          body:
              'End-of-month check complete. All active budgets are within limits.',
          payload: '/reports',
          l10n: l10n,
        );
      } else if (overBudgetCount > 0) {
        await notificationService.showNotification(
          id: 9001,
          title: 'End-of-Month Alert',
          body:
              '$overBudgetCount budget${overBudgetCount > 1 ? 's are' : ' is'} over limit. Tap to review.',
          payload: '/reports',
          l10n: l10n,
        );
      }
    } catch (e) {
      // Notifications must never break analytics flow
      debugPrint('[AnalyticsManager] Failed to show EOM notification: $e');
    }
  }

  // INSIGHT COORDINATION

  /// Trigger a safe insight refresh (debounced by engine)
  void refreshInsights() {
    try {
      // Note: InsightEngine generates insights on-demand via generate* methods
      // This method just notifies that a refresh was requested
      analyticsService.trackEvent(
        AnalyticsEventType.featureUsed,
        {'feature': 'insight_refresh'},
      );
    } catch (e) {
      debugPrint('[AnalyticsManager] Insight refresh failed: $e');
    }
  }

  // =========================================================================
  // FINANCIAL INTELLIGENCE ENGINE INTEGRATION
  // =========================================================================

  /// Initialize the Financial Intelligence Engine with database
  Future<void> initializeIntelligenceEngine() async {
    if (_db == null) return;
    
    try {
      await _intelligenceEngine.initialize(
        database: _db,
        supabase: Supabase.instance.client,
      );
      debugPrint('[AnalyticsManager] Intelligence Engine initialized');
    } catch (e) {
      debugPrint('[AnalyticsManager] Intelligence Engine init failed: $e');
    }
  }

  /// Get budget intelligence for a specific budget
  Future<BudgetIntelligence> getBudgetIntelligence(String budgetId) async {
    return await _intelligenceEngine.analyzeBudget(budgetId: budgetId);
  }

  /// Get spending patterns for a user
  Future<SpendingIntelligence> getSpendingPatterns({
    required String userId,
    AnalysisScope scope = AnalysisScope.last30Days,
  }) async {
    return await _intelligenceEngine.analyzeSpending(
      userId: userId,
      scope: scope,
    );
  }

  /// Predict category for an expense (ML integration point)
  Future<CategoryPrediction> predictCategory({
    required String title,
    String? merchant,
    int? amount,
  }) async {
    return await _intelligenceEngine.predictCategory(
      title: title,
      merchant: merchant,
      amount: amount,
    );
  }

  /// Access the Intelligence Engine directly
  FinancialIntelligenceEngine get intelligenceEngine => _intelligenceEngine;
}

/// Global singleton
final analyticsManager = AnalyticsManager();

