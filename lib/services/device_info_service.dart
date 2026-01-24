/// Device Info Service
/// Generates and persists a unique device ID for multi-device sync conflict resolution.
library;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';

class DeviceInfoService {
  static final DeviceInfoService _instance = DeviceInfoService._internal();
  factory DeviceInfoService() => _instance;
  DeviceInfoService._internal();

  static const _deviceIdKey = 'device_id';
  final _storage = const FlutterSecureStorage();
  String? _cachedDeviceId;

  /// Get or generate the unique device ID.
  /// This ID is persisted in secure storage and survives app reinstalls on iOS.
  Future<String> getDeviceId() async {
    // Return cached if available
    if (_cachedDeviceId != null) return _cachedDeviceId!;

    try {
      // Try to read existing device ID
      _cachedDeviceId = await _storage.read(key: _deviceIdKey);

      if (_cachedDeviceId == null || _cachedDeviceId!.isEmpty) {
        // Generate new device ID
        _cachedDeviceId = const Uuid().v4();
        await _storage.write(key: _deviceIdKey, value: _cachedDeviceId);
        debugPrint('📱 DeviceInfoService: Generated new device ID: $_cachedDeviceId');
      } else {
        debugPrint('📱 DeviceInfoService: Using existing device ID: $_cachedDeviceId');
      }

      return _cachedDeviceId!;
    } catch (e) {
      // Fallback: generate an in-memory ID if secure storage fails
      debugPrint('[DeviceInfoService] Secure storage failed, using in-memory ID. Error: $e');
      _cachedDeviceId ??= const Uuid().v4();
      return _cachedDeviceId!;
    }
  }

  /// Check if this device ID matches the one that made a remote change.
  /// Used to skip processing our own Realtime events.
  Future<bool> isOwnDevice(String? remoteDeviceId) async {
    if (remoteDeviceId == null) return false;
    final ourId = await getDeviceId();
    return ourId == remoteDeviceId;
  }
}

/// Global instance for easy access
final deviceInfoService = DeviceInfoService();
