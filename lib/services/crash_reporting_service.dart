/// CashPilot Crash Reporting Service (Improved, structure preserved)
library;

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

class CrashReportingService {
  static final CrashReportingService _instance = CrashReportingService._internal();
  factory CrashReportingService() => _instance;
  CrashReportingService._internal();

  SupabaseClient? _supabase;
  String? _userId;
  String? _deviceInfo;
  String? _appVersion;

  // ➕ Added metadata fields (non-breaking)
  String? _platform;
  String? _osVersion;
  String? _dartVersion;
  String? _runtimeMode;
  DateTime? _lastReportTime; // for debugging—not used to throttle

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Collect device info first (doesn't need Supabase)
      await _collectDeviceInfo();
      await _collectAppInfo();
      await _collectEnvironmentInfo();
      
      // Try to get Supabase client - may not be available yet
      try {
        _supabase = Supabase.instance.client;
      } catch (_) {
        // Supabase not initialized yet - that's okay, we'll try later
        debugPrint('CrashReportingService: Supabase not ready yet, will retry on first report');
      }

      _initialized = true;
      debugPrint('CrashReportingService initialized');
    } catch (e) {
      debugPrint('Failed to initialize CrashReportingService: $e');
    }
  }
  
  /// Try to connect to Supabase if not already connected
  void _ensureSupabaseConnection() {
    if (_supabase != null) return;
    
    try {
      _supabase = Supabase.instance.client;
    } catch (_) {
      // Still not available
    }
  }

  void setUserId(String? userId) {
    _userId = userId;
  }

  // =======================================================================
  // DEVICE + APP INFO
  // =======================================================================

  Future<void> _collectDeviceInfo() async {
    try {
      final deviceInfo = DeviceInfoPlugin();

      if (kIsWeb) {
        _platform = "web";
        _deviceInfo = "Web Browser";
        _osVersion = "Unknown";
      } else if (Platform.isAndroid) {
        final info = await deviceInfo.androidInfo;
        _platform = "android";
        _osVersion = info.version.release;
        _deviceInfo = "${info.manufacturer} ${info.model}";
      } else if (Platform.isIOS) {
        final info = await deviceInfo.iosInfo;
        _platform = "ios";
        _osVersion = info.systemVersion;
        _deviceInfo = "${info.name} ${info.model}";
      } else {
        _platform = Platform.operatingSystem;
        _osVersion = Platform.operatingSystemVersion;
        _deviceInfo = "Unknown device";
      }
    } catch (e) {
      _platform = "unknown";
      _osVersion = "unknown";
      _deviceInfo = "Unknown device";
    }
  }

  Future<void> _collectAppInfo() async {
    try {
      final package = await PackageInfo.fromPlatform();
      _appVersion = "${package.version}+${package.buildNumber}";
    } catch (_) {
      _appVersion = "Unknown";
    }
  }

  Future<void> _collectEnvironmentInfo() async {
    _dartVersion = Platform.version;
    _runtimeMode = kReleaseMode
        ? "release"
        : kProfileMode
            ? "profile"
            : "debug";
  }

  // =======================================================================
  // LOGGING
  // =======================================================================

  Future<void> reportFlutterError(FlutterErrorDetails details) async {
    await _reportError(
      errorType: 'FlutterError',
      message: details.exceptionAsString(),
      stackTrace: details.stack?.toString(),
      context: details.context?.toDescription(),
    );
  }

  Future<void> reportError(Object error, StackTrace stackTrace) async {
    await _reportError(
      errorType: error.runtimeType.toString(),
      message: error.toString(),
      stackTrace: stackTrace.toString(),
    );
  }

  Future<void> logException(
    dynamic exception, {
    StackTrace? stackTrace,
    String? context,
    Map<String, dynamic>? extras,
  }) async {
    await _reportError(
      errorType: 'CaughtException',
      message: exception.toString(),
      stackTrace: stackTrace?.toString(),
      context: context,
      extras: extras,
    );
  }

  Future<void> logMessage(String message, {String? level, Map<String, dynamic>? extras}) async {
    await _reportError(
      errorType: level ?? 'Log',
      message: message,
      extras: extras,
      isFatal: false,
    );
  }

  // =======================================================================
  // THE INTERNAL REPORT FUNCTION (UR STRUCTURE PRESERVED)
  // =======================================================================

  Future<void> _reportError({
    required String errorType,
    required String message,
    String? stackTrace,
    String? context,
    Map<String, dynamic>? extras,
    bool isFatal = true,
  }) async {
    if (kDebugMode) {
      debugPrint('[$errorType] $message');
      if (stackTrace != null) debugPrint(stackTrace);
      return;
    }

    if (!_initialized) {
      debugPrint('CrashReportingService NOT initialized — skipping report');
      return;
    }
    
    // Try to connect to Supabase if not already connected
    _ensureSupabaseConnection();
    
    if (_supabase == null) {
      debugPrint('CrashReportingService: No Supabase connection — skipping report');
      return;
    }

    _lastReportTime = DateTime.now();

    final payload = {
      'user_id': _userId,
      'error_type': errorType,
      'message': _safeTruncate(message, 1000),
      'stack_trace': _safeTruncate(stackTrace, 4000),
      'context': context,
      'extras': extras,

      // ➕ ADDED METADATA (non-breaking)
      'device_info': _deviceInfo,
      'platform': _platform,
      'os_version': _osVersion,
      'dart_version': _dartVersion,
      'runtime_mode': _runtimeMode,
      'app_version': _appVersion,
      'last_report_at': _lastReportTime?.toIso8601String(),

      'is_fatal': isFatal,
      'created_at': DateTime.now().toIso8601String(),
    };

    try {
      await _supabase!.from('crash_reports').insert(payload);
    } catch (e) {
      debugPrint('Failed to report crash: $e');
    }
  }

  // =======================================================================
  // SAFE HELPER (NON-BREAKING)
  // =======================================================================

  String? _safeTruncate(String? text, int maxLen) {
    if (text == null) return null;
    if (text.length <= maxLen) return text;
    return text.substring(0, maxLen);
  }
}

final crashReporter = CrashReportingService();
