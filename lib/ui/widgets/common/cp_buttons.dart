/// ===========================================================================
/// CASH PILOT — BUTTON KIT
/// Apple-grade UI with Android-safe sizing & interaction
/// Polished edition — NO API BREAKS
/// ===========================================================================
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_typography.dart';

const _kButtonRadius = 14.0;
const _kPressScale = 0.97;

/// ===========================================================================
/// INTERNAL PRESS SCALE WRAPPER (shared, non-breaking)
/// ===========================================================================
class _Pressable extends StatefulWidget {
  final bool enabled;
  final Widget child;

  const _Pressable({
    required this.enabled,
    required this.child,
  });

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed && widget.enabled ? _kPressScale : 1.0,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOutCubic,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTapDown: widget.enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: widget.child,
      ),
    );
  }
}

/// ===========================================================================
/// PRIMARY BUTTON — Solid filled, high-prominence actions
/// ===========================================================================
class CPButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool loading;
  final bool disabled;
  final bool expanded;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;

  const CPButton({
    super.key,
    required this.label,
    required this.onTap,
    this.loading = false,
    this.disabled = false,
    this.expanded = false,
    this.icon,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final primary = backgroundColor ?? Theme.of(context).colorScheme.primary;
    final foreground = textColor ?? Colors.white;
    final isEnabled = !disabled && !loading && onTap != null;

    final button = _Pressable(
      enabled: isEnabled,
      child: Material(
        color: isEnabled ? primary : primary.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(_kButtonRadius),
        elevation: isEnabled ? 2 : 0,
        child: InkWell(
          onTap: isEnabled
              ? () {
                  HapticFeedback.lightImpact();
                  onTap?.call();
                }
              : null,
          borderRadius: BorderRadius.circular(_kButtonRadius),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            alignment: Alignment.center,
            child: loading
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      valueColor: AlwaysStoppedAnimation(foreground),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, color: foreground, size: 20),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        label,
                        style: AppTypography.labelLarge.copyWith(
                          color: foreground,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );

    return expanded
        ? SizedBox(width: double.infinity, child: button)
        : button;
  }
}

/// ===========================================================================
/// OUTLINED BUTTON — Premium iOS-like, strong borders
/// ===========================================================================
class CPOutlinedButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool disabled;
  final bool expanded;
  final bool loading;
  final IconData? icon;
  final Color? borderColor;

  const CPOutlinedButton({
    super.key,
    required this.label,
    required this.onTap,
    this.disabled = false,
    this.expanded = false,
    this.loading = false,
    this.icon,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final primary = borderColor ?? Theme.of(context).colorScheme.primary;
    final isEnabled = !disabled && !loading && onTap != null;
    final color = isEnabled ? primary : primary.withValues(alpha: 0.4);

    final button = _Pressable(
      enabled: isEnabled,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(_kButtonRadius),
        child: InkWell(
          onTap: isEnabled
              ? () {
                  HapticFeedback.lightImpact();
                  onTap?.call();
                }
              : null,
          borderRadius: BorderRadius.circular(_kButtonRadius),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(_kButtonRadius),
              border: Border.all(
                color: color,
                width: Theme.of(context).platform == TargetPlatform.iOS ? 1.4 : 1.2,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            alignment: Alignment.center,
            child: loading
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      valueColor: AlwaysStoppedAnimation(color),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, color: color, size: 20),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        label,
                        style: AppTypography.labelLarge.copyWith(
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );

    return expanded
        ? SizedBox(width: double.infinity, child: button)
        : button;
  }
}

/// ===========================================================================
/// TEXT BUTTON — Clean & elegant, minimal padding
/// ===========================================================================
class CPTextButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool disabled;
  final IconData? icon;
  final Color? color;

  const CPTextButton({
    super.key,
    required this.label,
    required this.onTap,
    this.disabled = false,
    this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final primary = color ?? Theme.of(context).colorScheme.primary;
    final isEnabled = !disabled && onTap != null;
    final textColor = isEnabled ? primary : primary.withValues(alpha: 0.4);

    return _Pressable(
      enabled: isEnabled,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isEnabled
              ? () {
                  HapticFeedback.selectionClick();
                  onTap?.call();
                }
              : null,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: textColor, size: 18),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: AppTypography.labelLarge.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ===========================================================================
/// DANGER BUTTON — For destructive actions
/// ===========================================================================
class CPDangerButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool loading;
  final bool disabled;
  final bool expanded;
  final bool outlined;
  final IconData? icon;

  const CPDangerButton({
    super.key,
    required this.label,
    required this.onTap,
    this.loading = false,
    this.disabled = false,
    this.expanded = false,
    this.outlined = false,
    this.icon,
  });

  static const dangerColor = Color(0xFFE53935);

  @override
  Widget build(BuildContext context) {
    if (outlined) {
      return CPOutlinedButton(
        label: label,
        onTap: onTap,
        disabled: disabled,
        expanded: expanded,
        loading: loading,
        borderColor: dangerColor,
        icon: icon,
      );
    }

    return CPButton(
      label: label,
      onTap: onTap,
      loading: loading,
      disabled: disabled,
      expanded: expanded,
      backgroundColor: dangerColor,
      textColor: Colors.white,
      icon: icon,
    );
  }
}

/// ===========================================================================
/// ICON BUTTON — Circular icon-only button
/// ===========================================================================
class CPIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool disabled;
  final double size;
  final Color? backgroundColor;
  final Color? iconColor;
  final String? tooltip;

  const CPIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.disabled = false,
    this.size = 48,
    this.backgroundColor,
    this.iconColor,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final isEnabled = !disabled && onTap != null;

    final button = _Pressable(
      enabled: isEnabled,
      child: Material(
        color: backgroundColor ?? primary.withValues(alpha: 0.10),
        shape: const CircleBorder(),
        child: InkWell(
          onTap: isEnabled
              ? () {
                  HapticFeedback.lightImpact();
                  onTap?.call();
                }
              : null,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(
              icon,
              size: size * 0.5,
              color: isEnabled
                  ? (iconColor ?? primary)
                  : (iconColor ?? primary).withValues(alpha: 0.4),
            ),
          ),
        ),
      ),
    );

    return tooltip != null
        ? Tooltip(message: tooltip!, child: button)
        : button;
  }
}
