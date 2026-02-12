import 'package:cashpilot/data/drift/app_database.dart' show $AccountsTable, $SavingsGoalsTable, $UsersTable;
import 'package:drift/drift.dart';
import '../../../../data/drift/app_database.dart' as drift_db;

import '../../../../data/drift/tables.dart';
import '../../domain/entities/savings_goal.dart';

part 'savings_goals_dao.g.dart';

@DriftAccessor(tables: [SavingsGoals])
class SavingsGoalsDao extends DatabaseAccessor<drift_db.AppDatabase> with _$SavingsGoalsDaoMixin {
  SavingsGoalsDao(super.db);

  Stream<List<SavingsGoal>> watchGoals() {
    return (select(savingsGoals)
          ..where((t) => t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]))
        .watch()
        .map((rows) => rows.map((r) => _toDomain(r)).toList());
  }

  Future<SavingsGoal?> getGoal(String id) async {
    final row = await (select(savingsGoals)..where((t) => t.id.equals(id))).getSingleOrNull();
    return row != null ? _toDomain(row) : null;
  }

  SavingsGoal _toDomain(drift_db.SavingsGoal row) {
    return SavingsGoal(
      id: row.id,
      userId: row.userId,
      title: row.title,
      targetAmount: row.targetAmount,
      currentAmount: row.currentAmount,
      deadline: row.deadline,
      iconName: row.iconName,
      colorHex: row.colorHex,
      revision: row.revision,
      isArchived: row.isArchived,
      isDeleted: row.isDeleted,
    );
  }
}
