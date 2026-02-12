import 'dart:ui';
import 'package:flutter/material.dart';

/// A container that applies a blur effect to the background (Glassmorphism).
/// Optimized for AMOLED Apple style (dark glass on black).
class GlassContainer extends StatelessWidget {
  final Widget? child;
  final double blur;
  final double opacity;
  final Color? color;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Border? border;
  final Gradient? gradient;

  const GlassContainer({
    super.key,
    this.child,
    this.blur = 20, // High blur for premium feel
    this.opacity = 0.08, // Subtle opacity for dark mode readability
    this.color,
    this.borderRadius,
    this.padding,
    this.margin,
    this.border,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // AMOLED Apple Style: Very dark surface with high blur
    final effectiveColor = color ?? 
        (isDark ? Colors.white : Colors.black).withValues(alpha: opacity);

    final effectiveBorder = border ?? 
        Border.all(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
          width: 0.5,
        );
        
    final effectiveRadius = borderRadius ?? BorderRadius.circular(20);

    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: effectiveRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: effectiveColor,
              borderRadius: effectiveRadius,
              border: effectiveBorder,
              gradient: gradient,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// A Card variant that uses [GlassContainer].
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  const GlassCard({
    super.key, 
    required this.child, 
    this.padding, 
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final body = GlassContainer(
      padding: padding ?? const EdgeInsets.all(16),
      margin: margin,
      borderRadius: BorderRadius.circular(24), // Apple style rounded corners
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: body,
      );
    }
    return body;
  }
}
