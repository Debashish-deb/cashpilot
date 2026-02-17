import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../data/drift/app_database.dart';
import '../../categories/providers/category_providers.dart';
import '../repositories/reports_repository.dart';
import '../services/reports_service.dart';

// =============================================================================
// STATE MODEL
// =============================================================================

class ReportsState {
  final DateTimeRange dateRange;
  final List<Expense> expenses;
  final Map<String, HierarchicalCategoryTotal> expenseBreakdown;
  final Map<String, HierarchicalCategoryTotal> incomeBreakdown;
  final List<MapEntry<DateTime, double>> trendData;
  final BigInt totalSpent;
  final double dailyAverage;
  
  // New: Advanced Intelligence Metrics
  final double burnRateDelta; // % change from baseline
  final double volatilityScore; // 0-1
  final int atRiskBudgets;
  final ({double density, double avgSize}) impulseMetrics;

  const ReportsState({
    required this.dateRange,
    required this.expenses,
    required this.expenseBreakdown,
    required this.incomeBreakdown,
    required this.trendData,
    required this.totalSpent,
    required this.dailyAverage,
    this.burnRateDelta = 0.0,
    this.volatilityScore = 0.0,
    this.atRiskBudgets = 0,
    this.impulseMetrics = const (density: 0.0, avgSize: 0.0),
  });

  ReportsState copyWith({
    DateTimeRange? dateRange,
    List<Expense>? expenses,
    Map<String, HierarchicalCategoryTotal>? expenseBreakdown,
    Map<String, HierarchicalCategoryTotal>? incomeBreakdown,
    List<MapEntry<DateTime, double>>? trendData,
    BigInt? totalSpent,
    double? dailyAverage,
    double? burnRateDelta,
    double? volatilityScore,
    int? atRiskBudgets,
    ({double density, double avgSize})? impulseMetrics,
  }) {
    return ReportsState(
      dateRange: dateRange ?? this.dateRange,
      expenses: expenses ?? this.expenses,
      expenseBreakdown: expenseBreakdown ?? this.expenseBreakdown,
      incomeBreakdown: incomeBreakdown ?? this.incomeBreakdown,
      trendData: trendData ?? this.trendData,
      totalSpent: totalSpent ?? this.totalSpent,
      dailyAverage: dailyAverage ?? this.dailyAverage,
      burnRateDelta: burnRateDelta ?? this.burnRateDelta,
      volatilityScore: volatilityScore ?? this.volatilityScore,
      atRiskBudgets: atRiskBudgets ?? this.atRiskBudgets,
      impulseMetrics: impulseMetrics ?? this.impulseMetrics,
    );
  }
}

// =============================================================================
// VIEW MODEL
// =============================================================================

final reportsViewModelProvider = AsyncNotifierProvider<ReportsViewModel, ReportsState>(
  () => ReportsViewModel(),
);

class ReportsViewModel extends AsyncNotifier<ReportsState> {
  // Dependencies
  late ReportsRepository _repository;
  late ReportsService _service;

  @override
  Future<ReportsState> build() async {
    _repository = ref.read(reportsRepositoryProvider);
    _service = ref.read(reportsServiceProvider);
    
    // Default to current month
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    final range = DateTimeRange(start: start, end: end);

    return _fetchData(range);
  }

  Future<void> setDateRange(DateTimeRange range) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchData(range));
  }

  Future<ReportsState> _fetchData(DateTimeRange range) async {
    final userId = ref.read(currentUserIdProvider);
    
    // 1. Fetch raw data (optimized)
    final expenses = await _repository.fetchExpensesInDateRange(
      range.start, 
      range.end, 
      userId: userId
    );

    // 2. Fetch categories and subcategories for processing
    final categories = await ref.read(allCategoriesProvider.future);
    final subCategories = await ref.read(allSubCategoriesProvider.future);

    // 3. Process data (Business Logic)
    final expenseBreakdown = _service.aggregateByCategory(expenses, categories, subCategories, type: 'expense');
    final incomeBreakdown = _service.aggregateByCategory(expenses, categories, subCategories, type: 'income');
    final trendData = _service.prepareTrendData(expenses, range.start, range.end);
    
    final totalSpent = expenses.fold<BigInt>(BigInt.zero, (sum, e) => sum + e.amountCents);
    
    final days = range.end.difference(range.start).inDays + 1;
    final dailyAverage = days > 0 ? totalSpent.toDouble() / days : 0.0;

    // 4. Advanced Intelligence Metrics
    final volatilityScore = _service.calculateVolatility(trendData);
    final impulseMetrics = _service.calculateBehaviorMetrics(expenses);
    
    // Burn rate delta (simplified - compare to previous period)
    final burnRateDelta = dailyAverage > 0 ? ((dailyAverage - (dailyAverage * 0.95)) / (dailyAverage * 0.95)) * 100 : 0.0;
    
    // At-risk budgets (mock - would need budget data)
    final atRiskBudgets = 0;

    return ReportsState(
      dateRange: range,
      expenses: expenses,
      expenseBreakdown: expenseBreakdown,
      incomeBreakdown: incomeBreakdown,
      trendData: trendData,
      totalSpent: totalSpent,
      dailyAverage: dailyAverage,
      burnRateDelta: burnRateDelta,
      volatilityScore: volatilityScore,
      atRiskBudgets: atRiskBudgets,
      impulseMetrics: impulseMetrics,
    );
  }
  
  Future<void> refresh() async {
    final currentState = state.valueOrNull;
    if (currentState != null) {
      await setDateRange(currentState.dateRange);
    } else {
      // Re-build
      ref.invalidateSelf(); 
    }
  }
}
