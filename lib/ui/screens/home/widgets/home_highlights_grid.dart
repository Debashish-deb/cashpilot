import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cashpilot/l10n/app_localizations.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/managers/format_manager.dart';
import '../../../../features/home/viewmodels/home_view_model.dart';
import 'package:fl_chart/fl_chart.dart';

import 'home_section_header.dart';

import 'package:cashpilot/ui/widgets/common/insight_card.dart';
import 'package:cashpilot/features/reports/services/reports_service.dart';

class HomeHighlightsGrid extends ConsumerWidget {
  const HomeHighlightsGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final homeStateAsync = ref.watch(homeViewModelProvider);
    final formatter = ref.watch(formatManagerProvider);
    
    final homeState = homeStateAsync.valueOrNull;
    final currency = homeState?.currency ?? 'USD';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HomeSectionHeader(title: "Overview"),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Left Column (Health & Pulse)
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Expanded(
                            child: InsightCard(
                              title: "Health",
                              value: "${homeState?.healthMetrics?.score ?? 0}",
                              subtitle: homeState?.healthMetrics?.insight ?? "No diagnosis",
                              variant: InsightCardVariant.hero,
                              gradient: AppColors.magmaGradient,
                              indicator: _ScoreIndicator(
                                score: homeState?.healthMetrics?.score ?? 0,
                                momentum: homeState?.healthMetrics?.momentum ?? 1.0,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: InsightCard(
                              title: "Pulse",
                              value: homeState?.cashFlowPulse ?? "Neutral",
                              subtitle: "Momentum",
                              variant: InsightCardVariant.pulse,
                              gradient: AppColors.emeraldGradient,
                              indicator: const Icon(Icons.bolt_rounded, color: Colors.white, size: 20),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Right Column (Outlook & Alert)
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Expanded(
                            child: InsightCard(
                              title: "Outlook",
                              value: _getStatusLabel(homeState?.runway?.status ?? RunwayStatus.onTrack),
                              subtitle: homeState?.runway?.message ?? "Calculating...",
                              variant: InsightCardVariant.runway,
                              gradient: AppColors.tealGradient,
                              indicator: _ConditionIcon(status: homeState?.runway?.status ?? RunwayStatus.onTrack),
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (homeState?.smartAlert != null)
                            Expanded(
                              child: InsightCard(
                                title: "Alert",
                                value: homeState!.smartAlert!.title,
                                subtitle: homeState.smartAlert!.message,
                                variant: InsightCardVariant.alert,
                                gradient: AppColors.indigoGradient,
                                indicator: const Icon(Icons.notification_important_rounded, color: Colors.white, size: 20),
                              ),
                            )
                          else
                            const Spacer(), // Keep grid alignment
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getStatusLabel(RunwayStatus status) {
    switch (status) {
      case RunwayStatus.onTrack: return "On Track";
      case RunwayStatus.atRisk: return "At Risk";
      case RunwayStatus.overspending: return "Overspending";
    }
  }
}

class _ScoreIndicator extends StatelessWidget {
  final int score;
  final double momentum;
  const _ScoreIndicator({required this.score, required this.momentum});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 40,
          width: 40,
          child: CircularProgressIndicator(
            value: score / 100,
            strokeWidth: 4,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              momentum >= 1.0 ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
              size: 10,
              color: Colors.white,
            ),
            const SizedBox(width: 2),
            Text(
              "${(momentum * 10).toStringAsFixed(0)}%",
              style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }
}

class _ConditionIcon extends StatelessWidget {
  final RunwayStatus status;
  const _ConditionIcon({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;
    
    switch (status) {
      case RunwayStatus.onTrack:
        color = AppColors.primaryGreen;
        icon = Icons.check_circle_outline_rounded;
        break;
      case RunwayStatus.atRisk:
        color = AppColors.warning;
        icon = Icons.info_outline_rounded;
        break;
      case RunwayStatus.overspending:
        color = AppColors.danger;
        icon = Icons.warning_amber_rounded;
        break;
    }
    
    return Icon(icon, color: color, size: 28);
  }
}

class _HighlightCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final LinearGradient? gradient;
  final Color? textColor;
  final Widget? child;

  const _HighlightCard({
    required this.title,
    required this.value, this.subtitle, this.gradient, this.textColor, this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(18), // Reduced from 20
      decoration: BoxDecoration(
        color: gradient == null 
            ? (isDark ? theme.colorScheme.surfaceContainerHigh : Colors.white) 
            : null,
        gradient: gradient,
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
          Text(
            title,
            style: AppTypography.labelSmall.copyWith(
              color: textColor?.withValues(alpha: 0.7) ?? (isDark ? Colors.white60 : theme.hintColor),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 7), // Reduced from 8
          Text(
            value,
            style: AppTypography.titleLarge.copyWith(
              color: textColor ?? (isDark ? Colors.white : theme.colorScheme.onSurface),
              fontWeight: FontWeight.w800,
              fontSize: 20, // Reduced from 22
              letterSpacing: -0.5,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: AppTypography.labelSmall.copyWith(
                color: textColor?.withValues(alpha: 0.9) ?? AppColors.primaryGreen,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
          if (child != null) ...[
            const Spacer(),
            child!,
          ],
        ],
      ),
    );
  }
}

class _SmallSparkline extends StatelessWidget {
  final List<FlSpot> spots;
  const _SmallSparkline({required this.spots});

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
            color: AppColors.danger,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.danger.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }
}
