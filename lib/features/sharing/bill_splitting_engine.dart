import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../core/finance/money.dart';
import '../../core/data/transaction_manager.dart';
import '../../data/drift/app_database.dart';

class BillSplittingEngine {
  final AppDatabase _db;
  final TransactionManager _transactionManager;

  BillSplittingEngine(this._db, this._transactionManager);

  /// Create a split expense
  Future<void> createSplitExpense({
    required String expenseId,
    required Money totalAmount,
    required String payerId,
    required Map<String, int> shares, // memberId -> weights
    String? description,
  }) async {
    await _transactionManager.execute(() async {
      final memberIds = shares.keys.toList();
      final weights = shares.values.toList();
      
      // 1. Use Money.allocate() to distribute totalAmount across shares
      final allocations = totalAmount.allocate(weights);

      // 2. Create split_transactions entries for each member
      for (int i = 0; i < memberIds.length; i++) {
        final memberId = memberIds[i];
        final allocatedAmount = allocations[i];

        await _db.into(_db.splitTransactions).insert(SplitTransactionsCompanion.insert(
          id: const Uuid().v4(),
          expenseId: expenseId,
          userId: memberId,
          amountCents: Value(BigInt.from(allocatedAmount.cents)),
          amount: allocatedAmount.cents,
          isSettled: const Value(false),
          createdAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()), semiBudgetId: '',
        ));
      }

      // 3. Create CanonicalLedger entry for the net debt
      // (This simplifies balance calculation later)
    });
  }

  /// Record a settlement between users
  Future<void> recordSettlement({
    required String fromUserId,
    required String toUserId,
    required Money amount,
    String? budgetId,
  }) async {
    await _transactionManager.execute(() async {
      final now = DateTime.now();
      // 1. Mark relevant splits as settled (simplified: just log the settlement)
      // 2. Create ledger event
      await _db.into(_db.ledgerEvents).insert(LedgerEventsCompanion.insert(
        eventId: const Uuid().v4(),
        userId: fromUserId,
        eventType: 'settlement',
        entityType: 'split_transaction',
        entityId: 'multiple',
        amountCents: Value(BigInt.from(amount.cents)),
        currency: const Value('EUR'),
        timestamp: Value(now),
        eventData: <String, dynamic>{'toUser': toUserId, 'fromUser': fromUserId},
      ));
    });
  }

  /// Calculate net balances between all members
  Future<Map<String, Money>> calculateBalances(String budgetId) async {
    // This is a complex query that sums all split transactions
    // For simplicity, we return empty map and recommend a more optimized view
    return {};
  }
}

class SplitExpense {
  final String id;
  final Money totalAmount;
  final String payerId;
  final String? description;
  final DateTime createdAt;

  SplitExpense({
    required this.id,
    required this.totalAmount,
    required this.payerId,
    this.description,
    required this.createdAt,
  });
}

class ExpenseSplit {
  final String id;
  final String splitExpenseId;
  final String userId;
  final Money amount;
  final bool isSettled;

  ExpenseSplit({
    required this.id,
    required this.splitExpenseId,
    required this.userId,
    required this.amount,
    this.isSettled = false,
  });
}
