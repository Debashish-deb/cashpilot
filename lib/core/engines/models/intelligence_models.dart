/// Core Intelligence Models
/// Simple immutable data classes for Financial Intelligence Engine
library;

// ============================================================
// BUDGET INTELLIGENCE
// ============================================================

/// Budget health status
enum BudgetHealthStatus {
  healthy,    // On track
  watch,      // Slightly over pace
  risk,       // Significantly over pace
  exceeded,   // Over budget
}

/// Trend confidence levels
enum TrendConfidence {
  normal,
  slightlyUnusual,
  veryUnusual,
}


/// Complete budget intelligence
class BudgetIntelligence {
  final String budgetId;
  final BudgetHealthStatus health;
  final TrendConfidence trendConfidence;

  /// Monetary values are in **cents**
  final int totalLimit;
  final int totalSpent;

  final int daysPassed;
  final int daysTotal;
  final int daysLeft;

  /// Spend rate in **cents per day**
  final double spendRate;

  /// Forecast total in **cents**
  final double forecastTotal;

  /// Forecast delta vs limit in **cents**
  final int forecastDelta;

  final bool isAnomalous;
  final double anomalyScore;

  final DateTime computedAt;
  final String? cacheKey;

  const BudgetIntelligence({
    required this.budgetId,
    required this.health,
    required this.trendConfidence,
    required this.totalLimit,
    required this.totalSpent,
    required this.daysPassed,
    required this.daysTotal,
    required this.daysLeft,
    required this.spendRate,
    required this.forecastTotal,
    required this.forecastDelta,
    required this.isAnomalous,
    required this.anomalyScore,
    required this.computedAt,
    this.cacheKey,
  });

  // ------------------------------------------------------------
  // SEMANTIC HELPERS (non-breaking)
  // ------------------------------------------------------------

  bool get isOverBudget => totalSpent > totalLimit;

  bool get isForecastOverBudget => forecastDelta > 0;

  bool get isHealthy =>
      health == BudgetHealthStatus.healthy ||
      health == BudgetHealthStatus.watch;

  bool get needsAttention =>
      health == BudgetHealthStatus.risk ||
      health == BudgetHealthStatus.exceeded;

  bool get hasStrongAnomaly =>
      isAnomalous && trendConfidence == TrendConfidence.veryUnusual;

  double get progressRatio =>
      totalLimit == 0 ? 0 : totalSpent / totalLimit;

  double get timeRatio =>
      daysTotal == 0 ? 0 : daysPassed / daysTotal;

  // ------------------------------------------------------------
  // COPY (required for engine/cache enrichment)
  // ------------------------------------------------------------

  BudgetIntelligence copyWith({
    String? budgetId,
    BudgetHealthStatus? health,
    TrendConfidence? trendConfidence,
    int? totalLimit,
    int? totalSpent,
    int? daysPassed,
    int? daysTotal,
    int? daysLeft,
    double? spendRate,
    double? forecastTotal,
    int? forecastDelta,
    bool? isAnomalous,
    double? anomalyScore,
    DateTime? computedAt,
    String? cacheKey,
  }) {
    return BudgetIntelligence(
      budgetId: budgetId ?? this.budgetId,
      health: health ?? this.health,
      trendConfidence: trendConfidence ?? this.trendConfidence,
      totalLimit: totalLimit ?? this.totalLimit,
      totalSpent: totalSpent ?? this.totalSpent,
      daysPassed: daysPassed ?? this.daysPassed,
      daysTotal: daysTotal ?? this.daysTotal,
      daysLeft: daysLeft ?? this.daysLeft,
      spendRate: spendRate ?? this.spendRate,
      forecastTotal: forecastTotal ?? this.forecastTotal,
      forecastDelta: forecastDelta ?? this.forecastDelta,
      isAnomalous: isAnomalous ?? this.isAnomalous,
      anomalyScore: anomalyScore ?? this.anomalyScore,
      computedAt: computedAt ?? this.computedAt,
      cacheKey: cacheKey ?? this.cacheKey,
    );
  }
  // ------------------------------------------------------------
  // SERIALIZATION
  // ------------------------------------------------------------

  Map<String, dynamic> toJson() => {
        'budget_id': budgetId,
        'health': health.index,
        'trend_confidence': trendConfidence.index,
        'total_limit': totalLimit,
        'total_spent': totalSpent,
        'days_passed': daysPassed,
        'days_total': daysTotal,
        'days_left': daysLeft,
        'spend_rate': spendRate,
        'forecast_total': forecastTotal,
        'forecast_delta': forecastDelta,
        'is_anomalous': isAnomalous,
        'anomaly_score': anomalyScore,
        'computed_at': computedAt.toIso8601String(),
        'cache_key': cacheKey,
      };

  factory BudgetIntelligence.fromJson(Map<String, dynamic> json) {
    return BudgetIntelligence(
      budgetId: json['budget_id'] as String,
      health: BudgetHealthStatus.values[json['health'] as int],
      trendConfidence: TrendConfidence.values[json['trend_confidence'] as int],
      totalLimit: json['total_limit'] as int,
      totalSpent: json['total_spent'] as int,
      daysPassed: json['days_passed'] as int,
      daysTotal: json['days_total'] as int,
      daysLeft: json['days_left'] as int,
      spendRate: (json['spend_rate'] as num).toDouble(),
      forecastTotal: (json['forecast_total'] as num).toDouble(),
      forecastDelta: json['forecast_delta'] as int,
      isAnomalous: json['is_anomalous'] as bool,
      anomalyScore: (json['anomaly_score'] as num).toDouble(),
      computedAt: DateTime.parse(json['computed_at'] as String),
      cacheKey: json['cache_key'] as String?,
    );
  }
}

