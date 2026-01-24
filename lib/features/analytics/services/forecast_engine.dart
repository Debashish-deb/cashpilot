/// Forecast Engine
/// Phase 2: Weighted forecasting and honest analytics
library;

import 'dart:math';
import '../models/analytics_models.dart';
import 'metrics_engine.dart';
import 'confidence_engine.dart';

/// Generates forecasts and insights using metrics
/// Replaces naive projections with weighted algorithms
class ForecastEngine {
  final MetricsEngine _metrics;
  final ConfidenceEngine _confidenceEngine = ConfidenceEngine();
  
  ForecastEngine(this._metrics);
  
  // ========================================================================
  // FORECASTING (Weighted, Not Naive)
  // ========================================================================
  
  /// Forecast month-end spending using weighted recent pace + baseline
  Future<ForecastResult> forecastMonthEnd({
    required String budgetId,
    required int daysRemaining,
  }) async {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final range = DateRange(start: monthStart, end: now);
    
    // Get necessary metrics
    final dailySpending = await _metrics.getDailySpending(range, budgetId);
    final weekdayBaseline = await _metrics.getWeekdayBaseline(budgetId);
    final activeDays = await _metrics.getActiveDays(range, budgetId);
    final variance = await _metrics.getVariance(range, budgetId);
    final monthsOfHistory = await _metrics.getMonthsOfHistory(budgetId);
    
    // STEP 1: Recent pace (last 7 days, weighted more)
    final recentDays = dailySpending.take(min(7, dailySpending.length)).toList();
    double recentAvg = 0;
    if (recentDays.isNotEmpty) {
      double weightedSum = 0;
      double totalWeight = 0;
      for (int i = 0; i < recentDays.length; i++) {
        final weight = (i + 1) / recentDays.length; // More recent = higher
        weightedSum += recentDays[i].amount * weight;
        totalWeight += weight;
      }
      recentAvg = totalWeight > 0 ? weightedSum / totalWeight : 0;
    }
    
    // STEP 2: Baseline forecast for remaining days
    double baselineForecast = 0;
    for (int i = 1; i <= daysRemaining; i++) {
      final futureDate = now.add(Duration(days: i));
      final weekday = futureDate.weekday;
      baselineForecast += weekdayBaseline[weekday] ?? 0;
    }
    
    // STEP 3: Blend recent pace (70%) with baseline (30%)
    final blendedDaily = (recentAvg * 0.7) + 
                         ((baselineForecast / daysRemaining) * 0.3);
    final projected = blendedDaily * daysRemaining;
    
    // STEP 4: Calculate confidence
    // STEP 4: Calculate confidence (Statistical)
    final confidenceStats = _confidenceEngine.calculateStats(
       mean: recentAvg,
       variance: variance,
       sampleSize: activeDays,
    );
    final confidence = confidenceStats.level;
    
    // STEP 5: Build result with explanation
    final factors = {
      'recent_pace': recentAvg * daysRemaining,
      'baseline': baselineForecast,
      'blended': projected,
    };
    
    final reason = _buildForecastReason(
      recentAvg: recentAvg,
      daysRemaining: daysRemaining,
      confidence: confidence,
    );
    
    return ForecastResult(
      projected: projected,
      confidence: confidence,
      reason: reason,
      factors: factors,
      generatedAt: DateTime.now(),
    );
  }
  
  // ========================================================================
  // CONFIDENCE CALCULATION (Data-Driven)
  // ========================================================================
  
  /// Build honest explanation for forecast
  String _buildForecastReason({
    required double recentAvg,
    required int daysRemaining,
    required ConfidenceLevel confidence,
  }) {
    final recentFormatted = (recentAvg / 100).toStringAsFixed(2);
    
    switch (confidence) {
      case ConfidenceLevel.high:
        return 'Based on your consistent recent spending pattern of \$$recentFormatted/day '
               'and historical weekday averages over $daysRemaining remaining days';
      
      case ConfidenceLevel.medium:
        return 'Estimated from recent activity averaging \$$recentFormatted/day. '
               'More data needed for higher accuracy';
      
      case ConfidenceLevel.low:
        return 'Limited data available. Estimate based on available spending '
               'of \$$recentFormatted/day may not be accurate';
    }
    // Fallback in case a new enum value is added in the future
    return 'Forecast reason unavailable due to unknown confidence level.';
  }
  
  // ========================================================================
  // PATTERN DETECTION
  // ========================================================================
  
  /// Detect spending insights
  Future<List<Insight>> generateInsights({
    required String budgetId,
    required double budgetLimit,
  }) async {
    final insights = <Insight>[];
    
    // Get metrics snapshot
    final snapshot = await _metrics.getSnapshot(budgetId);
    
    // 1. Overspend risk
    final forecast = await forecastMonthEnd(
      budgetId: budgetId,
      daysRemaining: _daysRemainingInMonth(),
    );
    
    if (forecast.projected > budgetLimit) {
      insights.add(Insight.create(
        type: InsightType.overspendRisk,
        priority: 1,
        message: 'You may exceed budget by \$${((forecast.projected - budgetLimit) / 100).toStringAsFixed(2)}',
        confidence: forecast.confidence,
        reasons: [
          forecast.reason,
          'Current spending: \$${(snapshot.totalSpent / 100).toStringAsFixed(2)}',
        ],
        explanation: InsightExplanation.forecast(
          activeDays: snapshot.activeDays,
          variance: snapshot.variance,
          confidence: forecast.confidence == ConfidenceLevel.high ? 0.95 : (forecast.confidence == ConfidenceLevel.medium ? 0.70 : 0.50),
          forecastMethod: 'Weighted blend of recent pace (70%) and historical weekday baseline (30%)',
        ),
        data: {'projected': forecast.projected, 'limit': budgetLimit},
      ));
    } else if (forecast.projected < budgetLimit * 0.8) {
      insights.add(Insight.create(
        type: InsightType.onTrack,
        priority: 3,
        message: 'You\'re on track to stay within budget',
        confidence: forecast.confidence,
        reasons: [forecast.reason],
        data: {'projected': forecast.projected, 'limit': budgetLimit},
      ));
    }
    
    // 2. Micro-leak detection
    final microLeakInsight = await _detectMicroLeaks(budgetId, snapshot);
    if (microLeakInsight != null) insights.add(microLeakInsight);
    
    // 3. Spending trend
    final trendInsight = await _detectTrend(budgetId);
    if (trendInsight != null) insights.add(trendInsight);
    
    // Sort by priority
    insights.sort((a, b) => a.priority.compareTo(b.priority));
    
    return insights;
  }
  
