import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cashpilot/l10n/app_localizations.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/managers/format_manager.dart';
import '../../../../features/home/viewmodels/home_view_model.dart';
import 'package:fl_chart/fl_chart.dart';


import 'package:cashpilot/ui/widgets/common/insight_card.dart';

class HomeIncomeExpenseCards extends ConsumerWidget {
  const HomeIncomeExpenseCards({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final homeStateAsync = ref.watch(homeViewModelProvider);
    final formatter = ref.watch(formatManagerProvider);
    
    final state = homeStateAsync.valueOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Card 3: Cash Flow Pulse
                  Expanded(
                    child: InsightCard(
                      title: "Pulse",
                      value: state?.cashFlowPulse ?? "Neutral",
                      subtitle: "Momentum",
                      variant: InsightCardVariant.pulse,
                      gradient: AppColors.emeraldGradient,
                      indicator: const Icon(Icons.bolt_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Card 4: Attention Needed
                  if (state?.smartAlert != null)
                    Expanded(
                      child: InsightCard(
                        title: "Alert",
                        value: state!.smartAlert!.title,
                        subtitle: state.smartAlert!.message,
                        variant: InsightCardVariant.alert,
                        gradient: AppColors.indigoGradient,
                        indicator: const Icon(Icons.notification_important_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TrendCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final bool isPositive;
  final List<FlSpot> spots;

  const _TrendCard({
    required this.title,
    required this.value,
    required this.color,
    required this.isPositive,
    required this.spots,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(18), // Reduced from 20
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isPositive ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                  size: 14,
                  color: color,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: AppTypography.labelSmall.copyWith(
                  color: isDark ? Colors.white60 : theme.hintColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10), // Reduced from 12
          Text(
            value,
            style: AppTypography.titleLarge.copyWith(
              color: isDark ? Colors.white : theme.colorScheme.onSurface,
              fontWeight: FontWeight.w800,
              fontSize: 19, // Reduced from 20
              letterSpacing: -0.5,
            ),
          ),
          const Spacer(),
          const SizedBox(height: 10), // Reduced from 12
          SizedBox(
            height: 27, // Reduced from 30
            child: _MiniSparkline(color: color, spots: spots),
          ),
        ],
      ),
    );
  }
}

class _MiniSparkline extends StatelessWidget {
  final Color color;
  final List<FlSpot> spots;
  const _MiniSparkline({required this.color, required this.spots});

  @override
  Widget build(BuildContext context) {
    if (spots.isEmpty) return const SizedBox.shrink();
    
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: color,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: color.withValues(alpha: 0.05),
            ),
          ),
        ],
      ),
    );
  }
}
