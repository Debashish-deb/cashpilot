import '../../../data/drift/app_database.dart';
import '../models/budget_summary.dart';
import '../models/export_bundle.dart';
import '../models/vat_summary.dart';
import '../models/audit_trail.dart';

class ExportIntelligenceEngine {
  /// Aggregates a list of expenses into an [ExportBundle].
  /// [defaultVatRate] is used if no specific VAT is found (e.g., 0.20 for 20%).
  Future<ExportBundle> generateBundle({
    required List<Expense> expenses,
    required List<Budget> budgets,
    required String generatedBy,
    required String exportFormat,
    double defaultVatRate = 0.0,
  }) async {
    final categoryTotals = <String, double>{};
    final monthlyTotals = <String, double>{};
    double totalGross = 0;
    double totalVat = 0;

    for (final expense in expenses) {
      final amount = expense.amount / 100.0; // cents to main currency
      totalGross += amount;

      // Category Totals
      final category = expense.categoryId ?? 'Uncategorized';
      categoryTotals[category] = (categoryTotals[category] ?? 0) + amount;

      // Monthly Totals (YYYY-MM)
      final monthKey = '${expense.date.year}-${expense.date.month.toString().padLeft(2, '0')}';
      monthlyTotals[monthKey] = (monthlyTotals[monthKey] ?? 0) + amount;

      // VAT Calculation
      // If we had a specific VAT rate per expense, we'd use it here.
      // For now, we use the default rate.
      final vat = amount * (defaultVatRate / (1 + defaultVatRate));
      totalVat += vat;
    }

    final netAmount = totalGross - totalVat;

    final vatSummary = VatSummary(
      netAmount: netAmount,
      vatRate: defaultVatRate,
      vatAmount: totalVat,
      grossTotal: totalGross,
    );

    final budgetSummaries = _calculateBudgetSummaries(expenses, budgets);

    final auditTrail = AuditTrail(
      actions: ['Data aggregated', 'VAT computed', 'Summaries generated'],
      generatedAt: DateTime.now(),
      generatedBy: generatedBy,
      exportFormat: exportFormat,
    );

    return ExportBundle(
      expenses: expenses,
      categoryTotals: categoryTotals,
      monthlyTotals: monthlyTotals,
      budgetSummaries: budgetSummaries,
      vatSummary: vatSummary,
      auditTrail: auditTrail,
    );
  }

  List<BudgetSummary> _calculateBudgetSummaries(List<Expense> expenses, List<Budget> budgets) {
    final summaries = <BudgetSummary>[];

    for (final budget in budgets) {
      final budgetExpenses = expenses.where((e) => e.budgetId == budget.id).toList();
      final spent = budgetExpenses.fold<double>(0, (sum, e) => sum + (e.amount / 100.0));
      final limit = (budget.totalLimit ?? 0) / 100.0;
      final remaining = limit - spent;
      final percentageSpent = limit > 0 ? (spent / limit) * 100 : 0.0;

      summaries.add(BudgetSummary(
        budgetId: budget.id,
        budgetTitle: budget.title,
        limit: limit,
        spent: spent,
        remaining: remaining,
        percentageSpent: percentageSpent,
      ));
    }

    return summaries;
  }
}
