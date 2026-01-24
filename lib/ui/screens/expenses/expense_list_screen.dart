
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/constants/app_routes.dart';
import '../../../data/drift/app_database.dart';
import '../../../features/expenses/providers/expense_filter_provider.dart';
import '../../widgets/expenses/grouped_expense_list.dart';
import '../../widgets/expenses/expense_filter_bar.dart';
import 'package:cashpilot/l10n/app_localizations.dart';

class ExpenseListScreen extends ConsumerWidget {
  final String budgetId;
  
  const ExpenseListScreen({super.key, required this.budgetId});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(databaseProvider);
    final filter = ref.watch(expenseFilterProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? Colors.black : theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.expensesTitle),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.add,
                size: 20,
                color: theme.colorScheme.primary,
              ),
            ),
            onPressed: () => context.push(
              '${AppRoutes.addExpense}?budgetId=$budgetId',
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            children: [
              // Filter bar
              ExpenseFilterBar(
            showBudgetTypeFilter: false, // We're already in a specific budget
            onCustomDateTap: () => _showDateRangePicker(context, ref),
          ),
          
          // Expenses list
          Expanded(
            child: StreamBuilder<List<Expense>>(
              stream: db.watchExpensesByBudgetId(budgetId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('Error: ${snapshot.error}'),
                      ],
                    ),
                  );
                }
                
                final allExpenses = snapshot.data ?? [];
                
                // Apply time filter
                final filteredExpenses = _filterExpenses(allExpenses, filter);
                
                return GroupedExpenseList(
                  expenses: filteredExpenses,
                  onDismiss: (expense) async {
                    await db.deleteExpense(expense.id);
                  },
                );
              },
            ),
          ),
            ],
          );
        },
      ),
    );
  }

  List<Expense> _filterExpenses(List<Expense> expenses, ExpenseFilterState filter) {
    final dateRange = filter.getDateRange();
    
    if (dateRange == null) {
      return expenses;
    }
    
    return expenses.where((expense) {
      return expense.date.isAfter(dateRange.start.subtract(const Duration(days: 1))) &&
             expense.date.isBefore(dateRange.end);
    }).toList();
  }

  Future<void> _showDateRangePicker(BuildContext context, WidgetRef ref) async {
    final initialRange = DateTimeRange(
      start: DateTime.now().subtract(const Duration(days: 30)),
      end: DateTime.now(),
    );
    
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: initialRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).colorScheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      ref.read(expenseFilterProvider.notifier).setCustomRange(picked);
    }
  }
}
