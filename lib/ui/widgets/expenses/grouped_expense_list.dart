/// Grouped Expense List Widget
/// Displays expenses grouped by date with sticky headers
library;

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' show context;

import '../../../core/constants/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/drift/app_database.dart';
import 'package:cashpilot/l10n/app_localizations.dart';
import '../../../core/utils/date_formatter.dart';

/// Types of date grouping for expenses
enum DateGroupType {
  today,
  yesterday,
  thisWeek,
  lastWeek,
  earlier;

  String getLocalizedLabel(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (this) {
      case DateGroupType.today:
        return l10n.expensesGroupToday; // "Today"
      case DateGroupType.yesterday:
        return l10n.expensesGroupYesterday; // "Yesterday"
      case DateGroupType.thisWeek:
        return l10n.expensesGroupThisWeek; // "This Week"
      case DateGroupType.lastWeek:
        return l10n.expensesGroupLastWeek; // "Last Week"
      case DateGroupType.earlier:
        return l10n.expensesGroupEarlier; // "Earlier"
    }
  }

  IconData get icon {
    switch (this) {
      case DateGroupType.today:
        return Icons.today_outlined;
      case DateGroupType.yesterday:
        return Icons.history;
      case DateGroupType.thisWeek:
        return Icons.view_week_outlined;
      case DateGroupType.lastWeek:
        return Icons.calendar_view_week_outlined;
      case DateGroupType.earlier:
        return Icons.calendar_month_outlined;
    }
  }
}

/// Group of expenses by date category
class ExpenseGroup {
  final DateGroupType type;
  final DateTime? date;
  final List<Expense> expenses;
  final int totalCents;

  const ExpenseGroup({
    required this.type,
    this.date,
    required this.expenses,
    required this.totalCents,
  });
}

/// Main grouped expense list widget
class GroupedExpenseList extends StatelessWidget {
  final List<Expense> expenses;
  final Map<String, String> categoryIcons;
  final Map<String, Color> categoryColors;
  final String currency;
  final Function(Expense)? onDismiss;
  final bool showHeaders;

  const GroupedExpenseList({
    super.key,
    required this.expenses,
    this.categoryIcons = const {},
    this.categoryColors = const {},
    this.currency = '€',
    this.onDismiss,
    this.showHeaders = true,
  });

