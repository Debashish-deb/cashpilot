/// Insight Generator Service
/// Transforms technical spending patterns into readable narratives
library;

import '../models/intelligence_models.dart';

class InsightGenerator {
  /// Generate a list of narrative insights from spending intelligence
  static List<SpendingInsight> generateInsights(SpendingIntelligence intelligence) {
    final insights = <SpendingInsight>[];

    for (final pattern in intelligence.patterns) {
      if (!pattern.isWorthSurfacing) continue;

      final insight = _generateForPattern(pattern);
      if (insight != null) {
        insights.add(insight);
      }
    }

    return insights;
  }

  static SpendingInsight? _generateForPattern(SpendingPattern pattern) {
    switch (pattern.type) {
      case PatternType.stressSpending:
        return SpendingInsight(
          title: 'Stress Spending Detected',
          narrative: 'We noticed you tend to spend more when you feel stressed or anxious. This can be a subconscious coping mechanism.',
          actionableAdvice: 'Next time you feel stressed, try waiting 10 minutes before confirming a purchase.',
          type: InsightType.behavioral,
          impact: InsightImpact.medium,
          suggestedTopic: 'impulse_control',
        );

      case PatternType.weekendSplurge:
        final amountInUnits = pattern.averageAmount / 100.0;
        return SpendingInsight(
          title: 'Weekend Splurge Pattern',
          narrative: 'Your weekend spending is significantly higher than your weekday average. You spend about \$$amountInUnits per transaction on Saturdays and Sundays.',
          actionableAdvice: 'Set a specific "Weekend Fun" budget to keep this in check.',
          type: InsightType.trend,
          impact: InsightImpact.low,
          suggestedTopic: 'budgeting',
        );

      case PatternType.subscriptionWaste:
        return SpendingInsight(
          title: 'Unused Subscriptions',
          narrative: 'We detected several recurring payments for services you haven\'t engaged with recently.',
          actionableAdvice: 'Review your subscriptions and cancel any you no longer use to save immediately.',
          type: InsightType.savings,
          impact: InsightImpact.high,
          suggestedTopic: 'savings',
        );
        
      default:
        return null;
    }
  }
}

enum InsightType {
  behavioral,
  trend,
  savings,
  warning,
}

enum InsightImpact {
  low,
  medium,
  high,
}

class SpendingInsight {
  final String title;
  final String narrative;
  final String actionableAdvice;
  final InsightType type;
  final InsightImpact impact;
  final String? suggestedTopic; // Links to Knowledge Hub

  const SpendingInsight({
    required this.title,
    required this.narrative,
    required this.actionableAdvice,
    required this.type,
    required this.impact,
    this.suggestedTopic,
  });
}
