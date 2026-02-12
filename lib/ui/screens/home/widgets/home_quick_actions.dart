import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cashpilot/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../widgets/common/glass_card.dart';

class HomeQuickActions extends ConsumerWidget {
  final Color accentColor;

  const HomeQuickActions({
    super.key,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: _QuickActionButton(
            icon: Icons.flash_on_rounded,
            label: "Smart",
            color: accentColor,
            onTap: () {
               context.push(AppRoutes.addExpense, extra: {'mode': 'smart'});
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _QuickActionButton(
            icon: Icons.receipt_long_rounded,
            label: "Receipt",
            color: AppColors.accent,
            onTap: () => context.push(AppRoutes.scanReceipt),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _QuickActionButton(
            icon: Icons.qr_code_scanner_rounded,
            label: "Barcode",
            color: AppColors.warning,
            onTap: () async {
              final result = await context.push(AppRoutes.scanBarcode);
              // ... rest of the barcode logic remains same ...
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
    final theme = Theme.of(context);
    return GlassCard(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      borderRadius: 100, // Pill shape
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: color,
            size: 16,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 11,
                letterSpacing: -0.2,
                color: theme.colorScheme.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
