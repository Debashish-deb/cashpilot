/// Reports Screen V2 - Clean Architecture Implementation
/// 
/// Pilot implementation of the new architecture:
/// - Repository: Data fetching
/// - Service: Data processing
/// - ViewModel: State management
/// - Screen: Dumb UI
library;

import 'dart:async';
import 'dart:io';
import 'package:cashpilot/core/constants/app_routes.dart' show AppRoutes;
import 'package:cashpilot/core/constants/app_routes.dart';
import 'package:cashpilot/core/managers/format_manager.dart';
import 'package:cashpilot/core/providers/app_providers.dart';
import 'package:cashpilot/core/theme/app_colors.dart';
import 'package:cashpilot/core/theme/app_typography.dart';
import 'package:cashpilot/features/budgets/providers/budget_providers.dart';
import 'package:cashpilot/features/reports/providers/reports_view_model.dart';
import 'package:cashpilot/features/subscription/providers/subscription_providers.dart';
import 'package:cashpilot/l10n/app_localizations.dart';
import 'package:cashpilot/ui/widgets/reports/reports_widgets.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';


class ReportsScreenV2 extends ConsumerStatefulWidget {
  const ReportsScreenV2({super.key});

  @override
  ConsumerState<ReportsScreenV2> createState() => _ReportsScreenV2State();
}

