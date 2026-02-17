import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/drift/app_database.dart';
import '../../../../features/expenses/providers/expense_providers.dart';
import '../../../../features/categories/providers/category_providers.dart';
import '../../../../features/auth/providers/auth_provider.dart';
import '../../../../features/subscription/providers/subscription_providers.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/constants/subscription.dart';
import '../../../../features/budgets/providers/budget_providers.dart';
import '../../../../features/reports/providers/reports_view_model.dart';
import '../../../../features/accounts/providers/account_providers.dart';
import '../../../../features/net_worth/providers/net_worth_providers.dart';
import '../../../../domain/entities/net_worth/asset.dart' as domain;
import '../../../../domain/entities/net_worth/liability.dart' as domain;
import 'package:cashpilot/features/reports/services/reports_service.dart';


class HomeViewState {
  final BigInt todaySpending;
  final BigInt monthSpending;
  final BigInt totalIncome;
  final BigInt totalBalance;
  final BigInt totalAssets;
  final BigInt totalLiabilities;
  final List<MapEntry<DateTime, double>> expenseTrend;
  final List<Account> accounts;
  final List<domain.Asset> netWorthAssets;
  final List<domain.Liability> netWorthLiabilities;
  final List<Expense> recentExpenses;
  final Map<String, Category> categoryMap;
  final Map<String, SubCategory> subCategoryMap;
  final Map<String, Budget> budgetMap;
  final Map<String, BigInt> categoryWiseTotals;
  final String currency;
  final String? avatarUrl;
  final SubscriptionTier tier;
  
  // New Diagnostic Metrics
  final FinancialHealthMetrics? healthMetrics;
  final ({RunwayStatus status, double projectedSpend, String message})? runway;
  final String? cashFlowPulse;
  final ({String title, String message, int priority})? smartAlert;
  
  final bool isLoading;

  HomeViewState({
    BigInt? todaySpending,
    BigInt? monthSpending,
    BigInt? totalIncome,
    BigInt? totalBalance,
    BigInt? totalAssets,
    BigInt? totalLiabilities,
    this.expenseTrend = const [],
    this.accounts = const [],
    this.netWorthAssets = const [],
    this.netWorthLiabilities = const [],
    this.recentExpenses = const [],
    this.categoryMap = const {},
    this.subCategoryMap = const {},
    this.budgetMap = const {},
    this.categoryWiseTotals = const {},
    this.currency = 'USD',
    this.avatarUrl,
    this.tier = SubscriptionTier.free,
    this.healthMetrics,
    this.runway,
    this.cashFlowPulse,
    this.smartAlert,
    this.isLoading = false,
  }) : todaySpending = todaySpending ?? BigInt.zero,
       monthSpending = monthSpending ?? BigInt.zero,
       totalIncome = totalIncome ?? BigInt.zero,
       totalBalance = totalBalance ?? BigInt.zero,
       totalAssets = totalAssets ?? BigInt.zero,
       totalLiabilities = totalLiabilities ?? BigInt.zero;

