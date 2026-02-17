// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'savings_goals_dao.dart';

// ignore_for_file: type=lint
mixin _$SavingsGoalsDaoMixin on DatabaseAccessor<drift_db.AppDatabase> {
  $UsersTable get users => attachedDatabase.users;
  $AccountsTable get accounts => attachedDatabase.accounts;
  $SavingsGoalsTable get savingsGoals => attachedDatabase.savingsGoals;
  SavingsGoalsDaoManager get managers => SavingsGoalsDaoManager(this);
}

class SavingsGoalsDaoManager {
  final _$SavingsGoalsDaoMixin _db;
  SavingsGoalsDaoManager(this._db);
  $$UsersTableTableManager get users =>
      $$UsersTableTableManager(_db.attachedDatabase, _db.users);
  $$AccountsTableTableManager get accounts =>
      $$AccountsTableTableManager(_db.attachedDatabase, _db.accounts);
  $$SavingsGoalsTableTableManager get savingsGoals =>
      $$SavingsGoalsTableTableManager(_db.attachedDatabase, _db.savingsGoals);
}
