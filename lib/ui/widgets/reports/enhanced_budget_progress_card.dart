/// Enhanced Budget Progress Card
/// Gradient strip, rounded progress bar, color thresholds (60%, 85%, 100%)
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/managers/format_manager.dart';
import '../../../core/providers/app_providers.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/theme/tokens.g.dart';
import '../../../core/theme/app_typography.dart';

class EnhancedBudgetProgressCard extends ConsumerWidget {
  final String title;
  final int spent;
  final int limit;
  final Color? accentColor;
  final VoidCallback? onTap;
  final bool hasAnomaly; // ML: spending spike detected

  const EnhancedBudgetProgressCard({
    super.key,
    required this.title,
    required this.spent,
    required this.limit,
    this.accentColor,
    this.onTap,
    this.hasAnomaly = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formatManager = ref.watch(formatManagerProvider);
    final currency = ref.watch(currencyProvider);
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return const SizedBox.shrink();
    final progress = limit > 0 ? (spent / limit).clamp(0.0, 1.5) : 0.0;
    final progressColor = _getProgressColor(progress);
    final remaining = limit - spent;
    final isOverBudget = spent > limit;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap?.call();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            // Gradient strip on left
            Container(
              width: 6,
              height: 80,
              decoration: BoxDecoration(
                color: accentColor ?? progressColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: AppTypography.titleSmall.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (hasAnomaly)
                          Tooltip(
                            message: l10n.reportsAnomalousSpendingSpike,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: AppTokens.semanticWarning.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.warning_amber_rounded,
                                size: 14,
                                color: AppTokens.semanticWarning,
                              ),
                            ),
                          ),
                        _buildPercentBadge(progress, isOverBudget, formatManager),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Rounded progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Stack(
                        children: [
                          Container(
                            height: 10,
                            decoration: BoxDecoration(
                              color: progressColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: progress.clamp(0.0, 1.0),
                            child: Container(
                              height: 10,
                              decoration: BoxDecoration(
                                color: progressColor,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          formatManager.formatCurrency(spent / 100, currencyCode: currency),
                          style: AppTypography.labelMedium.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          isOverBudget
                              ? '-${formatManager.formatCurrency(remaining.abs() / 100, currencyCode: currency)}'
                              : '${formatManager.formatCurrency(remaining / 100, currencyCode: currency)} ${l10n.reportsLeft}',
                          style: AppTypography.labelMedium.copyWith(
                            color: isOverBudget ? AppTokens.semanticDanger : AppTokens.semanticSuccess,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPercentBadge(double progress, bool isOverBudget, FormatManager formatManager) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isOverBudget
            ? AppTokens.semanticDanger.withValues(alpha: 0.1)
            : AppTokens.semanticSuccess.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isOverBudget
              ? AppTokens.semanticDanger.withValues(alpha: 0.3)
              : AppTokens.semanticSuccess.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        formatManager.formatPercentage(progress),
        style: AppTypography.labelSmall.copyWith(
          color: isOverBudget ? AppTokens.semanticDanger : AppTokens.semanticSuccess,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _getProgressColor(double progress) {
    if (progress >= 1.0) return AppTokens.semanticDanger;
    if (progress >= 0.85) return AppTokens.semanticWarning;
    if (progress >= 0.60) return AppTokens.semanticCaution;
    return AppTokens.semanticSuccess;
  }
}
