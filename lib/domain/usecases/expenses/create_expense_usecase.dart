import '../use_case.dart';
import '../../repositories/i_expense_repository.dart';

/// Parameters for creating an expense
class CreateExpenseParams {
  final String budgetId;
  final String? semiBudgetId;
  final String title;
  final int amount;
  final DateTime date;
  final String? categoryId;
  final String? subCategoryId;
  final String? accountId;
  final String enteredBy;
  final String? tags;
  final String? ocrText;
  final String currency;
  final bool skipDuplicateCheck;
  final String? notes;
  final String? paymentMethod;
  final String? receiptUrl;
  final String? barcodeValue;
  final String? merchantName;
  final String? locationName;

  CreateExpenseParams({
    required this.budgetId,
    this.semiBudgetId,
    required this.title,
    required this.amount,
    required this.date,
    this.categoryId,
    this.subCategoryId,
    this.accountId,
    required this.enteredBy,
    this.currency = 'EUR',
    this.tags,
    this.ocrText,
    this.skipDuplicateCheck = false,
    this.notes,
    this.paymentMethod,
    this.receiptUrl,
    this.barcodeValue,
    this.merchantName,
    this.locationName,
  });
}

/// Use case for creating an expense
/// 
/// Encapsulates business logic:
/// - Validation (delegated to repo for now in some parts, or pre-validation here)
/// - Calling repository to persist
class CreateExpenseUseCase extends UseCase<String, CreateExpenseParams> {
  final IExpenseRepository _repository;

  CreateExpenseUseCase(this._repository);

  @override
  Future<String> execute(CreateExpenseParams params) {
    return _repository.createExpense(
      budgetId: params.budgetId,
      semiBudgetId: params.semiBudgetId,
      title: params.title,
      amount: params.amount,
      currency: params.currency,
      date: params.date,
      categoryId: params.categoryId,
      subCategoryId: params.subCategoryId,
      accountId: params.accountId,
      enteredBy: params.enteredBy,
      tags: params.tags,
      ocrText: params.ocrText,
      skipDuplicateCheck: params.skipDuplicateCheck,
      notes: params.notes,
      paymentMethod: params.paymentMethod ?? 'cash',
      receiptUrl: params.receiptUrl,
      barcodeValue: params.barcodeValue,
      merchantName: params.merchantName,
      locationName: params.locationName,
    );
  }
}
