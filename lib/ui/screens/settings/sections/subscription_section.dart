import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/constants/subscription.dart';
import '../../../../features/subscription/providers/subscription_providers.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../features/settings/viewmodels/settings_view_model.dart';
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

    String planName;
    if (isProPlus) {
      planName = 'Pro+';
    } else if (isPaid) {
      planName = l10n.settingsProPlan;
    } else {
      planName = l10n.settingsFreePlan;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(
            l10n.settingsSubscriptionAndFeatures,
            style: AppTypography.titleSmall.copyWith(
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Card(
          elevation: 0,
          color: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
            ),
          ),
          child: Column(
            children: [
              SettingsTile(
                icon: isPaid ? Icons.workspace_premium : Icons.card_membership_outlined,
                title: l10n.settingsSubscription,
                subtitle: planName,
                trailing: isPaid
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).primaryColor,
                              Theme.of(context).primaryColor.withValues(alpha: 0.8),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isProPlus ? 'PLUS' : 'PRO',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      )
                    : null,
                onTap: () {
                  if (isPaid) {
                    _showSubscriptionDetails(context, ref, l10n);
                  } else {
                    context.push(AppRoutes.paywall);
                  }
                },
              ),
              if (!isProPlus) ...[
                const Divider(height: 1, indent: 56),
                SettingsTile(
                  icon: Icons.document_scanner_outlined,
                  title: l10n.settingsOcrScans,
                  subtitle: l10n.settingsOcrScansSubtitle,
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      currentTier == SubscriptionTier.free ? l10n.settingsFree : 'Unlimited',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  void _showSubscriptionDetails(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    final tier = ref.read(currentTierProvider).valueOrNull ?? SubscriptionTier.free;
    final expiresAt = ref.read(subscriptionServiceProvider).subscriptionExpiresAt;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Subscription Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Tier: ${tier.displayName}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (expiresAt != null)
              Text('Expires: ${expiresAt.toString().substring(0, 10)}'),
            const SizedBox(height: 16),
            const Text(
              'Manage your subscription via the store.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  context.push(AppRoutes.paywall);
                },
                icon: const Icon(Icons.arrow_forward),
                label: const Text('View Plans'), // Hardcoded
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            if (tier == SubscriptionTier.free) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.warning_amber, size: 16, color: Colors.orange),
                        const SizedBox(width: 8),
                        const Text(
                          'Tier Issue',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Local tier mismatch.',
                      style: TextStyle(fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(settingsViewModelProvider.notifier).refreshSubscription();
            },
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Refresh'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.commonClose),
          ),
        ],
      ),
    );
  }
}
