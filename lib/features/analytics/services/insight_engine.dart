/// Insight Engine — Pro Edition
/// Smarter, safer, more accurate insight generation for CashPilot.
/// Fully backward compatible, no breaking changes.
library;

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/insight_card.dart';

class InsightEngine {
  static final InsightEngine _instance = InsightEngine._internal();
  factory InsightEngine() => _instance;
  InsightEngine._internal();

  final _uuid = const Uuid();

  /// Insights dismissed by the user (permanently hidden)
  final Set<String> _dismissedInsights = {};

  /// Last time each category surfaced an insight (spam-protection)
  final Map<String, DateTime> _lastShownByCategory = {};

  /// Max insights per run / day
  static const int maxInsightsPerDay = 2;

  /// Minimum confidence allowed to show
  static const double minConfidenceThreshold = 0.70;

  /// Minimum hours before showing another from the same category
  static const int minHoursBetweenInsights = 6;

  // ============================================================================
  // INITIALIZATION
  // ============================================================================
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final dismissed = prefs.getStringList('dismissed_insights') ?? [];

    _dismissedInsights.addAll(dismissed);
  }

  // ============================================================================
  // DISMISS INSIGHT
  // ============================================================================
  Future<void> dismissInsight(String insightId) async {
    _dismissedInsights.add(insightId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'dismissed_insights',
      _dismissedInsights.toList(),
    );
  }

  // ============================================================================
  // INTERNAL FILTERING LOGIC
  // ============================================================================
  bool _shouldShowInsight({
    required InsightCategory category,
    required double confidenceScore,
  }) {
    // Confidence threshold
    if (confidenceScore < minConfidenceThreshold) return false;

    // Cooldown for categories
    final last = _lastShownByCategory[category.name];
    if (last != null) {
      final hours = DateTime.now().difference(last).inHours;
      if (hours < minHoursBetweenInsights) return false;
    }

    return true;
  }

  void _markAsShown(InsightCategory category) {
    _lastShownByCategory[category.name] = DateTime.now();
  }

  // ============================================================================
  // BUDGET INSIGHTS
  // ============================================================================
  List<InsightCard> generateBudgetInsights({
    required int healthScore,
    required Map<String, double> componentScores,
    required double usagePercent,
    required bool willExceedBudget,
    required double projectedOverage,
  }) {
    final list = <InsightCard>[];

    // -------------------------------
    // Critical overspend prediction
    // -------------------------------
    if (willExceedBudget && projectedOverage > 50.0) {
      final over = (projectedOverage / 100).toStringAsFixed(2);
      list.add(
        InsightCard(
          id: _uuid.v4(),
          title: 'Budget Warning',
          message: 'You may exceed this budget by €$over at the current pace.',
          severity: InsightSeverity.critical,
          category: InsightCategory.budget,
          confidenceScore: 0.90,
          createdAt: DateTime.now(),
          actionLabel: 'Open Budget',
          actionRoute: '/budgets',
          explanation: 'Prediction based on average daily spend vs days remaining.',
        ),
      );
    }

    // -------------------------------
    // Excellent performance
    // -------------------------------
    if (healthScore >= 85 && usagePercent >= 0.70 && usagePercent <= 0.85) {
      list.add(
        InsightCard(
          id: _uuid.v4(),
          title: 'Great Budget Control',
          message: 'You are managing this budget almost perfectly!',
          severity: InsightSeverity.info,
          category: InsightCategory.budget,
          confidenceScore: 0.95,
          createdAt: DateTime.now(),
        ),
      );
    }

    // -------------------------------
    // Under-utilization (budget unused)
    // -------------------------------
    if (usagePercent < 0.50 && (componentScores['usage'] ?? 100) < 70) {
      list.add(
        InsightCard(
          id: _uuid.v4(),
          title: 'Budget Opportunity',
          message: 'A large part of this budget is unused. Consider reallocating.',
          severity: InsightSeverity.info,
          category: InsightCategory.budget,
          confidenceScore: 0.78,
          createdAt: DateTime.now(),
        ),
      );
    }

    return _filterInsights(list);
  }

  // ============================================================================
  // SUBSCRIPTION INSIGHTS
  // ============================================================================
  List<InsightCard> generateSubscriptionInsights({
    required int subscriptionCount,
    required double totalSubscriptionCost,
    required double budgetPercentage,
    required Map<String, DateTime> lastUsed,
  }) {
    final list = <InsightCard>[];

    // -------------------------------
    // High subscription burden
    // -------------------------------
    if (budgetPercentage > 0.25) {
      final percent = (budgetPercentage * 100).toStringAsFixed(0);
      list.add(
        InsightCard(
          id: _uuid.v4(),
          title: 'High Subscription Spending',
          message: 'Subscriptions take up $percent% of your monthly budget.',
          severity: InsightSeverity.warning,
          category: InsightCategory.subscription,
          confidenceScore: 0.90,
          createdAt: DateTime.now(),
          actionLabel: 'Review Subscriptions',
          actionRoute: '/recurring',
          explanation:
              'Financial planners recommend keeping fixed expenses below ~20%.',
        ),
      );
    }

    // -------------------------------
    // Unused subscriptions (not used for 30+ days)
    // -------------------------------
    final unused = lastUsed.values.where(
      (date) => DateTime.now().difference(date).inDays >= 30,
    );

    if (unused.isNotEmpty) {
      final count = unused.length;
      list.add(
        InsightCard(
          id: _uuid.v4(),
          title: 'Unused Subscription Detected',
          message: '$count subscription${count == 1 ? '' : 's'} not used in 30 days.',
          severity: InsightSeverity.info,
          category: InsightCategory.subscription,
          confidenceScore: 0.83,
          createdAt: DateTime.now(),
          actionLabel: 'Review',
          actionRoute: '/recurring',
        ),
      );
    }

    return _filterInsights(list);
  }

  // ============================================================================
  // BEHAVIOR INSIGHTS
  // ============================================================================
  List<InsightCard> generateBehaviorInsights({
    required Map<String, double> categorySpending,
    required double totalSpending,
    required Map<int, double> dayOfWeekSpending,
  }) {
    final list = <InsightCard>[];

    // -------------------------------
    // Micro-leak detection
    // Purchases < €10 but frequent
    // -------------------------------
    final microLeakCount = categorySpending.values
        .where((amount) => amount > 0 && amount < 1000) // €10 = 1000 cents
        .length;

    if (microLeakCount >= 20) {
      final euros = (totalSpending / 100).toStringAsFixed(2);
      list.add(
        InsightCard(
          id: _uuid.v4(),
          title: 'Hidden Spending Pattern',
          message:
              'Frequent small purchases add up to €$euros this month.',
          severity: InsightSeverity.info,
          category: InsightCategory.behavior,
          confidenceScore: 0.86,
          createdAt: DateTime.now(),
          explanation: 'We detected a high number of micro-purchases (< €10).',
        ),
      );
    }

    // -------------------------------
    // Day-of-week spending pattern
    // -------------------------------
    if (dayOfWeekSpending.isNotEmpty) {
      final top = dayOfWeekSpending.entries.reduce(
        (a, b) => a.value > b.value ? a : b,
      );

      const names = [
        'Monday', 'Tuesday', 'Wednesday', 'Thursday',
        'Friday', 'Saturday', 'Sunday'
      ];
      final name = names[top.key % 7];

      list.add(
        InsightCard(
          id: _uuid.v4(),
          title: 'Spending Habit Detected',
          message: 'Your highest spending day is $name.',
          severity: InsightSeverity.info,
          category: InsightCategory.behavior,
          confidenceScore: 0.72,
          createdAt: DateTime.now(),
        ),
      );
    }

    return _filterInsights(list);
  }

  // ============================================================================
  // FINAL FILTERING OF INSIGHTS
  // ============================================================================
  List<InsightCard> _filterInsights(List<InsightCard> list) {
    // Remove dismissed insights
    final filtered = list.where((i) => !_dismissedInsights.contains(i.id));

    // Sort by confidence (most important first)
    final sorted = filtered.toList()
      ..sort((a, b) => b.confidenceScore.compareTo(a.confidenceScore));

    // Apply logic throttles
    final result = sorted.where((insight) {
      return _shouldShowInsight(
        category: insight.category,
        confidenceScore: insight.confidenceScore,
      );
    }).toList();

    // Mark categories as shown
    for (final i in result) {
      _markAsShown(i.category);
    }

    // Return top N insights
    return result.take(maxInsightsPerDay).toList();
  }
}

// GLOBAL SINGLETON
final insightEngine = InsightEngine();