  /// Detect micro-leaks (many small purchases)
  Future<Insight?> _detectMicroLeaks(
    String budgetId, 
    MetricsSnapshot snapshot,
  ) async {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final range = DateRange(start: monthStart, end: now);
    
    final dailySpends = await _metrics.getDailySpending(range, budgetId);
    
    // Count transactions under $5
    int smallCount = 0;
    double smallTotal = 0;
    
    for (final day in dailySpends) {
      if (day.amount < 500 && day.amount > 0) { // $5 in cents
        smallCount += day.transactionCount;
        smallTotal += day.amount;
      }
    }
    
    // If >10 small transactions totaling >10% of budget
    if (smallCount >= 10 && (smallTotal / snapshot.totalSpent) > 0.1) {
      return Insight.create(
        type: InsightType.microLeak,
        priority: 2,
        message: '$smallCount small purchases total \$${(smallTotal / 100).toStringAsFixed(2)}',
        confidence: ConfidenceLevel.high,
        reasons: [
          'Detected pattern of frequent small purchases',
          'These add up to ${((smallTotal / snapshot.totalSpent) * 100).toStringAsFixed(0)}% of your spending',
        ],
        explanation: InsightExplanation.pattern(
          patternType: 'Small transaction frequency analysis',
          observationCount: smallCount,
          threshold: 5.0, // $5 threshold
        ),
        data: {'count': smallCount.toDouble(), 'total': smallTotal},
      );
    }
    
    return null;
  }
  
  /// Detect spending trend (increasing/decreasing)
  Future<Insight?> _detectTrend(String budgetId) async {
    // OLD NAIVE WAY:
    // final trend = await _metrics.getSpendingTrend(budgetId);
    
    // NEW ROBUST WAY: Linear Regression on Daily Spending (last 30 days)
    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 30));
    final range = DateRange(start: start, end: now);
    final dailySpends = await _metrics.getDailySpending(range, budgetId);
    
    // Convert to list of values (reversed to be chronological: Old -> New)
    final values = dailySpends.map((d) => d.amount).toList().reversed.toList();
    
    // Calculate 
    final trend = calculateRobustTrend(values);
    
    // Interpretation: Normalized slope. > 0.1 means +10% typical growth over the period
    if (trend > 0.15) { // Threshold: 15% increase trend
      return Insight.create(
        type: InsightType.categorySpike,
        priority: 2,
        message: 'Spending trending up significantly (+${(trend * 100).toStringAsFixed(0)}%)',
        confidence: ConfidenceLevel.high, // Math-backed
        reasons: [
          'Linear trend analysis of last 30 days indicates consistent increase',
        ],
        explanation: InsightExplanation(
          methodology: 'Linear regression slope analysis',
          dataSources: ['Daily spending data from last 30 days'],
          sampleSize: values.length,
          statisticalDetails: {
            'trend_slope': trend,
            'analysis_method': 'Least squares regression',
            'time_period': '30 days',
          },
          assumptions: ['Trend represents sustainable pattern', 'No external shocks'],
        ),
        data: {'trend': trend},
      );
    }
    
    return null;
  }
  
  // ========================================================================
  // HELPERS
  // ========================================================================
  

  int _daysRemainingInMonth() {
    final now = DateTime.now();
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
    return lastDayOfMonth.day - now.day;
  }

  // ========================================================================
  // ROBUST TREND CALCULATION
  // ========================================================================

  /// Calculate trend using Linear Regression Slope (Least Squares)
  /// Returns a normalized growth rate (e.g., 0.10 = +10% trend)
  /// More robust than simple (Current - Prev) / Prev
  double calculateRobustTrend(List<double> values) {
    if (values.length < 2) return 0.0;
    
    // X = index (time), Y = value
    int n = values.length;
    double sumX = 0;
    double sumY = 0;
    double sumXY = 0;
    double sumXX = 0;
    
    for (int i = 0; i < n; i++) {
      sumX += i;
      sumY += values[i];
      sumXY += i * values[i];
      sumXX += i * i;
    }
    
    // Slope (m)
    double slope = (n * sumXY - sumX * sumY) / (n * sumXX - sumX * sumX);
    
    // Normalize slope relative to the mean (to get a percentage-like change)
    double meanY = sumY / n;
    if (meanY == 0) return 0.0;
    
    // Trend = Slope / Mean * (TimeSpan)
    // Helps visualize magnitude of change over the period
    return (slope / meanY) * n; 
  }
}
