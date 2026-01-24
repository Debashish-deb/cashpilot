/// Category Selector Widget
/// Allows selecting category and subcategory for expenses
library;

import 'package:flutter/material.dart';
import 'package:cashpilot/l10n/app_localizations.dart';
import '../../../core/constants/category_templates.dart';

/// Category selector with subcategory support
class CategorySelector extends StatefulWidget {
  final CategoryGroup? selectedCategory;
  final String? selectedSubcategory;
  final Function(CategoryGroup) onCategorySelected;
  final Function(String) onSubcategorySelected;
  final Map<String, CategoryBudgetStatus>? budgetStatus; // Category ID -> status

  const CategorySelector({
    super.key,
    this.selectedCategory,
    this.selectedSubcategory,
    required this.onCategorySelected,
    required this.onSubcategorySelected,
    this.budgetStatus,
  });

  @override
  State<CategorySelector> createState() => _CategorySelectorState();
}

class _CategorySelectorState extends State<CategorySelector> {
  bool _showSubcategories = false;

  @override
  void didUpdateWidget(CategorySelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedCategory != oldWidget.selectedCategory) {
      _showSubcategories = widget.selectedCategory != null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category chips (horizontal scroll)
        Text(
          AppLocalizations.of(context)!.categorySelectorLabel,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.textTheme.labelSmall?.color?.withOpacity(0.6),
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        
        SizedBox(
          height: 44,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: CategoryGroup.values.length,
            itemBuilder: (context, index) {
              final category = CategoryGroup.values[index];
              final isSelected = category == widget.selectedCategory;
              final status = widget.budgetStatus?[category.name];
              
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _CategoryChip(
                  category: category,
                  isSelected: isSelected,
                  status: status,
                  onTap: () {
                    widget.onCategorySelected(category);
                    setState(() => _showSubcategories = true);
                  },
                ),
              );
            },
          ),
        ),
        
        // Subcategories (shown when category selected)
        if (_showSubcategories && widget.selectedCategory != null) ...[
          const SizedBox(height: 16),
          _buildSubcategorySection(theme),
        ],
      ],
    );
  }

  Widget _buildSubcategorySection(ThemeData theme) {
    final subcategories = CategoryTemplates.getSubcategories(widget.selectedCategory!);
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                widget.selectedCategory!.icon,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                widget.selectedCategory!.name,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              // Show budget status if available
              if (widget.budgetStatus != null)
                _buildBudgetStatusBadge(theme),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: subcategories.map((sub) {
              final isSelected = sub.name == widget.selectedSubcategory;
              
              return ChoiceChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(sub.icon, size: 16),
                    const SizedBox(width: 6),
                    Text(sub.name),
                  ],
                ),
                selected: isSelected,
                onSelected: (_) => widget.onSubcategorySelected(sub.name),
                selectedColor: theme.colorScheme.primary.withOpacity(0.2),
                labelStyle: TextStyle(
                  color: isSelected ? theme.colorScheme.primary : null,
                  fontWeight: isSelected ? FontWeight.w600 : null,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetStatusBadge(ThemeData theme) {
    final status = widget.budgetStatus?[widget.selectedCategory!.name];
    if (status == null) return const SizedBox.shrink();
    
    final percentage = status.percentage;
    final color = percentage >= 100 ? Colors.red :
                  percentage >= 75 ? Colors.orange : Colors.green;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        AppLocalizations.of(context)!.categoryUsagePercent(percentage.toInt()),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Simple category chip
class _CategoryChip extends StatelessWidget {
  final CategoryGroup category;
  final bool isSelected;
  final CategoryBudgetStatus? status;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.category,
    required this.isSelected,
    this.status,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Material(
      color: isSelected 
          ? theme.colorScheme.primary.withOpacity(0.15)
          : theme.cardColor,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected 
                  ? theme.colorScheme.primary 
                  : theme.dividerColor,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                category.icon,
                size: 18,
                color: isSelected ? theme.colorScheme.primary : null,
              ),
              const SizedBox(width: 8),
              Text(
                category.name.split(' ').first, // First word only for compact
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? theme.colorScheme.primary : null,
                ),
              ),
              // Show warning if over budget
              if (status != null && status!.percentage >= 90)
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Icon(
                    Icons.warning,
                    size: 14,
                    color: status!.percentage >= 100 ? Colors.red : Colors.orange,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Budget status for a category
class CategoryBudgetStatus {
  final int spent;
  final int limit;
  
  const CategoryBudgetStatus({
    required this.spent,
    required this.limit,
  });
  
  double get percentage => limit > 0 ? (spent / limit) * 100 : 0;
  int get remaining => limit - spent;
}
