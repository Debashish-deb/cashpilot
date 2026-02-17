import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cashpilot/l10n/app_localizations.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/managers/format_manager.dart';
import '../../../../features/home/viewmodels/home_view_model.dart';
import '../../../../core/theme/app_colors.dart';

class HomeBalanceSection extends ConsumerWidget {
  const HomeBalanceSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final formatManager = ref.watch(formatManagerProvider);
    final homeStateAsync = ref.watch(homeViewModelProvider);
    final state = homeStateAsync.valueOrNull;

    final balanceDisplay = formatManager.formatCents(state?.totalBalance ?? BigInt.zero, currencyCode: currency);
    final currency = state?.currency ?? 'USD';

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Balance Info
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.homeAvailableBalance,
                style: AppTypography.labelSmall.copyWith(
                  color: isDark ? Colors.white60 : theme.hintColor,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                balanceDisplay,
                style: AppTypography.moneyLarge.copyWith(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primaryGreen,
                  letterSpacing: -1,
                ),
              ),
            ],
          ),

          // Add Transaction Button
          ElevatedButton.icon(
            onPressed: () => context.push(AppRoutes.addExpense),
            icon: const Icon(Icons.add_rounded, size: 20),
            label: Text(
              l10n.homeAddTransaction,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? theme.colorScheme.surfaceContainerHigh : Colors.black,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }
}
