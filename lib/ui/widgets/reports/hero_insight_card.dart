/// Hero Insight Card Widget
/// Main insight card for Reports screen per UPGRADE_PLAN blueprint
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/managers/format_manager.dart';
import '../../../core/providers/app_providers.dart';
import '../../../l10n/app_localizations.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// Hero Insight Card - The main "at-a-glance" insight for Reports
/// Per blueprint:
/// - "This month you spent €X"
/// - Comparison: "↑12% vs last month"
/// - Top categories chips (max 3)
/// - CTA: "See breakdown"
class HeroInsightCard extends ConsumerWidget {
  final int totalSpent;
  final int lastMonthSpent;
  final List<CategoryChipData> topCategories;
  final VoidCallback? onSeeBreakdown;

  const HeroInsightCard({
    super.key,
    required this.totalSpent,
    required this.lastMonthSpent,
    this.topCategories = const [],
    this.onSeeBreakdown,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final formatManager = ref.watch(formatManagerProvider);
    final currency = ref.watch(currencyProvider);
    final l10n = AppLocalizations.of(context)!;
    final isDark = theme.brightness == Brightness.dark;

    // Calculate percentage change
    final percentChange = lastMonthSpent > 0
        ? ((totalSpent - lastMonthSpent) / lastMonthSpent * 100).round()
        : 0;
    final isIncrease = percentChange > 0;
    final changeColor = isIncrease ? AppColors.danger : AppColors.success;
    final changeIcon = isIncrease ? Icons.arrow_upward : Icons.arrow_downward;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  theme.primaryColor.withValues(alpha: 0.25),
                  theme.primaryColor.withValues(alpha: 0.10),
                ]
              : [
                  theme.primaryColor.withValues(alpha: 0.12),
                  theme.primaryColor.withValues(alpha: 0.04),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.primaryColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with icon
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.insights_outlined,
                  color: theme.primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                l10n.reportsThisMonth,
                style: AppTypography.labelLarge.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Main spending amount
          Text(
            formatManager.formatCurrency(totalSpent / 100, currencyCode: currency),
            style: AppTypography.displaySmall.copyWith(
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface,
              letterSpacing: -1,
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Comparison row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: changeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(changeIcon, size: 14, color: changeColor),
                    const SizedBox(width: 4),
                    Text(
                      formatManager.formatPercentage(percentChange.abs() / 100),
                      style: AppTypography.labelMedium.copyWith(
                        color: changeColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                l10n.reportsVsLastMonth,
                style: AppTypography.bodySmall.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          
          // Top categories (max 3)
          if (topCategories.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              l10n.reportsTopCategories,
              style: AppTypography.labelSmall.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: topCategories.take(3).map((cat) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: cat.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: cat.color.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: cat.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        cat.name,
                        style: AppTypography.labelSmall.copyWith(
                          color: cat.color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
          
          // CTA button
          if (onSeeBreakdown != null) ...[
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  onSeeBreakdown!();
                },
                icon: const Icon(Icons.pie_chart_outline, size: 18),
                label: Text(l10n.reportsSeeBreakdown),
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.primaryColor,
                  side: BorderSide(
                    color: theme.primaryColor.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Data class for category chips
class CategoryChipData {
  final String name;
  final Color color;
  final int amount;

  const CategoryChipData({
    required this.name,
    required this.color,
    required this.amount,
  });
}