  @override
  Widget build(BuildContext context) {
    if (expenses.isEmpty) {
      return _buildEmptyState(context);
    }

    final groups = _groupExpenses(expenses);

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _calculateItemCount(groups),
      itemBuilder: (context, index) {
        return _buildItem(context, groups, index);
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: isDark 
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.receipt_long_outlined,
              size: 36,
              color: isDark ? Colors.white38 : Colors.black26,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.expensesNoExpenses,
            style: AppTypography.titleMedium.copyWith(
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.expensesEmptyCreate,
            style: AppTypography.bodySmall.copyWith(
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ),
        ],
      ),
    );
  }

  List<ExpenseGroup> _groupExpenses(List<Expense> expenses) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final lastWeekStart = weekStart.subtract(const Duration(days: 7));

    // Initialize buckets
    final Map<DateGroupType, List<Expense>> grouped = {
      DateGroupType.today: [],
      DateGroupType.yesterday: [],
      DateGroupType.thisWeek: [],
      DateGroupType.lastWeek: [],
      DateGroupType.earlier: [],
    };

    for (final expense in expenses) {
      final expenseDate = DateTime(
        expense.date.year,
        expense.date.month,
        expense.date.day,
      );

      if (expenseDate == today) {
        grouped[DateGroupType.today]!.add(expense);
      } else if (expenseDate == yesterday) {
        grouped[DateGroupType.yesterday]!.add(expense);
      } else if (expenseDate.isAfter(weekStart.subtract(const Duration(days: 1)))) {
        grouped[DateGroupType.thisWeek]!.add(expense);
      } else if (expenseDate.isAfter(lastWeekStart.subtract(const Duration(days: 1)))) {
        grouped[DateGroupType.lastWeek]!.add(expense);
      } else {
        grouped[DateGroupType.earlier]!.add(expense);
      }
    }

    // Convert to ExpenseGroup list, filtering empty groups
    final List<ExpenseGroup> result = [];
    
    // Iterate in enum order to maintain specific display order
    for (final type in DateGroupType.values) {
      final expensesInGroup = grouped[type]!;
      if (expensesInGroup.isNotEmpty) {
        // Sort by date descending within each group
        expensesInGroup.sort((a, b) => b.date.compareTo(a.date));
        
        result.add(ExpenseGroup(
          type: type,
          expenses: expensesInGroup,
          totalCents: expensesInGroup.fold(0, (sum, e) => sum + e.amount),
        ));
      }
    }

    return result;
  }

  int _calculateItemCount(List<ExpenseGroup> groups) {
    int count = 0;
    for (final group in groups) {
      if (showHeaders) count++; // Header
      count += group.expenses.length; // Expenses
    }
    return count;
  }

  Widget _buildItem(BuildContext context, List<ExpenseGroup> groups, int index) {
    int currentIndex = 0;
    
    for (final group in groups) {
      // Check if this is the header
      if (showHeaders && currentIndex == index) {
        return _buildHeader(context, group);
      }
      if (showHeaders) currentIndex++;

      // Check if this is an expense in this group
      for (int i = 0; i < group.expenses.length; i++) {
        if (currentIndex == index) {
          return _buildExpenseItem(context, group.expenses[i]);
        }
        currentIndex++;
      }
    }

    return const SizedBox.shrink();
  }

  Widget _buildHeader(BuildContext context, ExpenseGroup group) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final total = group.totalCents / 100;

    return Container(
      margin: const EdgeInsets.only(top: 16, bottom: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark 
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark 
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.06),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      group.type.icon,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      group.type.getLocalizedLabel(context),
                      style: AppTypography.labelMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${group.expenses.length}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  '$currency${total.toStringAsFixed(2)}',
                  style: AppTypography.labelMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.danger,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpenseItem(BuildContext context, Expense expense) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final amount = expense.amount / 100;
    final categoryIcon = categoryIcons[expense.semiBudgetId] ?? '💰';
    final categoryColor = categoryColors[expense.semiBudgetId] ?? theme.colorScheme.primary;

    return Dismissible(
      key: Key(expense.id),
      direction: onDismiss != null 
          ? DismissDirection.endToStart 
          : DismissDirection.none,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline, color: AppColors.danger),
      ),
      confirmDismiss: (_) async {
        HapticFeedback.mediumImpact();
        return true;
      },
      onDismissed: (_) => onDismiss?.call(expense),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          context.push(AppRoutes.expenseDetailsPath(expense.id));
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark 
                ? Colors.white.withValues(alpha: 0.04)
                : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark 
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.06),
            ),
            boxShadow: isDark ? null : [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Category icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: categoryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    categoryIcon,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              
              // Title and time
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      expense.title,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatTime(expense.date, context),
                      style: AppTypography.labelSmall.copyWith(
                        color: isDark ? Colors.white54 : Colors.black45,
                        letterSpacing: -0.1,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Amount
              Text(
                '$currency${amount.toStringAsFixed(2)}',
                style: AppTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime date, BuildContext context) {
    final now = DateTime.now();
    final diff = now.difference(date);
    final l10n = AppLocalizations.of(context)!;

    if (diff.inMinutes < 1) return l10n.commonJustNow;
    if (diff.inMinutes < 60) return l10n.commonMinutesAgo(diff.inMinutes);
    if (diff.inHours < 24) return l10n.commonHoursAgo(diff.inHours);
    if (diff.inDays < 7) return l10n.commonDaysAgo(diff.inDays);
    
    // String _formatDate(DateTime date, AppLocalizations l10n) {
    return LocalizedDateFormatter.formatMonthDay(date, l10n.localeName);
  }
}
