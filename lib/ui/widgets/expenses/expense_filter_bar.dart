/// Expense Filter Bar Widget
/// Apple-inspired segmented control tabs with glassmorphism
library;

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/expenses/providers/expense_filter_provider.dart';
import '../../../core/theme/app_colors.dart';

/// Apple-inspired filter bar with segmented controls
class ExpenseFilterBar extends ConsumerWidget {
  final bool showBudgetTypeFilter;
  final VoidCallback? onCustomDateTap;

  const ExpenseFilterBar({
    super.key,
    this.showBudgetTypeFilter = true,
    this.onCustomDateTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(expenseFilterProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time period - Apple Segmented Control
          _AppleSegmentedControl<ExpenseTimePeriod>(
            values: ExpenseTimePeriod.values,
            selectedValue: filter.period,
            labelBuilder: (period) => period.label,
            onSelected: (period) {
              HapticFeedback.selectionClick();
              if (period == ExpenseTimePeriod.custom) {
                onCustomDateTap?.call();
              } else {
                ref.read(expenseFilterProvider.notifier).setPeriod(period);
              }
            },
          ),

          if (showBudgetTypeFilter) ...[
            const SizedBox(height: 12),
            
            // Budget type - Smaller Apple segment
            _AppleSegmentedControl<ExpenseBudgetType>(
              values: ExpenseBudgetType.values,
              selectedValue: filter.budgetType,
              labelBuilder: (type) => type.label,
              isSecondary: true,
              onSelected: (type) {
                HapticFeedback.selectionClick();
                ref.read(expenseFilterProvider.notifier).setBudgetType(type);
              },
            ),
          ],
        ],
      ),
    );
  }
}

/// Apple-style Segmented Control
class _AppleSegmentedControl<T> extends StatelessWidget {
  final List<T> values;
  final T selectedValue;
  final String Function(T) labelBuilder;
  final void Function(T) onSelected;
  final bool isSecondary;

  const _AppleSegmentedControl({
    required this.values,
    required this.selectedValue,
    required this.labelBuilder,
    required this.onSelected,
    this.isSecondary = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = isSecondary ? AppColors.accent : theme.colorScheme.primary;

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          height: isSecondary ? 36 : 40,
          decoration: BoxDecoration(
            color: isDark 
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDark 
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.06),
              width: 0.5,
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final segmentWidth = constraints.maxWidth / values.length;
              final selectedIndex = values.indexOf(selectedValue);
              
              return Stack(
                children: [
                  // Animated sliding indicator
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    left: selectedIndex * segmentWidth + 2,
                    top: 2,
                    bottom: 2,
                    width: segmentWidth - 4,
                    child: Container(
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withValues(alpha: isDark ? 0.4 : 0.3),
                            blurRadius: 8,
                            spreadRadius: -2,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Segment labels
                  Row(
                    children: values.map((value) {
                      final isSelected = value == selectedValue;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => onSelected(value),
                          behavior: HitTestBehavior.opaque,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            alignment: Alignment.center,
                            child: AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 150),
                              style: TextStyle(
                                fontSize: isSecondary ? 12 : 13,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                letterSpacing: -0.3,
                                color: isSelected
                                    ? Colors.white
                                    : isDark 
                                        ? Colors.white.withValues(alpha: 0.65)
                                        : Colors.black.withValues(alpha: 0.55),
                              ),
                              child: Text(
                                labelBuilder(value),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
