import 'package:cashpilot/l10n/app_localizations.dart' show AppLocalizations;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/accent_colors.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/managers/format_manager.dart';
import '../../../features/net_worth/providers/net_worth_providers.dart';
import '../../../features/home/viewmodels/home_view_model.dart';
import '../../../domain/entities/net_worth/net_worth_models.dart';

class FinancialOverviewCard extends ConsumerWidget {
  const FinancialOverviewCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final netWorthAsync = ref.watch(netWorthSummaryProvider);
    final homeStateAsync = ref.watch(homeViewModelProvider);
    final currency = ref.watch(currencyProvider);
    final formatter = ref.watch(formatManagerProvider);
    final accent = ref.watch(accentConfigProvider);
    final l10n = AppLocalizations.of(context)!;

    final netWorthData = netWorthAsync.when(
      data: (data) => data,
      loading: () => const NetWorthSummaryData(totalAssets: 0, totalLiabilities: 0, netWorth: 0),
      error: (_, __) => const NetWorthSummaryData(totalAssets: 0, totalLiabilities: 0, netWorth: 0),
    );

    final homeState = homeStateAsync.valueOrNull;
    final monthSpending = homeState?.monthSpending ?? 0;
    final todaySpending = homeState?.todaySpending ?? 0;

    final gradient = accent.gradient;
    final textColor = accent.textOnPrimary;
    final mutedText = accent.textOnPrimaryMuted;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: accent.primary.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () => context.push(AppRoutes.netWorth),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      // LEFT SIDE: NET WORTH
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.savingsNetWorth,
                              style: AppTypography.labelSmall.copyWith(
                                color: mutedText,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                formatter.formatCurrency(
                                  netWorthData.netWorth / 100.0,
                                  currencyCode: currency,
                                  decimalDigits: 0,
                                ),
                                style: AppTypography.moneyMedium.copyWith(
                                  color: textColor,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 28,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // DIVIDER
                      Container(
                        width: 1,
                        height: 42,
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        color: textColor.withValues(alpha: 0.2),
                      ),
                      
                      // RIGHT SIDE: MONTHLY SPENT
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.homeTotalSpentMonth,
                              style: AppTypography.labelSmall.copyWith(
                                color: mutedText,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                formatter.formatCurrency(
                                  monthSpending / 100.0,
                                  currencyCode: currency,
                                  decimalDigits: 0,
                                ),
                                style: AppTypography.moneyMedium.copyWith(
                                  color: textColor,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 28,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // BOTTOM ROW: ASSETS, LIABILITIES, TODAY
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: textColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSmallStat(
                          context,
                          l10n.savingsAssets,
                          netWorthData.totalAssets,
                          currency,
                          formatter,
                          textColor,
                        ),
                        _buildSmallStat(
                          context,
                          l10n.savingsLiabilities,
                          netWorthData.totalLiabilities,
                          currency,
                          formatter,
                          textColor,
                        ),
                        _buildSmallStat(
                          context,
                          l10n.homeToday,
                          todaySpending,
                          currency,
                          formatter,
                          textColor,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSmallStat(
    BuildContext context,
    String label,
    int amount,
    String currency,
    FormatManager formatter,
    Color textColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: textColor.withValues(alpha: 0.6),
            fontSize: 9,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          formatter.formatCurrency(
            amount / 100.0,
            currencyCode: currency,
            decimalDigits: 0,
          ),
          style: TextStyle(
            color: textColor,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
