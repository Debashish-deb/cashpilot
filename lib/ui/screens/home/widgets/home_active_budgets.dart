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
        Builder(
          builder: (context) {
            // Fix: Check for data availability first to prevent flickering to skeleton during background refresh
            final budgets = budgetsAsync.valueOrNull;
            
            if (budgets != null) {
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
            }
            
            // Only show skeleton if we have NO data and are loading
            if (budgetsAsync.isLoading) {
              return const _LoadingSkeleton();
            }
            
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }
}

class _LoadingSkeleton extends StatelessWidget {
  const _LoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(2, (index) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Container(
          height: 140, // Approximate height of a BudgetCard
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      )),
    );
  }
}