// ============================================================
// SPENDING INTELLIGENCE
// ============================================================

/// Spending pattern type
enum PatternType {
  weekdayMorning,
  weekendSplurge,
  subscription,
  recurringMerchant,
  bulkBuyOpportunity,
  subscriptionWaste,
  stressSpending,
}

/// Discovered spending pattern
class SpendingPattern {
  final String id;
  final PatternType type;
  final String? merchant;

  /// How often detected
  final int frequencyCount;

  /// Average amount in **cents**
  final int averageAmount;

  final double confidence;
  final int? weekday;
  final int? hourOfDay;
  final String? categoryId;

  const SpendingPattern({
    required this.id,
    required this.type,
    required this.merchant,
    required this.frequencyCount,
    required this.averageAmount,
    required this.confidence,
    this.weekday,
    this.hourOfDay,
    this.categoryId,
    this.notes,
  });

  final String? notes;

  // ------------------------------------------------------------
  // SEMANTIC HELPERS
  // ------------------------------------------------------------

  bool get isHighConfidence => confidence >= 0.7;

  bool get isFrequent => frequencyCount >= 3;

  bool get isWorthSurfacing =>
      isHighConfidence && isFrequent;

  bool get isSubscriptionRelated =>
      type == PatternType.subscription ||
      type == PatternType.subscriptionWaste;
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.index,
        'merchant': merchant,
        'frequency_count': frequencyCount,
        'average_amount': averageAmount,
        'confidence': confidence,
        'weekday': weekday,
        'hour_of_day': hourOfDay,
        'category_id': categoryId,
        'notes': notes,
      };

  factory SpendingPattern.fromJson(Map<String, dynamic> json) {
    return SpendingPattern(
      id: json['id'] as String,
      type: PatternType.values[json['type'] as int],
      merchant: json['merchant'] as String?,
      frequencyCount: json['frequency_count'] as int,
      averageAmount: json['average_amount'] as int,
      confidence: (json['confidence'] as num).toDouble(),
      weekday: json['weekday'] as int?,
      hourOfDay: json['hour_of_day'] as int?,
      categoryId: json['category_id'] as String?,
      notes: json['notes'] as String?,
    );
  }
}

/// Comprehensive spending intelligence
class SpendingIntelligence {
  final String userId;

  /// Average daily spend in **cents**
  final double averageDaily;

  final List<SpendingPattern> patterns;
  final Map<String, int> topCategories;
  final List<int> peakDays;

  final DateTime computedAt;

  const SpendingIntelligence({
    required this.userId,
    required this.averageDaily,
    required this.patterns,
    required this.topCategories,
    required this.peakDays,
    required this.computedAt,
  });

  // ------------------------------------------------------------
  // HELPERS
  // ------------------------------------------------------------

  List<SpendingPattern> get strongPatterns =>
      patterns.where((p) => p.isWorthSurfacing).toList();

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'average_daily': averageDaily,
        'patterns': patterns.map((p) => p.toJson()).toList(),
        'top_categories': topCategories,
        'peak_days': peakDays,
        'computed_at': computedAt.toIso8601String(),
      };

  factory SpendingIntelligence.fromJson(Map<String, dynamic> json) {
    return SpendingIntelligence(
      userId: json['user_id'] as String,
      averageDaily: (json['average_daily'] as num).toDouble(),
      patterns: (json['patterns'] as List)
          .map((e) => SpendingPattern.fromJson(e as Map<String, dynamic>))
          .toList(),
      topCategories: Map<String, int>.from(json['top_categories'] as Map),
      peakDays: List<int>.from(json['peak_days'] as List),
      computedAt: DateTime.parse(json['computed_at'] as String),
    );
  }
}

// ============================================================
// ML FEEDBACK
// ============================================================

/// User correction for ML learning
class MLFeedback {
  final String expenseId;
  final String suggestedCategory;
  final String actualCategory;
  final double confidence;
  final String title;
  final String? merchant;
  final int? amount;
  final DateTime createdAt;

  const MLFeedback({
    required this.expenseId,
    required this.suggestedCategory,
    required this.actualCategory,
    required this.confidence,
    required this.title,
    this.merchant,
    this.amount,
    required this.createdAt,
  });

  bool get isHighConfidence => confidence >= 0.8;

  Map<String, dynamic> toSupabaseJson() => {
        'expense_id': expenseId,
        'suggested_category': suggestedCategory,
        'actual_category': actualCategory,
        'confidence': confidence,
        'title': title,
        'merchant': merchant,
        'amount': amount,
      };
}

// ============================================================
// ANALYSIS SCOPE
// ============================================================

/// Scope of analysis
enum AnalysisScope {
  currentMonth,
  last30Days,
  last90Days,
  yearToDate,
  allTime,
}

// ============================================================
// CATEGORY PREDICTION
// ============================================================

/// Predicted category for an expense
class CategoryPrediction {
  final String categoryId;
  final String categoryName;
  final double confidence;
  final String? subcategoryId;
  final String? subcategoryName;
  final bool isUnknown;

  const CategoryPrediction({
    required this.categoryId,
    required this.categoryName,
    required this.confidence,
    this.subcategoryId,
    this.subcategoryName,
    this.isUnknown = false,
  });

  /// Factory for unknown predictions
  factory CategoryPrediction.unknown() {
    return const CategoryPrediction(
      categoryId: 'other',
      categoryName: 'Other',
      confidence: 0.0,
      isUnknown: true,
    );
  }

  /// Check if prediction is confident enough to auto-apply
  bool get isConfident => confidence >= 0.7;

  /// Check if this is a high confidence prediction
  bool get isHighConfidence => confidence >= 0.85;
}

