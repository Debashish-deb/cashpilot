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

      // Compute Trust Score (0.0 - 1.0)
      double score = 1.0;
      final List<String> signals = [];

      if (isJailbroken) {
        score -= 0.8;
        signals.add('ROOT_TAMPER_DETECTED');
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
        isCompromised: isJailbroken && !kDebugMode, // Only block if strictly non-debug
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
