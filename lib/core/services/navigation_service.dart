import 'package:go_router/go_router.dart';
import '../../core/constants/app_routes.dart';

/// Centralized Navigation Service
///
/// Addresses "Navigation Chaos" by providing a type-safe API for navigation.
/// Replace all `Navigator.push`, `context.go`, `context.push` with this service.
class NavigationService {
  final GoRouter _router;

  NavigationService(this._router);

  // ===========================================================================
  // CORE NAVIGATION
  // ===========================================================================

  void goHome() => _router.go(AppRoutes.home);
  
  void goLogin() => _router.go(AppRoutes.login);
  
  void goOnboarding() => _router.go(AppRoutes.onboarding);

  // ===========================================================================
  // EXPENSES
  // ===========================================================================

  void pushAddExpense({
    String? title,
    int? amount,
    DateTime? date,
    bool fromOCR = false,
  }) {
    _router.push(AppRoutes.addExpense, extra: {
      if (title != null) 'title': title,
      if (amount != null) 'amount': amount,
      if (date != null) 'date': date,
      'fromOCR': fromOCR,
    });
  }

  void pushExpenseDetails(String id) {
    _router.push(AppRoutes.expenseDetailsPath(id));
  }

  // ===========================================================================
  // BUDGETS
  // ===========================================================================

  void pushBudgetDetails(String id) {
    _router.push(AppRoutes.budgetDetailsPath(id));
  }

  void pushCreateBudget() {
    _router.push(AppRoutes.budgetCreate);
  }

  // ===========================================================================
  // FAMILY & SHARING
  // ===========================================================================

  void pushFamilySharing() => _router.push(AppRoutes.familySettings);
  
  void pushPendingInvites() => _router.push(AppRoutes.pendingInvites);

  // ===========================================================================
  // ALIASES (For easy migration)
  // ===========================================================================
  
  void pop() {
    if (_router.canPop()) {
      _router.pop();
    }
  }
}
