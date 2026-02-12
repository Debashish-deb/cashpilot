import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cashpilot/l10n/app_localizations.dart';
import 'contribute_dialog.dart';
import 'withdraw_dialog.dart';
import '../../../../features/savings_goals/domain/entities/savings_goal.dart'; // Correct entity
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
    final format = NumberFormat.currency(
      locale: AppLocalizations.of(context)!.localeName, // Corrected line
      symbol: goal.currency, // Added symbol for currency formatting
      decimalDigits: 0, // Assuming whole numbers for currency display
    );
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
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => showDialog(
                    context: context,
                    builder: (context) => ContributeDialog(goal: goal),
                  ),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Money'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: color,
                    side: BorderSide(color: color),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => showDialog(
                    context: context,
                    builder: (context) => WithdrawDialog(goal: goal),
                   ),
                  icon: const Icon(Icons.remove, size: 16),
                  label: const Text('Withdraw'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade300,
                    side: BorderSide(color: Colors.red.shade300),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatCurrency(context, goal.currentAmount, goal.currency),
                style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold, color: color),
              ),
              Text(
                _formatCurrency(context, goal.targetAmount, goal.currency),
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

  String _formatCurrency(BuildContext context, int amountInCents, String currency) {
    final amount = amountInCents / 100.0;
    // Basic formatting - in a real app use intl package
    return '${_getCurrencySymbol(currency)}${amount.toStringAsFixed(0)}';
  }

  String _getCurrencySymbol(String code) =>
      {'EUR': '€', 'USD': '\$', 'GBP': '£'}[code] ?? code;
}
