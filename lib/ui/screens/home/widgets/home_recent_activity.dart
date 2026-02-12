import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cashpilot/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/managers/format_manager.dart';
import '../../../../core/helpers/localized_category_helper.dart';
import '../../../../features/home/viewmodels/home_view_model.dart';
import '../../../widgets/common/empty_state.dart';
import '../../../widgets/common/cp_app_icon.dart';
import '../../../widgets/common/app_grade_icons.dart';
import '../../../widgets/expenses/collapsible_expense_group.dart';

class HomeRecentActivity extends ConsumerWidget {
  const HomeRecentActivity({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeStateAsync = ref.watch(homeViewModelProvider);
    final l10n = AppLocalizations.of(context)!;
    final formatManager = ref.watch(formatManagerProvider);

    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 0), // Removed duplicate title
        Builder(
          builder: (context) {
            // Fix: Persist data during background refreshes (prevent collapse at bottom of screen)
            final state = homeStateAsync.valueOrNull;
            
            if (state != null) {
              if (state.recentExpenses.isEmpty) {
                  return EmptyState(
                    title: l10n.expensesNoExpenses,
                    message: l10n.homeTrackSpendingDesc,
                    buttonLabel: l10n.homeTrackSpendingBtn,
                    icon: Icons.receipt_long_rounded,
                    onAction: () => context.push(AppRoutes.addExpense),
                  );
              }

              final budgetMap = state.budgetMap;
              final categoryMap = state.categoryMap;
              final dateGroups = state.expensesByDateAndBudget;
              
              // Sort dates descending
              final sortedDates = dateGroups.keys.toList()..sort((a, b) => b.compareTo(a));
              
              return Column(
                children: sortedDates.map((date) {
                  final budgetGroups = dateGroups[date]!;
                  final dateFormatted = formatManager.formatDate(date);
                  
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 4, top: 16, bottom: 8),
                        child: Text(
                          dateFormatted.toUpperCase(),
                          style: AppTypography.labelSmall.copyWith(
                            color: Theme.of(context).primaryColor.withValues(alpha: 0.7),
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      ...budgetGroups.entries.map((budgetEntry) {
                        final budgetId = budgetEntry.key;
                        final expenses = budgetEntry.value;
                        final budget = budgetMap[budgetId];
                        final budgetName = budget?.title ?? l10n.catUncategorized;
                        
                        final totalAmount = expenses.fold<double>(0, (sum, e) => sum + (e.amount / 100));
                        
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: CollapsibleExpenseGroup(
                            title: budgetName,
                            iconName: 'wallet', // Standard budget icon
                            color: AppColors.primaryGreen,
                            totalAmount: totalAmount,
                            currency: state.currency,
                            initiallyExpanded: true, // Expand by default for better visibility
                            children: [
                              ...expenses.map((expense) {
                                final category = categoryMap[expense.categoryId];
                                return _ExpenseListItem(
                                  title: expense.title,
                                  amount: expense.amount,
                                  currency: state.currency,
                                  date: expense.date,
                                  categoryColor: category?.colorHex != null 
                                    ? Color(int.parse(category!.colorHex!.replaceFirst('#', '0xFF')))
                                    : AppColors.primaryGreen,
                                  categoryIconName: category?.iconName,
                                  categoryId: expense.categoryId,
                                  subCategoryId: expense.subCategoryId,
                                  showDate: false, // Date is already in section header
                                );
                              }),
                            ],
                          ),
                        );
                      }),
                    ],
                  );
                }).toList(),
              );
            }
            
            // Only shrink if we have NO data and are loading.
            // Ideally we should show a skeleton here too, but to be safe and match previous behavior for initial load:
            return const SizedBox.shrink(); 
          },
        ),
      ],
    );
  }
}

class _ExpenseListItem extends ConsumerWidget {
  final String title;
  final int amount;
  final String currency;
  final DateTime date;
  final Color categoryColor;
  final String? categoryIconName;
  final String? categoryId;
  final String? subCategoryId;
  final bool showDate;

  const _ExpenseListItem({
    required this.title,
    required this.amount,
    required this.currency,
    required this.date,
    this.categoryColor = AppColors.primaryGreen,
    this.categoryIconName,
    this.categoryId,
    this.subCategoryId,
    this.showDate = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formatManager = ref.watch(formatManagerProvider);
    final amountFormatted = formatManager.formatCurrency(
      amount / 100,
      currencyCode: currency,
    );
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 10),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: categoryColor.withValues(alpha: 0.5),
                  blurRadius: 10,
                  spreadRadius: -2,
                ),
              ],
            ),
            child: CPAppIcon(
              icon: AppGradeIcons.getIcon(categoryIconName),
              color: categoryColor,
              size: 40,
              iconSize: 20,
              useGradient: true,
              useShadow: false, 
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  LocalizedCategoryHelper.getLocalizedName(context, title),
                  style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  LocalizedCategoryHelper.getLocalizedHierarchy(context, categoryId, subCategoryId),
                  style: AppTypography.labelSmall.copyWith(
                    color: Theme.of(context).hintColor.withValues(alpha: 0.7),
                    fontSize: 10,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (showDate)
                  Text(
                    formatManager.formatDate(date),
                    style: AppTypography.bodySmall.copyWith(
                      color: Theme.of(context).hintColor,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            '-$amountFormatted',
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
