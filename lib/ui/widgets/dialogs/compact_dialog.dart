import 'package:flutter/material.dart';
import '../../../core/theme/app_typography.dart';

/// Shows a compact, modern dialog with consistent styling
///
/// This replaces the default AlertDialog which takes up too much space.
/// The new design is:
/// - Smaller and more compact
/// - Has a circular icon at the top
/// - Uses modern styling with rounded corners
/// - Arranges buttons side-by-side for better UX
/// - Optionally auto-dismisses after a few seconds (for info dialogs only)
Future<T?> showCompactDialog<T>({
  required BuildContext context,
  required String title,
  required String message,
  required IconData icon,
  Color? iconColor,
  String? confirmText,
  String? cancelText,
  VoidCallback? onConfirm,
  VoidCallback? onCancel,
  bool barrierDismissible = true,
  int? autoDismissSeconds, // Set to 2-3 for info dialogs, null for confirmations
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (c) {
      // Auto-dismiss timer for informational dialogs
      if (autoDismissSeconds != null && autoDismissSeconds > 0) {
        Future.delayed(Duration(seconds: autoDismissSeconds), () {
          if (c.mounted) Navigator.pop(c);
        });
      }
      
      return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: (iconColor ?? Theme.of(context).primaryColor)
                    .withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: iconColor ?? Theme.of(context).primaryColor,
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            
            // Title
            Text(
              title,
              style: AppTypography.titleLarge.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            
            // Message
            Text(
              message,
              style: AppTypography.bodyMedium.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            
            // Buttons
            if (cancelText != null || confirmText != null)
              Row(
                children: [
                  if (cancelText != null)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(c, false);
                          onCancel?.call();
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(cancelText),
                      ),
                    ),
                  if (cancelText != null && confirmText != null)
                    const SizedBox(width: 12),
                  if (confirmText != null)
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          Navigator.pop(c, true);
                          onConfirm?.call();
                        },
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(confirmText),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
    },
  );
}
