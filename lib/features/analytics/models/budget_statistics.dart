/// Budget Statistics Model
/// Real-time budget data for analytics
library;

class BudgetStatistics {
  final double totalSpent;
  final double totalBudget;
  final int daysRemaining;
  final double dailyAverage;
  final double utilizationPercent;
  final int daysPassed;
  final double projectedTotal;
  final bool onTrack;

  const BudgetStatistics({
    required this.totalSpent,
    required this.totalBudget,
    required this.daysRemaining,
    required this.dailyAverage,
    required this.utilizationPercent,
    required this.daysPassed,
    required this.projectedTotal,
    required this.onTrack,
  });

  factory BudgetStatistics.empty() {
    return const BudgetStatistics(
      totalSpent: 0,
      totalBudget: 0,
      daysRemaining: 0,
      dailyAverage: 0,
      utilizationPercent: 0,
      daysPassed: 0,
      projectedTotal: 0,
      onTrack: true,
    );
  }

  double get remainingBudget => totalBudget - totalSpent;
  double get safeToSpendPerDay => daysRemaining > 0 ? remainingBudget / daysRemaining : 0;
  bool get isOverBudget => totalSpent > totalBudget;
}
