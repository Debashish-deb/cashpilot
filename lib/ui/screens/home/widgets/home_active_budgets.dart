import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cashpilot/l10n/app_localizations.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../features/budgets/providers/budget_providers.dart';
import '../../../widgets/common/section_header.dart';
import '../../../widgets/cards/budget_card.dart';
import '../../../widgets/common/empty_state.dart';

class HomeActiveBudgets extends ConsumerWidget {
  const HomeActiveBudgets({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetsAsync = ref.watch(activeBudgetsProvider);
    final l10n = AppLocalizations.of(context)!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: l10n.homeActiveBudgets,
          actionLabel: l10n.homeSeeAll,
          onAction: () => context.go(AppRoutes.budgets),
        ),
        const SizedBox(height: 16),
        budgetsAsync.when(
          data: (budgets) {
            if (budgets.isEmpty) {
              return EmptyState(
                title: l10n.homeNoBudgets,
                message: l10n.budgetsEmptyActiveDesc,
                buttonLabel: l10n.budgetsCreateBudget,
                icon: Icons.pie_chart_outline_rounded,
                onAction: () => context.push(AppRoutes.budgetCreate),
              );
            }
            
            return Column(
              children: budgets.map((budget) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: BudgetCard(
                    budget: budget,
                    onTap: () => context.push(AppRoutes.budgetDetailsPath(budget.id)),
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const SizedBox(),
        ),
      ],
    );
  }
}
