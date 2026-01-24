/// Burn Rate Calculator — Pro Edition
/// High-accuracy pacing model used in professional budgeting apps.
/// Works without requiring any structural changes to your app.
library;

class BurnRateResult {
  final double dailyAverage;      // Actual burn/day
  final double idealDailyLimit;   // Budget/day allowed
  final double paceIndex;         // Ratio between actual pace and budget pace
  final double projectedTotal;    // Projected spending at end of cycle
  final double projectedRemaining;
  final double projectedOverage;
  final bool willExceedBudget;
  final int daysElapsed;
  final int daysRemaining;
  final String insight;

  const BurnRateResult({
    required this.dailyAverage,
    required this.idealDailyLimit,
    required this.paceIndex,
    required this.projectedTotal,
    required this.projectedRemaining,
    required this.projectedOverage,
    required this.willExceedBudget,
    required this.daysElapsed,
    required this.daysRemaining,
    required this.insight,
  });
}

class BurnRateCalculator {
  static BurnRateResult calculate({
    required double totalBudget,
    required double totalSpent,
    required DateTime periodStart,
    required DateTime periodEnd,
  }) {
    final now = DateTime.now();

    // Clamp bounds for stability
    final start = now.isBefore(periodStart) ? now : periodStart;
    final end = periodEnd.isBefore(now) ? now : periodEnd;

    // Days elapsed / remaining
    final daysElapsed = now.difference(start).inDays + 1;
    final totalDays = end.difference(start).inDays + 1;
    final daysRemaining = (totalDays - daysElapsed).clamp(0, totalDays);

    // Ideal daily spend allowed
    final idealDailyLimit = totalBudget / totalDays;

    // Actual daily average
    final dailyAverage = daysElapsed > 0 ? totalSpent / daysElapsed : 0.0;

    // Pace index (1.0 = perfect pace)
    final paceIndex = dailyAverage / idealDailyLimit;

    // Smoothing: prevents wild projections in early cycle
    final smoothingWeight = _smoothing(daysElapsed, totalDays);

    // Projected end-of-cycle total
    final projectedTotal = totalSpent +
        (dailyAverage * daysRemaining * smoothingWeight) +
        (_stabilityOffset(totalSpent, daysElapsed));

    // Remaining budget vs projection
    final projectedRemaining = totalBudget - projectedTotal;
    final projectedOverage = (projectedTotal - totalBudget).clamp(0.0, double.infinity);

    final willExceedBudget = projectedOverage > 0;

    final insight = _generateInsight(
      dailyAverage,
      idealDailyLimit,
      paceIndex,
      daysRemaining,
      projectedOverage,
      totalBudget,
    );

    return BurnRateResult(
      dailyAverage: dailyAverage,
      idealDailyLimit: idealDailyLimit,
      paceIndex: paceIndex,
      projectedTotal: projectedTotal,
      projectedRemaining: projectedRemaining,
      projectedOverage: projectedOverage,
      willExceedBudget: willExceedBudget,
      daysElapsed: daysElapsed,
      daysRemaining: daysRemaining,
      insight: insight,
    );
  }

  // ========================================================================
  // SMOOTHING FUNCTIONS
  // ========================================================================

  /// Prevent aggressive projections when not enough days have passed.
  static double _smoothing(int daysElapsed, int totalDays) {
    if (daysElapsed < 3) return 0.40; // very early → reduce projection noise
    if (daysElapsed < 7) return 0.65;
    if (daysElapsed < totalDays * 0.5) return 0.80;
    return 1.0; // late cycle → trust the data fully
  }

  /// Helps stabilize projections for volatile spending patterns.
  static double _stabilityOffset(double totalSpent, int daysElapsed) {
    if (daysElapsed < 5) {
      return -(totalSpent * 0.04); // early → slightly pessimistic
    }
    return 0.0;
  }

  // ========================================================================
  // INSIGHT ENGINE — Premium, app-ready messages
  // ========================================================================
  static String _generateInsight(
    double dailyAvg,
    double idealDaily,
    double paceIndex,
    int daysRemaining,
    double overage,
    double budget,
  ) {
    final daily = (dailyAvg / 100).toStringAsFixed(2);
    final ideal = (idealDaily / 100).toStringAsFixed(2);
    final over = (overage / 100).toStringAsFixed(2);

    if (daysRemaining == 0) {
      return overage > 0
          ? "Period ended €$over over budget"
          : "Period ended under budget — great control!";
    }

    if (paceIndex < 0.75) {
      return "You're spending well under your daily limit (€$daily vs €$ideal). Strong pacing.";
    }

    if (paceIndex < 1.05) {
      return "Perfect pace — spending (€$daily/day) matches your plan.";
    }

    if (paceIndex < 1.25) {
      return "Slightly above ideal pace. Reduce daily spending to avoid end-period pressure.";
    }

    if (paceIndex < 1.5) {
      return "Warning: spending is running hot. You're on track to exceed the budget by €$over.";
    }

    return "Critical: current pace will exceed budget significantly (≈€$over). Immediate adjustment recommended.";
  }
}
