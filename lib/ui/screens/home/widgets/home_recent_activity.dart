import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cashpilot/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/managers/format_manager.dart';
import '../../../../core/helpers/localized_category_helper.dart';
import '../../../../features/home/viewmodels/home_view_model.dart';
import '../../../widgets/common/section_header.dart';
import '../../../widgets/common/glass_card.dart';
import '../../../widgets/common/empty_state.dart';
import '../../../widgets/common/cp_app_icon.dart';
import '../../../widgets/common/app_grade_icons.dart';

class HomeRecentActivity extends ConsumerWidget {
  const HomeRecentActivity({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeStateAsync = ref.watch(homeViewModelProvider);
    final l10n = AppLocalizations.of(context)!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: l10n.homeRecentActivity),
        const SizedBox(height: 16),
        homeStateAsync.when(
          data: (state) {
            if (state.recentExpenses.isEmpty) {
              return EmptyState(
                title: l10n.expensesNoExpenses,
                message: l10n.homeTrackSpendingDesc,
                buttonLabel: l10n.homeTrackSpendingBtn,
                icon: Icons.receipt_long_rounded,
                onAction: () => context.push(AppRoutes.addExpense),
              );
            }

            final categoryMap = state.categoryMap;
            
            return GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              borderRadius: 20,
              child: Column(
                children: state.recentExpenses.take(5).toList().asMap().entries.map((entry) {
                  final index = entry.key;
                  final expense = entry.value;
                  
                  final category = expense.categoryId != null ? categoryMap[expense.categoryId] : null;
                  Color categoryColor = AppColors.primaryGreen;
                  
                  if (category?.colorHex != null) {
                    try {
                      categoryColor = Color(int.parse(category!.colorHex!.replaceFirst('#', '0xFF')));
                    } catch (_) {}
                  }

                  return Column(
                    children: [
                      _ExpenseListItem(
                        title: expense.title,
                        amount: expense.amount,
                        currency: state.currency,
                        date: expense.date,
                        categoryColor: categoryColor,
                        categoryIconName: category?.iconName,
                      ),
                      if (index < 4 && index < state.recentExpenses.length - 1)
                        Divider(
                          height: 1,
                          indent: 56,
                          color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
                        ),
                    ],
                  );
                }).toList(),
              ),
            );
          },
          loading: () => const Center(child: Padding(
            padding: EdgeInsets.all(20.0),
            child: CircularProgressIndicator(),
          )),
          error: (_, __) => const SizedBox(),
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

  const _ExpenseListItem({
    required this.title,
    required this.amount,
    required this.currency,
    required this.date,
    this.categoryColor = AppColors.primaryGreen,
    this.categoryIconName,
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
          CPAppIcon(
            icon: AppGradeIcons.getIcon(categoryIconName),
            color: categoryColor,
            size: 40,
            iconSize: 20,
            useGradient: true, 
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
