/// Reporting Period Card
/// Per spec: Rounded 20-24, slight elevation, calendar icon in soft accent circle
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../features/expenses/providers/expense_providers.dart';
import 'package:cashpilot/l10n/app_localizations.dart';

class ReportingPeriodCard extends ConsumerWidget {
  final DateTimeRange dateRange;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const ReportingPeriodCard({
    super.key,
    required this.dateRange,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    
    // Calculate comparison data
    final comparisonAsync = ref.watch(_periodComparisonProvider(dateRange));
    
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      onLongPress: () {
        HapticFeedback.mediumImpact();
        onLongPress?.call();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          // Slight elevation y=1-2
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            // Calendar icon in soft accent circle
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.calendar_today_rounded,
                color: AppColors.primaryGreen,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Label: caption style
                  Text(
                    l10n.reportsPeriod,
                    style: AppTypography.labelSmall.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Value: titleMedium
                  Text(
                    _formatDateRange(),
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  // Comparison Indicator
                  comparisonAsync.when(
                    data: (data) {
                      if (data == null) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: _buildTrendIndicator(context, data),
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendIndicator(BuildContext context, PeriodComparisonData data) {
    final l10n = AppLocalizations.of(context)!;
    // Determine color and icon based on change (spending less is good!)
    final isIncrease = data.percentChange > 0;
    final isNeutral = data.percentChange == 0;
    
    // For expenses: Decrease is Green/Good, Increase is Red/Bad
    final color = isNeutral 
        ? Theme.of(context).cardColor.withOpacity(0.5) 
        : (isIncrease ? Colors.red : AppColors.primaryGreen);
        
    final icon = isNeutral
        ? Icons.remove
        : (isIncrease ? Icons.arrow_upward : Icons.arrow_downward);

    final prefix = isIncrease ? '↑' : (isNeutral ? '' : '↓');
    
    return Row(
      children: [
        Text(
          '$prefix${data.percentChange.abs().toStringAsFixed(1)}% ',
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          l10n.reportsVsPrevious,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  String _formatDateRange() {
    final start = DateFormat('MMM d').format(dateRange.start);
    final end = DateFormat('MMM d, yyyy').format(dateRange.end);
    return '$start – $end';
  }
}

/// Data class for comparison result
class PeriodComparisonData {
  final double percentChange;
  final int currentAmount;
  final int previousAmount;
  
  PeriodComparisonData({
    required this.percentChange,
    required this.currentAmount,
    required this.previousAmount,
  });
}

/// Provider to calculate period comparison
final _periodComparisonProvider = Provider.family<AsyncValue<PeriodComparisonData?>, DateTimeRange>((ref, range) {
  final allExpensesAsync = ref.watch(allExpensesProvider);
  
  return allExpensesAsync.whenData((expenses) {
    if (expenses.isEmpty) return null;
    
    // 1. Calculate Previous Range
    final duration = range.duration;
    final previousStart = range.start.subtract(duration);
    final previousEnd = range.start.subtract(const Duration(milliseconds: 1));
    
    // 2. Filter expenses for Current Period
    final currentTotal = expenses
        .where((e) => e.date.isAfter(range.start) && e.date.isBefore(range.end))
        .fold<int>(0, (sum, e) => sum + e.amount);
        
    // 3. Filter expenses for Previous Period
    final previousTotal = expenses
        .where((e) => e.date.isAfter(previousStart) && e.date.isBefore(previousEnd))
        .fold<int>(0, (sum, e) => sum + e.amount);
        
    if (previousTotal == 0) return null; // Can't calculate % change from 0
    
    // 4. Calculate % Change
    final change = ((currentTotal - previousTotal) / previousTotal) * 100;
    
    return PeriodComparisonData(
      percentChange: change,
      currentAmount: currentTotal,
      previousAmount: previousTotal,
    );
  });
});
