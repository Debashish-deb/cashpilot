import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../core/finance/money.dart';
import '../../core/data/transaction_manager.dart';
import '../../data/drift/app_database.dart';

class SharedGoalsEngine {
  final AppDatabase _db;
  final TransactionManager _transactionManager;

  SharedGoalsEngine(this._db, this._transactionManager);

  /// Create a shared goal
  Future<void> createGoal({
    required String userId,
    required String name,
    required Money targetAmount,
    DateTime? deadline,
  }) async {
    await _transactionManager.execute(() async {
      await _db.into(_db.savingsGoals).insert(SavingsGoalsCompanion.insert(
        id: const Uuid().v4(),
        userId: userId,
        title: name,
        targetAmountCents: Value(BigInt.from(targetAmount.cents)),
        currentAmountCents: Value(BigInt.zero),
        deadline: Value(deadline),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
        targetAmount: 0, // Legacy required
      ));
    });
  }

  /// Contribute to a goal
  Future<void> contributeToGoal({
    required String goalId,
    required String memberId,
    required Money amount,
  }) async {
    await _transactionManager.execute(() async {
      // 1. Fetch current goal state
      final goal = await (_db.select(_db.savingsGoals)..where((t) => t.id.equals(goalId))).getSingle();
      
      // 2. Update goal current_amount
      final newAmount = goal.currentAmountCents + BigInt.from(amount.cents);
      await (_db.update(_db.savingsGoals)..where((t) => t.id.equals(goalId))).write(SavingsGoalsCompanion(
        currentAmountCents: Value(newAmount),
        updatedAt: Value(DateTime.now()),
      ));

      // 3. Log activity
      await _db.into(_db.activityLogs).insert(ActivityLogsCompanion.insert(
        id: const Uuid().v4(),
        budgetId: 'shared', // Placeholder or real ID
        userId: memberId,
        action: 'contribution',
        entityType: 'savings_goal',
        entityId: Value(goalId),
        createdAt: Value(DateTime.now()),
      ));
    });
  }

  /// Automatically contribute budget surplus to a goal
  Future<void> autoSaveSurplus({
    required String budgetId,
    required String goalId,
    required String userId,
  }) async {
    await _transactionManager.execute(() async {
      // 1. Calculate unspent budget for current period
      final budget = await _db.getBudgetById(budgetId);
      if (budget == null || budget.totalLimitCents == null) return;

      final spent = await _db.getTotalSpentInBudget(budgetId);
      final surplus = budget.totalLimitCents! - spent;

      if (surplus > BigInt.zero) {
        // 2. Transfer it to the goal
        await contributeToGoal(
          goalId: goalId,
          memberId: userId,
          amount: Money(surplus.toInt(), Currency.EUR),
        );
      }
    });
  }

  /// Withdraw funds from a completed goal (e.g., to purchase)
  Future<void> releaseGoalFunds({
    required String goalId,
    required String approvedById,
    required Money amount,
  }) async {
    await _transactionManager.execute(() async {
      // 1. Verify goal has sufficient funds
      final goal = await (_db.select(_db.savingsGoals)..where((t) => t.id.equals(goalId))).getSingle();
      if (goal.currentAmountCents < BigInt.from(amount.cents)) {
        throw Exception('Insufficient funds in goal');
      }

      // 2. Update goal balance
      await (_db.update(_db.savingsGoals)..where((t) => t.id.equals(goalId))).write(SavingsGoalsCompanion(
        currentAmountCents: Value(goal.currentAmountCents - BigInt.from(amount.cents)),
        updatedAt: Value(DateTime.now()),
      ));
    });
  }
}

class SharedGoal {
  final String id;
  final String budgetId;
  final String name;
  final Money targetAmount;
  final Money currentAmount;
  final DateTime? deadline;
  final bool isCompleted;

  SharedGoal({
    required this.id,
    required this.budgetId,
    required this.name,
    required this.targetAmount,
    required this.currentAmount,
    this.deadline,
    this.isCompleted = false,
  });

  double get progress => currentAmount.cents / targetAmount.cents;
}
