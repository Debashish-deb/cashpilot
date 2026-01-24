/// Analytics Models
/// Phase 2: Honest analytics data structures
library;

/// Confidence level for analytics insights
/// Based on data quality, not arbitrary percentages
enum ConfidenceLevel {
  low,    // <10 active days or high variance
  medium, // 10-30 days or moderate variance
  high,   // >30 days with consistent patterns
}

extension ConfidenceExt on ConfidenceLevel {
  String get label {
    switch (this) {
      case ConfidenceLevel.low:
        return 'Limited data available';
      case ConfidenceLevel.medium:
        return 'Based on recent activity';
      case ConfidenceLevel.high:
        return 'High confidence based on consistent history';
    }
  }
  
  String get description {
    switch (this) {
      case ConfidenceLevel.low:
        return 'We need more spending data to make accurate predictions';
      case ConfidenceLevel.medium:
        return 'Predictions based on recent spending patterns';
      case ConfidenceLevel.high:
        return 'Strong historical data supports this prediction';
    }
  }
}

/// Result of a forecast calculation
class ForecastResult {
  /// Projected amount (in same unit as input, e.g. cents)
  final double projected;
  
  /// Confidence level based on data quality
  final ConfidenceLevel confidence;
  
  /// Human-readable explanation
  final String reason;
  
  /// Individual factors that contributed to forecast
  final Map<String, double> factors;
  
  /// Timestamp of forecast generation
  final DateTime generatedAt;
  
  const ForecastResult({
    required this.projected,
    required this.confidence,
    required this.reason,
    required this.factors,
    required this.generatedAt,
  });
  
  /// Forecast as percentage (for progress indicators)
  double asPercentage(double limit) {
    if (limit == 0) return 0;
    return (projected / limit).clamp(0, 2.0); // Cap at 200%
  }
}

/// Detailed explanation of how an insight was calculated
/// Provides transparency and builds user trust
class InsightExplanation {
  /// Calculation methodology used
  final String methodology;
  
  /// Data sources (e.g., "Last 30 days of transactions", "7-day weighted average")
  final List<String> dataSources;
  
  /// Sample size used in calculation
  final int sampleSize;
  
  /// Statistical details (variance, confidence interval, etc.)
  final Map<String, dynamic>? statisticalDetails;
  
  /// Assumptions made (e.g., "Assumes current spending rate continues")
  final List<String>? assumptions;
  
  const InsightExplanation({
    required this.methodology,
    required this.dataSources,
    required this.sampleSize,
    this.statisticalDetails,
    this.assumptions,
  });
  
  /// Create explanation for forecast-based insights
  factory InsightExplanation.forecast({
    required int activeDays,
    required double variance,
    required double confidence,
    required String forecastMethod,
  }) {
    return InsightExplanation(
      methodology: forecastMethod,
      dataSources: [
        'Last $activeDays days of spending activity',
        'Historical weekday spending patterns',
      ],
      sampleSize: activeDays,
      statisticalDetails: {
        'variance': variance,
        'confidence_score': confidence,
        'forecast_method': forecastMethod,
      },
      assumptions: [
        'Current spending patterns continue',
        'No major lifestyle changes',
      ],
    );
  }
  
  /// Create explanation for pattern-based insights
  factory InsightExplanation.pattern({
    required String patternType,
    required int observationCount,
    required double threshold,
  }) {
    return InsightExplanation(
      methodology: 'Pattern detection using $patternType',
      dataSources: ['Transaction history analysis'],
      sampleSize: observationCount,
      statisticalDetails: {
        'pattern_type': patternType,
        'detection_threshold': threshold,
      },
    );
  }
}

/// An analytical insight about spending
class Insight {
  /// Unique identifier for insight type
  final String id;
  
  /// Type of insight
  final InsightType type;
  
  /// Priority for display (1 = highest)
  final int priority;
  
  /// User-facing message
  final String message;
  
  /// Confidence in this insight
  final ConfidenceLevel confidence;
  
  /// Reasons supporting this insight
  final List<String> reasons;
  
  /// Detailed explanation of how this insight was calculated
  final InsightExplanation? explanation;
  
  /// Optional numeric data for visualization
  final Map<String, double>? data;
  
  /// When this insight was generated
  final DateTime timestamp;
  
  const Insight({
    required this.id,
    required this.type,
    required this.priority,
    required this.message,
    required this.confidence,
    required this.reasons,
    this.explanation,
    this.data,
    required this.timestamp,
  });
  
  /// Create insight with auto-generated ID
  factory Insight.create({
    required InsightType type,
    required int priority,
    required String message,
    required ConfidenceLevel confidence,
    required List<String> reasons,
    InsightExplanation? explanation,
    Map<String, double>? data,
  }) {
    return Insight(
      id: '${type.name}_${DateTime.now().millisecondsSinceEpoch}',
      type: type,
      priority: priority,
      message: message,
      confidence: confidence,
      reasons: reasons,
      explanation: explanation,
      data: data,
      timestamp: DateTime.now(),
    );
  }
}

/// Types of insights the system can generate
enum InsightType {
  overspendRisk,          // May exceed budget
  onTrack,                // Spending normally
  underBudget,            // Below target
  microLeak,              // Many small purchases
  categorySpike,          // Unusual category activity
  unusualTransaction,     // Out-of-pattern expense
  streakDetected,         // Consecutive pattern
  savingsOpportunity,     // Potential to save
  patternSimilarity,      // Similar to past month
}

/// Snapshot of metrics at a point in time
class MetricsSnapshot {
  final double totalSpent;
  final double averageDaily;
  final double variance;
  final int activeDays;
  final int monthsOfHistory;
  final Map<String, double> categoryShares;
  final Map<int, double> weekdayBaseline; // 1-7 for Mon-Sun
  
  const MetricsSnapshot({
    required this.totalSpent,
    required this.averageDaily,
    required this.variance,
    required this.activeDays,
    required this.monthsOfHistory,
    required this.categoryShares,
    required this.weekdayBaseline,
  });
}

/// Daily spending record
class DailySpend {
  final DateTime date;
  final double amount;
  final int transactionCount;
  
  const DailySpend({
    required this.date,
    required this.amount,
    required this.transactionCount,
  });
}

/// Anomaly detection result
class Anomaly {
  final String entityId;
  final String entityType;
  final String description;
  final double severity; // 0-1
  final String reason;
  
  const Anomaly({
    required this.entityId,
    required this.entityType,
    required this.description,
    required this.severity,
    required this.reason,
  });
}

/// Spending pattern for comparison
class SpendingPattern {
  final String id;
  final DateRange period;
  final List<DailySpend> dailySpending;
  final Map<String, double> categoryDistribution;
  final double totalSpent;
  final double similarity; // 0-1, how similar to current
  
  const SpendingPattern({
    required this.id,
    required this.period,
    required this.dailySpending,
    required this.categoryDistribution,
    required this.totalSpent,
    required this.similarity,
  });
}

/// Date range helper
class DateRange {
  final DateTime start;
  final DateTime end;
  
  const DateRange({required this.start, required this.end});
  
  int get days => end.difference(start).inDays + 1;
  
  bool contains(DateTime date) {
    return (date.isAfter(start) || date.isAtSameMomentAs(start)) &&
           (date.isBefore(end) || date.isAtSameMomentAs(end));
  }
}
