/// Enhanced Recent Expense Item
/// Category icon, merchant, bold amount, relative time
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/managers/format_manager.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/drift/app_database.dart';

import '../common/app_grade_icons.dart';
import 'package:cashpilot/l10n/app_localizations.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/helpers/localized_category_helper.dart';

class EnhancedRecentExpenseItem extends ConsumerWidget {
  final Expense expense;
  final String? categoryIconName;
  final Color? categoryColor;
  final VoidCallback onTap;
  final VoidCallback? onDismiss;

  const EnhancedRecentExpenseItem({
    super.key,
    required this.expense,
    this.categoryIconName,
    this.categoryColor,
    required this.onTap,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = categoryColor ?? AppColors.primaryGreen;
    final iconData = AppGradeIcons.getIcon(categoryIconName);
    
    // Use FormatManager for currency
    final formatManager = ref.watch(formatManagerProvider);
    final currency = ref.watch(currencyProvider);

    return Dismissible(
      key: Key(expense.id),
      direction: onDismiss != null 
          ? DismissDirection.endToStart 
          : DismissDirection.none,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(Icons.delete_outline, color: AppColors.danger),
      ),
      confirmDismiss: (_) async {
        HapticFeedback.mediumImpact();
        return true;
      },
      onDismissed: (_) => onDismiss?.call(),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.08),
            ),
          ),
          child: Row(
            children: [
              // Category icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(
                    iconData,
                    size: 24,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      LocalizedCategoryHelper.getLocalizedName(context, expense.title),
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _getRelativeTime(expense.date, context),
                      style: AppTypography.labelSmall.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              // Bold amount
              Text(
                formatManager.formatCurrency(expense.amount / 100, currencyCode: currency),
                style: AppTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getRelativeTime(DateTime date, BuildContext context) {
    final now = DateTime.now();
    final diff = now.difference(date);
    final l10n = AppLocalizations.of(context)!;

    if (diff.inMinutes < 1) return l10n.commonJustNow;
    if (diff.inMinutes < 60) return l10n.commonMinutesAgo(diff.inMinutes);
    if (diff.inHours < 24) return l10n.commonHoursAgo(diff.inHours);
    if (diff.inDays < 7) return l10n.commonDaysAgo(diff.inDays);
    
    // User requested full month names
    return LocalizedDateFormatter.formatMonthDay(date, l10n.localeName);
  }
}
