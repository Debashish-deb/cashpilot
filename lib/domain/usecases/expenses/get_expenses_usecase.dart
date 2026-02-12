import '../../repositories/i_expense_repository.dart';
import '../../../data/drift/app_database.dart'; // For Expense return type

/// UseCases:
/// 1. watchRecent
/// 2. watchByBudget
/// 3. watchBySemiBudget
/// 4. getById

class GetExpensesUseCase {
  final IExpenseRepository _repository;

  GetExpensesUseCase(this._repository);

  Stream<List<Expense>> watchRecent(String userId, {int limit = 50}) {
    return _repository.watchRecentExpenses(userId, limit: limit);
  }

  Stream<List<Expense>> watchByBudget(String budgetId) {
    return _repository.watchExpensesByBudget(budgetId);
  }

  Stream<List<Expense>> watchBySemiBudget(String semiBudgetId) {
    return _repository.watchExpensesBySemiBudget(semiBudgetId);
  }
  
  Future<Expense?> getById(String id) {
    return _repository.getExpenseById(id);
  }
}
