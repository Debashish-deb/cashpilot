import 'package:drift/drift.dart';
import '../../data/drift/app_database.dart';
import 'transaction_manager.dart';

class MigrationService {
  final AppDatabase _db;
  final TransactionManager _transactionManager;

  MigrationService(this._db, this._transactionManager);

  /// Performs the Phase 4 data migration from legacy columns to new cent/bps columns
  Future<MigrationReport> migrateToHighPrecision() async {
    final report = MigrationReport();
    
    await _transactionManager.execute(() async {
      // 1. Budgets: totalLimit -> totalLimitCents
      final budgetsToMigrate = await (_db.select(_db.budgets)..where((t) => t.totalLimitCents.isNull() & t.totalLimit.isNotNull())).get();
      for (final b in budgetsToMigrate) {
        await (_db.update(_db.budgets)..where((t) => t.id.equals(b.id))).write(BudgetsCompanion(
          totalLimitCents: Value(b.totalLimit != null ? BigInt.from(b.totalLimit!) : null),
        ));
        report.increment('budgets');
      }

      // 2. Expenses: amount -> amountCents, confidence -> confidenceBps
      final expensesToMigrate = await (_db.select(_db.expenses)..where((t) => t.amountCents.isNull() & t.amount.isNotNull())).get();
      for (final e in expensesToMigrate) {
        await (_db.update(_db.expenses)..where((t) => t.id.equals(e.id))).write(ExpensesCompanion(
          amountCents: Value(BigInt.from(e.amount)),
          confidenceBps: Value(BigInt.from((e.confidence * 10000).round())),
        ));
        report.increment('expenses');
      }

      // 3. Accounts: balance -> balanceCents
      final accountsToMigrate = await (_db.select(_db.accounts)..where((t) => t.balanceCents.isNull() & t.balance.isNotNull())).get();
      for (final a in accountsToMigrate) {
        await (_db.update(_db.accounts)..where((t) => t.id.equals(a.id))).write(AccountsCompanion(
          balanceCents: Value(BigInt.from(a.balance)),
        ));
        report.increment('accounts');
      }

      // 4. SemiBudgets: limitAmount -> limitAmountCents, suggestedPercent -> suggestedPercentBps
      final semiBudgetsToMigrate = await (_db.select(_db.semiBudgets)..where((t) => t.limitAmountCents.isNull() & t.limitAmount.isNotNull())).get();
      for (final s in semiBudgetsToMigrate) {
        await (_db.update(_db.semiBudgets)..where((t) => t.id.equals(s.id))).write(SemiBudgetsCompanion(
          limitAmountCents: Value(BigInt.from(s.limitAmount)),
          suggestedPercentBps: Value(BigInt.from(((s.suggestedPercent ?? 0) * 100).round())),
        ));
        report.increment('semi_budgets');
      }

      // 5. Liabilities: interestRate -> interestRateBps
      final liabilitiesToMigrate = await (_db.select(_db.liabilities)..where((t) => t.interestRateBps.isNull() & t.interestRate.isNotNull())).get();
      for (final l in liabilitiesToMigrate) {
        await (_db.update(_db.liabilities)..where((t) => t.id.equals(l.id))).write(LiabilitiesCompanion(
          interestRateBps: Value(BigInt.from(((l.interestRate ?? 0) * 100).round())),
          currentBalanceCents: Value(BigInt.from(l.currentBalance)),
          minPaymentCents: Value(l.minPayment != null ? BigInt.from(l.minPayment!) : null),
        ));
        report.increment('liabilities');
      }

      // 6. SavingsGoals: currentAmount -> currentAmountCents, targetAmount -> targetAmountCents
      final goalsToMigrate = await (_db.select(_db.savingsGoals)..where((t) => t.currentAmountCents.isNull() & t.currentAmount.isNotNull())).get();
      for (final g in goalsToMigrate) {
        await (_db.update(_db.savingsGoals)..where((t) => t.id.equals(g.id))).write(SavingsGoalsCompanion(
          currentAmountCents: Value(BigInt.from(g.currentAmount)),
          targetAmountCents: Value(BigInt.from(g.targetAmount)),
        ));
        report.increment('savings_goals');
      }
      
      // Add more tables as needed (Assets, ValuationHistory, etc.)
    });
    
    return report;
  }
}

class MigrationReport {
  final Map<String, int> migratedCounts = {};
  
  void increment(String table) {
    migratedCounts[table] = (migratedCounts[table] ?? 0) + 1;
  }
  
  @override
  String toString() => 'Migration Report: $migratedCounts';
}
