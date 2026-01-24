import 'package:flutter/material.dart';

/// Premium Card Widget with solid background
/// Following featurelytics.md: No transparency, solid backgrounds
/// 20dp border radius, 16dp inner padding, subtle shadows
class GlassCard extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Color? color;
  final bool isPrimary;
  final LinearGradient? gradient;
  final Border? border;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius = 20.0,
    this.color,
    this.isPrimary = false,
    this.gradient,
    this.border,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Solid background color - no transparency
    final effectiveColor = color ?? theme.colorScheme.surface;
    
    // Border based on theme
    final effectiveBorder = border ?? Border.all(
      color: isDark 
          ? Colors.white.withValues(alpha: 0.08) 
          : Colors.black.withValues(alpha: 0.04),
      width: 1,
    );
    
    // Shadow for light mode, glow for dark mode (per featurelytics)
    final shadows = isDark 
        ? [
            // Dark mode: subtle glow effect
            BoxShadow(
              color: theme.colorScheme.primary.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ]
        : [
            // Light mode: subtle shadow (4-6dp per featurelytics)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ];

    Widget card = Container(
      width: width,
      height: height,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: gradient == null ? effectiveColor : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(borderRadius),
        border: effectiveBorder,
        boxShadow: isPrimary 
            ? [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ]
            : shadows,
      ),
      child: child,
    );

    if (margin != null) {
      card = Padding(padding: margin!, child: card);
    }

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: card,
        ),
      );
    }

    return card;
  }
}

/// Primary Card - for the one main card per screen
/// Per featurelytics: "Exactly one primary card per screen"
class PrimaryCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final LinearGradient? gradient;
  final VoidCallback? onTap;

  const PrimaryCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.gradient,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      isPrimary: true,
      padding: padding ?? const EdgeInsets.all(20),
      margin: margin,
      gradient: gradient,
      onTap: onTap,
      child: child,
    );
  }
}

/// Secondary Card - supporting information
class SecondaryCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  const SecondaryCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: padding ?? const EdgeInsets.all(16),
      margin: margin,
      onTap: onTap,
      child: child,
    );
  }
}

/// Info Card with icon, title, value, and optional helper text
/// Follows featurelytics: Never show more than 2 font sizes per card
class InfoCard extends StatelessWidget {
  final String title;
  final String value;
  final String? helperText;
  final IconData? icon;
  final Color? iconColor;
  final VoidCallback? onTap;
  final bool isPrimary;

  const InfoCard({
    super.key,
    required this.title,
    required this.value,
    this.helperText,
    this.icon,
    this.iconColor,
    this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = iconColor ?? theme.colorScheme.primary;
    
    return GlassCard(
      isPrimary: isPrimary,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 20, color: color),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ),
              if (onTap != null)
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
              letterSpacing: -0.5,
            ),
          ),
          if (helperText != null) ...[
            const SizedBox(height: 8),
            Text(
              helperText!,
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Stat Row Card - for showing multiple stats in a row
class StatRowCard extends StatelessWidget {
  final List<StatItem> stats;
  final VoidCallback? onTap;

  const StatRowCard({
    super.key,
    required this.stats,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      child: Row(
        children: stats.asMap().entries.map((entry) {
          final index = entry.key;
          final stat = entry.value;
          return Expanded(
            child: Row(
              children: [
                if (index > 0)
                  Container(
                    width: 1,
                    height: 40,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
                  ),
                Expanded(child: _buildStatColumn(context, stat)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatColumn(BuildContext context, StatItem stat) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          stat.label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            if (stat.icon != null) ...[
              Icon(stat.icon, size: 16, color: stat.color ?? theme.colorScheme.primary),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                stat.value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: stat.color ?? theme.colorScheme.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class StatItem {
  final String label;
  final String value;
  final IconData? icon;
  final Color? color;

  const StatItem({
    required this.label,
    required this.value,
    this.icon,
    this.color,
  });
}
