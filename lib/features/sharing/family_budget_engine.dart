import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../core/finance/money.dart';
import '../../core/data/transaction_manager.dart';
import '../../data/drift/app_database.dart';

enum FamilyRole {
  owner,     // Complete control, can delete budget, manage members
  admin,     // Can add/remove members (except owner), approve expenses
  member,    // Can view and spend within limits
  viewer;    // Read-only access

  bool get canApprove => this == FamilyRole.owner || this == FamilyRole.admin;
  bool get canManageMembers => this == FamilyRole.owner || this == FamilyRole.admin;
  bool get canEditBudget => this == FamilyRole.owner || this == FamilyRole.admin;
  
  static FamilyRole fromString(String value) {
    return FamilyRole.values.firstWhere(
      (e) => e.name == value,
      orElse: () => FamilyRole.member,
    );
  }
}

class FamilyBudgetEngine {
  final AppDatabase _db;
  final TransactionManager _transactionManager;

  FamilyBudgetEngine(this._db, this._transactionManager);

  /// Create a new family budget
  Future<void> createFamilyBudget({
    required String ownerId,
    required String ownerEmail,
    required String name,
    required Money totalBudget,
  }) async {
    final budgetId = const Uuid().v4();
    final now = DateTime.now();

    await _transactionManager.execute(() async {
      // 1. Create budget entry
      await _db.into(_db.budgets).insert(BudgetsCompanion.insert(
        id: budgetId,
        ownerId: ownerId,
        title: name,
        type: 'family',
        startDate: now,
        endDate: now.add(const Duration(days: 30)),
        totalLimitCents: Value(BigInt.from(totalBudget.cents)),
        totalLimit: Value(totalBudget.cents),
        currency: Value(totalBudget.currency.name),
        isShared: const Value(true),
        createdAt: Value(now),
        updatedAt: Value(now),
      ));

      // 2. Add owner to budget_members
      await _db.into(_db.budgetMembers).insert(BudgetMembersCompanion.insert(
        id: const Uuid().v4(),
        budgetId: budgetId,
        userId: Value(ownerId),
        memberEmail: ownerEmail,
        role: FamilyRole.owner.name,
        status: const Value('active'),
        invitedAt: Value(now),
        acceptedAt: Value(now),
        createdAt: Value(now),
        updatedAt: Value(now),
      ));
    });
  }

  /// Add a member to the budget
  Future<void> addMember({
    required String budgetId,
    required String invitedBy,
    required String memberEmail,
    required FamilyRole role,
    Money? spendingLimit,
  }) async {
    await _transactionManager.execute(() async {
      // 1. Verify invitedBy has canManageMembers permission
      final inviter = await (_db.select(_db.budgetMembers)
            ..where((t) => t.budgetId.equals(budgetId) & t.userId.equals(invitedBy)))
          .getSingleOrNull();
      
      if (inviter == null || !FamilyRole.fromString(inviter.role).canManageMembers) {
        throw Exception('Permission denied: Only owners and admins can invite members');
      }

      // 2. Check if member already exists
      final existing = await (_db.select(_db.budgetMembers)
            ..where((t) => t.budgetId.equals(budgetId) & t.memberEmail.equals(memberEmail)))
          .getSingleOrNull();
      
      if (existing != null) {
        throw Exception('Member already invited or part of this budget');
      }

      // 3. Add to budget_members
      await _db.into(_db.budgetMembers).insert(BudgetMembersCompanion.insert(
        id: const Uuid().v4(),
        budgetId: budgetId,
        memberEmail: memberEmail,
        role: role.name,
        invitedBy: Value(invitedBy),
        spendingLimit: Value(spendingLimit?.cents),
        spendingLimitCents: Value(spendingLimit != null ? BigInt.from(spendingLimit.cents) : null),
        status: const Value('pending'),
        invitedAt: Value(DateTime.now()),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ));
    });
  }

  /// Update a member's role or limit
  Future<void> updateMember({
    required String budgetId,
    required String updaterId,
    required String memberEmail,
    FamilyRole? newRole,
    Money? newLimit,
  }) async {
    await _transactionManager.execute(() async {
      // 1. Verify updaterId has canManageMembers permission
      final updater = await (_db.select(_db.budgetMembers)
            ..where((t) => t.budgetId.equals(budgetId) & t.userId.equals(updaterId)))
          .getSingleOrNull();

      if (updater == null || !FamilyRole.fromString(updater.role).canManageMembers) {
        throw Exception('Permission denied');
      }

      // 2. Update record
      await (_db.update(_db.budgetMembers)
            ..where((t) => t.budgetId.equals(budgetId) & t.memberEmail.equals(memberEmail)))
          .write(BudgetMembersCompanion(
        role: newRole != null ? Value(newRole.name) : const Value.absent(),
        spendingLimit: newLimit != null ? Value(newLimit.cents) : const Value.absent(),
        spendingLimitCents: newLimit != null ? Value(BigInt.from(newLimit.cents)) : const Value.absent(),
        updatedAt: Value(DateTime.now()),
      ));
    });
  }

  /// Verify if a member can perform a spend operation
  Future<bool> canSpend({
    required String budgetId,
    required String memberId,
    required Money amount,
  }) async {
    // 1. Fetch member's role and limit
    final member = await (_db.select(_db.budgetMembers)
          ..where((t) => t.budgetId.equals(budgetId) & t.userId.equals(memberId)))
        .getSingleOrNull();
    
    if (member == null) return false;
    if (member.role == FamilyRole.viewer.name) return false;
    
    // 2. Fetch member's current spending in this period
    // (This would typically involve a sum query on expenses)
    final totalSpent = await _db.getTotalSpentInBudget(budgetId); // Placeholder - needs per-member if strict
    
    // 3. Check if role permits spending and amount is within limit
    final limit = member.spendingLimitCents ?? (member.spendingLimit != null ? BigInt.from(member.spendingLimit!) : null);
    if (limit != null) {
      if (BigInt.from(amount.cents) > limit) return false;
    }
    
    return true; 
  }
}

class BudgetMember {
  final String id;
  final String userId;
  final String budgetId;
  final FamilyRole role;
  final Money? spendingLimit;
  final Money currentSpent;

  BudgetMember({
    required this.id,
    required this.userId,
    required this.budgetId,
    required this.role,
    this.spendingLimit,
    required this.currentSpent,
  });
}
