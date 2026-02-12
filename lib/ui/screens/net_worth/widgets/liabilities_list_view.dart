
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../features/net_worth/providers/net_worth_providers.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../widgets/common/glass_widgets.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../domain/entities/net_worth/liability.dart';

class LiabilitiesListView extends ConsumerWidget {
  const LiabilitiesListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liabilitiesAsync = ref.watch(liabilitiesStreamProvider);

    return liabilitiesAsync.when(
      data: (liabilities) {
        if (liabilities.isEmpty) {
          return Center(
            child: Text(
              'No Liabilities Added Yet',
              style: TextStyle(color: Colors.white54),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 80),
          itemExtent: 80, // Known height for better performance
          itemCount: liabilities.length,
          itemBuilder: (context, index) {
            final liability = liabilities[index];
            return LiabilityListTile(liability: liability);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err', style: TextStyle(color: Colors.red))),
    );
  }
}

class LiabilityListTile extends StatelessWidget {
  final Liability liability;

  const LiabilityListTile({super.key, required this.liability});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      onTap: () {
        // Placeholder for future liability detail/edit functionality
      },
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.redAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.redAccent.withValues(alpha: 0.2), width: 0.5),
            ),
            child: Icon(_getIcon(liability.type), color: Colors.redAccent, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  liability.name,
                  style: AppTypography.titleSmall.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                Text(
                  liability.type.displayName,
                  style: AppTypography.labelMedium.copyWith(color: Colors.white60),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '-${CurrencyFormatter.format(liability.currentBalance / 100.0, currencyCode: liability.currency)}',
                style: AppTypography.titleMedium.copyWith(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (liability.interestRate != null)
                Text(
                  '${liability.interestRate}% APR',
                  style: AppTypography.labelSmall.copyWith(color: Colors.white38),
                ),
            ],
          ),
        ],
      ),
    );
  }
  
  IconData _getIcon(LiabilityType type) {
    switch (type) {
      case LiabilityType.mortgage: return Icons.home;
      case LiabilityType.loan: return Icons.money_off;
      case LiabilityType.creditCard: return Icons.credit_card;
      case LiabilityType.other: return Icons.receipt_long;
    }
  }
}
