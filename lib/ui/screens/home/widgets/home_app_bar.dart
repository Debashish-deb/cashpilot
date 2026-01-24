import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cashpilot/l10n/app_localizations.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/subscription.dart';
import '../../../../core/managers/format_manager.dart';
import '../../../../features/auth/providers/auth_provider.dart';
import '../../../../features/subscription/providers/subscription_providers.dart';
import '../../../../features/home/viewmodels/home_view_model.dart';
import '../../../widgets/notifications/notification_dialog.dart';
import '../../../widgets/sync/sync_status_indicator.dart';

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
    
    final greeting = _getGreeting(now.hour, l10n);
    final dateStr = formatManager.formatDate(now);

    return homeStateAsync.when(
      data: (state) => _buildAppBar(context, ref, state, greeting, dateStr),
      loading: () => _buildLoadingAppBar(context, greeting, dateStr),
      error: (_, __) => _buildLoadingAppBar(context, greeting, dateStr),
    );
  }

  Widget _buildAppBar(BuildContext context, WidgetRef ref, HomeViewState state, String greeting, String dateStr) {
    return SliverAppBar(
      expandedHeight: 130,
      floating: true,
      pinned: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.95),
      flexibleSpace: FlexibleSpaceBar(
        background: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
        ),
        titlePadding: const EdgeInsets.only(left: 20, right: 20, bottom: 16),
        title: SafeArea(
          bottom: false,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  dateStr.toUpperCase(),
                  style: AppTypography.labelSmall.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  greeting,
                  style: AppTypography.titleLarge.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 6),
                const SyncStatusIndicator(),
              ],
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_none_rounded),
          onPressed: () => _showNotifications(context),
        ),
        _buildProfileAvatar(context, state.tier, state.avatarUrl, profileColor),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildLoadingAppBar(BuildContext context, String greeting, String dateStr) {
    return SliverAppBar(
      expandedHeight: 130,
      floating: true,
      pinned: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.95),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(dateStr, style: const TextStyle(fontSize: 10)),
          Text(greeting, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
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
        tierColor = const Color(0xFFF59E0B);
        tierIcon = Icons.rocket_launch_rounded;
        break;
      case SubscriptionTier.pro:
        tierColor = const Color(0xFF6366F1);
        tierIcon = Icons.bolt_rounded;
        break;
      default:
        tierColor = Colors.grey;
        tierIcon = Icons.person_outline;
    }
    
    return GestureDetector(
      onTap: () => context.push(AppRoutes.profile),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: tier != SubscriptionTier.free ? tierColor : color.withValues(alpha: 0.5), 
                width: 2,
              ),
            ),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: color.withValues(alpha: 0.2),
              backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
              child: avatarUrl == null 
                  ? Icon(Icons.person, size: 18, color: color)
                  : null,
            ),
          ),
          if (tier != SubscriptionTier.free)
            Positioned(
              bottom: -2,
              right: -2,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: tierColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: tierColor.withValues(alpha: 0.5),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Icon(tierIcon, size: 10, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  String _getGreeting(int hour, AppLocalizations l10n) {
    if (hour < 12) return l10n.homeGoodMorning;
    if (hour < 17) return l10n.homeGoodAfternoon;
    return l10n.homeGoodEvening;
  }
}
