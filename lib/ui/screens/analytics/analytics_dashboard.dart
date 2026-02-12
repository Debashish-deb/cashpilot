/// Enhanced Analytics Dashboard
/// Rich, informative analytics screen with actionable insights
library;

import 'package:flutter/material.dart';
import 'package:cashpilot/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../features/analytics/providers/analytics_providers.dart' hide healthScoreProvider;
import '../../../features/analytics/providers/computed_analytics_providers.dart' as computed;
import '../../../features/analytics/models/category_spending.dart';
import '../../../features/analytics/providers/honest_analytics_providers.dart' as honest;
import '../../../core/constants/subscription.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../features/subscription/providers/subscription_providers.dart';
import '../../../features/analytics/models/insight_card.dart'; 
import '../../widgets/analytics/insight_card_widget.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/app_providers.dart';

class AnalyticsDashboard extends ConsumerStatefulWidget {
  final String budgetId;

  const AnalyticsDashboard({
    super.key,
    required this.budgetId,
  });

  @override
  ConsumerState<AnalyticsDashboard> createState() => _AnalyticsDashboardState();
}

class _AnalyticsDashboardState extends ConsumerState<AnalyticsDashboard> {
  IconData _getCategoryIcon(InsightCategory category) {
    switch (category) {
      case InsightCategory.budget:
        return Icons.account_balance_wallet;
      case InsightCategory.subscription:
        return Icons.subscriptions;
      case InsightCategory.behavior:
        return Icons.psychology;
      case InsightCategory.location:
        return Icons.place;
      case InsightCategory.trend:
        return Icons.trending_up;
    }
  }

