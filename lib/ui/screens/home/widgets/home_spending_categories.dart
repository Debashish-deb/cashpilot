import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cashpilot/l10n/app_localizations.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/managers/format_manager.dart';
import '../../../../core/helpers/localized_category_helper.dart';
import '../../../../features/home/viewmodels/home_view_model.dart';
import '../../../widgets/common/cp_app_icon.dart';
import '../../../widgets/common/app_grade_icons.dart';

import 'home_section_header.dart';

class HomeSpendingCategories extends ConsumerWidget {
  const HomeSpendingCategories({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final homeStateAsync = ref.watch(homeViewModelProvider);
    final formatter = ref.watch(formatManagerProvider);
    
    final state = homeStateAsync.valueOrNull;
    if (state == null || state.categoryWiseTotals.isEmpty) {
      return const SizedBox.shrink();
    }

    final currency = state.currency;
    final categoryTotals = state.categoryWiseTotals;
    final categoryMap = state.categoryMap;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HomeSectionHeader(
          title: l10n.reportsSpendingCategories,
          actionLabel: 'See all', // TODO: Localize
          onActionPressed: () {
            // TODO: Navigate to reports
          },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.all(10), // Reduced from 12
            decoration: BoxDecoration(
              color: isDark ? theme.colorScheme.surfaceContainerHigh : Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: isDark ? null : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Category List
                ...categoryTotals.entries.take(5).map((entry) {
                  final category = categoryMap[entry.key];
                  final name = category?.name ?? l10n.catUncategorized;
                  final localizedName = LocalizedCategoryHelper.getLocalizedName(context, name);
                  final color = category?.colorHex != null 
                      ? Color(int.parse(category!.colorHex!.replaceFirst('#', '0xFF')))
                      : AppColors.primaryGreen;

                  return _CategoryItem(
                    name: localizedName,
                    amount: formatter.formatCents(entry.value, currencyCode: currency),
                    iconName: category?.iconName,
                    color: color,
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CategoryItem extends StatelessWidget {
  final String name;
  final String amount;
  final String? iconName;
  final Color color;

  const _CategoryItem({
    required this.name,
    required this.amount,
    this.iconName,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: Row(
        children: [
          CPAppIcon(
            icon: AppGradeIcons.getIcon(iconName),
            color: color,
            size: 40,
            iconSize: 20,
            useGradient: true,
            useShadow: false,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              name,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : theme.colorScheme.onSurface,
              ),
            ),
          ),
          Text(
            amount,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.arrow_forward_ios_rounded, size: 12, color: theme.hintColor.withValues(alpha: 0.5)),
        ],
      ),
    );
  }
}
