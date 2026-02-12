
import 'package:cashpilot/ui/widgets/common/glass_widgets.dart' show GlassContainer;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../features/net_worth/providers/net_worth_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_typography.dart';

class NetWorthHeaderCard extends ConsumerWidget {
  const NetWorthHeaderCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(netWorthSummaryProvider);
    
    return GlassContainer(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'TOTAL NET WORTH',
              style: AppTypography.labelMedium.copyWith(
                color: Colors.white60,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            summaryAsync.when(
              data: (summary) {
                final currency = ref.watch(currencyProvider);
                return Text(
                  CurrencyFormatter.format(summary.netWorth / 100.0, currencyCode: currency),
                  style: AppTypography.displaySmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.0,
                  ),
                );
              },
              loading: () => const SizedBox(
                height: 50, 
                width: 50, 
                child: CircularProgressIndicator(color: AppColors.primaryGreen),
              ),
              error: (_, __) => const Text('---', style: TextStyle(color: Colors.white, fontSize: 32)),
            ),
            const SizedBox(height: 16),
            // Mini Graph Placeholder
            Container(
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.white.withValues(alpha: 0.05),
              ),
              child: const Center(
                child: Text(
                  'Insights Coming Soon', 
                  style: TextStyle(color: Colors.white30, fontSize: 10)
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
