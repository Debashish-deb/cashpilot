
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../features/net_worth/providers/net_worth_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../widgets/common/glass_widgets.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../domain/entities/net_worth/asset.dart';

class AssetsListView extends ConsumerWidget {
  const AssetsListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assetsAsync = ref.watch(assetsStreamProvider);

    return assetsAsync.when(
      data: (assets) {
        if (assets.isEmpty) {
          return Center(
            child: Text(
              'No Assets Added Yet',
              style: TextStyle(color: Colors.white54),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 80), // Fab space
          itemExtent: 80, // Known height for better performance
          itemCount: assets.length,
          itemBuilder: (context, index) {
            final asset = assets[index];
            return AssetListTile(asset: asset);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err', style: TextStyle(color: Colors.red))),
    );
  }
}

class AssetListTile extends StatelessWidget {
  final Asset asset;

  const AssetListTile({super.key, required this.asset});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      onTap: () {
        // Placeholder for future asset detail/edit functionality
      },
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.2), width: 0.5),
            ),
            child: Icon(_getIcon(asset.type), color: AppColors.primaryGreen, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  asset.name,
                  style: AppTypography.titleSmall.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                Text(
                  asset.type.displayName,
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
                CurrencyFormatter.format(asset.currentValue / 100.0, currencyCode: asset.currency),
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.primaryGreen,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (asset.institutionName != null)
                Text(
                  asset.institutionName!,
                  style: AppTypography.labelSmall.copyWith(color: Colors.white38),
                ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getIcon(AssetType type) {
    switch (type) {
      case AssetType.realEstate: return Icons.home_work;
      case AssetType.vehicle: return Icons.directions_car;
      case AssetType.investment: return Icons.trending_up;
      case AssetType.cash: return Icons.account_balance_wallet;
      case AssetType.crypto: return Icons.currency_bitcoin;
      case AssetType.other: return Icons.category;
    }
  }
}
