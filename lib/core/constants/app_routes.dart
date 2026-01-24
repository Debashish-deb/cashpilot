/// Route constants for GoRouter navigation
/// 
/// Rules:
/// - All routes are absolute
/// - Dynamic segments use :param syntax
/// - Helper methods must mirror route definitions exactly
library;

class AppRoutes {
  // ===========================================================================
  // MAIN TABS
  // ===========================================================================

  static const String home = '/';
  static const String budgets = '/budgets';
  static const String addExpense = '/add-expense';
  static const String reports = '/reports';
  static const String settings = '/settings';

  // ===========================================================================
  // BUDGET ROUTES
  // ===========================================================================

  static const String budgetDetails = '/budgets/:id';
  static const String budgetCreate = '/create-budget';
  static const String budgetEdit = '/budgets/:id/edit';

  // ===========================================================================
  // SEMI-BUDGET (CATEGORY) ROUTES
  // ===========================================================================

  static const String semiBudgetDetails = '/budgets/:budgetId/category/:id';
  static const String categoryAdd = '/budgets/:budgetId/category/add';
  static const String categoryEdit =
      '/budgets/:budgetId/category/:categoryId/edit';

  // ===========================================================================
  // EXPENSE ROUTES
  // ===========================================================================

  static const String expenseDetails = '/expenses/:id';
  static const String expenseEdit = '/expenses/:id/edit';
  static const String expenseList = '/budgets/:budgetId/expenses';

  // ===========================================================================
  // SCAN ROUTES
  // ===========================================================================

  static const String scanReceipt = '/scan-receipt';
  static const String scanBarcode = '/scan/barcode';

  // ===========================================================================
  // ACCOUNT ROUTES
  // ===========================================================================

  static const String accounts = '/accounts';
  static const String accountDetails = '/accounts/:id';
  static const String accountCreate = '/accounts/create';

  // ===========================================================================
  // FAMILY ROUTES
  // ===========================================================================

  static const String familySettings = '/family';
  static const String familyInvite = '/family/invite';
  static const String pendingInvites = '/family/pending-invites';

  // ===========================================================================
  // AUTH ROUTES
  // ===========================================================================

  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String userAgreement = '/user-agreement';
  static const String privacyPolicy = '/privacy-policy';
  static const String termsOfService = '/terms-of-service';

  // ===========================================================================
  // OTHER ROUTES
  // ===========================================================================

  static const String onboarding = '/onboarding';
  static const String profile = '/profile';
  static const String paywall = '/paywall';
  static const String recurringExpenses = '/recurring-expenses';
  static const String savings = '/savings';
  static const String categories = '/categories';
  static const String syncConflicts = '/sync/conflicts';
  
  // Banking / GoCardless
  static const String bankAccounts = '/banking/accounts';
  static const String bankConnectionFlow = '/banking/connect';
  static const String contactPicker = '/family/contacts';
  static const String bankTransactions = '/banking/transactions/:accountId';

  // ===========================================================================
  // ROUTE BUILDERS (SAFE HELPERS)
  // These MUST stay in sync with route definitions above
  // ===========================================================================

  static String budgetDetailsPath(String id) {
    assert(id.isNotEmpty);
    return '/budgets/$id';
  }

  static String budgetEditPath(String id) {
    assert(id.isNotEmpty);
    return '/budgets/$id/edit';
  }

  static String semiBudgetDetailsPath(String budgetId, String id) {
    assert(budgetId.isNotEmpty);
    assert(id.isNotEmpty);
    return '/budgets/$budgetId/category/$id';
  }

  static String categoryAddPath(String budgetId) {
    assert(budgetId.isNotEmpty);
    return '/budgets/$budgetId/category/add';
  }

  static String categoryEditPath(String budgetId, String categoryId) {
    assert(budgetId.isNotEmpty);
    assert(categoryId.isNotEmpty);
    return '/budgets/$budgetId/category/$categoryId/edit';
  }

  static String expenseDetailsPath(String id) {
    assert(id.isNotEmpty);
    return '/expenses/$id';
  }

  static String expenseEditPath(String id) {
    assert(id.isNotEmpty);
    return '/expenses/$id/edit';
  }

  static String accountDetailsPath(String id) {
    assert(id.isNotEmpty);
    return '/accounts/$id';
  }

  static String expenseListPath(String budgetId) {
    assert(budgetId.isNotEmpty);
    return '/budgets/$budgetId/expenses';
  }

  static String legalPath(String type) {
    if (type == 'privacy') return privacyPolicy;
    if (type == 'terms') return termsOfService;
    return userAgreement;
  }

  // ===========================================================================
  // UTILITIES (NON-BREAKING)
  // ===========================================================================

  /// Returns true if the route contains path parameters (":id")
  static bool isParameterized(String route) {
    return route.contains(':');
  }

  /// Debug-only route sanity check
  static void debugValidate() {
    assert(home.startsWith('/'));
    assert(!home.endsWith('//'));
    assert(budgetDetails.contains(':id'));
    assert(semiBudgetDetails.contains(':budgetId'));
  }
}
