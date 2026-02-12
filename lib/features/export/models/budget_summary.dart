class BudgetSummary {
  final String budgetId;
  final String budgetTitle;
  final double limit;
  final double spent;
  final double remaining;
  final double percentageSpent;

  BudgetSummary({
    required this.budgetId,
    required this.budgetTitle,
    required this.limit,
    required this.spent,
    required this.remaining,
    required this.percentageSpent,
  });

  Map<String, dynamic> toJson() => {
        'budgetId': budgetId,
        'budgetTitle': budgetTitle,
        'limit': limit,
        'spent': spent,
        'remaining': remaining,
        'percentageSpent': percentageSpent,
      };
}
