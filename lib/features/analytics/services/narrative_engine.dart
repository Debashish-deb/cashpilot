/// Narrative Engine
/// Phase 2: Generates honest, clear explanations for analytics
/// Replaces "AI predicts" with "Based on data"
library;

import 'package:intl/intl.dart';
import '../models/analytics_models.dart';

/// Turns insights and forecasts into human-readable text
class NarrativeEngine {
  final _currencyFormat = NumberFormat.simpleCurrency(decimalDigits: 0);
  
  /// Get main headline for an insight
  String getHeadline(Insight insight) {
    switch (insight.type) {
      case InsightType.overspendRisk:
        return 'Budget Risk Detected';
      case InsightType.onTrack:
        return 'Spending on Track';
      case InsightType.underBudget:
        return 'Under Budget';
      case InsightType.microLeak:
        return 'High Frequency Spending';
      case InsightType.categorySpike:
        return 'Category Alert';
      case InsightType.streakDetected:
        return 'Streak!';
      case InsightType.savingsOpportunity:
        return 'Savings Opportunity';
      default:
        return 'Spending Insight';
    }
  }

  /// Get honest, confident explanation
  String getDetailedExplanation(Insight insight) {
    final sb = StringBuffer();
    
    // Core message
    sb.writeln(insight.message);
    
    // Add confidence context
    if (insight.confidence != ConfidenceLevel.high) {
      sb.writeln('\nNote: ${insight.confidence.description}');
    }
    
    // Add reasons
    if (insight.reasons.isNotEmpty) {
      sb.writeln('\nWhy we\'re showing this:');
      for (final reason in insight.reasons) {
        sb.writeln('• $reason');
      }
    }
    
    return sb.toString();
  }
  
  /// Format a forecast result into a user-facing string
  String formatForecast(ForecastResult forecast, String currency) {
    final formattedAmount = _currencyFormat.format(forecast.projected / 100);
    
    switch (forecast.confidence) {
      case ConfidenceLevel.high:
        return 'projected to reach $formattedAmount';
      case ConfidenceLevel.medium:
        return 'estimated to reach ~$formattedAmount';
      case ConfidenceLevel.low:
        return 'might reach ~$formattedAmount (limited data)';
    }
  }
  
  /// Explain why a conflict happened (for Phase 1 conflicts UI)
  String explainConflict(String entityType, DateTime localTime) {
    return 'This $entityType was edited on another device while you were offline. '
           'Your changes from failure time are saved here.';
  }
  
  /// Create Instagram-style story recap text
  String generateRecapStory(MetricsSnapshot metrics, String currency) {
    final total = _currencyFormat.format(metrics.totalSpent / 100);
    final avg = _currencyFormat.format(metrics.averageDaily / 100);
    
    return 'This month so far:\n'
           '💸 You spent $total\n'
           '📅 Averaging $avg daily\n'
           '📊 ${(metrics.activeDays / 30 * 100).toStringAsFixed(0)}% active days';
  }
}
