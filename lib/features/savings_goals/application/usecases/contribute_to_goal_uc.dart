import '../commands/contribute_to_goal_cmd.dart';
import '../../domain/repositories/savings_goals_repository.dart';

class ContributeToGoalUseCase {
  final SavingsGoalsRepository repo;
  ContributeToGoalUseCase(this.repo);

  Future<void> call(ContributeToGoalCmd cmd) => repo.contribute(cmd);
}
