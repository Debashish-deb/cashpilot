import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/app_providers.dart';
import '../../application/usecases/create_goal_uc.dart';
import '../../application/usecases/delete_goal_uc.dart';
import '../../application/usecases/update_goal_uc.dart';
import '../../application/usecases/contribute_to_goal_uc.dart';
import '../../application/usecases/withdraw_from_goal_uc.dart';
import '../../domain/repositories/savings_goals_repository.dart';
import '../../infrastructure/drift/savings_goals_dao.dart';
import '../../infrastructure/repositories/savings_goals_repository_impl.dart';
import '../controllers/savings_goals_controller.dart';
import '../controllers/savings_goals_state.dart';

// DAO
final savingsGoalsDaoProvider = Provider<SavingsGoalsDao>((ref) {
  final db = ref.watch(databaseProvider);
  return SavingsGoalsDao(db);
});

// Repository
final savingsGoalsRepositoryProvider = Provider<SavingsGoalsRepository>((ref) {
  final db = ref.watch(databaseProvider);
  final dao = ref.watch(savingsGoalsDaoProvider);
  return SavingsGoalsRepositoryImpl(db, dao);
});

// Use Cases
final createGoalUseCaseProvider = Provider((ref) => CreateGoalUseCase(ref.watch(savingsGoalsRepositoryProvider)));
final updateGoalUseCaseProvider = Provider((ref) => UpdateGoalUseCase(ref.watch(savingsGoalsRepositoryProvider)));
final deleteGoalUseCaseProvider = Provider((ref) => DeleteGoalUseCase(ref.watch(savingsGoalsRepositoryProvider)));
final contributeToGoalUseCaseProvider = Provider((ref) => ContributeToGoalUseCase(ref.watch(savingsGoalsRepositoryProvider)));
final withdrawFromGoalUseCaseProvider = Provider((ref) => WithdrawFromGoalUseCase(ref.watch(savingsGoalsRepositoryProvider)));

// Controller
final savingsGoalsControllerProvider = StateNotifierProvider<SavingsGoalsController, SavingsGoalsState>((ref) {
  return SavingsGoalsController(
    ref.watch(createGoalUseCaseProvider),
    ref.watch(updateGoalUseCaseProvider),
    ref.watch(deleteGoalUseCaseProvider),
    ref.watch(contributeToGoalUseCaseProvider),
    ref.watch(withdrawFromGoalUseCaseProvider),
  );
});

// Watch Goals Stream
final savingsGoalsStreamProvider = StreamProvider((ref) {
  return ref.watch(savingsGoalsRepositoryProvider).watchGoals();
});
