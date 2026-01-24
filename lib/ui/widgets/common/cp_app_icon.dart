import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CPAppIcon extends StatelessWidget {
  final IconData icon;
  final Color color;

  /// Total container size
  final double size;

  /// Icon size (defaults to size * 0.5)
  final double? iconSize;

  /// Visual styles
  final bool useGradient;
  final bool useShadow;
  final bool useGlass; // NEW: iOS-style vibrancy
  final bool enableHaptics; // NEW

  /// Border
  final Color? borderColor;
  final double borderWidth;

  /// Interaction
  final VoidCallback? onTap; // NEW

  const CPAppIcon({
    super.key,
    required this.icon,
    required this.color,
    this.size = 48.0,
    this.iconSize,
    this.useGradient = true,
    this.useShadow = false,
    this.useGlass = false,
    this.enableHaptics = true,
    this.borderColor,
    this.borderWidth = 1.0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = size * 0.22; // Apple squircle-ish
    final resolvedIconSize = iconSize ?? size * 0.5;

    Widget content = _buildIconContainer(
      radius: radius,
      iconSize: resolvedIconSize,
    );

    // Optional glass / vibrancy layer (iOS Wallet style)
    if (useGlass) {
      content = ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: content,
        ),
      );
    }

    // Optional interaction wrapper
    if (onTap != null) {
      content = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (enableHaptics) {
            HapticFeedback.selectionClick();
          }
          onTap!();
        },
        child: AnimatedScale(
          scale: 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: content,
        ),
      );
    }

    return content;
  }

  Widget _buildIconContainer({
    required double radius,
    required double iconSize,
  }) {
    // Premium Apple-style decoration
    if (useGradient) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.9),
              color,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: borderColor != null
            ? Border.all(color: borderColor!, width: borderWidth)
            : null,
          boxShadow: useShadow
              ? [
                  // Depth shadow
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: size * 0.3,
                    offset: Offset(0, size * 0.15),
                  ),
                  // Inner glow (top edge)
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.2),
                    blurRadius: 2,
                    offset: const Offset(0, -1),
                  ),
                ]
              : null,
        ),
        child: Stack(
          children: [
            // Reflection layer (Glassmorphism shine)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: size * 0.4,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(radius)),
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.3),
                      Colors.white.withValues(alpha: 0.05),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            // Centered Icon
            Center(
              child: Icon(
                icon,
                size: iconSize,
                color: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    // Subtle / flat variant (Secondary style)
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(radius),
        border: borderColor != null
            ? Border.all(color: borderColor!, width: borderWidth)
            : null,
      ),
      child: Center(
        child: Icon(
          icon,
          size: iconSize,
          color: color,
        ),
      ),
    );
  }

  Widget _buildIcon({
    required double iconSize,
    required Color color,
  }) {
    // Deprecated method signature, but keeping for compatibility if called elsewhere
    // The new logic is self-contained in _buildIconContainer to handle the Stack properly
    return Icon(icon, size: iconSize, color: color);
  }
}
