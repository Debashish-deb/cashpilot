import 'package:cashpilot/data/drift/app_database.dart' show Budget;
import 'package:cashpilot/l10n/app_localizations.dart' show AppLocalizations;
import 'package:flutter/material.dart';
import '../../../../core/theme/tokens.g.dart';
import 'package:intl/intl.dart';

/// Overspend Forecast Bar
/// Shows budget health forecast based on current spending rate
class OverspendForecastBar extends StatelessWidget {
  final Budget budget;
  final int totalSpent;
  final String currency;

  const OverspendForecastBar({
    super.key,
    required this.budget,
    required this.totalSpent,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final totalLimit = budget.totalLimit;
    if (totalLimit == null || totalLimit == 0) return const SizedBox.shrink();
    
    final start = budget.startDate;
    final end = budget.endDate;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final totalDays = end.difference(start).inDays + 1;
    final daysPassed = today.difference(start).inDays + 1;

    // Guard rails
    if (daysPassed <= 0 || totalDays <= 0) return const SizedBox.shrink();
    if (daysPassed >= totalDays) return const SizedBox.shrink();

    // Prevent extreme volatility early in the budget
    final effectiveDays = daysPassed.clamp(3, totalDays);

    final dailyRunRate = totalSpent / effectiveDays;
    final forecastedTotal = dailyRunRate * totalDays;
    final projectedDelta = forecastedTotal - totalLimit;

    // Ignore noise under ±3%
    final deviationRatio = (projectedDelta.abs() / totalLimit);
    if (deviationRatio < 0.03) return const SizedBox.shrink();

    final bool isOverspending = projectedDelta > 0;

    late final Color color;
    late final IconData icon;
    late final String message;

    if (isOverspending) {
      icon = Icons.trending_up;

      if (totalSpent > totalLimit) {
        color = AppTokens.semanticDanger;
        message =
            "Budget exceeded by ${_formatMoney(context, (totalSpent - totalLimit).toInt())}";
      } else {
        color = AppTokens.semanticWarning;
        message =
            "On pace to exceed by ${_formatMoney(context, projectedDelta.round())}";
      }
    } else {
      icon = Icons.trending_flat;
      color = AppTokens.semanticSuccess;
      message =
          "On track to save ${_formatMoney(context, projectedDelta.abs().round())}";
    }

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ).copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }

  String _formatMoney(BuildContext context, int amount) {
    final format = NumberFormat.currency(
      locale: AppLocalizations.of(context)!.localeName,
      symbol: currency,
      decimalDigits: 0,
    ).format(amount / 100.0);
    return format;
  }
}
