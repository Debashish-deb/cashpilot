import 'package:drift/drift.dart' as drift;
import '../../../../data/drift/app_database.dart' as drift_db;

class ContributeToGoalCmd {
  final String goalId;
  final int amount; // Amount to add (in cents)
  final String? budgetId; // Optional: Budget to deduct from (creates an expense)
  final String? accountId; // Optional: Account to pay from
  final String userId;
  final DateTime date;
  
  ContributeToGoalCmd({
    required this.goalId,
    required this.amount,
    required this.userId,
    this.budgetId,
    this.accountId,
    DateTime? date,
  }) : date = date ?? DateTime.now();

  // Helper to create the Expense companion (if budgetId is provided)
  drift_db.ExpensesCompanion toExpenseCompanion(String expenseId) {
    return drift_db.ExpensesCompanion(
      id: drift.Value(expenseId),
      enteredBy: drift.Value(userId),
      budgetId: drift.Value(budgetId!),
      title: const drift.Value("Savings Contribution"),
      amount: drift.Value(amount),
      date: drift.Value(date),
      accountId: drift.Value(accountId),
      isDeleted: const drift.Value(false),
      syncState: const drift.Value('dirty'),
      revision: const drift.Value(1),
      // We might want to tag it?
      notes: const drift.Value("Contribution to Savings Goal"),
    );
  }
}
