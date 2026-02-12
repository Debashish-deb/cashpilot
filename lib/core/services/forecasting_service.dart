
import 'dart:math';

class ValuationPoint {
  final DateTime date;
  final int value; // in cents

  ValuationPoint(this.date, this.value);
}

class ForecastingService {
  /// Predicts net worth at a future date based on historical points.
  /// Uses simple linear regression (y = mx + b).
  double predictNetWorth(List<ValuationPoint> history, DateTime targetDate) {
    if (history.length < 2) return history.isNotEmpty ? history.last.value.toDouble() : 0.0;

    // Convert dates to numeric X values (days from the first point)
    final firstDate = history.first.date;
    final xValues = history.map((p) => p.date.difference(firstDate).inDays.toDouble()).toList();
    final yValues = history.map((p) => p.value.toDouble()).toList();

    // Linear Regression: Least Squares Method
    final n = history.length;
    double sumX = 0;
    double sumY = 0;
    double sumXY = 0;
    double sumX2 = 0;

    for (int i = 0; i < n; i++) {
      sumX += xValues[i];
      sumY += yValues[i];
      sumXY += xValues[i] * yValues[i];
      sumX2 += xValues[i] * xValues[i];
    }

    // slope (m) = (n*sumXY - sumX*sumY) / (n*sumX2 - sumX*sumX)
    final denominator = (n * sumX2 - sumX * sumX);
    if (denominator == 0) return history.last.value.toDouble(); // Vertical line or single point logic

    final slope = (n * sumXY - sumX * sumY) / denominator;
    // intercept (b) = (sumY - slope*sumX) / n
    final intercept = (sumY - slope * sumX) / n;

    // Predict for target date
    final targetX = targetDate.difference(firstDate).inDays.toDouble();
    return slope * targetX + intercept;
  }

  /// Calculates how many days until a target net worth is reached.
  /// Returns -1 if the trend is negative or the goal is already reached.
  int daysToReachGoal(List<ValuationPoint> history, int goalValueCents) {
    if (history.isEmpty) return -1;
    if (history.last.value >= goalValueCents) return 0;
    if (history.length < 2) return -1;

    final firstDate = history.first.date;
    final xValues = history.map((p) => p.date.difference(firstDate).inDays.toDouble()).toList();
    final yValues = history.map((p) => p.value.toDouble()).toList();

    final n = history.length;
    double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;

    for (int i = 0; i < n; i++) {
      sumX += xValues[i];
      sumY += yValues[i];
      sumXY += xValues[i] * yValues[i];
      sumX2 += xValues[i] * xValues[i];
    }

    final denominator = (n * sumX2 - sumX * sumX);
    if (denominator == 0) return -1;

    final slope = (n * sumXY - sumX * sumY) / denominator;
    if (slope <= 0) return -1; // Not growing or shrinking

    final intercept = (sumY - slope * sumX) / n;

    // x = (y - b) / m
    final targetX = (goalValueCents.toDouble() - intercept) / slope;
    final currentX = history.last.date.difference(firstDate).inDays.toDouble();
    
    final daysRemaining = (targetX - currentX).ceil();
    return max(0, daysRemaining);
  }

  /// Predicts days to reach a goal assuming an additional monthly contribution boost.
  int daysToReachGoalWithBoost(List<ValuationPoint> history, int goalValueCents, int monthlyBoostCents) {
    if (history.isEmpty) return -1;
    if (history.last.value >= goalValueCents) return 0;
    
    // Calculate current trend slope
    final firstDate = history.first.date;
    final xValues = history.map((p) => p.date.difference(firstDate).inDays.toDouble()).toList();
    final yValues = history.map((p) => p.value.toDouble()).toList();

    final n = history.length;
    double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;

    for (int i = 0; i < n; i++) {
      sumX += xValues[i];
      sumY += yValues[i];
      sumXY += xValues[i] * yValues[i];
      sumX2 += xValues[i] * xValues[i];
    }

    final denominator = (n * sumX2 - sumX * sumX);
    double currentSlope = 0;
    double currentIntercept = history.last.value.toDouble();

    if (denominator != 0) {
      currentSlope = (n * sumXY - sumX * sumY) / denominator;
    } else if (history.length >= 2) {
      // Fallback to simple average growth if regression fails
      currentSlope = (history.last.value - history.first.value).toDouble() / history.last.date.difference(history.first.date).inDays;
    }

    // Daily boost = Monthly boost / 30.44
    final dailyBoost = monthlyBoostCents.toDouble() / 30.44;
    final totalSlope = currentSlope + dailyBoost;
    
    if (totalSlope <= 0) return -1;

    // Days = (Goal - CurrentValue) / totalSlope
    final days = (goalValueCents.toDouble() - history.last.value.toDouble()) / totalSlope;
    return max(0, days.ceil());
  }
}
