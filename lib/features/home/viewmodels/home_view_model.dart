import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/drift/app_database.dart';
import '../../../../features/expenses/providers/expense_providers.dart';
import '../../../../features/categories/providers/category_providers.dart';
import '../../../../features/auth/providers/auth_provider.dart';
import '../../../../features/subscription/providers/subscription_providers.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/constants/subscription.dart';

class HomeViewState {
  final int todaySpending;
  final int monthSpending;
  final List<Expense> recentExpenses;
  final Map<String, Category> categoryMap;
  final String currency;
  final String? avatarUrl;
  final SubscriptionTier tier;
  final bool isLoading;

  const HomeViewState({
    this.todaySpending = 0,
    this.monthSpending = 0,
    this.recentExpenses = const [],
    this.categoryMap = const {},
    this.currency = 'USD',
    this.avatarUrl,
    this.tier = SubscriptionTier.free,
    this.isLoading = false,
  });

   HomeViewState copyWith({
    int? todaySpending,
    int? monthSpending,
    List<Expense>? recentExpenses,
    Map<String, Category>? categoryMap,
    String? currency,
    String? avatarUrl,
    SubscriptionTier? tier,
    bool? isLoading,
  }) {
    return HomeViewState(
      todaySpending: todaySpending ?? this.todaySpending,
      monthSpending: monthSpending ?? this.monthSpending,
      recentExpenses: recentExpenses ?? this.recentExpenses,
      categoryMap: categoryMap ?? this.categoryMap,
      currency: currency ?? this.currency,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      tier: tier ?? this.tier,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class HomeViewModel extends AutoDisposeAsyncNotifier<HomeViewState> {
  @override
  Future<HomeViewState> build() async {
    // Watch relevant providers using .select or direct watch for streams
    final todaySpending = ref.watch(todaySpendingProvider).value ?? 0;
    final monthSpending = ref.watch(thisMonthSpendingProvider).value ?? 0;
    final expenses = ref.watch(recentExpensesProvider).value ?? [];
    final categories = ref.watch(allCategoriesProvider).value ?? [];
    final currency = ref.watch(currencyProvider);
    
    // Auth & Subscription
    final authState = ref.watch(authProvider);
    final tier = ref.watch(currentTierProvider).value ?? SubscriptionTier.free;
    
    final categoryMap = {for (var c in categories) c.id: c};
    final avatarUrl = authState.user?.userMetadata?['avatar_url'] ?? 
                      authState.user?.userMetadata?['picture'];

    return HomeViewState(
      todaySpending: todaySpending,
      monthSpending: monthSpending,
      recentExpenses: expenses,
      categoryMap: categoryMap,
      currency: currency,
      avatarUrl: avatarUrl,
      tier: tier,
    );
  }
  
  // Logic to refresh data if needed
  Future<void> refresh() async {
    ref.invalidate(todaySpendingProvider);
    ref.invalidate(thisMonthSpendingProvider);
    ref.invalidate(recentExpensesProvider);
    ref.invalidate(allCategoriesProvider);
    await future;
  }
}

final homeViewModelProvider = AsyncNotifierProvider.autoDispose<HomeViewModel, HomeViewState>(() {
  return HomeViewModel();
});
