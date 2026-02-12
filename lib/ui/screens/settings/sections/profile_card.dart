import 'dart:ui';
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
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: () => context.push(AppRoutes.profile),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
          topRight: Radius.circular(4),
          bottomLeft: Radius.circular(4),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
                topRight: Radius.circular(4),
                bottomLeft: Radius.circular(4),
              ),
              border: Border.all(
                color: isDark 
                    ? Colors.white.withValues(alpha: 0.4) 
                    : Colors.white.withValues(alpha: 0.3), 
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.1),
                  blurRadius: 20,
                  spreadRadius: -5,
                ),
              ],
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark ? [
                  Colors.white.withValues(alpha: 0.12), 
                  Colors.white.withValues(alpha: 0.05),
                ] : [
                  Colors.white.withValues(alpha: 0.4),
                  Colors.white.withValues(alpha: 0.2),
                ],
              ),
            ),
            child: Stack(
              children: [
                // Centered Content
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Avatar with Glow
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: accentColor.withValues(alpha: 0.4),
                              blurRadius: 25,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: avatarUrl != null
                          ? Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 2),
                                image: DecorationImage(image: NetworkImage(avatarUrl), fit: BoxFit.cover),
                              ),
                            )
                          : CPAppIcon(
                              icon: Icons.person_rounded,
                              color: accentColor,
                              size: 72,
                              iconSize: 36,
                              useGradient: true,
                            ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Info
                      Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  displayName.toUpperCase(),
                                  style: AppTypography.titleMedium.copyWith(
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.2,
                                    fontSize: 16,
                                    color: isDark ? Colors.white : accentColor,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withValues(alpha: 0.2),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const _SubscriptionBadge(),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: AppTypography.bodySmall.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isDark 
                                  ? Colors.white.withValues(alpha: 0.6) 
                                  : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Top Right Navigation Indicator
                Positioned(
                  top: 0,
                  right: 0,
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: (isDark ? Colors.white : accentColor).withValues(alpha: 0.3),
                    size: 14,
                  ),
                ),
              ],
            ),
          ),
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
