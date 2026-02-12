import '../../data/drift/app_database.dart'; // For Expense class (Drift generated)

/// Interface for Expense data operations
/// 
/// Decouples domain logic from strict data implementation (Drift/Supabase)
abstract class IExpenseRepository {
  /// Create a new expense
  /// Returns the generated ID
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
  });

  /// Update an existing expense
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
  });

  /// Delete an expense (soft delete)
  Future<void> deleteExpense(String id);

  /// Get a single expense by ID
  Future<Expense?> getExpenseById(String id);

  /// Helper for duplicate detection
  Future<List<Map<String, dynamic>>> getRecentExpensesMaps({required String userId, int limit = 50});

  // ---------------------------------------------------------------------------
  // STREAMS (Reactive Data)
  // ---------------------------------------------------------------------------

  /// Watch recent expenses for a user
  Stream<List<Expense>> watchRecentExpenses(String userId, {int limit = 50});

  /// Watch expenses for a specific budget
  Stream<List<Expense>> watchExpensesByBudget(String budgetId);

  /// Watch expenses for a specific category (semi-budget)
  Stream<List<Expense>> watchExpensesBySemiBudget(String semiBudgetId);
}
