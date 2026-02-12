
class WithdrawFromGoalCmd {
  final String goalId;
  final int amount; // Amount to withdraw (in cents)
  final String? reason;
  
  WithdrawFromGoalCmd({
    required this.goalId,
    required this.amount,
    this.reason,
  });
}
