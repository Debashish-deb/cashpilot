import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import 'package:intl/intl.dart';

enum BudgetHealth {
  ok,
  watch,
  risk,
  inactive,
}

enum _ChipStyle { success, warning, danger, neutral }

class BudgetHealthChip extends StatelessWidget {
  final DateTime startDate;
  final DateTime endDate;
  final int totalLimit;
  final int totalSpent;
  final bool isCompact;

  const BudgetHealthChip({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.totalLimit,
    required this.totalSpent,
    this.isCompact = true,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    // Normalize dates (important for stability)
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);
    final today = DateTime(now.year, now.month, now.day);

    final isBefore = today.isBefore(start);
    final isAfter = today.isAfter(end);

    if (isBefore) {
      return _buildChip(
        context,
        'Upcoming',
        _ChipStyle.neutral,
        'Budget starts on ${DateFormat('MMM d').format(start)}',
      );
    }

    if (isAfter) {
      return _buildChip(
        context,
        'Completed',
        _ChipStyle.neutral,
        'Budget period has ended',
      );
    }

    if (totalLimit <= 0) {
      return _buildChip(
        context,
        'No Limit',
        _ChipStyle.neutral,
        'No budget limit has been set',
      );
    }

    final totalDays = end.difference(start).inDays + 1;
    final daysPassed = today.difference(start).inDays + 1;
    final daysLeft = (totalDays - daysPassed).clamp(0, totalDays);

    final percentTimePassed =
        (daysPassed / totalDays).clamp(0.0, 1.0);
    final percentMoneySpent =
        (totalSpent / totalLimit).clamp(0.0, 1.5);

    // Early-period tolerance (critical UX fix)
    final bool isEarlyPeriod = daysPassed <= 3;

    BudgetHealth health;
    String statusLabel;
    _ChipStyle chipStyle;

    if (percentMoneySpent >= 1.0) {
      health = BudgetHealth.risk;
      statusLabel = 'Exceeded';
      chipStyle = _ChipStyle.danger;
    } else if (!isEarlyPeriod &&
        percentMoneySpent > percentTimePassed + 0.15) {
      health = BudgetHealth.risk;
      statusLabel = 'Risk';
      chipStyle = _ChipStyle.danger;
    } else if (!isEarlyPeriod &&
        percentMoneySpent > percentTimePassed + 0.07) {
      health = BudgetHealth.watch;
      statusLabel = 'Watch';
      chipStyle = _ChipStyle.warning;
    } else {
      health = BudgetHealth.ok;
      statusLabel = 'Healthy';
      chipStyle = _ChipStyle.success;
    }

    final percentStr = (percentMoneySpent * 100).round();
    final explanation =
        'You’ve spent $percentStr% of your budget with $daysLeft days remaining.';

    return GestureDetector(
      onTap: () => _showExplanation(
        context,
        statusLabel,
        explanation,
        _getColor(health),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: chipStyle == _ChipStyle.danger
              ? Colors.white
              : chipStyle == _ChipStyle.success
                  ? Colors.white.withValues(alpha: 0.25)
                  : Colors.amber.shade900.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: chipStyle == _ChipStyle.danger
                ? Colors.red.shade700.withValues(alpha: 0.4)
                : Colors.white.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: chipStyle == _ChipStyle.danger
                    ? Colors.red.shade700
                    : Colors.white,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              statusLabel,
              style: AppTypography.labelSmall.copyWith(
                color: chipStyle == _ChipStyle.danger
                    ? Colors.red.shade700
                    : Colors.white,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(
    BuildContext context,
    String label,
    _ChipStyle style,
    String explanation,
  ) {
    final bgColor = style == _ChipStyle.danger
        ? Colors.white
        : style == _ChipStyle.neutral
            ? Colors.white.withValues(alpha: 0.2)
            : style == _ChipStyle.success
                ? Colors.white.withValues(alpha: 0.25)
                : Colors.amber.shade900.withValues(alpha: 0.6);

    final textColor =
        style == _ChipStyle.danger ? Colors.red.shade700 : Colors.white;

    final borderColor = style == _ChipStyle.danger
        ? Colors.red.shade700.withValues(alpha: 0.4)
        : Colors.white.withValues(alpha: 0.3);

    return GestureDetector(
      onTap: () =>
          _showExplanation(context, label, explanation, Colors.white),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
        ),
        child: Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Color _getColor(BudgetHealth health) {
    switch (health) {
      case BudgetHealth.ok:
        return AppColors.success;
      case BudgetHealth.watch:
        return AppColors.warning;
      case BudgetHealth.risk:
        return AppColors.danger;
      case BudgetHealth.inactive:
        return AppColors.neutral60;
    }
  }

  void _showExplanation(
    BuildContext context,
    String title,
    String message,
    Color color,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: color),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: AppTypography.titleLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(message, style: AppTypography.bodyMedium),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: color.withValues(alpha: 0.1),
                  foregroundColor: color,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding:
                      const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text('Got it'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
