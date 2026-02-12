import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;

enum BiometricResult {
  success,
  notAvailable,
  notEnrolled,
  lockedOut,
  permanentlyLockedOut,
  passcodeNotSet,
  cancelled,
  failed,
  error,
}

class BiometricService {
  static final BiometricService _instance = BiometricService._internal();
  factory BiometricService() => _instance;
  BiometricService._internal();

  final LocalAuthentication _auth = LocalAuthentication();

  /// Check if biometrics are available on device
  Future<bool> isAvailable() async {
    try {
      final isDeviceSupported = await _auth.isDeviceSupported();
      final canCheckBiometrics = await _auth.canCheckBiometrics;
      return isDeviceSupported && canCheckBiometrics;
    } catch (e) {
      return false;
    }
  }

  /// Check if biometrics are enrolled
  Future<bool> hasBiometricsEnrolled() async {
    try {
      final biometrics = await _auth.getAvailableBiometrics();
      return biometrics.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Get biometric type description (alias for getBiometricType)
  Future<String> getBiometricTypeDescription() => getBiometricType();

  /// Get available biometric type
  Future<String> getBiometricType() async {
    final biometrics = await _auth.getAvailableBiometrics();
    if (biometrics.contains(BiometricType.face)) {
      return defaultTargetPlatform == TargetPlatform.iOS ? 'Face ID' : 'Face Recognition';
    } else if (biometrics.contains(BiometricType.fingerprint)) {
      return defaultTargetPlatform == TargetPlatform.iOS ? 'Touch ID' : 'Fingerprint';
    } else if (biometrics.contains(BiometricType.iris)) {
      return 'Iris Scan';
    } else if (biometrics.contains(BiometricType.strong)) {
      return 'Biometric';
    } else if (biometrics.contains(BiometricType.weak)) {
      return 'Biometric';
    }
    return 'Biometric';
  }

  /// Check if device passcode/PIN is set
  Future<bool> canUseDevicePasscode() async {
    try {
      return await _auth.isDeviceSupported();
    } on PlatformException {
      return false;
    }
  }

  /// Authenticate user with biometrics or device passcode
  /// Returns BiometricResult indicating the outcome
  Future<BiometricResult> authenticate({
    required String reason,
    bool biometricOnly = false,
  }) async {
    try {
      // First check if device supports any form of strong auth
      final isSupported = await _auth.isDeviceSupported();
      if (!isSupported) {
        return BiometricResult.notAvailable;
      }

      // Check for hardware availability specifically for biometrics
      final canCheckBiometrics = await _auth.canCheckBiometrics;
      final enrolledBiometrics = await _auth.getAvailableBiometrics();
      
      final hasBiometrics = canCheckBiometrics && enrolledBiometrics.isNotEmpty;

      // If we ONLY want biometrics but none are enrolled/available
      if (biometricOnly && !hasBiometrics) {
         if (!canCheckBiometrics) return BiometricResult.notAvailable;
         return BiometricResult.notEnrolled;
      }

      // Attempt authentication
      final authenticated = await _auth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: biometricOnly,
          sensitiveTransaction: true,
          useErrorDialogs: true,
        ),
      );

      return authenticated ? BiometricResult.success : BiometricResult.failed;
    } on PlatformException catch (e) {
      // Log for diagnostic purposes
      debugPrint('🛡️ Biometric Hardware Exception: ${e.code} - ${e.message}');
      return _handlePlatformException(e);
    } catch (e) {
      debugPrint('🛡️ Biometric Unknown Exception: $e');
      return BiometricResult.error;
    }
  }

  /// Handle platform-specific exceptions
  BiometricResult _handlePlatformException(PlatformException e) {
    switch (e.code) {
      case auth_error.notAvailable:
        return BiometricResult.notAvailable;
      case auth_error.notEnrolled:
        return BiometricResult.notEnrolled;
      case auth_error.lockedOut:
        return BiometricResult.lockedOut;
      case auth_error.permanentlyLockedOut:
        return BiometricResult.permanentlyLockedOut;
      case auth_error.passcodeNotSet:
        return BiometricResult.passcodeNotSet;
      default:
        // User cancelled or other error
        if (e.message?.toLowerCase().contains('cancel') ?? false) {
          return BiometricResult.cancelled;
        }
        return BiometricResult.error;
    }
  }

  /// Stop any ongoing authentication
  Future<bool> stopAuthentication() async {
    try {
      return await _auth.stopAuthentication();
    } catch (e) {
      return false;
    }
  }

  /// Get user-friendly error message for a result
  String getErrorMessage(BiometricResult result) {
    switch (result) {
      case BiometricResult.success:
        return 'Authentication successful';
      case BiometricResult.notAvailable:
        return 'Biometric authentication is not available on this device';
      case BiometricResult.notEnrolled:
        return 'No biometrics enrolled. Please set up fingerprint or face recognition in device settings';
      case BiometricResult.lockedOut:
        return 'Too many failed attempts. Please try again later';
      case BiometricResult.permanentlyLockedOut:
        return 'Biometrics permanently locked. Please use device passcode';
      case BiometricResult.passcodeNotSet:
        return 'Device passcode not set. Please set up a passcode first';
      case BiometricResult.cancelled:
        return 'Authentication cancelled';
      case BiometricResult.failed:
        return 'Authentication failed. Please try again';
      case BiometricResult.error:
        return 'An error occurred. Please try again';
    }
  }
}

/// Global instance for easy access
final biometricService = BiometricService();
