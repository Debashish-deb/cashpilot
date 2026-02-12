import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cashpilot/l10n/app_localizations.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/managers/format_manager.dart';
import '../../../../features/home/viewmodels/home_view_model.dart';
import '../../../../core/constants/subscription.dart';

class HomeHeader extends ConsumerWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final l10n = AppLocalizations.of(context)!;
    final formatManager = ref.watch(formatManagerProvider);
    final homeStateAsync = ref.watch(homeViewModelProvider);
    final state = homeStateAsync.valueOrNull;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final monthStr = formatManager.formatDate(now, pattern: 'MMM yyyy');

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Month Selector
          InkWell(
            onTap: () {
              // TODO: Implement Month Selector
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  Text(
                    monthStr,
                    style: AppTypography.titleLarge.copyWith(
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                      letterSpacing: -0.5,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.keyboard_arrow_down_rounded, 
                    size: 22,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ],
              ),
            ),
          ),

          // Right Actions
          Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.notifications_none_rounded, 
                  size: 26,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
                onPressed: () {
                  // TODO: Show notifications
                },
              ),
              const SizedBox(width: 4),
              _buildProfileAvatar(context, state?.tier ?? SubscriptionTier.free, state?.avatarUrl),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileAvatar(BuildContext context, SubscriptionTier tier, String? avatarUrl) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: () => context.push(AppRoutes.profile),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isDark ? Colors.white10 : Colors.black12,
            width: 1,
          ),
        ),
        child: CircleAvatar(
          radius: 22,
          backgroundColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.1),
          backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
          child: avatarUrl == null 
              ? Icon(Icons.person, size: 24, color: isDark ? Colors.white54 : Colors.grey)
              : null,
        ),
      ),
    );
  }
}
