/// Budget Impact Badge Widget
/// Shows real-time budget usage percentage with color coding
library;

import 'package:flutter/material.dart';

class BudgetImpactBadge extends StatelessWidget {
  final double percentage;
  final String budgetName;

  const BudgetImpactBadge({
    super.key,
    required this.percentage,
    required this.budgetName,
  });

  /// Automatically normalizes ratio 0..1 to 0..100%
  double get _normalizedPercentage =>
      (percentage > 0.0 && percentage <= 1.0) ? percentage * 100.0 : percentage;

  Color _getColor(BuildContext context) {
    final p = _normalizedPercentage;
    if (p > 100) return Colors.red;
    if (p > 90) return Colors.deepOrange;
    if (p > 75) return Colors.orange;
    return Colors.green;
  }

  IconData _getIcon() {
    final p = _normalizedPercentage;
    if (p > 100) return Icons.error;
    if (p > 90) return Icons.warning;
    if (p > 75) return Icons.info;
    return Icons.check_circle;
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor(context);
    final displayPercent = _normalizedPercentage.round();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getIcon(),
            size: 16,
            color: color,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              '$displayPercent% of $budgetName used',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
