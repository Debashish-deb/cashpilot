import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/accent_colors.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/managers/format_manager.dart';
import '../../../features/accounts/providers/account_providers.dart';


// ================================================================
// MODEL
// ================================================================

class NetWorthSummary {
  final int totalAssets;
  final int totalLiabilities;
  final int netWorth;

  const NetWorthSummary({
    required this.totalAssets,
    required this.totalLiabilities,
    required this.netWorth,
  });
}


// ================================================================
// PROVIDER
// ================================================================

final netWorthProvider = Provider<AsyncValue<NetWorthSummary>>((ref) {
  final assetsAsync = ref.watch(totalAssetsProvider);
  final liabilitiesAsync = ref.watch(totalLiabilitiesProvider);

  return assetsAsync.when(
    loading: () => const AsyncLoading(),
    error: (e, s) => AsyncError(e, s),
    data: (assets) {
      return liabilitiesAsync.when(
        loading: () => const AsyncLoading(),
        error: (e, s) => AsyncError(e, s),
        data: (liabilities) {
          return AsyncData(
            NetWorthSummary(
              totalAssets: assets,
              totalLiabilities: liabilities,
              netWorth: assets - liabilities,
            ),
          );
        },
      );
    },
  );
});


// ================================================================
// NET WORTH CARD
// ================================================================

class NetWorthCard extends ConsumerWidget {
  const NetWorthCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final netWorthAsync = ref.watch(netWorthProvider);
    final currency = ref.watch(currencyProvider);
    final formatter = ref.watch(formatManagerProvider);

    final accent = ref.watch(accentConfigProvider);
    final gradient = accent.gradient;

    final textColor = accent.textOnPrimary;
    final mutedText = accent.textOnPrimaryMuted;

    return GestureDetector(
      onTap: () => context.push(AppRoutes.savings),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: accent.primary.withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: netWorthAsync.when(
          loading: () => _buildLoading(textColor),
          error: (_, __) => _buildError(textColor),
          data: (summary) => _buildContent(
            summary,
            currency,
            formatter,
            textColor,
            mutedText,
          ),
        ),
      ),
    );
  }

  // ================================================================
  // CONTENT
  // ================================================================

  Widget _buildContent(
    NetWorthSummary summary,
    String currency,
    FormatManager formatter,
    Color textColor,
    Color mutedText,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // HEADER
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: textColor.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.account_balance_outlined,
                color: textColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Total Net Worth',
              style: AppTypography.labelMedium.copyWith(
                color: mutedText,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: textColor.withValues(alpha: 0.5),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // NET WORTH VALUE
        Text(
          formatter.formatCurrency(
            summary.netWorth / 100,
            currencyCode: currency,
            decimalDigits: 0,
          ),
          style: AppTypography.moneyLarge.copyWith(
            color: textColor,
            fontSize: 36,
          ),
        ),

        const SizedBox(height: 24),

        // ASSETS / LIABILITIES
        Row(
          children: [
            Expanded(
              child: _StatItem(
                label: 'Assets',
                amount: summary.totalAssets,
                currency: currency,
                formatter: formatter,
                color: const Color(0xFF4ADE80),
                icon: Icons.arrow_upward_rounded,
                textColor: textColor,
              ),
            ),
            Container(
              width: 1,
              height: 40,
              color: textColor.withValues(alpha: 0.2),
            ),
            Expanded(
              child: _StatItem(
                label: 'Liabilities',
                amount: summary.totalLiabilities,
                currency: currency,
                formatter: formatter,
                color: const Color(0xFFFB7185),
                icon: Icons.arrow_downward_rounded,
                textColor: textColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ================================================================
  // STATES
  // ================================================================

  Widget _buildLoading(Color color) {
    return Center(
      child: CircularProgressIndicator(
        color: color,
        strokeWidth: 2,
      ),
    );
  }

  Widget _buildError(Color color) {
    return Text(
      '—',
      style: AppTypography.moneyLarge.copyWith(
        color: color,
        fontSize: 32,
      ),
    );
  }
}


// ================================================================
// STAT ITEM
// ================================================================

class _StatItem extends StatelessWidget {
  final String label;
  final int amount;
  final String currency;
  final FormatManager formatter;
  final Color color;
  final IconData icon;
  final Color textColor;

  const _StatItem({
    required this.label,
    required this.amount,
    required this.currency,
    required this.formatter,
    required this.color,
    required this.icon,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: textColor.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          formatter.formatCurrency(
            amount / 100,
            currencyCode: currency,
            decimalDigits: 0,
          ),
          style: AppTypography.titleSmall.copyWith(
            color: textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
