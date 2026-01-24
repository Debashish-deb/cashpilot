/// Unified Pro Gate Component
/// Consistent Pro/Pro Plus feature gating UI across the app
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../features/subscription/providers/subscription_providers.dart';

/// Consistent badge styles for Pro features
enum ProBadgeStyle {
  /// Small inline badge (e.g., next to a menu item)
  inline,
  
  /// Medium chip-style badge
  chip,
  
  /// Large prominent badge
  prominent,
}

/// Unified Pro Badge Widget
/// Use this EVERYWHERE a Pro badge is needed for consistency
class ProBadge extends StatelessWidget {
  final ProBadgeStyle style;
  final bool isProPlus;
  final VoidCallback? onTap;

  const ProBadge({
    super.key,
    this.style = ProBadgeStyle.inline,
    this.isProPlus = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final label = isProPlus ? 'PRO+' : 'PRO';
    final color = isProPlus ? AppColors.gold : const Color(0xFF6366F1);

    switch (style) {
      case ProBadgeStyle.inline:
        return _buildInlineBadge(label, color);
      case ProBadgeStyle.chip:
        return _buildChipBadge(label, color, context);
      case ProBadgeStyle.prominent:
        return _buildProminentBadge(label, color, context);
    }
  }

  Widget _buildInlineBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.8)],
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildChipBadge(String label, Color color, BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () => context.push(AppRoutes.paywall),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withValues(alpha: 0.85)],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star, size: 12, color: Colors.white),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProminentBadge(String label, Color color, BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () => context.push(AppRoutes.paywall),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withValues(alpha: 0.75)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.workspace_premium, size: 18, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Unified Pro Locked Overlay
/// Use this to wrap features that require Pro subscription
class ProLockedOverlay extends ConsumerWidget {
  final Widget child;
  final String featureName;
  final String? description;
  final bool requiresProPlus;
  final bool showBadge;
  final bool blurContent;

  const ProLockedOverlay({
    super.key,
    required this.child,
    required this.featureName,
    this.description,
    this.requiresProPlus = false,
    this.showBadge = true,
    this.blurContent = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPaid = ref.watch(isPaidProvider);
    final isProPlus = ref.watch(isProPlusProvider);

    // Check access
    final hasAccess = requiresProPlus ? isProPlus : isPaid;

    if (hasAccess) {
      return child;
    }

    return Stack(
      children: [
        // Blurred/dimmed content
        if (blurContent)
          Opacity(
            opacity: 0.4,
            child: AbsorbPointer(child: child),
          )
        else
          AbsorbPointer(child: child),

        // Lock overlay
        Positioned.fill(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              context.push(AppRoutes.paywall);
            },
            child: Container(
              color: Colors.transparent,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.lock_outline,
                            size: 32,
                            color: requiresProPlus
                                ? AppColors.gold
                                : const Color(0xFF6366F1),
                          ),
                          const SizedBox(height: 12),
                          if (showBadge) ...[
                            ProBadge(
                              style: ProBadgeStyle.chip,
                              isProPlus: requiresProPlus,
                            ),
                            const SizedBox(height: 8),
                          ],
                          Text(
                            featureName,
                            style: AppTypography.titleSmall.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (description != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              description!,
                              style: AppTypography.bodySmall.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.6),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                          const SizedBox(height: 12),
                          Text(
                            'Tap to upgrade',
                            style: AppTypography.labelSmall.copyWith(
                              color: requiresProPlus
                                  ? AppColors.gold
                                  : const Color(0xFF6366F1),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Unified Pro Upgrade Banner
/// Use this for consistent upgrade prompts
class ProUpgradeBanner extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isProPlus;
  final bool compact;
  final VoidCallback? onDismiss;

  const ProUpgradeBanner({
    super.key,
    this.title = 'Unlock Premium Features',
    this.subtitle = 'Get advanced analytics, unlimited budgets, and more.',
    this.isProPlus = false,
    this.compact = false,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final color = isProPlus ? AppColors.gold : const Color(0xFF6366F1);

    return Container(
      margin: compact
          ? const EdgeInsets.symmetric(horizontal: 16, vertical: 8)
          : const EdgeInsets.all(16),
      padding: compact
          ? const EdgeInsets.all(12)
          : const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.15),
            color.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(compact ? 12 : 20),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(compact ? 10 : 14),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(compact ? 10 : 14),
            ),
            child: Icon(
              Icons.workspace_premium,
              color: color,
              size: compact ? 24 : 32,
            ),
          ),
          SizedBox(width: compact ? 12 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: (compact
                          ? AppTypography.titleSmall
                          : AppTypography.titleMedium)
                      .copyWith(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: compact ? 2 : 4),
                Text(
                  subtitle,
                  style: AppTypography.bodySmall.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.7),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            children: [
              FilledButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  context.push(AppRoutes.paywall);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: color,
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? 12 : 16,
                    vertical: compact ? 8 : 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(compact ? 8 : 12),
                  ),
                ),
                child: Text(
                  'Upgrade',
                  style: TextStyle(
                    fontSize: compact ? 12 : 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (onDismiss != null) ...[
                const SizedBox(height: 4),
                TextButton(
                  onPressed: onDismiss,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Later',
                    style: AppTypography.labelSmall.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Unified Pro Feature Row (for settings/lists)
/// Use this when showing a locked feature in a list
class ProFeatureRow extends ConsumerWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool requiresProPlus;
  final VoidCallback? onTapWhenUnlocked;

  const ProFeatureRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.requiresProPlus = false,
    this.onTapWhenUnlocked,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPaid = ref.watch(isPaidProvider);
    final isProPlus = ref.watch(isProPlusProvider);
    final hasAccess = requiresProPlus ? isProPlus : isPaid;
    final color = requiresProPlus ? AppColors.gold : const Color(0xFF6366F1);

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: hasAccess
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
              : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: hasAccess
              ? Theme.of(context).colorScheme.primary
              : color,
          size: 22,
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: AppTypography.titleSmall.copyWith(
                color: hasAccess
                    ? null
                    : Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
              ),
            ),
          ),
          if (!hasAccess) ...[
            const SizedBox(width: 8),
            ProBadge(
              style: ProBadgeStyle.inline,
              isProPlus: requiresProPlus,
            ),
          ],
        ],
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: AppTypography.bodySmall.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5),
              ),
            )
          : null,
      trailing: hasAccess
          ? const Icon(Icons.chevron_right)
          : Icon(Icons.lock_outline, color: color, size: 20),
      onTap: () {
        HapticFeedback.selectionClick();
        if (hasAccess && onTapWhenUnlocked != null) {
          onTapWhenUnlocked!();
        } else {
          context.push(AppRoutes.paywall);
        }
      },
    );
  }
}