  Color _getSeverityColor(InsightSeverity severity) {
    switch (severity) {
      case InsightSeverity.info:
        return Colors.blue;
      case InsightSeverity.warning:
        return Colors.orange;
      case InsightSeverity.critical:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final insightCards = ref.watch(currentInsightCardsProvider);
    final tier = ref.watch(currentTierProvider).value ?? SubscriptionTier.free;
    final currency = ref.watch(currencyProvider);
    final l10n = AppLocalizations.of(context)!;

    // Feature gate check
    if (tier == SubscriptionTier.free) {
      return _buildLockedView(context);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.analyticsTitle),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showHelpDialog(context),
            tooltip: 'What do these metrics mean?',
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            // Invalidate all analytics providers to force refresh
            ref.invalidate(computed.healthScoreProvider);
            ref.invalidate(computed.budgetStatisticsProvider);
            ref.invalidate(computed.categoryBreakdownProvider);
            
            // Wait for refresh to complete
            await Future.wait([
              ref.refresh(computed.healthScoreProvider(widget.budgetId).future),
              ref.refresh(computed.budgetStatisticsProvider(widget.budgetId).future),
              ref.refresh(computed.categoryBreakdownProvider(widget.budgetId).future),
            ]);
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Budget Health Score - Real data from provider
              Consumer(
                builder: (context, ref, child) {
                  final healthData = ref.watch(computed.healthScoreProvider(widget.budgetId));
                  return healthData.when(
                    data: (data) => _EnhancedHealthScoreCard(
                      score: data.score,
                      level: data.level,
                      trend: data.trend,
                      componentScores: data.componentScores,
                    ),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => _ErrorCard('Failed to load health score: $e'),
                  );
                },
              ),
    
              const SizedBox(height: 20),
    
              // Quick Stats Row - Real data from provider
              Consumer(
                builder: (context, ref, child) {
                  final stats = ref.watch(computed.budgetStatisticsProvider(widget.budgetId));
                  return stats.when(
                    data: (data) => _QuickStatsRow(
                      totalSpent: data.totalSpent,
                      totalBudget: data.totalBudget,
                      daysRemaining: data.daysRemaining,
                      dailyAverage: data.dailyAverage,
                      currency: currency,
                      l10n: l10n,
                    ),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => _ErrorCard('Failed to load statistics: $e'),
                  );
                },
              ),
    
              const SizedBox(height: 24),
    
              // Insights Section
              if (insightCards.isNotEmpty) ...[
                _SectionHeader(
                  title: l10n.analyticsSectionInsights,
                  subtitle: '${insightCards.length} ${l10n.analyticsInsights}',
                  icon: Icons.lightbulb_outline,
                ),
                const SizedBox(height: 12),
                ...insightCards.map((insight) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InsightCardWidget(
                    title: insight.title,
                    message: insight.message,
                    icon: _getCategoryIcon(insight.category),
                    color: _getSeverityColor(insight.severity),
                    actionLabel: insight.actionLabel,
                    onDismiss: () {
                      final current = ref.read(currentInsightCardsProvider);
                      ref.read(currentInsightCardsProvider.notifier).state =
                          current.where((i) => i.id != insight.id).toList();
                    },
                    onAction: () {
                      if (insight.actionRoute != null) {
                        context.push(insight.actionRoute!);
                      }
                    },
                  ),
                )),
                const SizedBox(height: 24),
              ],
    
              // Spending Breakdown - Real data from provider
              Consumer(
                builder: (context, ref, child) {
                  final breakdown = ref.watch(computed.categoryBreakdownProvider(widget.budgetId));
                  return breakdown.when(
                    data: (categories) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionHeader(
                          title: l10n.analyticsSectionBreakdown,
                          subtitle: l10n.analyticsSectionBreakdownSub,
                          icon: Icons.pie_chart_outline,
                        ),
                        const SizedBox(height: 12),
                        if (categories.isEmpty)
                          _EmptyState('No expenses yet')
                        else
                          _CategoryBreakdownCardReal(
                            categories: categories,
                            currency: currency,
                          ),
                      ],
                    ),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => _ErrorCard('Failed to load categories: $e'),
                  );
                },
              ),
    
              const SizedBox(height: 24),
    
              // Burn Rate Analysis - Real Data
              Consumer(
                builder: (context, ref, child) {
                   final statsAsync = ref.watch(computed.budgetStatisticsProvider(widget.budgetId));
                   return statsAsync.when(
                     data: (stats) => _BurnRateCard(
                       dailyAverage: stats.dailyAverage,
                       daysRemaining: stats.daysRemaining,
                       projected: stats.projectedTotal,
                       budget: stats.totalBudget,
                       willStayUnder: stats.onTrack,
                       currency: currency,
                       l10n: l10n,
                     ),
                     loading: () => const Center(child: CircularProgressIndicator()),
                     error: (_, __) => const SizedBox.shrink(),
                   );
                },
              ),
    
              const SizedBox(height: 24),
    
              // Time-based patterns - Real Data
              Consumer(
                builder: (context, ref, child) {
                  final snapshotAsync = ref.watch(honest.analyticsSnapshotProvider(widget.budgetId));
                  return snapshotAsync.when(
                    data: (snapshot) {
                      // Convert Map<int, double> to Map<String, double>
                      final weekdayMap = <String, double>{};
                      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                      snapshot.weekdayBaseline.forEach((dayIndex, amount) {
                         if (dayIndex >= 1 && dayIndex <= 7) {
                           weekdayMap[days[dayIndex - 1]] = amount;
                         }
                      });
                      
                      if (weekdayMap.isEmpty) return const SizedBox.shrink();
    
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SectionHeader(
                            title: l10n.analyticsSectionPatterns,
                            subtitle: l10n.analyticsSectionPatternsSub,
                            icon: Icons.calendar_today_outlined,
                          ),
                          const SizedBox(height: 12),
                          _SpendingPatternsCard(
                            dayOfWeekData: weekdayMap,
                            currency: currency,
                            l10n: l10n,
                          ),
                        ],
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (_, __) => const SizedBox.shrink(),
                  );
                },
              ),
    
              const SizedBox(height: 24),
    
              // Comparison - Real Data (using HealthScore trend for now as proxy)
              Consumer(
                builder: (context, ref, child) {
                   final healthAsync = ref.watch(computed.healthScoreProvider(widget.budgetId));
                   return healthAsync.when(
                     data: (health) => _ComparisonCard(
                       thisMonth: 0, // TODO: Fetch from snapshot if needed
                       lastMonth: 0, 
                       changePercent: health.trend.toDouble(),
                       currency: currency,
                     ),
                     loading: () => const SizedBox.shrink(),
                     error: (_, __) => const SizedBox.shrink(),
                   );
                },
              ),
              
              // Bottom spacer for safe area
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLockedView(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.analyticsTitle),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.gold.withValues(alpha: 0.2),
                      AppColors.gold.withValues(alpha: 0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.insights,
                  size: 64,
                  color: AppColors.gold,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                AppLocalizations.of(context)!.analyticsUnlockTitle,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _buildFeatureRow(Icons.speed, AppLocalizations.of(context)!.analyticsHealthScore),
                    _buildFeatureRow(Icons.trending_up, AppLocalizations.of(context)!.analyticsVelocity),
                    _buildFeatureRow(Icons.pie_chart, AppLocalizations.of(context)!.analyticsBreakdown),
                    _buildFeatureRow(Icons.lightbulb, AppLocalizations.of(context)!.analyticsInsights),
                    _buildFeatureRow(Icons.compare_arrows, AppLocalizations.of(context)!.analyticsComparisons),
                    _buildFeatureRow(Icons.subscriptions, AppLocalizations.of(context)!.analyticsSubscriptions),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () => context.push(AppRoutes.paywall),
                icon: const Icon(Icons.star),
                label: Text(AppLocalizations.of(context)!.analyticsUpgrade),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                AppLocalizations.of(context)!.analyticsPricing,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.gold),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.analyticsHelpTitle),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: const [
              _HelpItem(
                title: 'Health Score',
                description: 'A 0–100 score reflecting overall budget management. Higher is better.',
              ),
              _HelpItem(
                title: 'Burn Rate',
                description: 'How quickly you’re spending. Used to project if you’ll stay under budget.',
              ),
              _HelpItem(
                title: 'Category Pressure',
                description: 'Shows which categories are close to their limits.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.commonGotIt),
          ),
        ],
      ),
    );
  }
}

