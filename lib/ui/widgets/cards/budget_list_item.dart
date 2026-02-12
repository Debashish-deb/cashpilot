import 'dart:math' show sqrt;
import 'package:cashpilot/data/drift/app_database.dart' show Budget;
import 'package:cashpilot/ui/widgets/common/cp_app_icon.dart' show CPAppIcon;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cashpilot/l10n/app_localizations.dart';
import '../../../core/utils/date_formatter.dart';

import '../../../core/theme/app_typography.dart';
import '../../../core/constants/app_routes.dart';
import '../../../features/expenses/providers/expense_providers.dart';
import '../budgets/budget_health_chip.dart';
import '../../../core/theme/accent_colors.dart';
import '../../../core/providers/app_providers.dart';

class BudgetListItem extends ConsumerWidget {
  final Budget budget;

  const BudgetListItem({
    super.key,
    required this.budget,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final totalSpentAsync = ref.watch(totalSpentInBudgetProvider(budget.id));
    final dailyHistoryAsync =
        ref.watch(dailySpendingHistoryProvider(budget.id));

    final currency = ref.watch(currencyProvider);
    final accent = ref.watch(accentConfigProvider);

    final gradient = LinearGradient(
      colors: [accent.primary, accent.primary.withValues(alpha: 0.7)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    final textColor = accent.textOnPrimary;
    final subtitleColor = accent.textOnPrimaryMuted;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      elevation: 4,
      shadowColor: gradient.colors.last.withValues(alpha: 0.4),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          context.push(AppRoutes.budgetDetailsPath(budget.id));
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: gradient,
            boxShadow: [
              BoxShadow(
                color: gradient.colors.last.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER
              Row(
                children: [
                  CPAppIcon(
                    icon: _getBudgetIcon(budget.type),
                    color: textColor,
                    size: 36,
                    useGradient: false,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      budget.title,
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: textColor,
                        fontSize: 18,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Row(
                    children: [
                      _buildHealthChip(context, budget, totalSpentAsync),
                      const SizedBox(width: 6),
                      _buildAnomalyChip(
                        context,
                        totalSpentAsync,
                        dailyHistoryAsync,
                        budget,
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // META
              Row(
                children: [
                  Icon(Icons.calendar_today_outlined,
                      size: 14, color: subtitleColor),
                  const SizedBox(width: 6),
                  Text(
                    LocalizedDateFormatter.formatDateRange(
                      budget.startDate,
                      budget.endDate,
                      l10n.localeName,
                    ),
                    style: AppTypography.bodySmall.copyWith(
                      color: subtitleColor,
                    ),
                  ),
                  if (budget.isShared) ...[
                    const SizedBox(width: 16),
                    Icon(Icons.group_outlined,
                        size: 14, color: subtitleColor),
                    const SizedBox(width: 4),
                    Text(
                      l10n.catGroupFamily,
                      style: AppTypography.labelSmall.copyWith(
                        color: subtitleColor,
                      ),
                    ),
                  ],
                  const Spacer(),
                  Text(
                    _formatCurrency(context, budget.totalLimit ?? 0, currency),
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================================================================
  // ANOMALY LOGIC (FIXED & STABLE)
  // ================================================================

  Widget _buildAnomalyChip(
    BuildContext context,
    AsyncValue<int> spentAsync,
    AsyncValue<List<int>> historyAsync,
    Budget budget,
  ) {
    return historyAsync.maybeWhen(
      data: (history) {
        if (history.length < 7) return const SizedBox.shrink();

        return spentAsync.maybeWhen(
          data: (totalSpent) {
            if (budget.totalLimit != null &&
                totalSpent >= budget.totalLimit!) {
              return const SizedBox.shrink();
            }

            final todaySpend = history.last;
            final result = _detectAnomaly(history, todaySpend);

            if (!result.isAnomalous) return const SizedBox.shrink();

            final color = result.severity == _Severity.critical
                ? Colors.redAccent
                : Colors.orange;

            return Tooltip(
              message: result.reason,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: color.withValues(alpha: 0.6)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_rounded, size: 14, color: color),
                    const SizedBox(width: 4),
                    Text(
                      'Unusual',
                      style: AppTypography.labelSmall.copyWith(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          orElse: () => const SizedBox.shrink(),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }

  _AnomalyResult _detectAnomaly(List<int> history, int todaySpend) {
    final baseline = history.sublist(0, history.length - 1);

    final mean =
        baseline.reduce((a, b) => a + b) / baseline.length.toDouble();

    final variance = baseline
            .map((v) => (v - mean) * (v - mean))
            .reduce((a, b) => a + b) /
        baseline.length;

    final std = sqrt(variance);
    if (std <= 0) {
      return _AnomalyResult(false, _Severity.none, '');
    }

    final z = (todaySpend - mean) / std;

    if (z >= 3.0) {
      return _AnomalyResult(
        true,
        _Severity.critical,
        'Spending far above your normal daily pattern',
      );
    }

    if (z >= 2.2) {
      return _AnomalyResult(
        true,
        _Severity.moderate,
        'Higher than usual spending today',
      );
    }

    return _AnomalyResult(false, _Severity.none, '');
  }

  // ================================================================
  // HELPERS (UNCHANGED)
  // ================================================================

  IconData _getBudgetIcon(String type) {
    switch (type.toLowerCase()) {
      case 'monthly':
      case 'personal':
        return Icons.calendar_month_outlined;
      case 'weekly':
        return Icons.calendar_view_week_outlined;
      case 'annual':
        return Icons.calendar_today_outlined;
      case 'event':
        return Icons.celebration_outlined;
      case 'savings':
        return Icons.savings_outlined;
      case 'food':
        return Icons.restaurant_outlined;
      case 'transport':
        return Icons.directions_car_outlined;
      case 'family':
        return Icons.family_restroom_outlined;
      case 'business':
        return Icons.business_center_outlined;
      default:
        return Icons.account_balance_wallet_outlined;
    }
  }

  Widget _buildHealthChip(
    BuildContext context,
    Budget budget,
    AsyncValue<int> spentAsync,
  ) {
    return spentAsync.maybeWhen(
      data: (spent) => BudgetHealthChip(
        startDate: budget.startDate,
        endDate: budget.endDate,
        totalLimit: budget.totalLimit ?? 0,
        totalSpent: spent,
        isCompact: true,
      ),
      orElse: () => _fallbackChip(),
    );
  }

  Widget _fallbackChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '...',
        style: AppTypography.labelSmall.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _formatCurrency(BuildContext context, int cents, String currency) {
    return NumberFormat.currency(
      locale: AppLocalizations.of(context)!.localeName,
      symbol: _getCurrencySymbol(currency),
      decimalDigits: 0,
    ).format(cents / 100);
  }

  String _getCurrencySymbol(String code) {
    switch (code) {
      case 'EUR':
        return '€';
      case 'USD':
        return '\$';
      case 'GBP':
        return '£';
      default:
        return code;
    }
  }
}

// ================================================================
// INTERNAL TYPES
// ================================================================

enum _Severity { none, moderate, critical }

class _AnomalyResult {
  final bool isAnomalous;
  final _Severity severity;
  final String reason;

  _AnomalyResult(this.isAnomalous, this.severity, this.reason);
}
