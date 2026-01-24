import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cashpilot/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../widgets/common/glass_card.dart';
import '../../../widgets/common/cp_app_icon.dart';

class HomeQuickActions extends ConsumerWidget {
  final Color accentColor;

  const HomeQuickActions({
    super.key,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _QuickActionButton(
                icon: Icons.flash_on_rounded,
                label: l10n.homeSmartAdd,
                color: accentColor,
                onTap: () {
                   context.push(AppRoutes.addExpense, extra: {'mode': 'smart'});
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionButton(
                icon: Icons.receipt_long_rounded,
                label: l10n.homeScanReceipt,
                color: AppColors.accent,
                onTap: () => context.push(AppRoutes.scanReceipt),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionButton(
                icon: Icons.qr_code_scanner_rounded,
                label: l10n.homeScanBarcode,
                color: AppColors.warning,
                onTap: () async {
                  final result = await context.push(AppRoutes.scanBarcode);
                  if (result != null && context.mounted) {
                     try {
                        final r = result as dynamic; 
                        final product = r.productInfo;
                        String? name;
                        int? amount; 
                        
                        if (product != null) {
                           name = product.name;
                           if (product.price != null) {
                             amount = (product.price * 100).toInt();
                           }
                        }
                        
                        name ??= "Scanned Item (${r.rawValue})";
                        
                        context.push(AppRoutes.addExpense, extra: {
                          'merchant': name,
                          'amount': amount,
                          'date': DateTime.now(),
                        });
                     } catch (e) {
                        debugPrint('Error parsing barcode result: $e');
                     }
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          CPAppIcon(
            icon: icon,
            color: color,
            size: 44,
            iconSize: 24,
            useGradient: false,
          ),
          const SizedBox(height: 12),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppTypography.labelSmall.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
