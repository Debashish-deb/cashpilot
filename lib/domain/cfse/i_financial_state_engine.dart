import 'financial_state.dart';

/// Interface for the Canonical Financial State Engine (CFSE).
/// 
/// The CFSE is responsible for:
/// 1. Reconciling data from multiple sub-systems (Budget, Expenses, etc.)
/// 2. Resolving conflicts between "parallel truths"
/// 3. Providing a single, authoritative stream of financial state.
abstract class IFinancialStateEngine {
  /// Stream of the most current financial state.
  /// 
  /// This stream emits whenever any underlying signal (expense, budget update, etc.)
  /// changes the financial reality.
  Stream<FinancialState> watchState(String userId);

  /// Get a snapshot of the current state.
  Future<FinancialState> getCurrentState(String userId);

  /// Forces a full reconciliation of the financial state.
  /// 
  /// Useful after sync operations or significant batch updates.
  Future<void> reconcile(String userId);

  /// Validates a proposed change against the current financial engine.
  Future<String?> validateProposedChange(String userId, Object changePayload);

  /// Records a snapshot of the current budget health.
  Future<void> recordHealthSnapshot(String userId, FinancialState state);
}
