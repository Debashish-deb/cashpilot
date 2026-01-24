/// Feature Gate Widget
/// Wraps content that requires a specific subscription tier
/// Shows upgrade prompt or locked state for non-entitled users
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/subscription.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../features/subscription/providers/subscription_providers.dart';

/// Widget that gates content based on subscription tier
class FeatureGate extends ConsumerWidget {
  final Feature feature;
  final Widget child;
  final Widget? lockedWidget;
  final bool showBadgeOnly;
  final bool showLockedOnTap;
  final VoidCallback? onLockedTap;

  const FeatureGate({
    super.key,
    required this.feature,
    required this.child,
    this.lockedWidget,
    this.showBadgeOnly = false,
    this.showLockedOnTap = true,
    this.onLockedTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasAccess = ref.watch(canUseFeatureProvider(feature));

    if (hasAccess) return child;

    if (showBadgeOnly) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          child,
          const Positioned(
            top: 4,
            right: 4,
            child: _ProBadge(),
          ),
        ],
      );
    }

    return lockedWidget ??
        _DefaultLockedWidget(
          feature: feature,
          showLockedOnTap: showLockedOnTap,
          onLockedTap: onLockedTap,
        );
  }
}

/// Compact feature gate for inline use
class FeatureGateInline extends ConsumerWidget {
  final Feature feature;
  final Widget child;
  final Widget? lockedChild;

  const FeatureGateInline({
    super.key,
    required this.feature,
    required this.child,
    this.lockedChild,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasAccess = ref.watch(canUseFeatureProvider(feature));

    if (hasAccess) return child;

    return lockedChild ??
        Semantics(
          label: 'Locked feature',
          child: Opacity(
            opacity: 0.45,
            child: IgnorePointer(child: child),
          ),
        );
  }
}

/// Button that checks feature access before executing action
class FeatureGatedButton extends ConsumerWidget {
  final Feature feature;
  final Widget child;
  final VoidCallback onPressed;
  final ButtonStyle? style;

  const FeatureGatedButton({
    super.key,
    required this.feature,
    required this.child,
    required this.onPressed,
    this.style,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasAccess = ref.watch(canUseFeatureProvider(feature));
    final requiredTier = ref.watch(requiredTierProvider(feature));

    return ElevatedButton(
      style: style,
      onPressed: hasAccess
          ? onPressed
          : () => _showUpgradeDialog(context, feature, requiredTier),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          child,
          if (!hasAccess) ...[
            const SizedBox(width: 8),
            Icon(
              Icons.lock_outline,
              size: 16,
              color: Theme.of(context)
                  .colorScheme
                  .onPrimary
                  .withValues(alpha: 0.7),
            ),
          ],
        ],
      ),
    );
  }
}

/// ListTile that shows lock icon for gated features
class FeatureGatedTile extends ConsumerWidget {
  final Feature feature;
  final Widget? leading;
  final Widget title;
  final Widget? subtitle;
  final VoidCallback onTap;

  const FeatureGatedTile({
    super.key,
    required this.feature,
    this.leading,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasAccess = ref.watch(canUseFeatureProvider(feature));
    final requiredTier = ref.watch(requiredTierProvider(feature));

    return ListTile(
      leading: leading,
      title: title,
      subtitle: subtitle,
      trailing: hasAccess
          ? const Icon(Icons.chevron_right)
          : _TierBadge(tier: requiredTier),
      onTap: hasAccess
          ? onTap
          : () => _showUpgradeDialog(context, feature, requiredTier),
    );
  }
}

/// Pro badge to show on locked features
class _ProBadge extends StatelessWidget {
  const _ProBadge();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Pro feature',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.gold,
              AppColors.gold.withValues(alpha: 0.85),
            ],
          ),
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(
              color: AppColors.gold.withValues(alpha: 0.25),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Text(
          'PRO',
          style: TextStyle(
            color: Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

/// Tier badge widget
class _TierBadge extends StatelessWidget {
  final SubscriptionTier tier;

  const _TierBadge({required this.tier});

  @override
  Widget build(BuildContext context) {
    final color =
        tier == SubscriptionTier.proPlus ? AppColors.gold : AppColors.primaryGreen;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            tier.displayName,
            style: AppTypography.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Default locked widget shown when feature is not available
class _DefaultLockedWidget extends StatelessWidget {
  final Feature feature;
  final bool showLockedOnTap;
  final VoidCallback? onLockedTap;

  const _DefaultLockedWidget({
    required this.feature,
    this.showLockedOnTap = true,
    this.onLockedTap,
  });

  @override
  Widget build(BuildContext context) {
    final featureName = SubscriptionManager.getFeatureName(feature);
    final featureDesc = SubscriptionManager.getFeatureDescription(feature);

    return GestureDetector(
      onTap: () {
        if (onLockedTap != null) {
          onLockedTap!();
        } else if (showLockedOnTap) {
          _showUpgradeDialog(context, feature, SubscriptionTier.pro);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).dividerColor,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock_outline_rounded,
              size: 48,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              featureName,
              style: AppTypography.titleMedium.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              featureDesc,
              style: AppTypography.bodySmall.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const _ProBadge(),
          ],
        ),
      ),
    );
  }
}

/// Show upgrade dialog for locked features
void _showUpgradeDialog(BuildContext context, Feature feature, SubscriptionTier requiredTier) {
  final featureName = SubscriptionManager.getFeatureName(feature);
  final featureDesc = SubscriptionManager.getFeatureDescription(feature);

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          Icon(Icons.lock, color: AppColors.gold),
          const SizedBox(width: 12),
          Expanded(child: Text('Upgrade Required')),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            featureName,
            style: AppTypography.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            featureDesc,
            style: AppTypography.bodyMedium,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.star, color: AppColors.gold),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'This feature requires ${requiredTier.displayName}',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.gold,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Maybe Later'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            // Navigate to subscription screen
            Navigator.of(context).pushNamed('/subscription');
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.gold,
          ),
          child: const Text('Upgrade Now'),
        ),
      ],
    ),
  );
}
