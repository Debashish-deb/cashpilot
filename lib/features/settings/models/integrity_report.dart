/// Model for backup integrity check results
library;

class IntegrityReport {
  final List<OrphanIssue> orphanExpenses;
  final List<OrphanIssue> orphanSemiBudgets;
  final List<String> invalidCurrencies;
  final List<DateIssue> invalidDates;
  final int totalIssues;

  IntegrityReport({
    required this.orphanExpenses,
    required this.orphanSemiBudgets,
    required this.invalidCurrencies,
    required this.invalidDates,
  }) : totalIssues = orphanExpenses.length + 
                     orphanSemiBudgets.length + 
                     invalidCurrencies.length + 
                     invalidDates.length;

  bool get hasIssues => totalIssues > 0;
  bool get isClean => totalIssues == 0;

  String get summary {
    if (isClean) return 'No integrity issues found';
    return '$totalIssues integrity issue(s) detected';
  }
}

class OrphanIssue {
  final String id;
  final String title;
  final String type; // 'expense' or 'semi_budget'
  final String? missingParentId;

  OrphanIssue({
    required this.id,
    required this.title,
    required this.type,
    this.missingParentId,
  });
}

class DateIssue {
  final String budgetId;
  final String budgetTitle;
  final DateTime startDate;
  final DateTime endDate;

  DateIssue({
    required this.budgetId,
    required this.budgetTitle,
    required this.startDate,
    required this.endDate,
  });

  String get description => 
      'End date ($endDate) is before start date ($startDate)';
}
