/// Reports Screen V2 - Premium Redesigned
/// 
/// Clean Architecture with modern, premium UI design
/// - Fixed padding issues
/// - Better visual hierarchy
/// - Modern card styling
/// - Improved spacing consistency

import 'dart:async';
import 'package:cashpilot/core/constants/app_routes.dart';
import 'package:cashpilot/core/managers/format_manager.dart';
import 'package:cashpilot/core/providers/app_providers.dart';
import 'package:cashpilot/core/theme/app_colors.dart';
import 'package:cashpilot/core/theme/app_typography.dart';
import 'package:cashpilot/core/theme/accent_colors.dart';
import 'package:cashpilot/features/budgets/providers/budget_providers.dart';
import 'package:cashpilot/features/reports/providers/reports_view_model.dart';
import 'package:cashpilot/features/reports/services/reports_service.dart';
import 'package:cashpilot/features/subscription/providers/subscription_providers.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cashpilot/core/helpers/localized_category_helper.dart';
import 'package:cashpilot/l10n/app_localizations.dart';
import 'package:cashpilot/ui/widgets/common/insight_card.dart';
import 'package:cashpilot/ui/widgets/reports/reports_widgets.dart';

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
    final accentColor = ref.watch(accentConfigProvider).primary;
    final stateAsync = ref.watch(reportsViewModelProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D0D0D) : const Color(0xFFF5F5F7),
      appBar: _buildAppBar(l10n),
      body: SafeArea(
        top: false, // Allow tabs to respect our custom padding from AppBar
        child: Column(
          children: [
            // Segmented Control
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
              child: AppleSegmentedControl(
                segments: [l10n.reportsOverview, l10n.reportsCategories, l10n.reportsTrends],
                icons: const [Icons.dashboard_outlined, Icons.category_outlined, Icons.timeline_outlined],
                selectedIndex: _selectedTabIndex,
                onSegmentChanged: _onTabChanged,
              ),
            ),

            // Tab Content
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: stateAsync.when(
                  data: (state) => _buildTabContent(state),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => _buildErrorState(l10n, err),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // APP BAR
  // ═══════════════════════════════════════════════════════════════════════════

  PreferredSizeWidget _buildAppBar(AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return AppBar(
      title: Text(
        l10n.reportsTitle,
        style: AppTypography.titleLarge.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
      ),
      centerTitle: true,
      backgroundColor: isDark ? const Color(0xFF0D0D0D) : const Color(0xFFF5F5F7),
      elevation: 0,
      scrolledUnderElevation: 0,
      actions: [
        RotationTransition(
          turns: Tween(begin: 0.0, end: 1.0).animate(_refreshController),
          child: IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _refreshData,
            tooltip: l10n.commonRefresh,
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ERROR STATE
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildErrorState(AppLocalizations l10n, Object err) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline, size: 40, color: Colors.orange),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.reportsFailedLoad(err.toString()),
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _refreshData,
              icon: const Icon(Icons.refresh),
              label: Text(l10n.commonRetry),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB CONTENT
  // ═══════════════════════════════════════════════════════════════════════════

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

  // ═══════════════════════════════════════════════════════════════════════════
  // OVERVIEW TAB
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildOverviewTab(ReportsState state) {
    final l10n = AppLocalizations.of(context)!;
    final currency = ref.watch(currencyProvider);
    final formatter = ref.watch(formatManagerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          
          // Period Selector
          _buildSectionHeader(l10n.reportsPeriodTitle ?? 'Reporting Period'),
          const SizedBox(height: 8),
          ReportingPeriodCard(
            dateRange: state.dateRange,
            onTap: () => _showDateRangePicker(context, state.dateRange),
          ),
          
          const SizedBox(height: 24),
          
          // Key Metrics Section
          _buildSectionHeader(l10n.reportsMetricsTitle ?? 'Key Metrics'),
          const SizedBox(height: 12),
          
          // Metrics Grid - 2x2 Layout
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  title: 'Burn Rate',
                  value: '${state.burnRateDelta > 0 ? '+' : ''}${state.burnRateDelta.toStringAsFixed(1)}%',
                  subtitle: state.burnRateDelta > 0 ? 'Above norm' : 'Below norm',
                  icon: Icons.trending_up_rounded,
                  gradient: AppColors.magmaGradient,
                  valueColor: state.burnRateDelta > 0 ? Colors.red : Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  title: 'Volatility',
                  value: (state.volatilityScore * 100).toStringAsFixed(0),
                  subtitle: state.volatilityScore > 0.5 ? 'High' : 'Stable',
                  icon: Icons.waves_rounded,
                  gradient: AppColors.tealGradient,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  title: 'Stress',
                  value: '${state.atRiskBudgets} Risk',
                  subtitle: state.atRiskBudgets > 0 ? 'Action needed' : 'All safe',
                  icon: Icons.warning_amber_rounded,
                  gradient: state.atRiskBudgets > 0 ? AppColors.magmaGradient : AppColors.emeraldGradient,
                  isAlert: state.atRiskBudgets > 0,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  title: 'Behavior',
                  value: '${(state.impulseMetrics.density * 100).toStringAsFixed(0)}%',
                  subtitle: 'Impulse density',
                  icon: Icons.psychology_outlined,
                  gradient: AppColors.indigoGradient,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Average Transaction Card
          _buildSectionHeader('Average Transaction'),
          const SizedBox(height: 12),
          _buildLargeMetricCard(
            title: 'Avg Transaction Size',
            value: formatter.formatCurrency(
              state.impulseMetrics.avgSize / 100, 
              currencyCode: currency, 
              decimalDigits: 0,
            ),
            subtitle: 'Your typical spending amount',
            icon: Icons.receipt_long_outlined,
            color: AppColors.info,
          ),
          
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SECTION HEADER
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildSectionHeader(String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: isDark ? Colors.white.withOpacity(0.5) : Colors.black.withOpacity(0.5),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // METRIC CARD - Compact
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Gradient gradient,
    Color? valueColor,
    bool isAlert = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isAlert ? Colors.red : Colors.black).withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(height: 12),
          
          // Value
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          
          // Title
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 2),
          
          // Subtitle
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LARGE METRIC CARD
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildLargeMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CATEGORIES TAB
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildCategoriesTab(ReportsState state) {
    final l10n = AppLocalizations.of(context)!;
    final currency = ref.watch(currencyProvider);
    final formatManager = ref.watch(formatManagerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final breakdown = state.expenseBreakdown;
    
    if (breakdown.isEmpty) {
      return _buildEmptyState(
        icon: Icons.pie_chart_outline,
        title: l10n.reportsNoExpensesAnalyze,
        subtitle: l10n.reportsAddExpensesCategory,
      );
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          
          // Distribution Chart
          _buildSectionHeader(l10n.reportsDistributionTitle ?? 'Expense Distribution'),
          const SizedBox(height: 12),
          
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: _buildPieChart(context, breakdown),
          ),
          
          const SizedBox(height: 24),
          
          // Category Breakdown
          _buildSectionHeader(l10n.reportsBreakdownTitle ?? 'Category Breakdown'),
          const SizedBox(height: 12),
          
          ...breakdown.entries.map((entry) {
            final group = entry.value;
            final rawName = group.name;
            final localizedName = rawName == 'UNCATEGORIZED' 
                ? l10n.catUncategorized 
                : LocalizedCategoryHelper.getLocalizedName(context, rawName);
            
            final hasSubcategories = group.subcategoryTotals.isNotEmpty;
            
            if (!hasSubcategories) {
              return _buildCategoryListItem(
                name: localizedName,
                amount: group.totalCents.toDouble(),
                currency: currency,
                formatManager: formatManager,
                hasChildren: false,
              );
            }

            return _buildExpandableCategoryItem(
              group: group,
              name: localizedName,
              currency: currency,
              formatManager: formatManager,
            );
          }).toList(),
          
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PIE CHART
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildPieChart(BuildContext context, Map<String, HierarchicalCategoryTotal> breakdown) {
    final currency = ref.watch(currencyProvider);
    final formatManager = ref.watch(formatManagerProvider);
    final total = breakdown.values.fold<double>(0, (sum, item) => sum + item.totalCents);
    
    if (total == 0) return const SizedBox.shrink();

    final List<PieChartSectionData> sections = [];
    final entries = breakdown.entries.toList();
    
    double otherTotal = 0;
    int sectionCount = 0;
    const maxSections = 5;

    for (int i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final val = entry.value.totalCents.toDouble();
      final percentage = (val / total) * 100;

      if (sectionCount < maxSections && percentage >= 5) {
        sections.add(
          PieChartSectionData(
            color: _getCategoryColor(sectionCount),
            value: val,
            title: '${percentage.toStringAsFixed(0)}%',
            radius: 55,
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        );
        sectionCount++;
      } else {
        otherTotal += val;
      }
    }

    if (otherTotal > 0) {
      final otherPercentage = (otherTotal / total) * 100;
      sections.add(
        PieChartSectionData(
          color: Colors.grey.shade500,
          value: otherTotal,
          title: '${otherPercentage.toStringAsFixed(0)}%',
          radius: 55,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sectionsSpace: 3,
              centerSpaceRadius: 50,
              sections: sections,
            ),
          ),
        ),
        const SizedBox(height: 20),
        
        // Total Display
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Text(
                'Total Expenses',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                formatManager.formatCurrency(total / 100, currencyCode: currency, decimalDigits: 0),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getCategoryColor(int index) {
    const colors = [
      Color(0xFF26A69A), // Teal
      Color(0xFF66BB6A), // Green
      Color(0xFFFFA726), // Orange
      Color(0xFFEF5350), // Red
      Color(0xFFAB47BC), // Purple
      Color(0xFF5C6BC0), // Indigo
    ];
    return colors[index % colors.length];
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CATEGORY LIST ITEM
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildCategoryListItem({
    required String name,
    required double amount,
    required String currency,
    required dynamic formatManager,
    required bool hasChildren,
    int depth = 0,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.only(
          left: 16 + (depth * 16),
          right: 16,
          top: 8,
          bottom: 8,
        ),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primaryGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            hasChildren ? Icons.folder_outlined : Icons.label_outlined,
            color: AppColors.primaryGreen,
            size: 20,
          ),
        ),
        title: Text(
          name,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        trailing: Text(
          formatManager.formatCurrency(amount / 100, currencyCode: currency),
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // EXPANDABLE CATEGORY ITEM
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildExpandableCategoryItem({
    required HierarchicalCategoryTotal group,
    required String name,
    required String currency,
    required dynamic formatManager,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.folder_outlined,
              color: AppColors.primaryGreen,
              size: 20,
            ),
          ),
          title: Text(
            name,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          trailing: Text(
            formatManager.formatCurrency(group.totalCents / 100, currencyCode: currency),
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          children: group.subcategoryTotals.entries.map((sub) {
            return Container(
              padding: const EdgeInsets.only(left: 72, right: 16, top: 8, bottom: 8),
              decoration: BoxDecoration(
                color: isDark ? Colors.black.withOpacity(0.2) : Colors.grey.shade50,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        sub.key,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    formatManager.formatCurrency(sub.value / 100, currencyCode: currency),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TRENDS TAB
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildTrendsTab(ReportsState state) {
    final l10n = AppLocalizations.of(context)!;
    final currency = ref.watch(currencyProvider);
    final formatManager = ref.watch(formatManagerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (state.trendData.isEmpty) {
      return _buildEmptyState(
        icon: Icons.trending_up,
        title: l10n.reportsNoExpensesAnalyze,
        subtitle: l10n.reportsAddExpensesTrends,
      );
    }

    final maxY = state.trendData.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final sortedDays = state.trendData;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          
          // Chart Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.reportsSpendingTrend,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Daily spending over time',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 24),
                
                SizedBox(
                  height: 220,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: maxY > 0 ? maxY / 4 : 1,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                            strokeWidth: 1,
                          );
                        },
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                formatManager.formatCurrency(value / 100, currencyCode: currency, decimalDigits: 0),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isDark ? Colors.white38 : Colors.black38,
                                ),
                              );
                            },
                          ),
                        ),
                        bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      minX: 0,
                      maxX: (sortedDays.length - 1).toDouble(),
                      minY: 0,
                      maxY: maxY * 1.1,
                      lineBarsData: [
                        LineChartBarData(
                          spots: sortedDays.asMap().entries.map((e) => 
                            FlSpot(e.key.toDouble(), e.value.value)
                          ).toList(),
                          isCurved: true,
                          curveSmoothness: 0.35,
                          color: AppColors.primaryGreen,
                          barWidth: 3,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, bar, index) {
                              return FlDotCirclePainter(
                                radius: 4,
                                color: AppColors.primaryGreen,
                                strokeWidth: 2,
                                strokeColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                              );
                            },
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primaryGreen.withOpacity(0.3),
                                AppColors.primaryGreen.withOpacity(0.0),
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
          
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // EMPTY STATE
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 48,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LOCKED CONTENT
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildLockedContent(String title, String description) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.gold.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_outline, size: 32, color: AppColors.gold),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => context.push(AppRoutes.paywall),
                  icon: const Icon(Icons.star_rounded, size: 18),
                  label: Text(l10n.commonUpgradeToPro),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DATE PICKER
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _showDateRangePicker(BuildContext context, DateTimeRange currentRange) async {
    HapticFeedback.lightImpact();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: currentRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.transparent,
              elevation: 0,
            ),
          ),
          child: child ?? const SizedBox(),
        );
      },
    );
    if (picked != null) {
      ref.read(reportsViewModelProvider.notifier).setDateRange(picked);
    }
  }
}
