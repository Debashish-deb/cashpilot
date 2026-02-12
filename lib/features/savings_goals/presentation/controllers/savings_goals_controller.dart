import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/commands/create_goal_cmd.dart';
import '../../application/commands/update_goal_cmd.dart';
import '../../application/usecases/create_goal_uc.dart';
import '../../application/usecases/delete_goal_uc.dart';
import '../../application/usecases/update_goal_uc.dart';
import '../../application/usecases/contribute_to_goal_uc.dart';
import '../../application/usecases/withdraw_from_goal_uc.dart';
import '../../application/commands/contribute_to_goal_cmd.dart';
import '../../application/commands/withdraw_from_goal_cmd.dart';
import 'savings_goals_state.dart';

class SavingsGoalsController extends StateNotifier<SavingsGoalsState> {
  final CreateGoalUseCase createUC;
  final UpdateGoalUseCase updateUC;
  final DeleteGoalUseCase deleteUC;
  final ContributeToGoalUseCase contributeUC;
  final WithdrawFromGoalUseCase withdrawUC;

  SavingsGoalsController(
    this.createUC, 
    this.updateUC, 
    this.deleteUC,
    this.contributeUC,
    this.withdrawUC,
  ) : super(const SavingsGoalsState.idle());

  Future<void> create(CreateGoalCmd cmd) async {
    state = const SavingsGoalsState.processing();
    try {
      await createUC(cmd);
      state = const SavingsGoalsState.success();
    } catch (e) {
      state = SavingsGoalsState.error(e.toString());
    }
  }

  Future<void> update(UpdateGoalCmd cmd) async {
    state = const SavingsGoalsState.processing();
    try {
      await updateUC(cmd);
      state = const SavingsGoalsState.success();
    } catch (e) {
      state = SavingsGoalsState.error(e.toString());
    }
  }

  Future<void> delete(String id) async {
    state = const SavingsGoalsState.processing();
    try {
      await deleteUC(id);
      state = const SavingsGoalsState.success();
    } catch (e) {
      state = SavingsGoalsState.error(e.toString());
    }
  }

  Future<void> contribute(ContributeToGoalCmd cmd) async {
    state = const SavingsGoalsState.processing();
    try {
      await contributeUC(cmd);
      state = const SavingsGoalsState.success();
    } catch (e) {
      state = SavingsGoalsState.error(e.toString());
    }
  }

  Future<void> withdraw(WithdrawFromGoalCmd cmd) async {
    state = const SavingsGoalsState.processing();
    try {
      await withdrawUC(cmd);
      state = const SavingsGoalsState.success();
    } catch (e) {
      state = SavingsGoalsState.error(e.toString());
    }
  }
}
