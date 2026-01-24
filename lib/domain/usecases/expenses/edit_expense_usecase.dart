import '../use_case.dart';
import '../../../data/drift/app_database.dart';
import 'package:drift/drift.dart';

/// Parameters for editing an expense
class EditExpenseParams {
  final String expenseId;
  final String? title;
  final int? amount;
  final DateTime? date;
  final String? categoryId;
  final String? semiBudgetId;
  final String? ocrText;

  EditExpenseParams({
    required this.expenseId,
    this.title,
    this.amount,
    this.date,
    this.categoryId,
    this.semiBudgetId,
    this.ocrText,
  });
}

/// Use case for editing an existing expense
/// 
/// Business logic:
/// - Validates expense exists
/// - Increments revision number
/// - Sets sync state to 'dirty'
/// - Updates only provided fields
class EditExpenseUseCase extends UseCase<void, EditExpenseParams> {
  final AppDatabase _db;

  EditExpenseUseCase(this._db);

  @override
  Future<void> execute(EditExpenseParams params) async {
    // Validate expense exists
    final existing = await (_db.select(_db.expenses)
      ..where((e) => e.id.equals(params.expenseId))
    ).getSingleOrNull();

    if (existing == null) {
      throw Exception('Expense not found: ${params.expenseId}');
    }

    // Build update companion with only changed fields
    final update = ExpensesCompanion(
      title: params.title != null ? Value(params.title!) : const Value.absent(),
      amount: params.amount != null ? Value(params.amount!) : const Value.absent(),
      date: params.date != null ? Value(params.date!) : const Value.absent(),
      categoryId: params.categoryId != null ? Value(params.categoryId) : const Value.absent(),
      semiBudgetId: params.semiBudgetId != null ? Value(params.semiBudgetId) : const Value.absent(),
      ocrText: params.ocrText != null ? Value(params.ocrText) : const Value.absent(),
      // Business Logic: Increment revision and mark dirty
      revision: Value(existing.revision + 1),
      syncState: const Value('dirty'),
      updatedAt: Value(DateTime.now()),
    );

    // Apply update
    await (_db.update(_db.expenses)
      ..where((e) => e.id.equals(params.expenseId))
    ).write(update);
  }
}
