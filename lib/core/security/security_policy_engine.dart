import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:safe_device/safe_device.dart';

/// Performance-grade Security Policy Engine
/// 
/// Separates security DECISION logic from ORCHESTRATION.
/// Implements trust scoring and multi-signal tamper detection.
class SecurityPolicyEngine {
  static final SecurityPolicyEngine _instance = SecurityPolicyEngine._internal();
  factory SecurityPolicyEngine() => _instance;
  SecurityPolicyEngine._internal();

  static const List<String> _commonRootPaths = [
    '/system/app/Superuser.apk',
    '/sbin/su',
    '/system/bin/su',
    '/system/xbin/su',
    '/data/local/xbin/su',
    '/data/local/bin/su',
    '/system/sd/xbin/su',
    '/system/bin/failsafe/su',
    '/data/local/su',
    '/su/bin/su',
    '/system/bin/.ext/.su',
  ];

  static const List<String> _fridaBinaries = [
    '/data/local/tmp/frida-server',
    '/data/local/tmp/re.frida.server',
    '/data/local/tmp/frida',
    '/sdcard/frida-server',
    '/system/bin/frida-server',
  ];

  bool _detectRootFilesystemSignals() {
    if (kIsWeb || !Platform.isAndroid) return false;
    try {
      for (final path in _commonRootPaths) {
        if (File(path).existsSync()) {
          return true;
        }
      }
    } catch (_) {}
    return false;
  }

  bool _detectFridaFilesystem() {
    if (kIsWeb || !Platform.isAndroid) return false;
    try {
      for (final path in _fridaBinaries) {
        if (File(path).existsSync()) return true;
      }
    } catch (_) {}
    return false;
  }

  bool _detectFridaMemoryMaps() {
    if (kIsWeb || !Platform.isAndroid) return false;
    try {
      final mapsFile = File('/proc/self/maps');
      if (mapsFile.existsSync()) {
        final content = mapsFile.readAsStringSync().toLowerCase();
        if (content.contains('frida') ||
            content.contains('gadget') ||
            content.contains('gum-js-loop') ||
            content.contains('libfrida')) {
          return true;
        }
      }
    } catch (_) {}
    return false;
  }

  bool _detectTracerPid() {
    if (kIsWeb || !Platform.isAndroid) return false;
    try {
      final statusFile = File('/proc/self/status');
      if (statusFile.existsSync()) {
        final lines = statusFile.readAsLinesSync();
        for (final line in lines) {
          if (line.startsWith('TracerPid:')) {
            final pid = int.tryParse(line.split(':')[1].trim()) ?? 0;
            if (pid > 0) return true;
          }
        }
      }
    } catch (_) {}
    return false;
  }

  Future<bool> _detectFridaPort() async {
    if (kIsWeb || !Platform.isAndroid) return false;
    try {
      final socket = await Socket.connect('127.0.0.1', 27042, timeout: const Duration(milliseconds: 150));
      socket.destroy();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Comprehensive device integrity report
  Future<DeviceIntegrityReport> evaluateIntegrity() async {
    try {
      final results = await Future.wait([
        SafeDevice.isJailBroken, // Index 0
        SafeDevice.isRealDevice, // Index 1
        SafeDevice.isOnExternalStorage, // Index 2
        SafeDevice.isDevelopmentModeEnable, // Index 3
      ]);

      final bool isJailbroken = results[0];
      final bool isDevMode = results[3];
      final bool isEmulator = !(results[1]);
      final bool isOnExternal = results[2];
      final bool fsRootDetected = _detectRootFilesystemSignals();
      final bool isRootedOrCompromised = isJailbroken || fsRootDetected;

      // Runtime dynamic instrumentation checks (Frida / House / ptrace)
      final fridaFs = _detectFridaFilesystem();
      final fridaMaps = _detectFridaMemoryMaps();
      final tracerAttached = _detectTracerPid();
      final fridaPort = await _detectFridaPort();
      final isFridaDetected = fridaFs || fridaMaps || tracerAttached || fridaPort;

      // Compute Trust Score (0.0 - 1.0)
      double score = 1.0;
      final List<String> signals = [];

      if (isRootedOrCompromised) {
        score -= 0.8;
        signals.add('ROOT_TAMPER_DETECTED');
        if (fsRootDetected && !isJailbroken) {
          signals.add('ROOT_BINARY_LOCATED');
        }
      }
      if (isFridaDetected) {
        score -= 0.9;
        signals.add('DYNAMIC_INSTRUMENTATION_DETECTED');
        if (fridaMaps) signals.add('FRIDA_AGENT_MEMORY_MAP');
        if (fridaFs) signals.add('FRIDA_SERVER_BINARY');
        if (tracerAttached) signals.add('TRACER_DEBUGGER_ATTACHED');
        if (fridaPort) signals.add('FRIDA_DEFAULT_PORT_OPEN');
      }
      if (isEmulator && !kDebugMode) {
        score -= 0.4;
        signals.add('UNAUTHORIZED_EMULATOR');
      }
      if (isDevMode && !kDebugMode) {
        score -= 0.2;
        signals.add('DEVELOPER_MODE_ACTIVE');
      }
      if (isOnExternal) {
        score -= 0.1;
        signals.add('EXTERNAL_STORAGE_RUN');
      }

      return DeviceIntegrityReport(
        trustScore: score.clamp(0.0, 1.0),
        isCompromised: (isRootedOrCompromised || isFridaDetected) && !kDebugMode, // Block on root or instrumentation
        signals: signals,
        evaluatedAt: DateTime.now(),
      );
    } catch (e) {
      debugPrint('[SecurityPolicyEngine] Evaluation failed: $e');
      return DeviceIntegrityReport(
        trustScore: 0.0,
        isCompromised: !kDebugMode,
        signals: ['EVALUATION_ERROR'],
        evaluatedAt: DateTime.now(),
      );
    }
  }

  /// Check if an action is allowed based on trust score
  bool isActionPermitted(double trustScore, {double threshold = 0.5}) {
    return trustScore >= threshold;
  }
}

/// Immutable integrity report
class DeviceIntegrityReport {
  final double trustScore;
  final bool isCompromised;
  final List<String> signals;
  final DateTime evaluatedAt;

  const DeviceIntegrityReport({
    required this.trustScore,
    required this.isCompromised,
    required this.signals,
    required this.evaluatedAt,
  });

  bool get isHealthy => trustScore > 0.8;
  bool get isHighRisk => trustScore < 0.4;
}
