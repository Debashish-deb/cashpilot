import 'package:flutter/material.dart';
import '../../../core/theme/app_typography.dart';
import 'glass_card.dart';

enum InsightCardVariant {
  hero,       // For Health Score
  runway,     // For Month Outlook
  pulse,      // For Cash Flow
  alert       // For Smart Alerts
}

class InsightCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final Widget? indicator;
  final InsightCardVariant variant;
  final VoidCallback? onTap;
  final Color? accentColor;
  final LinearGradient? gradient;
  final double? minHeight;

  const InsightCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    this.indicator,
    this.variant = InsightCardVariant.pulse,
    this.onTap,
    this.accentColor,
    this.gradient,
    this.minHeight,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final cardColor = isDark 
        ? theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.8)
        : Colors.white;
        
    final border = Border.all(
      color: isDark 
          ? theme.dividerColor.withValues(alpha: 0.1) 
          : theme.dividerColor.withValues(alpha: 0.2),
      width: 1,
    );

    return GlassCard(
      onTap: onTap,
      borderRadius: 16,
      color: cardColor,
      border: border,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      gradient: gradient,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelSmall.copyWith(
                    letterSpacing: 1.0,
                    fontWeight: FontWeight.w700,
                    fontSize: 8.5,
                    color: (gradient != null || isDark) 
                        ? Colors.white.withValues(alpha: 0.7) 
                        : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ),
              if (indicator != null) ...[
                const SizedBox(width: 4),
                indicator!,
              ],
            ],
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: AppTypography.titleLarge.copyWith(
                fontWeight: FontWeight.w900,
                fontSize: variant == InsightCardVariant.hero ? 20 : 16,
                letterSpacing: -0.5,
                color: (gradient != null || isDark) ? Colors.white : theme.colorScheme.onSurface,
              ),
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 1),
            Text(
              subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodySmall.copyWith(
                fontSize: 8.5,
                color: (gradient != null || isDark) 
                    ? Colors.white.withValues(alpha: 0.8) 
                    : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
