import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/accent_colors.dart';
import '../../../../features/auth/providers/auth_provider.dart';
import '../../../../features/subscription/providers/subscription_providers.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../widgets/common/cp_app_icon.dart';
import '../../../widgets/common/enhanced_widgets.dart';
import '../../../../core/constants/subscription.dart';

class ProfileCard extends ConsumerWidget {
  const ProfileCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final accentColor = ref.watch(accentConfigProvider).primary;
    
    // Get user display name from auth or local
    String displayName = l10n.profileGuestUser;
    String subtitle = l10n.profileSignInToSync;
    String? avatarUrl;
    
    if (user != null) {
      displayName = user.userMetadata?['name'] ?? 
          user.userMetadata?['full_name'] ??
          user.email?.split('@').first ?? 
          l10n.profileGuestUser;
      subtitle = user.email ?? '';
      avatarUrl = user.userMetadata?['avatar_url'] ?? user.userMetadata?['picture'];
    } else if (authState.status == AuthStatus.authenticated) {
      // Guest user with local account
      displayName = l10n.profileGuestUser;
      subtitle = l10n.authGuest;
    }
    
    return GestureDetector(
      onTap: () => context.push(AppRoutes.profile),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accentColor.withValues(alpha: 0.2), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            avatarUrl != null
              ? Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(64 * 0.22),
                    border: Border.all(color: accentColor.withValues(alpha: 0.3), width: 2),
                    image: DecorationImage(image: NetworkImage(avatarUrl), fit: BoxFit.cover),
                  ),
                )
              : CPAppIcon(
                  icon: Icons.person_rounded,
                  color: accentColor,
                  size: 64,
                  iconSize: 32,
                  useGradient: true,
                ),
            
            const SizedBox(width: 16),
            
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          displayName,
                          style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _SubscriptionBadge(),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTypography.bodyMedium.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            
            // Chevron
            Icon(
              Icons.chevron_right_rounded,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubscriptionBadge extends ConsumerWidget {
  const _SubscriptionBadge();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tierAsync = ref.watch(currentTierProvider);
    final tier = tierAsync.value ?? SubscriptionTier.free;

    if (tier == SubscriptionTier.free) return const SizedBox.shrink();

    return FeatureBadge(
      label: tier.displayName.toUpperCase(),
      isProPlus: tier == SubscriptionTier.proPlus,
    );
  }
}
