import '../commands/withdraw_from_goal_cmd.dart';
import '../../domain/repositories/savings_goals_repository.dart';

class WithdrawFromGoalUseCase {
  final SavingsGoalsRepository repo;
  WithdrawFromGoalUseCase(this.repo);

  Future<void> call(WithdrawFromGoalCmd cmd) => repo.withdraw(cmd);
}
