import '../use_case.dart';
import '../../repositories/i_expense_repository.dart';

class UpdateExpenseParams {
  final String id;
  final String? title;
  final int? amount;
  final String? currency;
  final DateTime? date;
  final String? notes;
  final String? paymentMethod;
  final String? categoryId;
  final String? subCategoryId;
  final String? semiBudgetId;
  final String? budgetId;
  final String? merchantName;
  final String? tags;

  UpdateExpenseParams({
    required this.id,
    this.title,
    this.amount,
    this.currency,
    this.date,
    this.notes,
    this.paymentMethod,
    this.categoryId,
    this.subCategoryId,
    this.semiBudgetId,
    this.budgetId,
    this.merchantName,
    this.tags,
  });
}

class UpdateExpenseUseCase extends UseCase<void, UpdateExpenseParams> {
  final IExpenseRepository _repository;

  UpdateExpenseUseCase(this._repository);

  @override
  Future<void> execute(UpdateExpenseParams params) {
    return _repository.updateExpense(
      id: params.id,
      title: params.title,
      amount: params.amount,
      currency: params.currency,
      date: params.date,
      notes: params.notes,
      paymentMethod: params.paymentMethod,
      categoryId: params.categoryId,
      subCategoryId: params.subCategoryId,
      semiBudgetId: params.semiBudgetId,
      budgetId: params.budgetId,
      merchantName: params.merchantName,
      tags: params.tags,
    );
  }
}
