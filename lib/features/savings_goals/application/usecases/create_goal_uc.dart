import '../commands/create_goal_cmd.dart';
import '../../domain/repositories/savings_goals_repository.dart';

class CreateGoalUseCase {
  final SavingsGoalsRepository repo;
  CreateGoalUseCase(this.repo);

  Future<void> call(CreateGoalCmd cmd) => repo.create(cmd);
}
