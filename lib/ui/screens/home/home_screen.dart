import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cashpilot/l10n/app_localizations.dart';

import '../../../core/theme/app_typography.dart';
import '../../../core/providers/user_mode_provider.dart';
import '../../../core/theme/accent_colors.dart';
import '../../widgets/cards/net_worth_card.dart';
import '../../widgets/cards/upcoming_bills_card.dart';
import '../../widgets/stories/spending_stories_list.dart';
import '../../widgets/cards/welcome_insight_card.dart';
import '../../widgets/common/responsive_wrapper.dart';

// Modular Widgets
import 'widgets/home_app_bar.dart';
import 'widgets/home_quick_actions.dart';
import 'widgets/home_spending_summary.dart';
import 'widgets/home_active_budgets.dart';
import 'widgets/home_recent_activity.dart';

/// Clean HomeScreen Orchestrator
/// Refactored to address "God Widget" issues.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accentConfig = ref.watch(accentConfigProvider);
    final accentColor = accentConfig.primary;
    final userMode = ref.watch(userModeProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          _buildAmbientBackground(context, accentColor),
          
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              HomeSliverAppBar(profileColor: accentColor),
              
              SliverToBoxAdapter(
                child: _buildMainContent(context, userMode, accentColor, l10n),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAmbientBackground(BuildContext context, Color accentColor) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              accentColor.withValues(alpha: 0.15),
              Theme.of(context).scaffoldBackgroundColor,
              Theme.of(context).scaffoldBackgroundColor,
            ],
            stops: const [0.0, 0.4, 1.0],
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent(BuildContext context, UserMode userMode, Color accentColor, AppLocalizations l10n) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenSize = ResponsiveScreenSize(width: constraints.maxWidth, height: constraints.maxHeight);
        final horizontalPadding = screenSize.isSmallScreen ? 12.0 : 16.0;
        
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 0, vertical: screenSize.isSmallScreen ? 8 : 10),
          child: Column(
            children: [
               // MODE SPECIFIC UI: Stories vs Welcome
              if (userMode == UserMode.beginner) ...[
                 Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: screenSize.isSmallScreen ? 8 : 10),
                  child: WelcomeInsightCard(), 
                ),
              ] else ...[
                const SpendingStoriesList(),
              ],

              const SizedBox(height: 10),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    const NetWorthCard(),
                    const SizedBox(height: 12),
                    
                    if (userMode == UserMode.beginner) ...[
                      Text(
                        l10n.homeNetWorthDesc,
                        style: AppTypography.bodySmall.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                    ],

                    HomeSpendingSummary(profileColor: accentColor),
                    const SizedBox(height: 16),
                    
                    HomeQuickActions(accentColor: accentColor),
                    const SizedBox(height: 16),
                    
                    if (userMode == UserMode.expert) ...[
                      const UpcomingBillsCard(), 
                      const SizedBox(height: 16),
                      const HomeActiveBudgets(),
                      const SizedBox(height: 16),
                    ],

                    const HomeRecentActivity(),
                    const SizedBox(height: 24),
                    _buildTrustFooter(context, l10n),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTrustFooter(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_outline_rounded, size: 14, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)),
          const SizedBox(width: 6),
          Text(
            l10n.homeSecurityNote,
            style: AppTypography.labelSmall.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
