import '../commands/update_goal_cmd.dart';
import '../../domain/repositories/savings_goals_repository.dart';

class UpdateGoalUseCase {
  final SavingsGoalsRepository repo;
  UpdateGoalUseCase(this.repo);

  Future<void> call(UpdateGoalCmd cmd) => repo.update(cmd);
}
