import 'package:drift/drift.dart';
import '../../domain/repositories/i_expense_repository.dart';
import '../drift/app_database.dart';
import '../../features/sync/services/outbox_service.dart';
import 'package:uuid/uuid.dart';

class ExpenseRepositoryImpl implements IExpenseRepository {
  final AppDatabase _db;
  final OutboxService _outbox;
  final Uuid _uuid = const Uuid();

  ExpenseRepositoryImpl(this._db) : _outbox = OutboxService(_db);

  @override
  Future<String> createExpense({
    required String budgetId,
    String? semiBudgetId,
    String? categoryId,
    String? subCategoryId,
    required String title,
    required int amount,
    required String currency,
    required DateTime date,
    required String enteredBy,
    String? notes,
    String paymentMethod = 'cash',
    String? accountId,
    String? receiptUrl,
    String? barcodeValue,
    String? ocrText,
    String? merchantName,
    String? locationName,
    String? tags,
    bool skipDuplicateCheck = false,
  }) async {
    // Note: Duplicate check logic should ideally be here or in a domain service.
    // For this refactor, we are focusing on moving the persistence logic.

    final id = _uuid.v4();

    await _db.insertExpense(ExpensesCompanion.insert(
      id: id,
      budgetId: budgetId,
      semiBudgetId: Value(semiBudgetId),
      categoryId: Value(categoryId),
      subCategoryId: Value(subCategoryId),
      enteredBy: enteredBy,
      title: title,
      amount: amount,
      currency: Value(currency),
      date: date,
      notes: Value(notes),
      paymentMethod: Value(paymentMethod),
      accountId: Value(accountId),
      receiptUrl: Value(receiptUrl),
      barcodeValue: Value(barcodeValue),
      ocrText: Value(ocrText),
      merchantName: Value(merchantName),
      locationName: Value(locationName),
      tags: Value(tags),
      syncState: const Value('dirty'),
      createdAt: Value(DateTime.now()),
      updatedAt: Value(DateTime.now()),
      revision: const Value(1),
    ));

    // Ledger Event
    await _db.logLedgerEvent(
      entityType: 'expense',
      entityId: id,
      eventType: 'EXPENSE_CREATED',
      data: {
        'title': title,
        'amount': amount,
        'currency': currency,
        'date': date.toIso8601String(),
        'budgetId': budgetId,
        'categoryId': categoryId,
        'subCategoryId': subCategoryId,
      },
    );

    // Queue for sync
    try {
      await _outbox.queueEvent(
        entityType: 'expense',
        entityId: id,
        operation: 'create',
        payload: {
          'budgetId': budgetId,
          'semiBudgetId': semiBudgetId,
          'categoryId': categoryId,
          'subCategoryId': subCategoryId,
          'title': title,
          'amount': amount,
          'currency': currency,
          'date': date.toIso8601String(),
          'notes': notes,
          'paymentMethod': paymentMethod,
          'merchantName': merchantName,
        },
        baseRevision: 0,
      );
    } catch (e) {
      // Log error but don't fail operation
      // Logger would be injected here
      print('Repository: Outbox queue failed: $e');
    }

    return id;
  }

  @override
  Future<void> updateExpense({
    required String id,
    String? title,
    int? amount,
    String? currency,
    DateTime? date,
    String? notes,
    String? paymentMethod,
    String? categoryId,
    String? subCategoryId,
    String? semiBudgetId,
    String? budgetId,
    String? merchantName,
    String? tags,
  }) async {
    final existing = await getExpenseById(id);
    if (existing == null) throw Exception('Expense not found: $id');

    await _db.updateExpense(ExpensesCompanion(
      id: Value(id),
      budgetId: Value(budgetId ?? existing.budgetId),
      categoryId: Value(categoryId ?? existing.categoryId),
      subCategoryId: Value(subCategoryId ?? existing.subCategoryId),
      semiBudgetId: Value(semiBudgetId ?? existing.semiBudgetId),
      title: Value(title ?? existing.title),
      amount: Value(amount ?? existing.amount),
      currency: Value(currency ?? existing.currency),
      date: Value(date ?? existing.date),
      notes: Value(notes ?? existing.notes),
      paymentMethod: Value(paymentMethod ?? existing.paymentMethod),
      merchantName: Value(merchantName ?? existing.merchantName),
      tags: Value(tags ?? existing.tags),
      updatedAt: Value(DateTime.now()),
      revision: Value(existing.revision + 1),
      syncState: const Value('dirty'),
    ));

    // Ledger Event
    await _db.logLedgerEvent(
      entityType: 'expense',
      entityId: id,
      eventType: 'EXPENSE_UPDATED',
      data: {
        if (title != null) 'title': title,
        if (amount != null) 'amount': amount,
        if (merchantName != null) 'merchantName': merchantName,
        if (categoryId != null) 'categoryId': categoryId,
        if (subCategoryId != null) 'subCategoryId': subCategoryId,
      },
    );

    try {
      await _outbox.queueEvent(
        entityType: 'expense',
        entityId: id,
        operation: 'update',
        payload: {
          if (title != null) 'title': title,
          if (amount != null) 'amount': amount,
          if (merchantName != null) 'merchantName': merchantName,
          if (semiBudgetId != null) 'semiBudgetId': semiBudgetId,
          if (categoryId != null) 'categoryId': categoryId,
          if (subCategoryId != null) 'subCategoryId': subCategoryId,
          // Add other fields as needed for sync payload
        },
        baseRevision: existing.revision,
      );
    } catch (e) {
      print('Repository: Outbox queue failed: $e');
    }
  }

  @override
  Future<void> deleteExpense(String id) async {
    final existing = await getExpenseById(id);
    if (existing == null) return;

    await _db.deleteExpense(id); // Using soft delete logic in DAO usually

    // Ledger Event
    await _db.logLedgerEvent(
      entityType: 'expense',
      entityId: id,
      eventType: 'EXPENSE_DELETED',
      data: {'deletedAt': DateTime.now().toIso8601String()},
    );

    try {
      await _outbox.queueEvent(
        entityType: 'expense',
        entityId: id,
        operation: 'delete',
        payload: {'deletedAt': DateTime.now().toIso8601String()},
        baseRevision: existing.revision,
      );
    } catch (e) {
      print('Repository: Outbox queue failed: $e');
    }
  }

  @override
  Future<Expense?> getExpenseById(String id) {
    return _db.getExpenseById(id);
  }

  @override
  Future<List<Map<String, dynamic>>> getRecentExpensesMaps({required String userId, int limit = 50}) {
    return _db.getRecentExpensesMaps(userId, limit: limit);
  }

  @override
  Stream<List<Expense>> watchRecentExpenses(String userId, {int limit = 50}) {
    return _db.watchRecentExpenses(userId, limit: limit);
  }

  @override
  Stream<List<Expense>> watchExpensesByBudget(String budgetId) {
    return _db.watchExpensesByBudgetId(budgetId);
  }

  @override
  Stream<List<Expense>> watchExpensesBySemiBudget(String semiBudgetId) {
    return _db.watchExpensesBySemiBudgetId(semiBudgetId);
  }
}
