import '../use_case.dart';
import '../../../data/drift/app_database.dart';
import 'package:drift/drift.dart';

/// Parameters for creating an expense
class CreateExpenseParams {
  final String budgetId;
  final String? semiBudgetId;
  final String title;
  final int amount;
  final DateTime date;
  final String? categoryId;
  final String? accountId;
  final String enteredBy;
  final String? tags;
  final String? ocrText;

  CreateExpenseParams({
    required this.budgetId,
    this.semiBudgetId,
    required this.title,
    required this.amount,
    required this.date,
    this.categoryId,
    this.accountId,
    required this.enteredBy,
    this.tags,
    this.ocrText,
  });
}

/// Use case for creating an expense
/// 
/// Encapsulates business logic:
/// - Generates UUID
/// - Sets sync state to 'dirty'
/// - Validates budget exists
/// - Inserts into database
class CreateExpenseUseCase extends UseCase<String, CreateExpenseParams> {
  final AppDatabase _db;

  CreateExpenseUseCase(this._db);

  @override
  Future<String> execute(CreateExpenseParams params) async {
    // Business Logic: Generate consistent ID
    final expenseId = _generateExpenseId();

    // Business Logic: Validate budget exists
    final budget = await (_db.select(_db.budgets)
      ..where((b) => b.id.equals(params.budgetId))
    ).getSingleOrNull();

    if (budget == null) {
      throw Exception('Budget not found: ${params.budgetId}');
    }

    // Insert expense with 'dirty' sync state
    await _db.into(_db.expenses).insert(
      ExpensesCompanion.insert(
        id: expenseId,
        budgetId: params.budgetId,
        semiBudgetId: Value(params.semiBudgetId),
        title: params.title,
        amount: params.amount,
        currency: Value(budget.currency), // Inherit from budget
        date: params.date,
        categoryId: Value(params.categoryId),
        accountId: Value(params.accountId),
        enteredBy: params.enteredBy,
        tags: Value(params.tags),
        ocrText: Value(params.ocrText),
        syncState: const Value('dirty'), // Will be synced
        revision: const Value(1),
      ),
    );

    return expenseId;
  }

  String _generateExpenseId() {
    return 'exp_${DateTime.now().millisecondsSinceEpoch}_${_randomString(6)}';
  }

  String _randomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return String.fromCharCodes(
      Iterable.generate(
        length,
        (_) => chars.codeUnitAt((DateTime.now().microsecond * 13) % chars.length),
      ),
    );
  }
}
