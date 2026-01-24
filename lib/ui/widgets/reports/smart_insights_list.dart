/// Smart Insights List Widget
/// Dynamic text-based insights for Reports screen per UPGRADE_PLAN blueprint
library;

import 'package:flutter/material.dart';
import '../../../core/managers/format_manager.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';

/// Smart insight data model
class SmartInsight {
  final IconData icon;
  final String title;
  final String value;
  final Color color;
  final InsightSentiment sentiment;

  const SmartInsight({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
    this.sentiment = InsightSentiment.neutral,
  });
}

/// Sentiment for visual styling
enum InsightSentiment {
  positive, // Green tint - good news
  negative, // Red tint - warning
  neutral,  // Default - informational
}

/// Smart Insights List per blueprint:
/// - "Highest spend day: Friday (€X)"
/// - "Most repeated merchant: Lidl (8 times)"
/// - "You're on track: 62% budget used, 18 days left"
class SmartInsightsList extends StatelessWidget {
  final List<SmartInsight> insights;
  final String? title;

  const SmartInsightsList({
    super.key,
    required this.insights,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (insights.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Icon(
                  Icons.auto_awesome_outlined,
                  size: 18,
                  color: theme.primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  title!,
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
        ...insights.map((insight) => _InsightRow(insight: insight)),
      ],
    );
  }
}

class _InsightRow extends StatelessWidget {
  final SmartInsight insight;

  const _InsightRow({required this.insight});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Background tint based on sentiment
    final backgroundColor = switch (insight.sentiment) {
      InsightSentiment.positive => AppColors.success.withValues(alpha: 0.08),
      InsightSentiment.negative => AppColors.danger.withValues(alpha: 0.08),
      InsightSentiment.neutral => theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: insight.color.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Icon circle
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: insight.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              insight.icon,
              size: 18,
              color: insight.color,
            ),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.title,
                  style: AppTypography.labelSmall.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  insight.value,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Factory methods to generate common insights
class InsightFactory {
  static SmartInsight highestSpendDay({
    required FormatManager formatManager,
    required String dayName,
    required int amount,
    required String currency,
    required AppLocalizations l10n,
  }) {
    return SmartInsight(
      icon: Icons.calendar_today_outlined,
      title: l10n.insightHighestSpendDay,
      value: l10n.insightHighestSpendDayValue(dayName, formatManager.formatCurrency(amount / 100, currencyCode: currency)),
      color: const Color(0xFFFF9800),
      sentiment: InsightSentiment.neutral,
    );
  }

  static SmartInsight mostRepeatedMerchant({
    required String merchantName,
    required int count,
    required AppLocalizations l10n,
  }) {
    return SmartInsight(
      icon: Icons.store_outlined,
      title: l10n.insightMostVisited,
      value: l10n.insightMostVisitedValue(merchantName, count),
      color: const Color(0xFF2196F3),
      sentiment: InsightSentiment.neutral,
    );
  }

  static SmartInsight budgetOnTrack({
    required int percentUsed,
    required int daysLeft,
    required AppLocalizations l10n,
  }) {
    final isOnTrack = percentUsed <= (100 - (daysLeft * 100 / 30).round());
    return SmartInsight(
      icon: isOnTrack ? Icons.check_circle_outline : Icons.warning_outlined,
      title: isOnTrack ? l10n.insightOnTrack : l10n.insightWatchSpending,
      value: l10n.insightSpendingStatus(percentUsed, daysLeft),
      color: isOnTrack ? AppColors.success : AppColors.danger,
      sentiment: isOnTrack ? InsightSentiment.positive : InsightSentiment.negative,
    );
  }

  static SmartInsight savingsOpportunity({
    required FormatManager formatManager,
    required int savingsAmount,
    required String currency,
    required AppLocalizations l10n,
  }) {
    return SmartInsight(
      icon: Icons.savings_outlined,
      title: l10n.insightPotentialSavings,
      value: formatManager.formatCurrency(savingsAmount / 100, currencyCode: currency),
      color: AppColors.success,
      sentiment: InsightSentiment.positive,
    );
  }

  static SmartInsight overBudgetWarning({
    required FormatManager formatManager,
    required int overBy,
    required String currency,
    required AppLocalizations l10n,
  }) {
    return SmartInsight(
      icon: Icons.warning_amber_outlined,
      title: l10n.insightOverBudget,
      value: l10n.insightExceededBy(formatManager.formatCurrency(overBy / 100, currencyCode: currency)),
      color: AppColors.danger,
      sentiment: InsightSentiment.negative,
    );
  }

  static SmartInsight dailyAverage({
    required FormatManager formatManager,
    required int averageAmount,
    required String currency,
    required AppLocalizations l10n,
  }) {
    return SmartInsight(
      icon: Icons.trending_flat_outlined,
      title: l10n.insightDailyAverage,
      value: formatManager.formatCurrency(averageAmount / 100, currencyCode: currency),
      color: const Color(0xFF9C27B0),
      sentiment: InsightSentiment.neutral,
    );
  }
}
