import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../../data/drift/app_database.dart' as drift_db; // Alias this
import '../../domain/entities/savings_goal.dart';
import '../../domain/failures/savings_goal_failure.dart';
import '../../domain/repositories/savings_goals_repository.dart';
import '../../application/commands/create_goal_cmd.dart';
import '../../application/commands/update_goal_cmd.dart';
import '../../application/commands/contribute_to_goal_cmd.dart';
import '../../application/commands/withdraw_from_goal_cmd.dart';
import '../drift/savings_goals_dao.dart';

class SavingsGoalsRepositoryImpl implements SavingsGoalsRepository {
  final drift_db.AppDatabase db;
  final SavingsGoalsDao dao;

  SavingsGoalsRepositoryImpl(this.db, this.dao);

  @override
  Stream<List<SavingsGoal>> watchGoals() => dao.watchGoals();

  @override
  Future<SavingsGoal?> getGoal(String id) => dao.getGoal(id);

  @override
  Future<void> create(CreateGoalCmd cmd) async {
    final id = const Uuid().v4();
    final goal = cmd.toDomain(id);
    
    // 1. Domain Validation
    try {
      goal.validate();
    } catch (e) {
      if (e is SavingsGoalFailure) rethrow;
      throw ValidationFailure(e.toString());
    }

    // 2. Transaction: Write DB + Write Outbox
    await db.transaction(() async {
      await db.into(db.savingsGoals).insert(cmd.toCompanion(id));
      // Sync handled by DataBatchSync (dirty flag)
    });
  }

  @override
  Future<void> update(UpdateGoalCmd cmd) async {
    await db.transaction(() async {
      // Optimistic Concurrency Check
      final rows = await (db.update(db.savingsGoals)
            ..where((g) => g.id.equals(cmd.id) & g.revision.equals(cmd.revision)))
          .write(cmd.toCompanion());

      if (rows == 0) {
        throw ConcurrencyFailure(); // Remote handled, local outdated
      }

      // Sync handled by DataBatchSync
    });
  }

  @override
  Future<void> contribute(ContributeToGoalCmd cmd) async {
    await db.transaction(() async {
      final goal = await dao.getGoal(cmd.goalId);
      if (goal == null) throw DatabaseFailure("Goal not found");

      // 1. Update Goal Amount
      final freshRow = await (db.select(db.savingsGoals)..where((t) => t.id.equals(cmd.goalId))).getSingle();
      final newAmount = freshRow.currentAmount + cmd.amount;
      final nextRev = freshRow.revision + 1;
      
      await (db.update(db.savingsGoals)..where((g) => g.id.equals(cmd.goalId)))
          .write(drift_db.SavingsGoalsCompanion(
             currentAmount: Value(newAmount),
             revision: Value(nextRev),
             updatedAt: Value(DateTime.now()),
             syncState: const Value('dirty'),
      ));

      // Sync handled by DataBatchSync

      // 2. Create Expense if Budget Linked
      if (cmd.budgetId != null) {
        final expenseId = const Uuid().v4();
        await db.into(db.expenses).insert(cmd.toExpenseCompanion(expenseId));
        
         // Expense Sync also handled by DataBatchSync via dirty flag (set in toExpenseCompanion)
      }
    });
  }

  @override
  Future<void> withdraw(WithdrawFromGoalCmd cmd) async {
    await db.transaction(() async {
      final goal = await dao.getGoal(cmd.goalId);
      if (goal == null) throw DatabaseFailure("Goal not found");

      final newAmount = goal.currentAmount - cmd.amount;
      if (newAmount < 0) throw ValidationFailure("Cannot withdraw more than balance");

      final freshRow = await (db.select(db.savingsGoals)..where((t) => t.id.equals(cmd.goalId))).getSingle();
      final nextRev = freshRow.revision + 1;

      await (db.update(db.savingsGoals)..where((g) => g.id.equals(cmd.goalId)))
          .write(drift_db.SavingsGoalsCompanion(
             currentAmount: Value(newAmount),
             revision: Value(nextRev),
             updatedAt: Value(DateTime.now()),
             syncState: const Value('dirty'),
      ));

      // Sync handled by DataBatchSync
    });
  }

  @override
  Future<void> delete(String id) async {
    await db.transaction(() async {
      final rows = await (db.update(db.savingsGoals)..where((g) => g.id.equals(id)))
          .write(const drift_db.SavingsGoalsCompanion(
        isDeleted: Value(true),
        syncState: Value('dirty'),
      ));

      if (rows == 0) throw DatabaseFailure("Item not found");

      // Sync handled by DataBatchSync
    });
  }

  // OutboxService helper removed in favor of DataBatchSync (Drift/DB)
}
