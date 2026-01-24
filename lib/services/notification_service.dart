/// Notification Service
/// Handles local push notifications for bill reminders and recurring expenses
library;

import 'dart:io';
import 'dart:async';
import 'dart:ui' show Color;
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:cashpilot/l10n/app_localizations.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize timezone
    tz_data.initializeTimeZones();

    // Android settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    final settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request permissions on iOS
    if (Platform.isIOS) {
      await _notifications
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }

    // Request permissions on Android 13+
    if (Platform.isAndroid) {
      await _notifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }

    _isInitialized = true;
    debugPrint('[NotificationService] Initialized');
  }

  final _payloadController = StreamController<String?>.broadcast();
  Stream<String?> get payloadStream => _payloadController.stream;

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('[NotificationService] Notification tapped: ${response.payload}');
    if (response.payload != null) {
      _payloadController.add(response.payload);
    }
  }

  /// Schedule a bill reminder notification
  Future<void> scheduleBillReminder({
    required int id,
    required String title,
    required int amountInCents,
    required DateTime dueDate,
    required String currency,
    required AppLocalizations l10n,
    int daysBefore = 1,
  }) async {
    if (!_isInitialized) await initialize();

    final reminderDate = dueDate.subtract(Duration(days: daysBefore));
    
    // Skip if reminder date is in the past
    if (reminderDate.isBefore(DateTime.now())) {
      debugPrint('[NotificationService] Skipping past reminder for $title');
      return;
    }

    final formattedAmount = (amountInCents / 100).toStringAsFixed(2);
    final currencySymbol = currency == 'EUR' ? '€' : currency;

    final androidDetails = AndroidNotificationDetails(
      'bill_reminders',
      l10n.notifChannelBill,
      channelDescription: l10n.notifChannelBillDesc,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: const Color(0xFF6366F1), // Primary color
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      id,
      l10n.notifDueSoon(title),
      '$currencySymbol$formattedAmount due ${_formatDate(dueDate, l10n)}',
      tz.TZDateTime.from(reminderDate, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'recurring_$id',
    );

    debugPrint('[NotificationService] Scheduled reminder for $title on ${reminderDate.toIso8601String()}');
  }

  /// Cancel a specific notification
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  /// Show an immediate notification with custom content
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    required AppLocalizations l10n,
    String? payload,
  }) async {
    if (!_isInitialized) await initialize();

    final androidDetails = AndroidNotificationDetails(
      'general_alerts',
      l10n.notifChannelAlerts,
      channelDescription: l10n.notifChannelAlertsDesc,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails();

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      id,
      title,
      body,
      details,
      payload: payload,
    );
  }

  String _formatDate(DateTime date, AppLocalizations l10n) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;

    if (difference == 0) return l10n.notifDateToday;
    if (difference == 1) return l10n.notifDateTomorrow;
    return l10n.notifDateFuture(difference);
  }
}

/// Global instance
final notificationService = NotificationService();