class _HelpItem extends StatelessWidget {
  final String title;
  final String description;

  const _HelpItem({
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(description),
        ],
      ),
    );
  }
}

class _EnhancedHealthScoreCard extends StatelessWidget {
  final int score;
  final String level;
  final int trend;
  final Map<String, double> componentScores;

  const _EnhancedHealthScoreCard({
    required this.score,
    required this.level,
    required this.trend,
    required this.componentScores,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Budget Health',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            trend >= 0 ? Icons.trending_up : Icons.trending_down,
                            size: 16,
                            color: trend >= 0 ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${trend >= 0 ? '+' : ''}$trend from last month',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Score Circle
                SizedBox(
                  width: 100,
                  height: 100,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: 1.0,
                        strokeWidth: 10,
                        valueColor: AlwaysStoppedAnimation(
                          theme.colorScheme.surfaceContainerHighest,
                        ),
                      ),
                      CircularProgressIndicator(
                        value: score / 100,
                        strokeWidth: 10,
                        valueColor: AlwaysStoppedAnimation(
                          _getScoreColor(score),
                        ),
                      ),
                    Positioned.fill(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$score',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            level.toUpperCase(),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: _getScoreColor(score),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 16),
            // Component breakdown
            Text(
              'Score Breakdown',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...componentScores.entries.map((entry) {
              final label = _formatLabel(entry.key);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _ScoreComponent(
                  label: label,
                  value: entry.value,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.amber;
    if (score >= 40) return Colors.orange;
    return Colors.red;
  }

  String _formatLabel(String key) {
    switch (key) {
      case 'usage':
        return 'Budget Usage';
      case 'consistency':
        return 'Consistency';
      case 'balance':
        return 'Category Balance';
      case 'recurring':
        return 'Recurring Ratio';
      default:
        return key;
    }
  }
}

class _ScoreComponent extends StatelessWidget {
  final String label;
  final double value;

  const _ScoreComponent({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: theme.textTheme.bodyMedium,
          ),
        ),
        Expanded(
          flex: 3,
          child: LinearProgressIndicator(
            value: value / 100,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 40,
          child: Text(
            '${value.toInt()}%',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

class _QuickStatsRow extends StatelessWidget {
  final double totalSpent;
  final double totalBudget;
  final int daysRemaining;
  final double dailyAverage;
  final String currency;
  final AppLocalizations l10n;

  const _QuickStatsRow({
    required this.totalSpent,
    required this.totalBudget,
    required this.daysRemaining,
    required this.dailyAverage,
    required this.currency,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final percentUsed =
        totalBudget == 0 ? 0 : (totalSpent / totalBudget * 100).round();

    return Row(
      children: [
        Expanded(
          child: _QuickStatCard(
            label: 'Spent',
            value: NumberFormat.simpleCurrency(name: currency, locale: l10n.localeName, decimalDigits: 0).format(totalSpent),
            subtitle: '$percentUsed% of budget',
            icon: Icons.payment,
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickStatCard(
            label: 'Days Left',
            value: '$daysRemaining',
            subtitle: '${NumberFormat.simpleCurrency(name: currency, locale: l10n.localeName, decimalDigits: 2).format(dailyAverage)}/day avg',
            icon: Icons.calendar_today,
            color: Colors.orange,
          ),
        ),
      ],
    );
  }
}

class _QuickStatCard extends StatelessWidget {
  final String label;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _QuickStatCard({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Old CategorySpending class removed - using model from lib/features/analytics/models/category_spending.dart
// Old _CategoryBreakdownCard and _CategoryItem removed - using _CategoryBreakdownCardReal instead

class _BurnRateCard extends StatelessWidget {
  final double dailyAverage;
  final int daysRemaining;
  final double projected;
  final double budget;
  final bool willStayUnder;
  final String currency;
  final AppLocalizations l10n;

  const _BurnRateCard({
    required this.dailyAverage,
    required this.daysRemaining,
    required this.projected,
    required this.budget,
    required this.willStayUnder,
    required this.currency,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final difference = (projected - budget).abs();

    return Card(
      color: willStayUnder
          ? theme.colorScheme.surfaceContainerHighest
          : theme.colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  willStayUnder ? Icons.check_circle : Icons.warning,
                  color: willStayUnder ? Colors.green : theme.colorScheme.error,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    willStayUnder
                        ? l10n.analyticsBurnTrack
                        : l10n.analyticsBurnWarning,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: willStayUnder ? null : theme.colorScheme.error,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _InfoRow(
                    label: 'Daily Average',
                    value: NumberFormat.simpleCurrency(name: currency, locale: l10n.localeName, decimalDigits: 2).format(dailyAverage),
                  ),
                ),
                Expanded(
                  child: _InfoRow(
                    label: 'Projected Total',
                    value: NumberFormat.simpleCurrency(name: currency, locale: l10n.localeName, decimalDigits: 0).format(projected),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              willStayUnder
                  ? l10n.analyticsBurnFinishUnder(NumberFormat.simpleCurrency(name: currency, locale: l10n.localeName, decimalDigits: 0).format(difference))
                  : l10n.analyticsBurnExceed(NumberFormat.simpleCurrency(name: currency, locale: l10n.localeName, decimalDigits: 0).format(difference)),
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _SpendingPatternsCard extends StatelessWidget {
  final Map<String, double> dayOfWeekData;
  final String currency;
  final AppLocalizations l10n;

  const _SpendingPatternsCard({
    required this.dayOfWeekData,
    required this.currency,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final maxValue = dayOfWeekData.values.isEmpty
        ? 1
        : dayOfWeekData.values.reduce((a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: dayOfWeekData.entries.map((entry) {
            final percent = maxValue == 0 ? 0.0 : (entry.value / maxValue).toDouble();
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  SizedBox(
                    width: 40,
                    child: Text(
                      entry.key,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: percent,
                      minHeight: 12,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(width: 12),
                    SizedBox(
                      width: 50,
                      child: Text(
                        NumberFormat.simpleCurrency(name: currency, locale: l10n.localeName, decimalDigits: 0).format(entry.value),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.right,
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
}

class _ComparisonCard extends StatelessWidget {
  final double thisMonth;
  final double lastMonth;
  final double changePercent;
  final String currency;

  const _ComparisonCard({
    required this.thisMonth,
    required this.lastMonth,
    required this.changePercent,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final isImprovement = changePercent < 0;
    return Card(
      color: isImprovement
          ? Colors.green.shade50
          : Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Text('This Month', style: TextStyle(fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(
                      NumberFormat.simpleCurrency(name: currency, decimalDigits: 0).format(thisMonth),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Icon(
                  isImprovement ? Icons.trending_down : Icons.trending_up,
                  size: 32,
                  color: isImprovement ? Colors.green : Colors.orange,
                ),
                Column(
                  children: [
                    const Text('Last Month', style: TextStyle(fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(
                      NumberFormat.simpleCurrency(name: currency, decimalDigits: 0).format(lastMonth),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isImprovement ? Colors.green : Colors.orange,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${changePercent >= 0 ? '+' : ''}${changePercent.toStringAsFixed(1)}% ${isImprovement ? 'savings' : 'increase'}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== HELPER WIDGETS ====================

/// Error card widget
class _ErrorCard extends StatelessWidget {
  final String message;
  
  const _ErrorCard(this.message);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.danger),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
  }
}

/// Empty state widget
class _EmptyState extends StatelessWidget {
  final String message;
  
  const _EmptyState(this.message);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

/// Category breakdown card using real data model
class _CategoryBreakdownCardReal extends StatelessWidget {
  final List<CategorySpending> categories;
  final String currency;
  
  const _CategoryBreakdownCardReal({
    required this.categories,
    required this.currency,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          ...categories.take(5).map((cat) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  Icon(cat.icon, color: cat.color, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cat.categoryName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: cat.percentage / 100,
                            backgroundColor: Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation(cat.color),
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        NumberFormat.simpleCurrency(name: currency, decimalDigits: 0).format(cat.amount),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        '${cat.percentage.toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
