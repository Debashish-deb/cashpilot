/// Budget Card Widget
/// Card component for displaying budget info
/// Refactored for Vibrant/Amoled design with category-wise gradients
library;

import 'dart:ui';
import 'package:cashpilot/core/providers/app_providers.dart' show currencyProvider;
import 'package:cashpilot/core/theme/accent_colors.dart' show accentConfigProvider;
import 'package:cashpilot/core/theme/app_typography.dart' show AppTypography;
import 'package:cashpilot/features/expenses/providers/expense_providers.dart'
    show totalSpentInBudgetProvider;
import 'package:cashpilot/ui/widgets/budgets/budget_health_chip.dart'
    show BudgetHealthChip;
import 'package:cashpilot/ui/widgets/common/cp_app_icon.dart' show CPAppIcon;
import 'package:cashpilot/ui/widgets/common/progress_bar.dart'
    show BudgetProgressBar;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/managers/format_manager.dart';
import 'package:cashpilot/l10n/app_localizations.dart';

class BudgetCard extends ConsumerWidget {
  final dynamic budget;
  final VoidCallback? onTap;

  const BudgetCard({
    super.key,
    required this.budget,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // WORKAROUND: Always use system currency from settings
    // This ensures budget cards match the user's selected currency
    // regardless of what's stored in the budget record
    final currency = ref.watch(currencyProvider);
    final totalSpentAsync = ref.watch(totalSpentInBudgetProvider(budget.id));
    final l10n = AppLocalizations.of(context)!;
    final formatManager = ref.watch(formatManagerProvider);

    // Normalize "today" once (prevents off-by-one around midnight / DST)
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final accent = ref.watch(accentConfigProvider);
    final gradient = LinearGradient(
      colors: [accent.primary, accent.primary.withValues(alpha: 0.8)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    // Smart text colors based on accent
    final textColor = accent.textOnPrimary;
    final subtitleColor = accent.textOnPrimaryMuted;

    // RepaintBoundary reduces GPU overdraw for cards with heavy shadows
    return RepaintBoundary(
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        tween: Tween(begin: 0.97, end: 1),
        builder: (context, scale, child) =>
            Transform.scale(scale: scale, child: child),
        child: Material(
          color: Colors.transparent,
          elevation: 10,
          shadowColor: gradient.colors.first.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(24),
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              onTap?.call();
            },
            borderRadius: BorderRadius.circular(24),
            splashColor: Colors.white.withValues(alpha: 0.08),
            highlightColor: Colors.transparent,
            child: Stack(
              children: [
                // ================================
                // CARD BASE
                // ================================
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: gradient,
                    boxShadow: [
                      BoxShadow(
                        color: gradient.colors.last.withValues(alpha: 0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: _buildContent(
                    context,
                    ref,
                    formatManager,
                    currency,
                    totalSpentAsync,
                    l10n,
                    textColor,
                    subtitleColor,
                    today, // ✅ added (internal only)
                  ),
                ),

                // ================================
                // SUBTLE LIGHT REFLECTION (APPLE STYLE)
                // ================================
                Positioned.fill(
                  child: IgnorePointer(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 0.6, sigmaY: 0.6),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withValues(alpha: 0.10),
                                Colors.transparent,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ================================================================
  // CONTENT
  // ================================================================

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    FormatManager formatManager,
    String currency,
    AsyncValue<int> totalSpentAsync,
    AppLocalizations l10n,
    Color textColor,
    Color subtitleColor,
    DateTime today, // ✅ internal-only param (no public API impact)
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ================================
        // HEADER
        // ================================
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CPAppIcon(
              icon: _getBudgetIcon(budget.type),
              color: textColor,
              size: 48,
              useGradient: false,
              borderColor: textColor.withValues(alpha: 0.15),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    budget.title,
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: textColor,
                      fontSize: 18,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getDateRange(
                        budget.startDate, budget.endDate, formatManager),
                    style: AppTypography.bodySmall.copyWith(
                      color: subtitleColor,
                    ),
                  ),
                ],
              ),
            ),
            _buildHealthChip(context, budget, totalSpentAsync),
          ],
        ),

        const SizedBox(height: 24),

        // ================================
        // MONEY & PROGRESS
        // ================================
        totalSpentAsync.when(
          data: (totalSpent) {
            final totalLimit = budget.totalLimit ?? 0;
            final progress = totalLimit > 0
                ? (totalSpent / totalLimit).clamp(0.0, 1.0)
                : 0.0;

            final remaining = totalLimit - totalSpent;

            // Date-safe "days left"
            final daysLeft =
                budget.endDate.difference(today).inDays.clamp(0, 365);

            // Daily safe: only meaningful if there is remaining budget and time left
            final bool showDailySafe = remaining > 0 && daysLeft > 0;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatManager.formatCurrency(totalSpent / 100,
                          currencyCode: currency),
                      style: AppTypography.headlineMedium.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.w800,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        '/ ${formatManager.formatCurrency(totalLimit / 100, currencyCode: currency)}',
                        style: AppTypography.bodyMedium.copyWith(
                          color: subtitleColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: AppTypography.titleMedium.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Progress with bloom
                Stack(
                  children: [
                    BudgetProgressBar(
                      progress: progress,
                      height: 12,
                      backgroundColor: Colors.black.withValues(alpha: 0.25),
                      color: textColor,
                    ),
                    if (progress > 0.7)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: textColor.withValues(alpha: 0.15),
                                  blurRadius: 14,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 12),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.budgetsRemaining,
                      style: AppTypography.labelSmall
                          .copyWith(color: subtitleColor),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        remaining >= 0
                            ? formatManager.formatCurrency(remaining / 100,
                                currencyCode: currency)
                            : '${formatManager.formatCurrency(remaining.abs() / 100, currencyCode: currency)} Over',
                        style: AppTypography.labelSmall.copyWith(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                if (progress < 1.0) ...[
                  const SizedBox(height: 12),
                  Divider(color: subtitleColor.withValues(alpha: 0.2), height: 1),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Days Left
                      Row(
                        children: [
                          Icon(Icons.calendar_today_rounded,
                              size: 12, color: subtitleColor),
                          const SizedBox(width: 4),
                          Text(
                            '${formatManager.formatNumber(daysLeft)} days left',
                            style: AppTypography.labelSmall.copyWith(
                                color: subtitleColor,
                                fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      // Daily Safe
                      Row(
                        children: [
                          Icon(Icons.savings_outlined,
                              size: 12, color: subtitleColor),
                          const SizedBox(width: 4),
                          Text(
                            showDailySafe
                                ? '~${formatManager.formatCurrency((remaining / daysLeft).floor() / 100, currencyCode: currency)} / day'
                                : '—',
                            style: AppTypography.labelSmall.copyWith(
                              color: subtitleColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                ],
              ],
            );
          },
          loading: () =>
              Center(child: CircularProgressIndicator(color: textColor)),
          error: (_, __) => _buildFallbackError(context, textColor),
        ),
      ],
    );
  }

  // ================================================================
  // HELPERS (UNCHANGED)
  // ================================================================

  Widget _buildHealthChip(
      BuildContext context, dynamic budget, AsyncValue<int> spentAsync) {
    return spentAsync.when(
      data: (spent) => BudgetHealthChip(
        startDate: budget.startDate,
        endDate: budget.endDate,
        totalLimit: budget.totalLimit ?? 0,
        totalSpent: spent,
        isCompact: true,
      ),
      loading: () => _buildFallbackChip(context),
      error: (_, __) => _buildFallbackChip(context),
    );
  }

  Widget _buildFallbackChip(BuildContext context) {
    // Uses white to match BudgetHealthChip styling
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1,
        ),
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

  Widget _buildFallbackError(BuildContext context, Color textColor) {
    // Keep structure simple, but avoid raw "Error" text in UI
    return Text(
      '—',
      style: TextStyle(color: textColor),
    );
  }

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

  String _getDateRange(
      DateTime start, DateTime end, FormatManager formatManager) {
    if (start.year == end.year) {
      if (start.month == end.month) {
        return '${formatManager.formatDate(start)} - ${end.day}, ${end.year}';
      }
      return '${formatManager.formatDate(start)} - ${formatManager.formatDate(end)}, ${end.year}';
    }
    return '${formatManager.formatDate(start)} - ${formatManager.formatDate(end)}';
  }
}
