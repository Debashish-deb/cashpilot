import '../../../data/drift/app_database.dart';
import 'package:drift/drift.dart';
import '../models/export_bundle.dart';

class SecurityPrivacyLayer {
  /// Masks PII (Personally Identifiable Information) in the [ExportBundle].
  ExportBundle applyPrivacyFilter(ExportBundle bundle, {bool maskNotes = true, bool maskMerchant = false}) {
    final maskedExpenses = bundle.expenses.map((e) {
      return e.copyWith(
        notes: Value(maskNotes ? (e.notes != null ? '***' : null) : e.notes),
        merchantName: Value(maskMerchant ? (e.merchantName != null ? 'REDACTED' : null) : e.merchantName),
      );
    }).toList();

    return ExportBundle(
      expenses: maskedExpenses,
      categoryTotals: bundle.categoryTotals,
      monthlyTotals: bundle.monthlyTotals,
      budgetSummaries: bundle.budgetSummaries,
      vatSummary: bundle.vatSummary,
      auditTrail: bundle.auditTrail,
    );
  }

  /// Filters expenses based on user role (Owner, Member, etc.)
  List<Expense> filterByRole(List<Expense> expenses, String userRole) {
    if (userRole == 'viewer') {
      // Viewers might only see non-sensitive categories? 
      // For now, return all, but this is the hook for RBAC.
      return expenses;
    }
    return expenses;
  }
}
