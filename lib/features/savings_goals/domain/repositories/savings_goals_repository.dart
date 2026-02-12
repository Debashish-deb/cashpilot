import '../entities/savings_goal.dart';

import '../../application/commands/create_goal_cmd.dart';
import '../../application/commands/update_goal_cmd.dart';
import '../../application/commands/contribute_to_goal_cmd.dart';
import '../../application/commands/withdraw_from_goal_cmd.dart';

abstract class SavingsGoalsRepository {
  /// Watch all active goals
  Stream<List<SavingsGoal>> watchGoals();
  
  /// Get single goal
  Future<SavingsGoal?> getGoal(String id);

  /// Transactional creation
  Future<void> create(CreateGoalCmd cmd);

  /// Transactional update
  Future<void> update(UpdateGoalCmd cmd);

  /// Contribute money to goal (optional: deduct from budget)
  Future<void> contribute(ContributeToGoalCmd cmd);

  /// Withdraw money from goal
  Future<void> withdraw(WithdrawFromGoalCmd cmd);

  /// Transactional deletion (soft delete)
  Future<void> delete(String id);
}
