import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/drift/app_database.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../widgets/common/app_grade_icons.dart';
import '../../../widgets/common/glass_card.dart';

class SavingsGoalCard extends ConsumerWidget {
  final SavingsGoal goal;
  final VoidCallback onTap;

  const SavingsGoalCard({
    super.key,
    required this.goal,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final percent = (goal.currentAmount / goal.targetAmount).clamp(0.0, 1.0);
    final color = goal.colorHex != null 
        ? Color(int.parse(goal.colorHex!.replaceFirst('#', '0xFF'))) 
        : theme.primaryColor;

    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  AppGradeIcons.getIcon(goal.iconName),
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.title,
                      style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (goal.deadline != null)
                      Text(
                        'Target: ${_formatDate(goal.deadline!)}',
                        style: AppTypography.bodySmall.copyWith(color: Colors.grey),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatCurrency(goal.currentAmount, goal.currency),
                style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold, color: color),
              ),
              Text(
                _formatCurrency(goal.targetAmount, goal.currency),
                style: AppTypography.bodySmall.copyWith(color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent,
              backgroundColor: color.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatCurrency(int amountInCents, String currency) {
    final amount = amountInCents / 100.0;
    // Basic formatting - in a real app use intl package
    return '${_getCurrencySymbol(currency)}${amount.toStringAsFixed(0)}';
  }

  String _getCurrencySymbol(String code) =>
      {'EUR': '€', 'USD': '\$', 'GBP': '£'}[code] ?? code;
}
