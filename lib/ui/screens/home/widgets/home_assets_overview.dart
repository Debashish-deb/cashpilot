import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cashpilot/l10n/app_localizations.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/managers/format_manager.dart';
import '../../../../features/home/viewmodels/home_view_model.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';

import 'home_section_header.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/providers/app_providers.dart';

class HomeAssetsOverview extends ConsumerWidget {
  const HomeAssetsOverview({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final homeStateAsync = ref.watch(homeViewModelProvider);
    final formatter = ref.watch(formatManagerProvider);
    
    final state = homeStateAsync.valueOrNull;
    final currency = state?.currency ?? 'USD';
    final accounts = state?.accounts ?? [];
    final assets = state?.netWorthAssets ?? [];
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Map account/asset types to colors
    Color getColorForType(String type) {
      switch (type.toLowerCase()) {
        case 'savings': 
        case 'cash':
          return AppColors.primaryGreen;
        case 'investment': 
        case 'crypto':
        case 'stocks':
          return AppColors.accent;
        case 'realestate':
        case 'real estate':
          return AppColors.warning;
        case 'vehicle':
          return AppColors.danger;
        default: return AppColors.accent;
      }
    }

    // Unified Asset Model for visualization
    final List<_UnifiedAsset> unifiedAssets = [
      ...accounts
          .where((a) => a.type != 'credit' && a.type != 'loan')
          .map((a) => _UnifiedAsset(name: a.name, value: a.balance, type: a.type)),
      ...assets.map((a) => _UnifiedAsset(name: a.name, value: a.currentValue, type: a.type.displayName)),
    ];

    final totalAssets = unifiedAssets.fold<int>(0, (sum, a) => sum + a.value);

    final sections = unifiedAssets.map((acc) {
      final percentage = totalAssets > 0 ? (acc.value / totalAssets) * 100 : 0.0;
      return PieChartSectionData(
        color: getColorForType(acc.type),
        value: percentage,
        title: '',
        radius: 18,
      );
    }).toList();

    // EMPTY STATE WIDGET
    if (unifiedAssets.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HomeSectionHeader(title: l10n.savingsAssetsOverview),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: isDark ? theme.colorScheme.surfaceContainerHigh : Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  Icon(Icons.pie_chart_outline_rounded, size: 48, color: theme.hintColor.withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  Text(
                    'No assets tracked yet',
                    style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add your bank accounts or real-world assets to see your portfolio here.',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySmall.copyWith(color: theme.hintColor),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FilledButton.icon(
                        onPressed: () => context.push(AppRoutes.accountCreate),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Add Account'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final userId = ref.read(currentUserIdProvider);
                          if (userId != null) {
                            await ref.read(databaseProvider).seedDemoAccounts(userId);
                            // The stream will naturally rebuild
                          }
                        },
                        icon: const Icon(Icons.auto_awesome_rounded),
                        label: const Text('Seed Demo'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.hintColor,
                          side: BorderSide(color: theme.hintColor.withValues(alpha: 0.3)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HomeSectionHeader(title: l10n.savingsAssetsOverview),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.all(22),
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
            child: Row(
              children: [
                // Donut Chart
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 126,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 36,
                        sections: sections.isNotEmpty 
                            ? sections 
                            : [PieChartSectionData(color: Colors.grey.withValues(alpha: 0.2), value: 1, radius: 18)],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                // Legend
                Expanded(
                  flex: 3,
                  child: Column(
                    children: unifiedAssets.take(4).map((acc) {
                      final percentage = totalAssets > 0 ? (acc.value / totalAssets) * 100 : 0;
                      return _LegendItem(
                        label: acc.name, 
                        percentage: '${percentage.toStringAsFixed(0)}%', 
                        color: getColorForType(acc.type)
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _UnifiedAsset {
  final String name;
  final int value;
  final String type;

  _UnifiedAsset({required this.name, required this.value, required this.type});
}

class _LegendItem extends StatelessWidget {
  final String label;
  final String percentage;
  final Color color;

  const _LegendItem({required this.label, required this.percentage, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: AppTypography.bodySmall.copyWith(color: Theme.of(context).hintColor),
            ),
          ),
          Text(
            percentage,
            style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
