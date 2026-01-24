/// CashPilot Router Configuration
/// GoRouter setup with all app routes
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cashpilot/l10n/app_localizations.dart';

import '../../features/receipt/models/receipt_extraction_meta.dart';
import '../constants/app_routes.dart';
import '../providers/app_providers.dart';
import '../../features/subscription/providers/subscription_providers.dart';
import '../constants/subscription.dart';
import 'page_transitions.dart';
import 'route_guards.dart';
import '../../services/auth_service.dart';

// Screens
import '../../ui/screens/home/home_screen.dart';
import '../../ui/screens/budgets/budget_list_screen.dart';
import '../../ui/screens/budgets/budget_details_screen.dart';
import '../../ui/screens/budgets/budget_form_screen.dart';
import '../../ui/screens/expenses/add_expense_screen.dart';
import '../../ui/screens/expenses/expense_list_screen.dart';
import '../../ui/screens/reports/reports_screen_v2.dart';
import '../../ui/screens/settings/settings_screen.dart';
import '../../ui/screens/admin/ml_dashboard_screen.dart';
import '../../ui/screens/admin/ab_testing_screen.dart';
import '../../ui/screens/shell/main_shell.dart';
import '../../ui/screens/onboarding/onboarding_screen.dart';
import '../../ui/screens/categories/category_form_screen.dart';
import '../../features/family/screens/contact_picker_screen.dart';

import '../../ui/screens/scan/receipt_scan_screen.dart';
import '../../ui/screens/recurring/recurring_expenses_screen.dart';
import '../../ui/screens/family/family_sharing_screen.dart';
import '../../ui/screens/family/pending_invites_screen.dart';
import '../../ui/screens/auth/login_screen.dart';
import '../../ui/screens/profile/profile_screen.dart';
import '../../ui/screens/paywall/paywall_screen.dart';
import '../../ui/screens/scan/barcode_scan_screen.dart';
import '../../ui/screens/legal/user_agreement_screen.dart';
import '../../ui/screens/savings/savings_goals_screen.dart';
import '../../ui/screens/categories/category_list_screen.dart';
import '../../ui/screens/sync/conflicts_screen.dart';
// Bank screens temporarily disabled until feature complete
// import '../../ui/screens/banking/bank_accounts_screen.dart';
// import '../../ui/screens/banking/bank_connection_flow_screen.dart';

// ============================================================================
// ROUTER REFRESH NOTIFIER - Listens to auth state and triggers router refresh
// ============================================================================

/// A ChangeNotifier that listens to Supabase auth state changes
/// and notifies the GoRouter to re-evaluate its redirect logic.
class RouterRefreshNotifier extends ChangeNotifier {
  late final StreamSubscription _subscription;
  Timer? _debounceTimer;
  
  RouterRefreshNotifier(Ref ref) {
    // Listen to Supabase auth state changes
    _subscription = authService.authStateChanges.listen((event) {
      debugPrint('🔄 RouterRefreshNotifier: Auth state changed - ${event.event}');
      // Use debounce to allow state to propagate before redirect
      _scheduleNotify();
    });
    
    // Also listen to currentUserIdProvider changes (primary trigger for redirect)
    ref.listen(currentUserIdProvider, (previous, next) {
      if (previous != next) {
        debugPrint('🔄 RouterRefreshNotifier: User ID changed - $previous → $next');
        notifyListeners();
      }
    });

    // Listen for tier changes (upgrades/downgrades)
    ref.listen(currentTierProvider, (previous, next) {
      if (previous?.value != next.value) {
        debugPrint('🔄 RouterRefreshNotifier: Tier changed - ${previous?.value} → ${next.value}');
        notifyListeners();
      }
    });

    // Listen for onboarding completion
    ref.listen(onboardingCompleteProvider, (previous, next) {
      if (previous != next) {
        debugPrint('🔄 RouterRefreshNotifier: Onboarding changed - $previous → $next');
        notifyListeners();
      }
    });
  }
  
  /// Schedule a debounced notify to allow async state updates to complete
  void _scheduleNotify() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 200), () {
      if (!hasListeners) return;
      notifyListeners();
    });
  }
  
  @override
  void dispose() {
    _debounceTimer?.cancel();
    _subscription.cancel();
    super.dispose();
  }
}