class _ReportsScreenV2State extends ConsumerState<ReportsScreenV2>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  
  late AnimationController _refreshController;
  int _selectedTabIndex = 0;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshController.dispose();
    super.dispose();
  }

  Future<void> _refreshData() async {
    _refreshController.repeat();
    HapticFeedback.lightImpact();
    
    await ref.read(reportsViewModelProvider.notifier).refresh();
    
    _refreshController.stop();
    _refreshController.reset();
  }

  void _onTabChanged(int index) {
    HapticFeedback.selectionClick();
    setState(() => _selectedTabIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final stateAsync = ref.watch(reportsViewModelProvider);

    return Scaffold(
      backgroundColor: isDark
          ? Theme.of(context).colorScheme.surfaceContainerLow
          : Theme.of(context).colorScheme.surface,
      appBar: _buildAppBar(l10n),
      body: Column(
        children: [
          const SizedBox(height: 8),
          AppleSegmentedControl(
            segments: [l10n.reportsOverview, l10n.reportsCategories, l10n.reportsTrends],
            icons: const [Icons.dashboard_outlined, Icons.category_outlined, Icons.timeline_outlined],
            selectedIndex: _selectedTabIndex,
            onSegmentChanged: _onTabChanged,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: stateAsync.when(
                data: (state) => _buildTabContent(state),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.orange),
                      const SizedBox(height: 16),
                      Text('Failed to load reports: $err'),
                      TextButton(onPressed: _refreshData, child: const Text('Retry'))
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(AppLocalizations l10n) {
    return AppBar(
      title: Text(
        l10n.reportsTitle,
        style: Platform.isIOS
            ? AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.w600)
            : AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w500),
      ),
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent,
      actions: [
        RotationTransition(
          turns: Tween(begin: 0.0, end: 1.0).animate(_refreshController),
          child: IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: _refreshData,
            tooltip: l10n.commonRefresh,
          ),
        ),
      ],
    );
  }

  Widget _buildTabContent(ReportsState state) {
    final l10n = AppLocalizations.of(context)!;
    final isPaid = ref.watch(isPaidProvider);

    switch (_selectedTabIndex) {
      case 0:
        return _buildOverviewTab(state);
      case 1:
        return !isPaid
            ? _buildLockedContent(l10n.reportsLockedCategoryTitle, l10n.reportsLockedCategoryDesc)
            : _buildCategoriesTab(state);
      case 2:
        return !isPaid
            ? _buildLockedContent(l10n.reportsLockedTrendsTitle, l10n.reportsLockedTrendsDesc)
            : _buildTrendsTab(state);
      default:
        return _buildOverviewTab(state);
    }
  }

  // ===========================================================================
  // TABS
  // ===========================================================================

  Widget _buildOverviewTab(ReportsState state) {
    final l10n = AppLocalizations.of(context)!;
    final currency = ref.watch(currencyProvider);
    final activeBudgets = ref.watch(activeBudgetsProvider);

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // Period Selector
          ReportingPeriodCard(
            dateRange: state.dateRange,
            onTap: () => _showDateRangePicker(context, state.dateRange),
          ),
          
          const SizedBox(height: 20),
          
          // Metrics Grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2, // 2x2 grid
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.05,
            children: [
              AnimatedStatCard(
                title: l10n.reportsThisMonth,
                value: state.totalSpent.toInt(),
                currency: currency,
                icon: Icons.calendar_month_outlined,
                color: AppColors.primaryGreen,
                onTap: () => _onTabChanged(1),
              ),
              AnimatedStatCard(
                title: l10n.reportsDailyAvg,
                value: state.dailyAverage.toInt(),
                currency: currency,
                icon: Icons.trending_up_outlined,
                color: const Color(0xFFFF9800),
              ),
              AnimatedStatCard(
                title: l10n.reportsActiveBudgets,
                value: (activeBudgets.valueOrNull?.length ?? 0) * 100,
                currency: '',
                icon: Icons.account_balance_wallet_outlined,
                color: const Color(0xFF9C27B0),
                onTap: () => context.push(AppRoutes.budgets),
              ),
              // Optional: Transaction Count
              AnimatedStatCard(
                title: 'Transactions',
                value: state.expenses.length * 100, // *100 for display generic
                currency: '',
                icon: Icons.receipt_long_outlined,
                color: Colors.blue,
              ),
            ],
          ),
          
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildCategoriesTab(ReportsState state) {
    final l10n = AppLocalizations.of(context)!;
    final currency = ref.watch(currencyProvider);
    final formatManager = ref.watch(formatManagerProvider);
    
    if (state.categoryBreakdown.isEmpty) {
      return _buildEmptyState(
        icon: Icons.pie_chart_outline,
        title: l10n.reportsNoExpensesAnalyze,
        subtitle: l10n.reportsAddExpensesCategory,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.categoryBreakdown.length,
      itemBuilder: (context, index) {
        final entry = state.categoryBreakdown.entries.elementAt(index);
        
        return ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.category_outlined, color: AppColors.primaryGreen, size: 20),
          ),
          title: Text(entry.key), // Clean categorized name from Service
          trailing: Text(
            formatManager.formatCurrency(entry.value / 100, currencyCode: currency),
            style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
          ),
        );
      },
    );
  }

  Widget _buildTrendsTab(ReportsState state) {
    final l10n = AppLocalizations.of(context)!;
    final currency = ref.watch(currencyProvider);
    final formatManager = ref.watch(formatManagerProvider);
    
    if (state.trendData.isEmpty) {
      return _buildEmptyState(
        icon: Icons.trending_up,
        title: l10n.reportsNoExpensesAnalyze,
        subtitle: l10n.reportsAddExpensesTrends,
      );
    }

    final maxY = state.trendData.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final sortedDays = state.trendData; // Already sorted by Service

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.surface,
                Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Spending Trend',
                style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 250,
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(show: false),
                    titlesData: FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    minX: 0,
                    maxX: (sortedDays.length - 1).toDouble(),
                    minY: 0,
                    maxY: maxY * 1.2,
                    lineBarsData: [
                      LineChartBarData(
                        spots: sortedDays.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.value)).toList(),
                        isCurved: true,
                        color: AppColors.primaryGreen,
                        barWidth: 3,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primaryGreen.withValues(alpha: 0.2),
                              AppColors.primaryGreen.withValues(alpha: 0.0),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // HELPERS
  // ===========================================================================

  Future<void> _showDateRangePicker(BuildContext context, DateTimeRange currentRange) async {
    HapticFeedback.lightImpact();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: currentRange,
    );
    if (picked != null) {
      ref.read(reportsViewModelProvider.notifier).setDateRange(picked);
    }
  }

  Widget _buildEmptyState({required IconData icon, required String title, required String subtitle}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          Text(title, style: AppTypography.titleMedium),
          const SizedBox(height: 8),
          Text(subtitle, style: AppTypography.bodySmall, textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildLockedContent(String title, String description) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const Icon(Icons.lock_outline, size: 48, color: AppColors.gold),
            const SizedBox(height: 24),
            Text(title, style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(description, textAlign: TextAlign.center, style: AppTypography.bodyMedium),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.push(AppRoutes.paywall),
              icon: const Icon(Icons.star, size: 18),
              label: Text(l10n.commonUpgradeToPro),
              style: FilledButton.styleFrom(backgroundColor: AppColors.gold),
            ),
          ],
        ),
      ),
    );
  }
}
