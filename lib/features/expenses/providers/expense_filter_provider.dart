/// Expense Filter Provider
/// State management for expense grouping and filtering
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Time period for filtering expenses
enum ExpenseTimePeriod {
  today,
  week,
  month,
  year,
  custom,
  all,
}

/// Budget type filter
enum ExpenseBudgetType {
  all,
  personal,
  shared,
}

/// Filter state for expenses
class ExpenseFilterState {
  final ExpenseTimePeriod period;
  final ExpenseBudgetType budgetType;
  final DateTimeRange? customRange;
  final String? budgetId; // Optional: filter by specific budget

  const ExpenseFilterState({
    this.period = ExpenseTimePeriod.all,
    this.budgetType = ExpenseBudgetType.all,
    this.customRange,
    this.budgetId,
  });

  /// Get date range based on period
  DateTimeRange? getDateRange() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (period) {
      case ExpenseTimePeriod.today:
        return DateTimeRange(
          start: today,
          end: today.add(const Duration(days: 1)),
        );
      case ExpenseTimePeriod.week:
        final weekStart = today.subtract(Duration(days: today.weekday - 1));
        return DateTimeRange(
          start: weekStart,
          end: today.add(const Duration(days: 1)),
        );
      case ExpenseTimePeriod.month:
        return DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: today.add(const Duration(days: 1)),
        );
      case ExpenseTimePeriod.year:
        return DateTimeRange(
          start: DateTime(now.year, 1, 1),
          end: today.add(const Duration(days: 1)),
        );
      case ExpenseTimePeriod.custom:
        return customRange;
      case ExpenseTimePeriod.all:
        return null;
    }
  }

  ExpenseFilterState copyWith({
    ExpenseTimePeriod? period,
    ExpenseBudgetType? budgetType,
    DateTimeRange? customRange,
    String? budgetId,
  }) {
    return ExpenseFilterState(
      period: period ?? this.period,
      budgetType: budgetType ?? this.budgetType,
      customRange: customRange ?? this.customRange,
      budgetId: budgetId ?? this.budgetId,
    );
  }
}

/// Expense filter notifier
class ExpenseFilterNotifier extends StateNotifier<ExpenseFilterState> {
  ExpenseFilterNotifier() : super(const ExpenseFilterState());

  void setPeriod(ExpenseTimePeriod period) {
    state = state.copyWith(period: period);
  }

  void setBudgetType(ExpenseBudgetType type) {
    state = state.copyWith(budgetType: type);
  }

  void setCustomRange(DateTimeRange range) {
    state = state.copyWith(
      period: ExpenseTimePeriod.custom,
      customRange: range,
    );
  }

  void setBudgetId(String? budgetId) {
    state = state.copyWith(budgetId: budgetId);
  }

  void reset() {
    state = const ExpenseFilterState();
  }
}

/// Provider for expense filter state
final expenseFilterProvider =
    StateNotifierProvider<ExpenseFilterNotifier, ExpenseFilterState>((ref) {
  return ExpenseFilterNotifier();
});

/// Helper to get period label
extension ExpenseTimePeriodLabel on ExpenseTimePeriod {
  String get label {
    switch (this) {
      case ExpenseTimePeriod.today:
        return 'Today';
      case ExpenseTimePeriod.week:
        return 'This Week';
      case ExpenseTimePeriod.month:
        return 'This Month';
      case ExpenseTimePeriod.year:
        return 'This Year';
      case ExpenseTimePeriod.custom:
        return 'Custom';
      case ExpenseTimePeriod.all:
        return 'All Time';
    }
  }

  IconData get icon {
    switch (this) {
      case ExpenseTimePeriod.today:
        return Icons.today_outlined;
      case ExpenseTimePeriod.week:
        return Icons.view_week_outlined;
      case ExpenseTimePeriod.month:
        return Icons.calendar_month_outlined;
      case ExpenseTimePeriod.year:
        return Icons.calendar_today_outlined;
      case ExpenseTimePeriod.custom:
        return Icons.date_range_outlined;
      case ExpenseTimePeriod.all:
        return Icons.all_inclusive;
    }
  }
}

/// Helper to get budget type label
extension ExpenseBudgetTypeLabel on ExpenseBudgetType {
  String get label {
    switch (this) {
      case ExpenseBudgetType.all:
        return 'All';
      case ExpenseBudgetType.personal:
        return 'Personal';
      case ExpenseBudgetType.shared:
        return 'Shared';
    }
  }

  IconData get icon {
    switch (this) {
      case ExpenseBudgetType.all:
        return Icons.apps;
      case ExpenseBudgetType.personal:
        return Icons.person_outline;
      case ExpenseBudgetType.shared:
        return Icons.group_outlined;
    }
  }
}