/// Router provider
final routerProvider = Provider<GoRouter>((ref) {
  // Use ref.read for initial state to avoid re-creating the GoRouter instance
  // when these values change. The refreshNotifier and redirect logic
  // will handle state changes without destroying the navigation stack.
  final isOnboardingComplete = ref.read(onboardingCompleteProvider);
  final currentUserId = ref.read(currentUserIdProvider);

  // Create a refresh listenable that triggers when auth changes
  final refreshNotifier = RouterRefreshNotifier(ref);

  return GoRouter(
    debugLogDiagnostics: kDebugMode,
    
    // CRITICAL: This makes router re-evaluate redirect when auth state changes
    refreshListenable: refreshNotifier,

    /// Initial route selection
    initialLocation: isOnboardingComplete
        ? (currentUserId != null ? AppRoutes.home : AppRoutes.login)
        : AppRoutes.onboarding,

    /// Authentication + onboarding redirect logic
    redirect: (context, state) {
      // Always get fresh values inside the redirect handler
      final onboarding = ref.read(onboardingCompleteProvider);
      final user = ref.read(currentUserIdProvider);
      final tier = ref.read(currentTierProvider).value ?? SubscriptionTier.free;
      
      return RouteGuards.redirect(
        state.matchedLocation,
        onboardingComplete: onboarding,
        currentUserId: user,
        tier: tier,
      );
    },

    /// All application routes
    routes: [
      // ---------------------------------------------------------
      // Onboarding + Authentication
      // ---------------------------------------------------------

      GoRoute(
        path: AppRoutes.onboarding,
        name: 'onboarding',
        pageBuilder: (context, state) => FastFadePage(
          key: state.pageKey,
          name: 'onboarding',
          child: const OnboardingScreen(),
        ),
      ),

      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        pageBuilder: (context, state) => FastFadePage(
          key: state.pageKey,
          name: 'login',
          child: const LoginScreen(),
        ),
      ),
          
          // ML Dashboard (Admin)
          GoRoute(
            path: '/ml-dashboard',
            name: 'ml-dashboard',
            pageBuilder: (context, state) => FastFadePage(
              key: state.pageKey,
              name: 'ml-dashboard',
              child: const MLDashboardScreen(),
            ),
          ),

      // A/B Testing Dashboard (Admin)
      GoRoute(
        path: '/admin/ab-testing',
        name: 'ab-testing',
        pageBuilder: (context, state) => FastFadePage(
          key: state.pageKey,
          name: 'ab-testing',
          child: const ABTestingScreen(),
        ),
      ),


      // Legacy/Default User Agreement
      GoRoute(
        path: AppRoutes.userAgreement,
        name: 'user-agreement',
        pageBuilder: (context, state) => SlideUpPage(
          key: state.pageKey,
          name: 'user-agreement',
          child: const UserAgreementScreen(type: LegalDocType.userAgreement),
        ),
      ),

      // Privacy Policy
      GoRoute(
        path: AppRoutes.privacyPolicy,
        name: 'privacy-policy',
        pageBuilder: (context, state) => SlideUpPage(
          key: state.pageKey,
          name: 'privacy-policy',
          child: const UserAgreementScreen(
            type: LegalDocType.privacyPolicy,
            requireScrollToEnd: false, // Privacy is usually informational
            requireCheckbox: false,
          ),
        ),
      ),

      // Terms of Service
      GoRoute(
        path: AppRoutes.termsOfService,
        name: 'terms-of-service',
        pageBuilder: (context, state) => SlideUpPage(
          key: state.pageKey,
          name: 'terms-of-service',
          child: const UserAgreementScreen(
            type: LegalDocType.termsOfService,
            requireScrollToEnd: false,
            requireCheckbox: false,
          ),
        ),
      ),

      // Profile
      GoRoute(
        path: AppRoutes.profile,
        name: 'profile',
        pageBuilder: (context, state) => SlideUpPage(
          key: state.pageKey,
          name: 'profile',
          child: const ProfileScreen(),
        ),
      ),

      // ---------------------------------------------------------
      // Main Shell (Bottom Navigation)
      // ---------------------------------------------------------
      ShellRoute(
        builder: (context, state, child) => MainShell(
          currentPath: state.uri.path,
          child: child,
        ),
        routes: [
          // Home Tab
          GoRoute(
            path: AppRoutes.home,
            name: 'home',
            pageBuilder: (_, state) => NoTransitionPage(child: HomeScreen()),
          ),

          // Budgets Tab
          GoRoute(
            path: AppRoutes.budgets,
            name: 'budgets',
            pageBuilder: (_, state) =>
                const NoTransitionPage(child: BudgetListScreen()),
            routes: [
              GoRoute(
                path: ':id',
                name: 'budget-details',
                builder: (context, state) =>
                    BudgetDetailsScreen(budgetId: state.pathParameters['id']!),
              ),
            ],
          ),

          // Reports Tab
          GoRoute(
            path: AppRoutes.reports,
            name: 'reports',
            pageBuilder: (_, state) =>
                const NoTransitionPage(child: ReportsScreenV2()),
          ),

          // Settings Tab
          GoRoute(
            path: AppRoutes.settings,
            name: 'settings',
            pageBuilder: (_, state) =>
                const NoTransitionPage(child: SettingsScreen()),
          ),
        ],
      ),

      // ---------------------------------------------------------
      // Full-Screen Routes (Modals, Screens)
      // ---------------------------------------------------------

      GoRoute(
        path: AppRoutes.addExpense,
        name: 'add-expense',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return SlideUpPage(
            key: state.pageKey,
            name: 'add-expense',
            child: AddExpenseScreen(
              budgetId: state.uri.queryParameters['budgetId'],
              semiBudgetId: state.uri.queryParameters['semiBudgetId'],
              initialAmount: extra?['amount'] as int?,
              initialTitle: extra?['merchant'] as String? ?? extra?['title'] as String?,
              initialDate: extra?['date'] as DateTime?,
              fromOCR: extra?['fromOCR'] as bool? ?? false,
              receiptMeta: extra?['receiptMeta'] as ReceiptExtractionMeta?,
            ),
          );
        },
      ),

      GoRoute(
        path: AppRoutes.expenseDetails,
        name: 'expense-details',
        pageBuilder: (context, state) => SlideUpPage(
          key: state.pageKey,
          name: 'expense-details',
          child: AddExpenseScreen(expenseId: state.pathParameters['id']),
        ),
      ),

      // Expense List
      GoRoute(
        path: AppRoutes.expenseList,
        name: 'expense-list',
        pageBuilder: (context, state) => SlideInPage(
          key: state.pageKey,
          name: 'expense-list',
          child: ExpenseListScreen(budgetId: state.pathParameters['budgetId']!),
        ),
      ),

      // Budget Create/Edit
      GoRoute(
        path: AppRoutes.budgetCreate,
        name: 'budget-create',
        pageBuilder: (_, state) => SlideUpPage(
          key: state.pageKey,
          name: 'budget-create',
          child: const BudgetFormScreen(),
        ),
      ),

      GoRoute(
        path: '${AppRoutes.budgets}/:id/edit',
        name: 'budget-edit',
        pageBuilder: (_, state) => SlideUpPage(
          key: state.pageKey,
          name: 'budget-edit',
          child: BudgetFormScreen(budgetId: state.pathParameters['id']!),
        ),
      ),

      // Category Management
      GoRoute(
        path: AppRoutes.categoryAdd,
        name: 'category-add',
        pageBuilder: (_, state) => SlideUpPage(
          key: state.pageKey,
          name: 'category-add',
          child: CategoryFormScreen(
            budgetId: state.pathParameters['budgetId']!,
          ),
        ),
      ),

      GoRoute(
        path: AppRoutes.categoryEdit,
        name: 'category-edit',
        pageBuilder: (_, state) => SlideUpPage(
          key: state.pageKey,
          name: 'category-edit',
          child: CategoryFormScreen(
            budgetId: state.pathParameters['budgetId']!,
            categoryId: state.pathParameters['categoryId']!,
          ),
        ),
      ),



      // Receipt Scanner
      GoRoute(
        path: AppRoutes.scanReceipt,
        name: 'scan-receipt',
        pageBuilder: (_, state) => FastFadePage(
          key: state.pageKey,
          name: 'scan-receipt',
          child: const ReceiptScanScreen(),
        ),
      ),

      // Barcode Scanner
      GoRoute(
        path: AppRoutes.scanBarcode,
        name: 'scan-barcode',
        pageBuilder: (_, state) => FastFadePage(
          key: state.pageKey,
          name: 'scan-barcode',
          child: const BarcodeScanScreen(),
        ),
      ),

      // Recurring Expenses
      GoRoute(
        path: AppRoutes.recurringExpenses,
        name: 'recurring-expenses',
        pageBuilder: (_, state) => SlideInPage(
          key: state.pageKey,
          name: 'recurring-expenses',
          child: const RecurringExpensesScreen(),
        ),
      ),

      // Savings Goals
      GoRoute(
        path: AppRoutes.savings,
        name: 'savings',
        pageBuilder: (_, state) => SlideInPage(
          key: state.pageKey,
          name: 'savings',
          child: const SavingsGoalsScreen(),
        ),
      ),

      // Family Sharing
      GoRoute(
        path: AppRoutes.familySettings,
        name: 'family-sharing',
        pageBuilder: (_, state) => SlideInPage(
          key: state.pageKey,
          name: 'family-sharing',
          child: const FamilySharingScreen(),
        ),
      ),

      // Pending Invites
      GoRoute(
        path: AppRoutes.pendingInvites,
        name: 'pending-invites',
        pageBuilder: (_, state) => SlideInPage(
          key: state.pageKey,
          name: 'pending-invites',
          child: const PendingInvitesScreen(),
        ),
      ),

      // Contact Picker
      GoRoute(
        path: AppRoutes.contactPicker,
        name: 'contact-picker',
        pageBuilder: (_, state) => SlideUpPage(
          key: state.pageKey,
          name: 'contact-picker',
          child: const ContactPickerScreen(),
        ),
      ),

      // Paywall
      GoRoute(
        path: AppRoutes.paywall,
        name: 'paywall',
        pageBuilder: (_, state) => ScalePage(
          key: state.pageKey,
          name: 'paywall',
          child: const PaywallScreen(),
        ),
      ),

      // Categories Manager
      GoRoute(
        path: AppRoutes.categories,
        name: 'categories',
        pageBuilder: (_, state) => SlideInPage(
          key: state.pageKey,
          name: 'categories',
          child: const CategoryListScreen(),
        ),
      ),

      // Sync Conflicts
      GoRoute(
        path: '/sync/conflicts',
        name: 'sync-conflicts',
        pageBuilder: (_, state) => SlideInPage(
          key: state.pageKey,
          name: 'sync-conflicts',
          child: const ConflictsScreen(),
        ),
      ),

      // -------------------------------------------------------------------------
      // Banking / Yapily - STUBBED FOR FUTURE IMPLEMENTATION
      // Requires eIDAS certificates for production use
      // See: docs/BANK_INTEGRATION_GUIDE.md
      // -------------------------------------------------------------------------
      
      /* UNCOMMENT WHEN READY TO IMPLEMENT BANK CONNECTIVITY:
      
      GoRoute(
        path: AppRoutes.bankAccounts,
        name: 'bank-accounts',
        pageBuilder: (_, state) => SlideInPage(
          key: state.pageKey,
          name: 'bank-accounts',
          child: const BankAccountsScreen(),
        ),
      ),

      GoRoute(
        path: AppRoutes.bankConnectionFlow,
        name: 'bank-connect',
        pageBuilder: (_, state) => SlideUpPage(
          key: state.pageKey,
          name: 'bank-connect',
          child: const BankConnectionFlowScreen(),
        ),
      ),
      
      */
    ],

    /// Error Page
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)?.commonPageNotFound ?? 'Page not found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              state.uri.toString(),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.home),
              child: Text(AppLocalizations.of(context)?.commonGoHome ?? 'Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
});
