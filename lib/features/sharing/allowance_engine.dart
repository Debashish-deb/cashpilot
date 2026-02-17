import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../core/finance/money.dart';
import '../../core/data/transaction_manager.dart';
import '../../data/drift/app_database.dart';

enum AllowanceFrequency {
  daily,
  weekly,
  biweekly,
  monthly;
}

class AllowanceEngine {
  final AppDatabase _db;
  final TransactionManager _transactionManager;

  AllowanceEngine(this._db, this._transactionManager);

  /// Create an allowance rule
  Future<void> createAllowanceRule({
    required String budgetId,
    required String memberId,
    required Money amount,
    required AllowanceFrequency frequency,
    DateTime? startDate,
  }) async {
    final start = startDate ?? DateTime.now();
    await _transactionManager.execute(() async {
      await _db.into(_db.allowances).insert(AllowancesCompanion.insert(
        id: const Uuid().v4(),
        budgetId: budgetId,
        userId: memberId,
        amountCents: BigInt.from(amount.cents),
        frequency: frequency.name,
        nextPayoutDate: _calculateNextPayout(start, frequency),
        isActive: const Value(true),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ));
    });
  }

  /// Process all due allowances
  Future<void> processAllowances() async {
    final now = DateTime.now();
    await _transactionManager.execute(() async {
      // 1. Fetch all active allowance rules that are due
      final dueAllowances = await (_db.select(_db.allowances)
            ..where((t) => t.isActive.equals(true) & t.nextPayoutDate.isSmallerOrEqualValue(now)))
          .get();

      for (final allowance in dueAllowances) {
        // 2. Create transaction/expense for allowance
        await _db.into(_db.expenses).insert(ExpensesCompanion.insert(
          id: const Uuid().v4(),
          budgetId: allowance.budgetId,
          enteredBy: allowance.userId, // Or a system user?
          title: 'Allowance Payout',
          amountCents: Value(allowance.amountCents),
          amount: allowance.amountCents.toInt(),
          currency: const Value('EUR'), // Should probably come from budget
          date: now,
          createdAt: Value(now),
          updatedAt: Value(now),
          source: const Value('system'),
        ));

        // 3. Update nextPayoutDate
        final frequency = AllowanceFrequency.values.firstWhere((e) => e.name == allowance.frequency);
        await (_db.update(_db.allowances)..where((t) => t.id.equals(allowance.id))).write(AllowancesCompanion(
          nextPayoutDate: Value(_calculateNextPayout(allowance.nextPayoutDate, frequency)),
          updatedAt: Value(now),
        ));
      }
    });
  }

  /// Manually trigger a one-time allowance
  Future<void> triggerOneTimeAllowance({
    required String budgetId,
    required String memberId,
    required Money amount,
    String? reason,
  }) async {
    final now = DateTime.now();
    await _transactionManager.execute(() async {
      // 1. Create a one-time expense record
      await _db.into(_db.expenses).insert(ExpensesCompanion.insert(
        id: const Uuid().v4(),
        budgetId: budgetId,
        enteredBy: memberId,
        title: reason ?? 'One-time Allowance',
        amountCents: Value(BigInt.from(amount.cents)),
        amount: amount.cents,
        currency: const Value('EUR'),
        date: now,
        createdAt: Value(now),
        updatedAt: Value(now),
        source: const Value('manual'),
      ));
    });
  }

  DateTime _calculateNextPayout(DateTime current, AllowanceFrequency frequency) {
    switch (frequency) {
      case AllowanceFrequency.daily:
        return current.add(const Duration(days: 1));
      case AllowanceFrequency.weekly:
        return current.add(const Duration(days: 7));
      case AllowanceFrequency.biweekly:
        return current.add(const Duration(days: 14));
      case AllowanceFrequency.monthly:
        return DateTime(current.year, current.month + 1, current.day);
    }
  }
}

class AllowanceRule {
  final String id;
  final String budgetId;
  final String memberId;
  final Money amount;
  final AllowanceFrequency frequency;
  final DateTime lastProcessedAt;
  final bool isActive;

  AllowanceRule({
    required this.id,
    required this.budgetId,
    required this.memberId,
    required this.amount,
    required this.frequency,
    required this.lastProcessedAt,
    this.isActive = true,
  });
}
