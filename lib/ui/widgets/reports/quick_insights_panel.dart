/// Quick Insights Panel - AI Insight Surface
/// Glassmorphism with BackdropFilter, soft mint green
library;

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class QuickInsightsPanel extends StatelessWidget {
  final List<InsightItem> insights;
  final VoidCallback? onTap;

  const QuickInsightsPanel({
    super.key,
    required this.insights,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (insights.isEmpty) return const SizedBox.shrink();

    final displayInsights = insights.take(2).toList(); // Max 2 insights

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap?.call();
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF4ADE80).withValues(alpha: 0.12), // Mint green
                  const Color(0xFF22C55E).withValues(alpha: 0.06),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.success.withValues(alpha: 0.25),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Glowing lightbulb icon
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.success.withValues(alpha: 0.3),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.lightbulb_rounded,
                        color: AppColors.success,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Quick Insights',
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...displayInsights.map((insight) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _InsightRow(insight: insight),
                )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InsightRow extends StatelessWidget {
  final InsightItem insight;

  const _InsightRow({required this.insight});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: insight.color ?? AppColors.primaryGreen,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            insight.text,
            style: AppTypography.bodyMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.85),
            ),
          ),
        ),
        if (insight.trend != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: (insight.trend! > 0 ? AppColors.danger : AppColors.success)
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '${insight.trend! > 0 ? '↑' : '↓'}${insight.trend!.abs()}%',
              style: AppTypography.labelSmall.copyWith(
                color: insight.trend! > 0 ? AppColors.danger : AppColors.success,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}

class InsightItem {
  final String text;
  final Color? color;
  final double? trend;

  const InsightItem({
    required this.text,
    this.color,
    this.trend,
  });
}
