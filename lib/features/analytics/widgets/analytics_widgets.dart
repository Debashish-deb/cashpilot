import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../providers/analytics_providers.dart';

/// Safe-to-Spend Card (PocketGuard-inspired)
/// Shows daily safe spending amount
class SafeToSpendCard extends ConsumerWidget {
  final double spent;
  final double budget;
  
  const SafeToSpendCard({
    super.key,
    required this.spent,
    required this.budget,
  });
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final forecast = ref.watch(monthEndForecastProvider((spent: spent, budget: budget)));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: forecast.onTrack
              ? [AppColors.primaryGreen, AppColors.primaryGreenDark]
              : [AppColors.warning, AppColors.warningLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (forecast.onTrack ? AppColors.primaryGreen : AppColors.warning)
                .withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.account_balance_wallet_rounded,
                color: Colors.white.withValues(alpha: 0.9),
                size: 24,
              ),
              const SizedBox(width: 10),
              Text(
                'Safe to Spend',
                style: AppTypography.titleMedium.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Main amount
          Text(
            '\$${forecast.safeToSpend.toStringAsFixed(0)}',
            style: AppTypography.displayLarge.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 42,
            ),
          ),
          
          Text(
            'per day for ${forecast.daysRemaining} days',
            style: AppTypography.bodyMedium.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StatColumn(
                label: 'Spent',
                value: '\$${forecast.currentSpent.toStringAsFixed(0)}',
              ),
              _StatColumn(
                label: 'Projected',
                value: '\$${forecast.projectedTotal.toStringAsFixed(0)}',
              ),
              _StatColumn(
                label: 'Budget',
                value: '\$${forecast.budgetLimit.toStringAsFixed(0)}',
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Status indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  forecast.onTrack ? Icons.trending_up : Icons.trending_down,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  forecast.onTrack 
                      ? 'On track to save \$${forecast.projectedSavings.toStringAsFixed(0)}'
                      : 'Over budget by \$${(-forecast.projectedSavings).toStringAsFixed(0)}',
                  style: AppTypography.labelMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
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

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;
  
  const _StatColumn({required this.label, required this.value});
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 11,
          ),
        ),
        Text(
          value,
          style: AppTypography.titleMedium.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// Dashboard mode switcher
class AnalyticsDashboardModeSelector extends ConsumerWidget {
  const AnalyticsDashboardModeSelector({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMode = ref.watch(analyticsDashboardModeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark 
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: AnalyticsDashboardMode.values.map((mode) {
          final isSelected = mode == currentMode;
          return Expanded(
            child: GestureDetector(
              onTap: () => ref.read(analyticsDashboardModeProvider.notifier).state = mode,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Icon(
                      _getModeIcon(mode),
                      size: 18,
                      color: isSelected
                          ? Colors.white
                          : Theme.of(context).hintColor,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getModeLabel(mode),
                      style: AppTypography.labelSmall.copyWith(
                        color: isSelected
                            ? Colors.white
                            : Theme.of(context).hintColor,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
  
  IconData _getModeIcon(AnalyticsDashboardMode mode) {
    switch (mode) {
      case AnalyticsDashboardMode.quick:
        return Icons.flash_on_rounded;
      case AnalyticsDashboardMode.comparison:
        return Icons.compare_arrows_rounded;
      case AnalyticsDashboardMode.trends:
        return Icons.trending_up_rounded;
      case AnalyticsDashboardMode.forecast:
        return Icons.auto_graph_rounded;
    }
  }
  
  String _getModeLabel(AnalyticsDashboardMode mode) {
    switch (mode) {
      case AnalyticsDashboardMode.quick:
        return 'Quick';
      case AnalyticsDashboardMode.comparison:
        return 'Compare';
      case AnalyticsDashboardMode.trends:
        return 'Trends';
      case AnalyticsDashboardMode.forecast:
        return 'Forecast';
    }
  }
}

/// Health Score Ring Widget
class HealthScoreRing extends StatelessWidget {
  final int score; // 0-100
  final double size;
  
  const HealthScoreRing({
    super.key,
    required this.score,
    this.size = 120,
  });
  
  @override
  Widget build(BuildContext context) {
    final color = _getScoreColor(score);
    
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background ring
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: 1.0,
              strokeWidth: 10,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation(color.withValues(alpha: 0.2)),
            ),
          ),
          // Progress ring
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: score / 100,
              strokeWidth: 10,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation(color),
              strokeCap: StrokeCap.round,
            ),
          ),
          // Score text
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                score.toString(),
                style: AppTypography.displayMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                _getScoreLabel(score),
                style: AppTypography.labelSmall.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Color _getScoreColor(int score) {
    if (score >= 80) return AppColors.success;
    if (score >= 60) return AppColors.warning;
    if (score >= 40) return Colors.orange;
    return AppColors.danger;
  }
  
  String _getScoreLabel(int score) {
    if (score >= 80) return 'Excellent';
    if (score >= 60) return 'Good';
    if (score >= 40) return 'Fair';
    return 'Needs Work';
  }
}
