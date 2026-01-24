import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final deviceManagerProvider =
    Provider<DeviceManager>((ref) => DeviceManager());

/// DeviceManager
/// Centralized wrapper for all device / hardware interactions
///
/// Design goals:
/// - Never throw
/// - Never block UI
/// - Be platform-safe
/// - Feel consistent and intentional to the user
class DeviceManager {
  // ---------------------------------------------------------------------------
  // INTERNAL SAFETY GUARDS
  // ---------------------------------------------------------------------------

  DateTime? _lastHapticAt;
  static const Duration _minHapticInterval =
      Duration(milliseconds: 40); // prevent spam

  bool _canTriggerHaptic() {
    final now = DateTime.now();
    if (_lastHapticAt != null &&
        now.difference(_lastHapticAt!) < _minHapticInterval) {
      return false;
    }
    _lastHapticAt = now;
    return true;
  }

  // ---------------------------------------------------------------------------
  // HAPTICS
  // ---------------------------------------------------------------------------

  Future<void> vibrateSelection() async {
    try {
      if (!_canTriggerHaptic()) return;
      await HapticFeedback.selectionClick();
    } catch (_) {
      // Haptics must never crash app
    }
  }

  Future<void> vibrateLight() async {
    try {
      if (!_canTriggerHaptic()) return;
      await HapticFeedback.lightImpact();
    } catch (_) {}
  }

  Future<void> vibrateMedium() async {
    try {
      if (!_canTriggerHaptic()) return;
      await HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  Future<void> vibrateHeavy() async {
    try {
      if (!_canTriggerHaptic()) return;
      await HapticFeedback.heavyImpact();
    } catch (_) {}
  }

  Future<void> vibrateSuccess() async {
    try {
      if (!_canTriggerHaptic()) return;
      // Medium feels “positive” across iOS + Android
      await HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  Future<void> vibrateError() async {
    try {
      if (!_canTriggerHaptic()) return;

      // Strong + short echo = error signal
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 80));
      await HapticFeedback.lightImpact();
    } catch (_) {}
  }

  // ---------------------------------------------------------------------------
  // SYSTEM SOUNDS
  // ---------------------------------------------------------------------------

  Future<void> playClickSound() async {
    try {
      await SystemSound.play(SystemSoundType.click);
    } catch (_) {
      // Sound playback failure is non-fatal
    }
  }

  // ---------------------------------------------------------------------------
  // SYSTEM UI (STATUS / NAV BAR)
  // ---------------------------------------------------------------------------

  void setSystemOverlayStyle({required bool isDark}) {
    try {
      SystemChrome.setSystemUIOverlayStyle(
        isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      );
    } catch (_) {
      // Defensive: platform may reject changes in rare cases
    }
  }

  // ---------------------------------------------------------------------------
  // ORIENTATION CONTROL
  // ---------------------------------------------------------------------------

  /// Lock orientation to portrait
  Future<void> lockOrientationPortrait() async {
    try {
      await SystemChrome.setPreferredOrientations(
        const [
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ],
      );
    } catch (_) {
      // Orientation failure should not crash app
    }
  }

  /// Reset orientation to system default
  Future<void> unlockOrientation() async {
    try {
      await SystemChrome.setPreferredOrientations([]);
    } catch (_) {}
  }
}
