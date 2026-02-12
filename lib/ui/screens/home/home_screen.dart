import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cashpilot/l10n/app_localizations.dart';



// Modular Widgets
import 'widgets/home_header.dart';
import 'widgets/home_balance_section.dart';
import 'widgets/home_highlights_grid.dart';
import 'widgets/home_spending_categories.dart';
import 'widgets/home_assets_overview.dart';
import 'widgets/home_recent_activity.dart';
import 'widgets/home_section_header.dart';

/// Redesigned Home Screen Orchestrator
/// Premium Dark Mode Aesthetic with modular components.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async {
            // Trigger refresh logic if needed
          },
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // 1. Header (Month Selector, Notifications, Profile)
              const SliverToBoxAdapter(
                child: HomeHeader(),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 8)),

              // 2. Balance Section
              const SliverToBoxAdapter(
                child: HomeBalanceSection(),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 12)),

              // 3. Highlights Grid (Net Worth & Spendings Sparkline)
              const SliverToBoxAdapter(
                child: HomeHighlightsGrid(),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 12)),

              const SliverToBoxAdapter(child: SizedBox(height: 12)),

              // 5. Assets Overview (Donut Chart)
              const SliverToBoxAdapter(
                child: HomeAssetsOverview(),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 12)),

              // 6. Spending Categories
              const SliverToBoxAdapter(
                child: HomeSpendingCategories(),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 12)),

              // 7. Recent Activity Header
              SliverToBoxAdapter(
                child: HomeSectionHeader(
                  title: l10n.reportsRecentActivity ?? 'Recent Activity',
                  actionLabel: 'View All',
                  onActionPressed: () {
                    // TODO: Navigate to transactions
                  },
                ),
              ),

              // 8. Recent Activity List
              const SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverToBoxAdapter(
                  child: HomeRecentActivity(),
                ),
              ),

              // Bottom Spacer for Navigation Bar
              const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
            ],
          ),
        ),
      ),
    );
  }
}
