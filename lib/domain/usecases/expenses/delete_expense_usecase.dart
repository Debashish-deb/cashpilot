import '../use_case.dart';
import '../../repositories/i_expense_repository.dart';

class DeleteExpenseUseCase extends UseCase<void, String> {
  final IExpenseRepository _repository;

  DeleteExpenseUseCase(this._repository);

  @override
  Future<void> execute(String id) {
    return _repository.deleteExpense(id);
  }
}
