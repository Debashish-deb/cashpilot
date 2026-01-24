/// Notification Manager
/// Centralized manager for notification operations
/// Facade for notification service with app-specific helpers
library;

import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../services/notification_service.dart';
import 'package:flutter/widgets.dart'; // for Locale
import 'package:cashpilot/l10n/app_localizations.dart';

// =============================================================================
// NOTIFICATION MANAGER - Singleton Pattern
// =============================================================================

/// Centralized notification manager
class NotificationManager {
  static final NotificationManager _instance = NotificationManager._internal();
  factory NotificationManager() => _instance;
  NotificationManager._internal();

  bool _initialized = false;

  // Robustness: avoid predictable collisions across restarts
  int _notificationId =
      1000 + Random().nextInt(500000); // safe local range

  // Robustness: prevent notification spam
  DateTime? _lastNotificationAt;
  static const Duration _minNotificationInterval =
      Duration(seconds: 2);

  // ==========================================================================
  // INITIALIZATION
  // ==========================================================================

  /// Initialize the notification manager
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      await notificationService.initialize();
      _initialized = true;
      debugPrint('NotificationManager initialized');
    } catch (e, stack) {
      debugPrint('⚠️ NotificationManager init failed: $e');
      debugPrintStack(stackTrace: stack);
      // Non-fatal: app can continue without notifications
    }
  }

  // ==========================================================================
  // BUDGET ALERTS
  // ==========================================================================

  /// Show budget warning notification (75% used)
  Future<void> showBudgetWarning({
    required String budgetName,
    required double percentUsed,
  }) async {
    if (!_canNotify()) return;

    await _safeNotify(
      title: 'Budget Alert: $budgetName',
      body:
          'You\'ve used ${percentUsed.clamp(0, 100).toStringAsFixed(0)}% of your budget',
      payload: '/budgets',
    );
  }

  /// Show budget exceeded notification
  Future<void> showBudgetExceeded({
    required String budgetName,
    required double amountOver,
    required String currency,
  }) async {
    if (!_canNotify()) return;

    await _safeNotify(
      title: '⚠️ Budget Exceeded: $budgetName',
      body:
          'You\'re $currency${amountOver.abs().toStringAsFixed(2)} over budget',
      payload: '/budgets',
    );
  }

  // ==========================================================================
  // SAVINGS NOTIFICATIONS
  // ==========================================================================

  /// Show savings milestone reached
  Future<void> showSavingsMilestone({
    required String goalName,
    required int percentReached,
  }) async {
    if (!_canNotify()) return;

    await _safeNotify(
      title: '🎉 Savings Milestone!',
      body:
          'You\'ve reached ${percentReached.clamp(0, 100)}% of your "$goalName" goal!',
      payload: '/savings',
    );
  }

  /// Show savings goal completed
  Future<void> showSavingsGoalCompleted({
    required String goalName,
    required double amount,
    required String currency,
  }) async {
    if (!_canNotify()) return;

    await _safeNotify(
      title: '🏆 Goal Achieved!',
      body:
          'You\'ve saved $currency${amount.toStringAsFixed(2)} for "$goalName"!',
      payload: '/savings',
    );
  }

  // ==========================================================================
  // SYNC NOTIFICATIONS
  // ==========================================================================

  /// Show sync completed notification
  Future<void> showSyncCompleted() async {
    if (!_canNotify()) return;

    await _safeNotify(
      title: '✅ Sync Complete',
      body: 'Your data has been synced successfully',
      payload: '/',
    );
  }

  /// Show sync error notification
  Future<void> showSyncError() async {
    if (!_canNotify()) return;

    await _safeNotify(
      title: '⚠️ Sync Failed',
      body: 'Unable to sync data. Please try again.',
      payload: '/settings',
    );
  }

  // ==========================================================================
  // GENERAL NOTIFICATIONS
  // ==========================================================================

  /// Show a simple notification
  Future<void> showSimple({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_canNotify()) return;

    await _safeNotify(
      title: title,
      body: body,
      payload: payload ?? '/',
    );
  }

  // ==========================================================================
  // HELPERS
  // ==========================================================================

  int _getNextId() => _notificationId++;

  bool _canNotify() {
    final now = DateTime.now();
    if (_lastNotificationAt != null &&
        now.difference(_lastNotificationAt!) <
            _minNotificationInterval) {
      if (kDebugMode) {
        debugPrint('NotificationManager: throttled notification');
      }
      return false;
    }
    _lastNotificationAt = now;
    return true;
  }

  Future<void> _safeNotify({
    required String title,
    required String body,
    required String payload,
  }) async {
    try {
      // Default to English if we can't contextually determine language in this manager yet
      final l10n = lookupAppLocalizations(const Locale('en'));
      
      await notificationService.showNotification(
        id: _getNextId(),
        title: title,
        body: body,
        payload: payload,
        l10n: l10n,
      );
    } catch (e, stack) {
      debugPrint('NotificationManager: notify failed: $e');
      if (kDebugMode) debugPrintStack(stackTrace: stack);
    }
  }

  /// Clear all notifications
  Future<void> clearAll() async {
    try {
      await notificationService.cancelAllNotifications();
    } catch (e) {
      debugPrint('NotificationManager: clearAll failed: $e');
    }
  }
}

// =============================================================================
// PROVIDERS & GLOBAL INSTANCE
// =============================================================================

/// Global notification manager instance
final notificationManager = NotificationManager();
