import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../core/finance/money.dart';
import '../../core/data/transaction_manager.dart';
import '../../data/drift/app_database.dart';
import 'family_budget_engine.dart';

enum ApprovalStatus {
  pending,
  approved,
  rejected;
}

class ExpenseApprovalWorkflow {
  final AppDatabase _db;
  final TransactionManager _transactionManager;

  ExpenseApprovalWorkflow(this._db, this._transactionManager);

  /// Submit an expense for approval if it exceeds member's limit
  Future<bool> processExpenseSubmission({
    required String expenseId,
    required String memberId,
    required Money amount,
    required Money limit,
  }) async {
    return await _transactionManager.execute(() async {
      if (amount.cents > limit.cents) {
        await _db.into(_db.expenseApprovals).insert(ExpenseApprovalsCompanion.insert(
          id: const Uuid().v4(),
          expenseId: expenseId,
          status: const Value('pending'),
          createdAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
          approvedBy: const Value(null),
        ));
        return true; // Requires approval
      }
      return false; // Auto-approved
    });
  }

  /// Approve an expense
  Future<void> approveExpense({
    required String approvalId,
    required String adminId,
  }) async {
    await _transactionManager.execute(() async {
      final now = DateTime.now();
      
      // 1. Verify adminId has canApprove role
      final approval = await (_db.select(_db.expenseApprovals)..where((t) => t.id.equals(approvalId))).getSingle();
      final expense = await (_db.select(_db.expenses)..where((t) => t.id.equals(approval.expenseId))).getSingle();
      
      final adminMember = await (_db.select(_db.budgetMembers)
            ..where((t) => t.budgetId.equals(expense.budgetId) & t.userId.equals(adminId)))
          .getSingleOrNull();

      if (adminMember == null || !FamilyRole.fromString(adminMember.role).canApprove) {
        throw Exception('Permission denied: Only owners and admins can approve expenses');
      }

      // 2. Update status to approved
      await (_db.update(_db.expenseApprovals)..where((t) => t.id.equals(approvalId))).write(ExpenseApprovalsCompanion(
        status: const Value('approved'),
        approvedBy: Value(adminId),
        updatedAt: Value(now),
      ));

      // 3. Mark expense as verified
      await (_db.update(_db.expenses)..where((t) => t.id.equals(approval.expenseId))).write(const ExpensesCompanion(
        isVerified: Value(true),
      ));
    });
  }

  /// Reject an expense
  Future<void> rejectExpense({
    required String approvalId,
    required String adminId,
    String? reason,
  }) async {
    await _transactionManager.execute(() async {
      final now = DateTime.now();
      
      // 1. Verify adminId has canApprove role
      final approval = await (_db.select(_db.expenseApprovals)..where((t) => t.id.equals(approvalId))).getSingle();
      final expense = await (_db.select(_db.expenses)..where((t) => t.id.equals(approval.expenseId))).getSingle();
      
      final adminMember = await (_db.select(_db.budgetMembers)
            ..where((t) => t.budgetId.equals(expense.budgetId) & t.userId.equals(adminId)))
          .getSingleOrNull();

      if (adminMember == null || !FamilyRole.fromString(adminMember.role).canApprove) {
        throw Exception('Permission denied');
      }

      // 2. Update status to rejected
      await (_db.update(_db.expenseApprovals)..where((t) => t.id.equals(approvalId))).write(ExpenseApprovalsCompanion(
        status: const Value('rejected'),
        rejectionReason: Value(reason),
        updatedAt: Value(now),
      ));

      // 3. Mark expense as deleted or rejected
      await (_db.update(_db.expenses)..where((t) => t.id.equals(approval.expenseId))).write(const ExpensesCompanion(
        isDeleted: Value(true), // Rejection results in deletion/cancellation for now
      ));
    });
  }
}
