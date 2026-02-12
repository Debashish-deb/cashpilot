import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cashpilot/l10n/app_localizations.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/subscription.dart';
import '../../../../core/managers/format_manager.dart';
import '../../../../core/managers/greeting_manager.dart';

import '../../../../features/home/viewmodels/home_view_model.dart';
import '../../../widgets/notifications/notification_dialog.dart';

import '../../../../core/theme/tokens.g.dart';

class HomeSliverAppBar extends ConsumerWidget {
  final Color profileColor;

  const HomeSliverAppBar({
    super.key,
    required this.profileColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final l10n = AppLocalizations.of(context)!;
    final formatManager = ref.watch(formatManagerProvider);
    final homeStateAsync = ref.watch(homeViewModelProvider);
    
    // Smart Greeting Logic
    final greetingConfig = ref.watch(greetingStateProvider);
    // Trigger update check on rebuild (or can be done via timer elsewhere, but this is simple)
    // Ideally this should be in a viewmodel init, but this works for "every 30 mins" check on redraw
    ref.listen(greetingStateProvider, (_, __) {}); 
    // We actually need to trigger the check. 
    // Let's do it in a post-frame callback or better, just trust the notifier if it has a timer. 
    // But GreetingNotifier relies on 'checkUpdates'. 
    // We will call checkUpdates() every time this builds, if time has passed it updates.
    ref.read(greetingStateProvider.notifier).checkUpdates();

    String greeting;
    if (greetingConfig.type == GreetingType.timeBased) {
      if (now.hour < 12) {
        greeting = l10n.homeGoodMorning;
      } else if (now.hour < 17) {
        greeting = l10n.homeGoodAfternoon;
      } else {
        greeting = l10n.homeGoodEvening;
      }
    } else {
      // Map index to localized string using list lookup
      final greetings = [
        l10n.welcomeMessage_1,
        l10n.welcomeMessage_2,
        l10n.welcomeMessage_3,
        l10n.welcomeMessage_4,
        l10n.welcomeMessage_5,
        l10n.welcomeMessage_6,
        l10n.welcomeMessage_7,
        l10n.welcomeMessage_8,
        l10n.welcomeMessage_9,
        l10n.welcomeMessage_10,
        l10n.welcomeMessage_11,
        l10n.welcomeMessage_12,
        l10n.welcomeMessage_13,
        l10n.welcomeMessage_14,
        l10n.welcomeMessage_15,
        l10n.welcomeMessage_16,
        l10n.welcomeMessage_17,
        l10n.welcomeMessage_18,
        l10n.welcomeMessage_19,
        l10n.welcomeMessage_20,
      ];
      // Clamp index to valid range (1-indexed in config, 0-indexed in list)
      final index = (greetingConfig.index - 1).clamp(0, greetings.length - 1);
      greeting = greetings[index];
    }
    
    final dateStr = formatManager.formatDate(now);

    // Fix: Persist app bar state during background refreshes to prevent scroll jumps
    final state = homeStateAsync.valueOrNull;
    
    // If we have data (even if loading), show it.
    if (state != null) {
      return _buildAppBar(context, ref, state, greeting, dateStr);
    }
    
    // Only show skeleton/default if we have NO data and are loading (or error)
    return _buildAppBar(context, ref, const HomeViewState(isLoading: true), greeting, dateStr);
  }

  Widget _buildAppBar(BuildContext context, WidgetRef ref, HomeViewState state, String greeting, String dateStr) {
    final theme = Theme.of(context);
    return SliverAppBar(
      expandedHeight: 140, // Increased slightly to accommodate larger avatar
      floating: true,
      pinned: true,
      toolbarHeight: 80, // Increased from 70 to fix persistent 8px overflow
      backgroundColor: theme.scaffoldBackgroundColor.withValues(alpha: 0.95),
      surfaceTintColor: Colors.transparent, // Disable elevation tint
      flexibleSpace: FlexibleSpaceBar(
        background: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
        ),
        titlePadding: const EdgeInsets.only(left: 20, right: 20, bottom: 8),
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    dateStr.toUpperCase(),
                    style: AppTypography.labelSmall.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w600,
                      fontSize: 7.5,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 0), // Removed spacing further
                  Text(
                    greeting,
                    style: AppTypography.titleLarge.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5, // Reduced from 14.0
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                ],
              ),
            ),
            const SizedBox(width: 12),
            Padding(
              padding: const EdgeInsets.only(bottom: 0), // Tightened alignment
              child: _buildProfileAvatar(context, state.tier, state.avatarUrl, profileColor),
            ),
          ],
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(top: 8), // Better vertical centering in the app bar
          child: IconButton(
            icon: const Icon(Icons.notifications_none_rounded, size: 20), // Reduced from default 24
            onPressed: () => _showNotifications(context),
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
          ),
        ),
        const SizedBox(width: 12),
      ],
    );
  }



  void _showNotifications(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const NotificationDialog(),
    );
  }

  Widget _buildProfileAvatar(BuildContext context, SubscriptionTier tier, String? avatarUrl, Color color) {
    Color tierColor;
    IconData tierIcon;
    switch (tier) {
      case SubscriptionTier.proPlus:
        tierColor = AppTokens.semanticWarning; // Gold/Amber
        tierIcon = Icons.rocket_launch_rounded;
        break;
      case SubscriptionTier.pro:
        tierColor = AppTokens.brandSecondary; // Blueish
        tierIcon = Icons.bolt_rounded;
        break;
      default:
        tierColor = AppTokens.neutralGrey500;
        tierIcon = Icons.person_outline;
    }
    
    return GestureDetector(
      onTap: () => context.push(AppRoutes.profile),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(2.0), // Reduced from 2.5
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: tier != SubscriptionTier.free ? tierColor : color.withValues(alpha: 0.5), 
                width: 2.5,
              ),
            ),
            child: CircleAvatar(
              radius: 18, // Reduced by 10% from 20
              backgroundColor: color.withValues(alpha: 0.2),
              backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
              child: avatarUrl == null 
                  ? Icon(Icons.person, size: 20, color: color) // Reduced from 22
                  : null,
            ),
          ),
          // Tier Badge (Bottom Right)
          if (tier != SubscriptionTier.free)
            Positioned(
              bottom: -1,
              right: -1,
              child: _buildBadge(context, tierColor, Icon(tierIcon, size: 7, color: Colors.white)),
            ),
        ],
      ),
    );
  }

  Widget _buildBadge(BuildContext context, Color color, Widget child, {double padding = 3}) {
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 4,
          ),
        ],
      ),
      child: child,
    );
  }


}
