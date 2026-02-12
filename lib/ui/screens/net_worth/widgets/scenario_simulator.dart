import 'package:cashpilot/ui/widgets/common/glass_widgets.dart' show GlassContainer;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cashpilot/core/theme/app_colors.dart';
import 'package:cashpilot/core/theme/app_typography.dart';
import '../../../../features/net_worth/providers/net_worth_providers.dart';
import '../../../../core/services/forecasting_service.dart';

class ScenarioSimulator extends ConsumerStatefulWidget {
  const ScenarioSimulator({super.key});

  @override
  ConsumerState<ScenarioSimulator> createState() => _ScenarioSimulatorState();
}

class _ScenarioSimulatorState extends ConsumerState<ScenarioSimulator> {
  double _goalAmount = 100000;
  double _monthlyBoost = 500;

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(netWorthHistoryProvider(days: 90));
    final currency = NumberFormat.simpleCurrency(decimalDigits: 0);

    return historyAsync.when(
      data: (history) {
        if (history.isEmpty) return const SizedBox.shrink();

        final service = ref.watch(forecastingServiceProvider);
        final points = history.map((h) => ValuationPoint(
          h.date,
          h.valueCents,
        )).toList();

        final days = service.daysToReachGoalWithBoost(points, (_goalAmount * 100).round(), (_monthlyBoost * 100).round());
        final years = days / 365.25;
        final targetDate = DateTime.now().add(Duration(days: days > 0 ? days : 0));

        return GlassContainer(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Scenario Simulator',
                style: AppTypography.titleLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Predict when you\'ll hit your financial goals.',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 24),
              
              // Goal Input
              const Text('Target Wealth Goal', style: TextStyle(color: Colors.white60, fontSize: 12)),
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: _goalAmount,
                      min: 1000,
                      max: 1000000,
                      divisions: 99,
                      activeColor: AppColors.primaryGreen,
                      onChanged: (val) => setState(() => _goalAmount = val),
                    ),
                  ),
                  Container(
                    width: 100,
                    alignment: Alignment.centerRight,
                    child: Text(
                      currency.format(_goalAmount),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Boost Input
              const Text('Additional Monthly Savings', style: TextStyle(color: Colors.white60, fontSize: 12)),
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: _monthlyBoost,
                      min: 0,
                      max: 10000,
                      divisions: 100,
                      activeColor: AppColors.primaryGreen,
                      onChanged: (val) => setState(() => _monthlyBoost = val),
                    ),
                  ),
                  Container(
                    width: 100,
                    alignment: Alignment.centerRight,
                    child: Text(
                      '+${currency.format(_monthlyBoost)}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),

              const Divider(color: Colors.white10, height: 32),

              // Result
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Estimated Goal Date', style: TextStyle(color: Colors.white60, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(
                        days < 0 ? 'Never at current trend' : DateFormat('MMMM yyyy').format(targetDate),
                        style: AppTypography.headlineSmall.copyWith(
                          color: days < 0 ? Colors.redAccent : AppColors.primaryGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Time Remaining', style: TextStyle(color: Colors.white60, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(
                        days < 0 ? '--' : '${years.toStringAsFixed(1)} Years',
                        style: AppTypography.titleLarge.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (e, _) => const SizedBox.shrink(),
    );
  }
}
