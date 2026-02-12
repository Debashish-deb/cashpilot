import '../../domain/repositories/savings_goals_repository.dart';

class DeleteGoalUseCase {
  final SavingsGoalsRepository repo;
  DeleteGoalUseCase(this.repo);

  Future<void> call(String id) => repo.delete(id);
}
