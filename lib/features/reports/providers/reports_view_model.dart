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
  final Map<String, double> categoryBreakdown;
  final List<MapEntry<DateTime, double>> trendData;
  final double totalSpent;
  final double dailyAverage;

  const ReportsState({
    required this.dateRange,
    required this.expenses,
    required this.categoryBreakdown,
    required this.trendData,
    required this.totalSpent,
    required this.dailyAverage,
  });

  ReportsState copyWith({
    DateTimeRange? dateRange,
    List<Expense>? expenses,
    Map<String, double>? categoryBreakdown,
    List<MapEntry<DateTime, double>>? trendData,
    double? totalSpent,
    double? dailyAverage,
  }) {
    return ReportsState(
      dateRange: dateRange ?? this.dateRange,
      expenses: expenses ?? this.expenses,
      categoryBreakdown: categoryBreakdown ?? this.categoryBreakdown,
      trendData: trendData ?? this.trendData,
      totalSpent: totalSpent ?? this.totalSpent,
      dailyAverage: dailyAverage ?? this.dailyAverage,
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

    // 2. Fetch categories for processing
    final categories = await ref.read(allCategoriesProvider.future);

    // 3. Process data (Business Logic)
    final categoryBreakdown = _service.aggregateByCategory(expenses, categories);
    final trendData = _service.prepareTrendData(expenses, range.start, range.end);
    
    final totalSpentCents = expenses.fold<int>(0, (sum, e) => sum + e.amount);
    final totalSpent = totalSpentCents / 100.0;
    
    final days = range.end.difference(range.start).inDays + 1;
    final dailyAverage = days > 0 ? totalSpent / days : 0.0;

    return ReportsState(
      dateRange: range,
      expenses: expenses,
      categoryBreakdown: categoryBreakdown,
      trendData: trendData,
      totalSpent: totalSpent,
      dailyAverage: dailyAverage,
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
