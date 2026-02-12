import 'package:cashpilot/ui/widgets/common/glass_widgets.dart' show GlassContainer;
import 'package:flutter/material.dart';
import '../../../core/theme/tokens.g.dart';

enum GlassToastType { info, success, warning, error, ai }

class GlassToast extends StatelessWidget {
  final String? title;
  final String message;
  final IconData? icon;
  final Color? color;
  final GlassToastType type;

  const GlassToast({
    super.key,
    required this.message,
    this.title,
    this.icon,
    this.color,
    this.type = GlassToastType.info,
  });

  static void show(
    BuildContext context, {
    required String message,
    String? title,
    GlassToastType type = GlassToastType.info,
    Duration duration = const Duration(seconds: 4),
    IconData? icon,
    Color? color,
  }) {
    final overlay = Overlay.of(context);
    final entry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 20,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: GlassToast(
            message: message,
            title: title,
            type: type,
            icon: icon,
            color: color,
          ),
        ),
      ),
    );

    overlay.insert(entry);
    Future.delayed(duration, () => entry.remove());
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? _getSecondaryColor(context);
    final effectiveIcon = icon ?? _getIcon();

    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      borderRadius: BorderRadius.circular(20),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: effectiveColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(effectiveIcon, color: effectiveColor, size: 28),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (title != null)
                  Text(
                    title!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIcon() {
    switch (type) {
      case GlassToastType.success: return Icons.check_circle_outline;
      case GlassToastType.warning: return Icons.warning_amber_rounded;
      case GlassToastType.error: return Icons.error_outline;
      case GlassToastType.ai: return Icons.auto_awesome;
      case GlassToastType.info:
      default: return Icons.info_outline;
    }
  }

  Color _getSecondaryColor(BuildContext context) {
    switch (type) {
      case GlassToastType.success: return AppTokens.semanticSuccess;
      case GlassToastType.warning: return AppTokens.semanticWarning;
      case GlassToastType.error: return AppTokens.semanticDanger;
      case GlassToastType.ai: return AppTokens.brandSecondary;
      case GlassToastType.info:
      default: return AppTokens.brandPrimary;
    }
  }
}
