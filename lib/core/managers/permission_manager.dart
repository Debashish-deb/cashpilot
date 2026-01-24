import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

final permissionManagerProvider =
    Provider<PermissionManager>((ref) => PermissionManager());

/// PermissionManager
/// Centralized permission handling
///
/// Guarantees:
/// - Never crashes UI
/// - Correct behavior across Android/iOS
/// - Clear, trust-friendly user messaging
class PermissionManager {
  // ==========================================================================
  // CAMERA
  // ==========================================================================

  /// Request Camera Permission
  Future<bool> requestCamera(BuildContext context) async {
    try {
      final status = await Permission.camera.request();
      if (!context.mounted) return status.isGranted;
      return _handleStatus(context, status, 'Camera');
    } catch (e) {
      // Defensive: permission plugin may fail on some OEMs
      return false;
    }
  }

  // ==========================================================================
  // PHOTOS / STORAGE
  // ==========================================================================

  /// Request Photos/Storage Permission
  Future<bool> requestPhotos(BuildContext context) async {
    try {
      // Platform-aware handling
      final permission = Platform.isIOS
          ? Permission.photos
          : Permission.storage;

      final result = await permission.request();
      if (!context.mounted) return result.isGranted;
      return _handleStatus(context, result, 'Photos');
    } catch (e) {
      return false;
    }
  }

  // ==========================================================================
  // NOTIFICATIONS
  // ==========================================================================

  /// Request Notification Permission
  Future<bool> requestNotification(BuildContext context) async {
    try {
      final status = await Permission.notification.request();
      if (!context.mounted) return status.isGranted;
      return _handleStatus(context, status, 'Notifications');
    } catch (e) {
      return false;
    }
  }

  // ==========================================================================
  // INTERNAL HANDLING
  // ==========================================================================

  Future<bool> _handleStatus(
    BuildContext context,
    PermissionStatus status,
    String feature,
  ) async {
    if (status.isGranted) {
      return true;
    }

    // Permanently denied → guide to settings
    if (status.isPermanentlyDenied) {
      if (context.mounted) {
        _showSettingsDialog(context, feature);
      }
      return false;
    }

    // Denied but not permanent → silent failure (user may retry later)
    return false;
  }

  // ==========================================================================
  // UI
  // ==========================================================================

  void _showSettingsDialog(BuildContext context, String feature) {
    // Defensive: prevent dialog spam
    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$feature Permission Required'),
        content: Text(
          'To continue, CashPilot needs access to $feature.\n\n'
          'You can enable this permission anytime from app settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Not Now'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }
}