  HomeViewState copyWith({
    BigInt? todaySpending,
    BigInt? monthSpending,
    BigInt? totalIncome,
    BigInt? totalBalance,
    BigInt? totalAssets,
    BigInt? totalLiabilities,
    List<MapEntry<DateTime, double>>? expenseTrend,
    List<Account>? accounts,
    List<domain.Asset>? netWorthAssets,
    List<domain.Liability>? netWorthLiabilities,
    List<Expense>? recentExpenses,
    Map<String, Category>? categoryMap,
    Map<String, SubCategory>? subCategoryMap,
    Map<String, Budget>? budgetMap,
    Map<String, BigInt>? categoryWiseTotals,
    String? currency,
    String? avatarUrl,
    SubscriptionTier? tier,
    FinancialHealthMetrics? healthMetrics,
    ({RunwayStatus status, double projectedSpend, String message})? runway,
    String? cashFlowPulse,
    ({String title, String message, int priority})? smartAlert,
    bool? isLoading,
  }) {
    return HomeViewState(
      todaySpending: todaySpending ?? this.todaySpending,
      monthSpending: monthSpending ?? this.monthSpending,
      totalIncome: totalIncome ?? this.totalIncome,
      totalBalance: totalBalance ?? this.totalBalance,
      totalAssets: totalAssets ?? this.totalAssets,
      totalLiabilities: totalLiabilities ?? this.totalLiabilities,
      expenseTrend: expenseTrend ?? this.expenseTrend,
      accounts: accounts ?? this.accounts,
      netWorthAssets: netWorthAssets ?? this.netWorthAssets,
      netWorthLiabilities: netWorthLiabilities ?? this.netWorthLiabilities,
      recentExpenses: recentExpenses ?? this.recentExpenses,
      categoryMap: categoryMap ?? this.categoryMap,
      subCategoryMap: subCategoryMap ?? this.subCategoryMap,
      budgetMap: budgetMap ?? this.budgetMap,
      categoryWiseTotals: categoryWiseTotals ?? this.categoryWiseTotals,
      currency: currency ?? this.currency,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      tier: tier ?? this.tier,
      healthMetrics: healthMetrics ?? this.healthMetrics,
      runway: runway ?? this.runway,
      cashFlowPulse: cashFlowPulse ?? this.cashFlowPulse,
      smartAlert: smartAlert ?? this.smartAlert,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  /// Groups recent expenses by category ID
  Map<String, List<Expense>> get groupedExpenses {
    final Map<String, List<Expense>> groups = {};
    for (var expense in recentExpenses) {
      final catId = expense.categoryId ?? 'undeclared';
      groups.putIfAbsent(catId, () => []).add(expense);
    }
    return groups;
  }

  /// Groups by Category -> Subcategory
  Map<String, Map<String, List<Expense>>> get hierarchicalExpenses {
    final Map<String, Map<String, List<Expense>>> hierarchy = {};
    for (var expense in recentExpenses) {
      final catId = expense.categoryId ?? 'undeclared';
      final subCatId = expense.subCategoryId ?? 'none';
      
      hierarchy.putIfAbsent(catId, () => {});
      hierarchy[catId]!.putIfAbsent(subCatId, () => []).add(expense);
    }
    return hierarchy;
  }

  /// Groups by Date -> Budget -> Expenses
  Map<DateTime, Map<String, List<Expense>>> get expensesByDateAndBudget {
    final Map<DateTime, Map<String, List<Expense>>> grouped = {};
    
    for (var expense in recentExpenses) {
      final date = DateTime(expense.date.year, expense.date.month, expense.date.day);
      final budgetId = expense.budgetId;
      
      grouped.putIfAbsent(date, () => {});
      grouped[date]!.putIfAbsent(budgetId, () => []).add(expense);
    }
    
    return grouped;
  }
}

class HomeViewModel extends AutoDisposeAsyncNotifier<HomeViewState> {
  Timer? _debounceTimer;

  @override
  Future<HomeViewState> build() async {
    // Watch relevant providers using .select or direct watch for streams
    final todaySpending = ref.watch(todaySpendingProvider).value ?? BigInt.zero;
    final monthSpending = ref.watch(thisMonthSpendingProvider).value ?? BigInt.zero;
    final expenses = ref.watch(recentExpensesProvider).value ?? [];
    final categories = ref.watch(allCategoriesProvider).value ?? [];
    final subCategories = ref.watch(allSubCategoriesProvider).value ?? [];
    final budgets = ref.watch(budgetsStreamProvider).value ?? [];
    final categoryBreakdown = ref.watch(groupedExpensesByCategoryProvider).value ?? {};
    final currency = ref.watch(currencyProvider);
    
    // NEW: Real data integration
    final totalBalance = ref.watch(totalBalanceProvider);
    final liquidNetWorth = ref.watch(netWorthProvider);
    final accounts = ref.watch(accountsProvider).valueOrNull ?? [];
    
    // Watch Net Worth Assets/Liabilities (Real-world assets)
    final assets = ref.watch(assetsStreamProvider).valueOrNull ?? [];
    final liabilities = ref.watch(liabilitiesStreamProvider).valueOrNull ?? [];
    final netWorthSummary = ref.watch(netWorthSummaryProvider).valueOrNull;

    final reportsState = ref.watch(reportsViewModelProvider).valueOrNull;

    // Calculate total income and trend from reports state if available
    BigInt totalIncome = BigInt.zero;
    List<MapEntry<DateTime, double>> expenseTrend = [];
    if (reportsState != null) {
      totalIncome = reportsState.incomeBreakdown.values.fold<BigInt>(BigInt.zero, (sum, item) => sum + item.totalCents);
      expenseTrend = reportsState.trendData;
    }
    
    // Auth & Subscription optimization: Only watch what we need to avoid rebuilds on token refresh
    final avatarUrl = ref.watch(authProvider.select((state) => 
      state.user?.userMetadata?['avatar_url'] ?? state.user?.userMetadata?['picture']
    ));
    final tier = ref.watch(currentTierProvider).value ?? SubscriptionTier.free;
    
    final Map<String, Category> categoryMap = {for (var c in categories) c.id: c};
    final Map<String, SubCategory> subCategoryMap = {for (var s in subCategories) s.id: s};
    final Map<String, Budget> budgetMap = {for (var b in budgets) b.id: b};

    ref.onDispose(() {
      _debounceTimer?.cancel();
    });

    final Map<String, BigInt> categoryWiseTotals = categoryBreakdown.map(
      (key, value) => MapEntry(key, value.fold<BigInt>(BigInt.zero, (sum, e) => sum + e.amountCents)),
    );

    // Aggregated totals
    final combinedAssets = liquidNetWorth.totalAssets + BigInt.from(netWorthSummary?.totalAssets ?? 0);
    final combinedLiabilities = liquidNetWorth.totalLiabilities + BigInt.from(netWorthSummary?.totalLiabilities ?? 0);

    // INTELLIGENCE RADAR CALCULATIONS
    final reportService = ref.read(reportsServiceProvider);
    
    // 1. Health Score
    final healthMetrics = reportService.calculateHealthMetrics(
      totalIncome: totalIncome.toDouble(),
      totalSpent: monthSpending.toDouble(),
      budgetedAmount: budgets.fold<double>(0, (sum, b) => sum + (b.totalLimitCents?.toDouble() ?? 0.0) / 100.0),
      previousMonthAvg: monthSpending.toDouble() * 0.95, // Simplified historic factor for now
    );

    // 2. Month Outlook (Runway)
    final now = DateTime.now();
    final runway = reportService.calculateRunway(
      currentSpent: monthSpending.toDouble(),
      daysPassed: now.day,
      totalDaysInMonth: DateTime(now.year, now.month + 1, 0).day,
      historicalMean: monthSpending.toDouble() * 1.1, // Simplified base for mock runway
    );

    // 3. Cash Flow Pulse
    final diff = totalIncome - monthSpending;
    final cashFlowPulse = "Net ${diff >= BigInt.zero ? '+' : '-'}$currency${ (diff.abs().toDouble() / 100.0).toStringAsFixed(0) } · ${diff >= BigInt.zero ? 'Improving' : 'Strained'}";

    // 4. Smart Alert (Mock Insight for REDESIGN)
    final smartAlert = (
      title: "Category Alert",
      message: "Spending on Food is 14% higher than your average.",
      priority: 1,
    );

    return HomeViewState(
      todaySpending: todaySpending,
      monthSpending: monthSpending,
      totalIncome: totalIncome,
      totalBalance: totalBalance,
      totalAssets: combinedAssets,
      totalLiabilities: combinedLiabilities,
      expenseTrend: expenseTrend,
      accounts: accounts,
      netWorthAssets: assets,
      netWorthLiabilities: liabilities,
      recentExpenses: expenses,
      categoryMap: categoryMap,
      subCategoryMap: subCategoryMap,
      budgetMap: budgetMap,
      categoryWiseTotals: categoryWiseTotals,
      currency: currency,
      avatarUrl: avatarUrl as String?,
      tier: tier,
      healthMetrics: healthMetrics,
      runway: runway,
      cashFlowPulse: cashFlowPulse,
      smartAlert: smartAlert,
    );
  }
  
  // Logic to refresh data if needed (Debounced)
  Future<void> refresh() async {
    if (_debounceTimer?.isActive ?? false) return;
    
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      ref.invalidate(todaySpendingProvider);
      ref.invalidate(thisMonthSpendingProvider);
      ref.invalidate(recentExpensesProvider);
      ref.invalidate(allCategoriesProvider);
      // Removed await future to avoid blocking
    });
  }
}

final homeViewModelProvider = AsyncNotifierProvider.autoDispose<HomeViewModel, HomeViewState>(() {
  return HomeViewModel();
});
