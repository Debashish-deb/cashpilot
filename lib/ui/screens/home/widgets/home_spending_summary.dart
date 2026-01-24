import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cashpilot/l10n/app_localizations.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/managers/format_manager.dart';
import '../../../../features/home/viewmodels/home_view_model.dart';
import '../../../widgets/common/glass_card.dart';

class HomeSpendingSummary extends ConsumerWidget {
  final Color profileColor;

  const HomeSpendingSummary({
    super.key,
    required this.profileColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeStateAsync = ref.watch(homeViewModelProvider);
    final formatManager = ref.watch(formatManagerProvider);
    final l10n = AppLocalizations.of(context)!;
    
    return homeStateAsync.when(
      data: (state) => _buildContent(context, state, formatManager, l10n),
      loading: () => const _LoadingSummary(),
      error: (_, __) => const _ErrorSummary(),
    );
  }

  Widget _buildContent(BuildContext context, HomeViewState state, FormatManager formatManager, AppLocalizations l10n) {
    return GlassCard(
      color: profileColor.withValues(alpha: 0.15),
      borderRadius: 28,
      border: Border.all(color: profileColor.withValues(alpha: 0.3)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.homeTotalSpentMonth,
                style: AppTypography.bodyMedium.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              Tooltip(
                message: "This shows how much you've spent across all categories since the 1st of this month.",
                triggerMode: TooltipTriggerMode.tap,
                showDuration: const Duration(seconds: 4),
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Icon(Icons.info_outline_rounded, color: profileColor.withValues(alpha: 0.6), size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            formatManager.formatCurrency(state.monthSpending / 100, currencyCode: state.currency),
            style: AppTypography.displayMedium.copyWith(
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.onSurface,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: profileColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.arrow_upward_rounded, size: 14, color: profileColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.homeToday,
                        style: AppTypography.labelSmall.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                      Text(
                        formatManager.formatCurrency(state.todaySpending / 100, currencyCode: state.currency),
                        style: AppTypography.titleSmall.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingSummary extends StatelessWidget {
  const _LoadingSummary();
  @override
  Widget build(BuildContext context) => const GlassCard(child: Center(child: CircularProgressIndicator()));
}

class _ErrorSummary extends StatelessWidget {
  const _ErrorSummary();
  @override
  Widget build(BuildContext context) => const GlassCard(child: Center(child: Text('---')));
}
