/// Category Limit Card Widget
/// Displays a category with its budget limit, progress, and subcategories
library;

import 'package:flutter/material.dart';

/// Card showing category budget with limit and progress
class CategoryLimitCard extends StatelessWidget {
  final String name;
  final IconData icon;
  final int limitAmount; // in cents
  final int spentAmount; // in cents
  final Color? color;
  final List<SubcategoryInfo>? subcategories;
  final bool isExpanded;
  final VoidCallback? onTap;
  final Function(int)? onLimitChanged;
  final String currencySymbol;

  const CategoryLimitCard({
    super.key,
    required this.name,
    required this.icon,
    required this.limitAmount,
    required this.spentAmount,
    this.color,
    this.subcategories,
    this.isExpanded = false,
    this.onTap,
    this.onLimitChanged,
    this.currencySymbol = '\$',
  });

  double get percentage => limitAmount > 0 ? (spentAmount / limitAmount) * 100 : 0;
  int get remaining => limitAmount - spentAmount;

  Color _getHealthColor() {
    if (percentage >= 100) return Colors.red;
    if (percentage >= 90) return Colors.deepOrange;
    if (percentage >= 75) return Colors.orange;
    return Colors.green;
  }

  IconData _getStatusIcon() {
    if (percentage >= 100) return Icons.error;
    if (percentage >= 90) return Icons.warning;
    if (percentage >= 75) return Icons.info;
    return Icons.check_circle;
  }

  String _formatAmount(int cents) {
    return '$currencySymbol${(cents / 100).toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final healthColor = _getHealthColor();
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  // Icon
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: (color ?? theme.colorScheme.primary).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      icon,
                      color: color ?? theme.colorScheme.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Name and limit
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Limit: ${_formatAmount(limitAmount)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: healthColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_getStatusIcon(), size: 14, color: healthColor),
                        const SizedBox(width: 4),
                        Text(
                          '${percentage.toInt()}%',
                          style: TextStyle(
                            color: healthColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Expand icon
                  if (subcategories != null && subcategories!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Icon(
                        isExpanded ? Icons.expand_less : Icons.expand_more,
                        color: theme.iconTheme.color?.withOpacity(0.5),
                      ),
                    ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (percentage / 100).clamp(0.0, 1.0),
                  backgroundColor: theme.dividerColor,
                  valueColor: AlwaysStoppedAnimation(healthColor),
                  minHeight: 6,
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Spent / Remaining row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Spent: ${_formatAmount(spentAmount)}',
                    style: theme.textTheme.bodySmall,
                  ),
                  Text(
                    remaining >= 0 
                        ? 'Remaining: ${_formatAmount(remaining)}'
                        : 'Over by: ${_formatAmount(-remaining)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: remaining >= 0 ? Colors.green : Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              
              // Subcategories (if expanded)
              if (isExpanded && subcategories != null && subcategories!.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 12),
                ...subcategories!.map((sub) => _buildSubcategoryRow(sub, theme)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubcategoryRow(SubcategoryInfo sub, ThemeData theme) {
    final subPercentage = sub.limit > 0 ? (sub.spent / sub.limit) * 100 : 0;
    final subColor = subPercentage >= 100 ? Colors.red : 
                     subPercentage >= 75 ? Colors.orange : Colors.green;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 8),
      child: Row(
        children: [
          Icon(sub.icon, size: 18, color: theme.iconTheme.color?.withOpacity(0.6)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(sub.name, style: theme.textTheme.bodyMedium),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: (subPercentage / 100).clamp(0.0, 1.0),
                    backgroundColor: theme.dividerColor,
                    valueColor: AlwaysStoppedAnimation(subColor),
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${_formatAmount(sub.spent)}/${_formatAmount(sub.limit)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: subColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Subcategory info for display
class SubcategoryInfo {
  final String name;
  final IconData icon;
  final int spent;
  final int limit;

  const SubcategoryInfo({
    required this.name,
    required this.icon,
    required this.spent,
    required this.limit,
  });
}
