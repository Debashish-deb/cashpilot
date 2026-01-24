import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../widgets/common/progress_bar.dart';

class SavingsGoalCard extends StatelessWidget {
  final String title;
  final int currentAmount;
  final int targetAmount;
  final String currency;
  final String? iconName;
  final Color? color;
  final DateTime? deadline;
  final VoidCallback onTap;
  final VoidCallback onAddMoney;

  const SavingsGoalCard({
    super.key,
    required this.title,
    required this.currentAmount,
    required this.targetAmount,
    required this.currency,
    this.iconName,
    this.color,
    this.deadline,
    required this.onTap,
    required this.onAddMoney,
  });

  @override
  Widget build(BuildContext context) {
    final progress = targetAmount > 0 ? (currentAmount / targetAmount).clamp(0.0, 1.0) : 0.0;
    final percentage = (progress * 100).toInt();
    final remaining = targetAmount - currentAmount;
    final themeColor = color ?? Theme.of(context).primaryColor;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          // Solid background from theme surface
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20), // 20dp per featurelytics
          border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.04), // Subtle border
            width: 1,
          ),
          boxShadow: Theme.of(context).brightness == Brightness.dark
              ? [
                  BoxShadow(
                    color: (color ?? Theme.of(context).primaryColor).withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 2),
                  )
                ]
              : [
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
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: themeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    _getIcon(iconName),
                    color: themeColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        deadline != null 
                            ? 'Goal by ${DateFormat.yMMMd().format(deadline!)}' 
                            : 'No deadline',
                        style: AppTypography.bodySmall.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                _buildPercentageBadge(context, percentage, themeColor),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Saved',
                      style: AppTypography.labelSmall.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatCurrency(currentAmount, currency),
                      style: AppTypography.titleLarge.copyWith(
                        fontWeight: FontWeight.bold,
                        color: themeColor,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Target',
                      style: AppTypography.labelSmall.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatCurrency(targetAmount, currency),
                      style: AppTypography.titleSmall.copyWith(
                         fontWeight: FontWeight.w600,
                         color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            BudgetProgressBar(
              progress: progress,
              height: 12,
              color: themeColor,
              backgroundColor: themeColor.withValues(alpha: 0.1),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: remaining > 0 
                  ? Text(
                      '${_formatCurrency(remaining, currency)} left to go',
                      style: AppTypography.bodySmall.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    )
                  : Text(
                      'Goal Reached! 🎉',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ),
                TextButton.icon(
                  onPressed: onAddMoney,
                  style: TextButton.styleFrom(
                    backgroundColor: themeColor.withValues(alpha: 0.1),
                    foregroundColor: themeColor,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add Money'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPercentageBadge(BuildContext context, int percentage, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$percentage%',
        style: AppTypography.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _formatCurrency(int amountInCents, String currency) {
    final amount = amountInCents / 100;
    return NumberFormat.simpleCurrency(name: currency, decimalDigits: 0).format(amount);
  }

  IconData _getIcon(String? iconName) {
    // simplified map
    switch (iconName) {
      case 'home': return Icons.home_rounded;
      case 'car': return Icons.directions_car_rounded;
      case 'vacation': return Icons.flight_takeoff_rounded;
      case 'emergency': return Icons.health_and_safety_rounded;
      case 'electronics': return Icons.devices_rounded;
      default: return Icons.savings_rounded;
    }
  }
}
