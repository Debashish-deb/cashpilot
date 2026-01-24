/// Device Gate Service
/// Registers device with Supabase and enforces device limits per subscription tier.
library;

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../services/device_info_service.dart';
import '../../../services/auth_service.dart';
import '../../../core/constants/subscription.dart';
import '../../../services/subscription_service.dart';

class DeviceGateResult {
  final bool allowed;
  final String? reason;
  final int currentDeviceCount;
  final int maxDevices;

  DeviceGateResult({
    required this.allowed,
    this.reason,
    this.currentDeviceCount = 0,
    this.maxDevices = 1,
  });
}

class DeviceGateService {
  static final DeviceGateService _instance = DeviceGateService._internal();
  factory DeviceGateService() => _instance;
  DeviceGateService._internal();

  final _client = Supabase.instance.client;
  final _deviceInfoService = DeviceInfoService();
  final _deviceInfoPlus = DeviceInfoPlugin();

  /// Register this device and check if sync is allowed based on device limits.
  /// Returns DeviceGateResult with allowed=true if device can sync.
  Future<DeviceGateResult> registerAndCheck() async {
    try {
      final userId = authService.currentUser?.id;
      if (userId == null) {
        return DeviceGateResult(
          allowed: false,
          reason: 'Not authenticated',
        );
      }

      final deviceId = await _deviceInfoService.getDeviceId();
      final deviceInfo = await _getDeviceInfo();

      // Upsert device into devices table
      await _client.from('devices').upsert({
        'user_id': userId,
        'device_id': deviceId,
        'device_name': deviceInfo['device_name'],
        'os': deviceInfo['os'],
        'app_version': deviceInfo['app_version'],
        'last_seen_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id, device_id');

      if (kDebugMode) {
        debugPrint('[DeviceGate] Registered device: $deviceId');
      }

      // Check device count vs tier limit
      final tier = SubscriptionService().currentTier;
      final maxDevices = _getMaxDevices(tier);

      final countResponse = await _client
          .from('devices')
          .select('device_id')
          .eq('user_id', userId);

      final currentCount = (countResponse as List).length;

      // -1 means unlimited devices
      if (maxDevices != -1 && currentCount > maxDevices) {
        return DeviceGateResult(
          allowed: false,
          reason: 'Device limit exceeded. Max $maxDevices devices for ${tier.value} tier.',
          currentDeviceCount: currentCount,
          maxDevices: maxDevices,
        );
      }

      return DeviceGateResult(
        allowed: true,
        currentDeviceCount: currentCount,
        maxDevices: maxDevices,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[DeviceGate] Error: $e');
      }
      // Fail open - allow sync if device check fails
      return DeviceGateResult(allowed: true, reason: 'Device check failed: $e');
    }
  }

  /// Get max devices allowed for subscription tier
  /// Returns -1 for unlimited
  int _getMaxDevices(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.free:
        return 1;
      case SubscriptionTier.pro:
        return 50;
      case SubscriptionTier.proPlus:
        return -1; // Unlimited
    }
  }

  /// Collect device info for registration
  Future<Map<String, String>> _getDeviceInfo() async {
    String deviceName = 'Unknown';
    String os = 'Unknown';
    String appVersion = 'Unknown';

    try {
      if (Platform.isAndroid) {
        final info = await _deviceInfoPlus.androidInfo;
        deviceName = '${info.brand} ${info.model}';
        os = 'Android ${info.version.release}';
      } else if (Platform.isIOS) {
        final info = await _deviceInfoPlus.iosInfo;
        deviceName = info.name;
        os = '${info.systemName} ${info.systemVersion}';
      }

      final packageInfo = await PackageInfo.fromPlatform();
      appVersion = '${packageInfo.version}+${packageInfo.buildNumber}';
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[DeviceGate] Could not get device info: $e');
      }
    }

    return {
      'device_name': deviceName,
      'os': os,
      'app_version': appVersion,
    };
  }

  /// Remove a device from the user's device list
  Future<void> removeDevice(String deviceId) async {
    final userId = authService.currentUser?.id;
    if (userId == null) return;

    await _client
        .from('devices')
        .delete()
        .eq('user_id', userId)
        .eq('device_id', deviceId);

    if (kDebugMode) {
      debugPrint('[DeviceGate] Removed device: $deviceId');
    }
  }

  /// Get all registered devices for current user
  Future<List<Map<String, dynamic>>> getRegisteredDevices() async {
    final userId = authService.currentUser?.id;
    if (userId == null) return [];

    final response = await _client
        .from('devices')
        .select()
        .eq('user_id', userId)
        .order('last_seen_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }
}

/// Global instance
final deviceGateService = DeviceGateService();
