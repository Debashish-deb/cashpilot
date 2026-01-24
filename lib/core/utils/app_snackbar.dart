import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Standardized SnackBar utilities for consistent messaging
/// All snackbars are compact, centered, and theme-aware
class AppSnackBar {
  AppSnackBar._();

  // ============================================================
  // PUBLIC API (UNCHANGED)
  // ============================================================

  static void showSuccess(BuildContext context, String message) {
    _show(
      context,
      message: message,
      icon: Icons.check_circle_rounded,
      color: AppColors.success,
    );
  }

  static void showError(BuildContext context, String message) {
    _show(
      context,
      message: message,
      icon: Icons.error_rounded,
      color: AppColors.error,
    );
  }

  static void showWarning(BuildContext context, String message) {
    _show(
      context,
      message: message,
      icon: Icons.warning_rounded,
      color: AppColors.warning,
    );
  }

  static void showInfo(BuildContext context, String message) {
    _show(
      context,
      message: message,
      icon: Icons.info_rounded,
      color: AppColors.info,
    );
  }

  /// Show undo-style SnackBar with custom action (for delete operations)
  static void showUndo(
    BuildContext context, {
    required String message,
    required VoidCallback onUndo,
    Duration duration = const Duration(seconds: 4),
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();

    messenger.showSnackBar(
      SnackBar(
        content: _contentRow(
          icon: Icons.delete_outline,
          message: message,
          textColor: Colors.white,
        ),
        backgroundColor: isDark
            ? AppColors.danger.withValues(alpha: 0.95)
            : AppColors.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        duration: duration,
        dismissDirection: DismissDirection.horizontal,
        action: SnackBarAction(
          label: 'UNDO',
          textColor: Colors.white,
          backgroundColor: Colors.white.withValues(alpha: 0.2),
          onPressed: onUndo,
        ),
      ),
    );
  }

  // ============================================================
  // INTERNALS (NEW – NON-BREAKING)
  // ============================================================

  static void _show(
    BuildContext context, {
    required String message,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final messenger = ScaffoldMessenger.of(context);

    // Prevent snackbar pile-up (common UX bug)
    messenger.clearSnackBars();

    messenger.showSnackBar(
      SnackBar(
        content: _contentRow(
          icon: icon,
          message: message,
          textColor: Colors.white,
        ),
        backgroundColor:
            isDark ? color.withValues(alpha: 0.95) : color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(milliseconds: 1500),
        dismissDirection: DismissDirection.horizontal,
      ),
    );
  }

  static Widget _contentRow({
    required IconData icon,
    required String message,
    required Color textColor,
  }) {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: textColor, size: 18),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              message,
              style: TextStyle(
                color: textColor,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
