import 'package:cashpilot/ui/widgets/common/glass_widgets.dart' show GlassContainer;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cashpilot/core/theme/app_colors.dart';
import 'package:cashpilot/core/providers/app_providers.dart';
import 'package:cashpilot/features/net_worth/providers/net_worth_providers.dart';

class NetWorthChart extends ConsumerWidget {
  const NetWorthChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(netWorthHistoryProvider(days: 30));

    return historyAsync.when(
      data: (history) {
        if (history.isEmpty) {
          return const SizedBox(
            height: 200,
            child: Center(
              child: Text(
                'No wealth history yet.\nAdd assets to track progress.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54),
              ),
            ),
          );
        }

        // Map history to FlSpot using timestamp for X axis
        final spots = history.map((e) {
          return FlSpot(
            e.date.millisecondsSinceEpoch.toDouble(),
            e.valueCents / 100.0,
          );
        }).toList();

        final firstDate = history.first.date.millisecondsSinceEpoch.toDouble();
        final lastDate = history.last.date.millisecondsSinceEpoch.toDouble();

        return GlassContainer(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Wealth Trajectory (30d)',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 180,
                child: LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: false),
                    titlesData: FlTitlesData(
                      show: true,
                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 22,
                          interval: history.length > 1 
                              ? (lastDate - firstDate) / 4 
                              : const Duration(days: 7).inMilliseconds.toDouble(), // Fallback for single point
                          getTitlesWidget: (value, meta) {
                            if (value == meta.min || value == meta.max) return const SizedBox.shrink();
                            final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                            return Text(
                              DateFormat('dd/MM').format(date),
                              style: const TextStyle(color: Colors.white24, fontSize: 10),
                            );
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    minX: firstDate,
                    maxX: lastDate,
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        color: AppColors.primaryGreen,
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: AppColors.primaryGreen.withValues(alpha: 0.1),
                        ),
                      ),
                    ],
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipColor: (_) => Colors.black87,
                        getTooltipItems: (touchedSpots) {
                          return touchedSpots.map((spot) {
                            final date = DateTime.fromMillisecondsSinceEpoch(spot.x.toInt());
                            final formattedDate = DateFormat('MMM dd').format(date);
                            final amount = NumberFormat.simpleCurrency(
                              decimalDigits: 0,
                              name: ref.read(currencyProvider),
                            ).format(spot.y);
                            return LineTooltipItem(
                              '$formattedDate\n$amount',
                              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            );
                          }).toList();
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => const SizedBox.shrink(),
    );
  }
}
