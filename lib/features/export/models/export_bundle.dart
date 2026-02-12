import '../../../data/drift/app_database.dart';
import 'audit_trail.dart';
import 'budget_summary.dart';
import 'vat_summary.dart';

class ExportBundle {
  final List<Expense> expenses;
  final Map<String, double> categoryTotals;
  final Map<String, double> monthlyTotals;
  final List<BudgetSummary> budgetSummaries;
  final VatSummary vatSummary;
  final AuditTrail auditTrail;

  ExportBundle({
    required this.expenses,
    required this.categoryTotals,
    required this.monthlyTotals,
    required this.budgetSummaries,
    required this.vatSummary,
    required this.auditTrail,
  });

  Map<String, dynamic> toJson() => {
        'expenses': expenses.map((e) => e.toJson()).toList(),
        'categoryTotals': categoryTotals,
        'monthlyTotals': monthlyTotals,
        'budgetSummaries': budgetSummaries.map((b) => b.toJson()).toList(),
        'vatSummary': vatSummary.toJson(),
        'auditTrail': auditTrail.toJson(),
      };
}
