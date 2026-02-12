import 'dart:async';
import 'package:drift/drift.dart';
import '../../data/drift/app_database.dart';
import '../../domain/cfse/financial_state.dart';
import '../../domain/cfse/i_financial_state_engine.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';

class FinancialStateEngine implements IFinancialStateEngine {
  final AppDatabase _db;

  FinancialStateEngine(this._db);

  @override
  Future<FinancialState> getCurrentState(String userId) async {
    return _computeState(userId);
  }

  @override
  Stream<FinancialState> watchState(String userId) {
    // We combine multiple streams to trigger re-computation
    // In a production app, we would use a more optimized approach with selective invalidation
    final expensesStream = _db.watchAllExpenses(userId);
    final budgetsStream = _db.watchAccessibleBudgets(userId, ''); // Simplified for now
    final assetsStream = _db.watchAssets(userId);
    final liabilitiesStream = _db.watchLiabilities(userId);

    return StreamGroup.merge([
      expensesStream,
      budgetsStream,
      assetsStream,
      liabilitiesStream,
    ]).asyncMap((_) => _computeState(userId));
  }

  @override
  Future<void> reconcile(String userId) async {
    // 1. Reconcile raw Bank/OCR facts into the Canonical Ledger
    await _reconcileLedger(userId);
    
    // 2. Compute the state from the Ledger (The Truth)
    final state = await _computeState(userId);
    await recordHealthSnapshot(userId, state);
  }

  @override
  Future<void> recordHealthSnapshot(String userId, FinancialState state) async {
    await _db.into(_db.budgetHealthSnapshots).insert(
      BudgetHealthSnapshotsCompanion.insert(
        id: Uuid().v4(),
        userId: userId,
        overallScore: state.budgetHealth,
        metricsJson: jsonEncode({
          'cashPosition': state.cashPosition,
          'burnRate': state.monthlyBurnRate,
          'netWorth': state.netWorth,
          'riskProfile': state.riskProfile.name,
        }),
        timestamp: Value(DateTime.now()),
      ),
    );
  }

  Future<bool> _checkImmutability(String bankTransactionId) async {
    final entry = await (_db.select(_db.canonicalLedger)
          ..where((t) => t.sourceReference.equals(bankTransactionId)))
        .getSingleOrNull();
    return entry?.verificationStatus == 'verified';
  }

  Future<void> _reconcileLedger(String userId) async {
    // Implementation for merging Bank transactions into Ledger
    // This is where Layer 6 (Hierarchy) is applied.
  }

  @override
  Future<String?> validateProposedChange(String userId, Object changePayload) async {
    // TRUTH BOUNDARY: Prevent client from overriding immutable bank data
    if (changePayload is ExpensesCompanion) {
      if (changePayload.bankTransactionId.present) {
        final txId = changePayload.bankTransactionId.value;
        if (txId != null) {
          final isImmutable = await _checkImmutability(txId);
          if (isImmutable) {
            return 'Security Violation: Cannot modify immutable bank record.';
          }
        }
      }
    }
    
    final current = await getCurrentState(userId);
    // ... existing safety logic
    
    return null;
  }

  Future<FinancialState> _computeState(String userId) async {
    // 1. Fetch all raw signals
    final assets = await _db.getAssets(userId);
    final liabilities = await _db.getLiabilities(userId);
    final expenses = await _db.getExpenses(userId);
    final budgets = await (_db.select(_db.budgets)..where((t) => t.ownerId.equals(userId))).get();

    // 2. Resolve Cash Position (Total Assets Type 'cash' or 'checking')
    int cashPosition = 0;
    int totalInvestments = 0;
    for (final asset in assets) {
      if (asset.type == 'cash' || asset.type == 'checking' || asset.type == 'savings') {
        cashPosition += asset.currentValue;
      } else if (asset.type == 'investment' || asset.type == 'crypto') {
        totalInvestments += asset.currentValue;
      }
    }

    // 3. Resolve Net Worth
    int totalAssets = assets.fold(0, (sum, a) => sum + a.currentValue);
    int totalLiabilities = liabilities.fold(0, (sum, l) => sum + l.currentBalance);
    int netWorth = totalAssets - totalLiabilities;

    // 4. Resolve Burn Rate (Rolling 30 days)
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    final recentExpenses = expenses.where((e) => e.date.isAfter(thirtyDaysAgo)).toList();
    int monthlyBurnRate = recentExpenses.fold(0, (sum, e) => sum + e.amount);

    // 5. Resolve Budget Health
    double budgetHealth = 1.0;
    if (budgets.isNotEmpty) {
      int totalLimit = budgets.fold(0, (sum, b) => sum + (b.totalLimit ?? 0));
      if (totalLimit > 0) {
        // Find expenses belonging to these budgets
        final budgetIds = budgets.map((b) => b.id).toSet();
        int budgetSpent = expenses
            .where((e) => budgetIds.contains(e.budgetId) && e.date.isAfter(thirtyDaysAgo))
            .fold(0, (sum, e) => sum + e.amount);
            
        double ratio = budgetSpent / totalLimit;
        budgetHealth = (1.0 - ratio).clamp(0.0, 1.0);
      }
    }

    // 6. Resolve Savings Rate (Simplified: Net Worth Growth / Income placeholder)
    // For now, let's just use a dummy calculation until we have an Income model
    double savingsRate = 0.15; // 15% default fallback

    // 7. Resolve Risk Profile
    RiskProfile profile = RiskProfile.moderate;
    if (monthlyBurnRate > cashPosition && cashPosition > 0) {
      profile = RiskProfile.critical;
    } else if (cashPosition > monthlyBurnRate * 6) {
      profile = RiskProfile.conservative;
    } else if (totalInvestments > totalAssets * 0.7) {
      profile = RiskProfile.aggressive;
    }

    return FinancialState(
      timestamp: DateTime.now(),
      cashPosition: cashPosition,
      monthlyBurnRate: monthlyBurnRate,
      savingsRate: savingsRate,
      investmentExposure: totalAssets > 0 ? totalInvestments / totalAssets : 0.0,
      netWorth: netWorth,
      budgetHealth: budgetHealth,
      riskProfile: profile,
      goalProgress: 0.5, // Placeholder
    );
  }
}

/// Helper for merging streams (simplified for this context)
class StreamGroup {
  static Stream<void> merge(List<Stream<dynamic>> streams) {
    final controller = StreamController<void>.broadcast();
    for (final stream in streams) {
      stream.listen((_) => controller.add(null), onError: (_) {});
    }
    return controller.stream;
  }
}
