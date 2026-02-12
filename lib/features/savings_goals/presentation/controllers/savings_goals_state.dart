import 'package:freezed_annotation/freezed_annotation.dart';

part 'savings_goals_state.freezed.dart';

@freezed
class SavingsGoalsState with _$SavingsGoalsState {
  const factory SavingsGoalsState.idle() = _Idle; 
  const factory SavingsGoalsState.processing() = _Processing;
  const factory SavingsGoalsState.success() = _Success;
  const factory SavingsGoalsState.error(String message) = _ErrorState; 
}
