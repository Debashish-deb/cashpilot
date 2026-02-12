import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/subscription.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../features/subscription/providers/subscription_providers.dart';
import '../../../../features/settings/viewmodels/settings_view_model.dart';
import '../../../../l10n/app_localizations.dart';

import '../settings_tiles.dart';

class SubscriptionSection extends ConsumerWidget {
  const SubscriptionSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    final tierAsync = ref.watch(currentTierProvider);
    final currentTier = tierAsync.value ?? SubscriptionTier.free;

    final isPaid = currentTier != SubscriptionTier.free;
    final isProPlus = currentTier == SubscriptionTier.proPlus;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ------------------------------------------------------------------
          // SECTION TITLE
          // ------------------------------------------------------------------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              l10n.settingsSubscriptionAndFeatures.toUpperCase(),
              style: AppTypography.titleSmall.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ------------------------------------------------------------------
          // CONTENT CONTAINER
          // ------------------------------------------------------------------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).dividerColor.withOpacity(0.15),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 600;
                    final itemWidth = isWide
                        ? (constraints.maxWidth - 12) / 2
                        : constraints.maxWidth;

                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _tile(
                          width: itemWidth,
                          child: _subscriptionTile(
                            context,
                            ref,
                            l10n,
                            currentTier,
                            isPaid,
                            isProPlus,
                          ),
                        ),
                        if (!isProPlus)
                          _tile(
                            width: itemWidth,
                            child: _ocrQuotaTile(
                              context,
                              l10n,
                              currentTier,
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // TILE WRAPPER
  // --------------------------------------------------------------------------

  Widget _tile({
    required double width,
    required Widget child,
  }) {
    return SizedBox(
      width: width,
      height: 74,
      child: child,
    );
  }

  // --------------------------------------------------------------------------
  // SUBSCRIPTION TILE
  // --------------------------------------------------------------------------

  Widget _subscriptionTile(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    SubscriptionTier tier,
    bool isPaid,
    bool isProPlus,
  ) {
    return SettingsTile(
      icon: isPaid
          ? Icons.workspace_premium_rounded
          : Icons.card_membership_rounded,
      iconColor: isPaid ? AppColors.primaryGold : null,
      title: l10n.settingsSubscription,
      trailing: isPaid
          ? _planBadge(context, isProPlus ? 'PRO +' : 'PRO')
          : null,
      onTap: () => context.push(AppRoutes.paywall),
    );
  }

  // --------------------------------------------------------------------------
  // OCR QUOTA TILE
  // --------------------------------------------------------------------------

  Widget _ocrQuotaTile(
    BuildContext context,
    AppLocalizations l10n,
    SubscriptionTier tier,
  ) {
    return SettingsTile(
      icon: Icons.document_scanner_rounded,
      title: l10n.settingsOcrScans,
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          tier == SubscriptionTier.free
              ? l10n.settingsFree
              : l10n.commonUnlimited,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // BADGE
  // --------------------------------------------------------------------------

  Widget _planBadge(BuildContext context, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 10,
          letterSpacing: 0.4,
        ),
      ),
    );
  }


}
