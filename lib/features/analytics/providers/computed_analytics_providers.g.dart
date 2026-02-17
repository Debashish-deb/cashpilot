// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'computed_analytics_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Budget Statistics Provider - Real data from database

@ProviderFor(budgetStatistics)
final budgetStatisticsProvider = BudgetStatisticsFamily._();

/// Budget Statistics Provider - Real data from database

final class BudgetStatisticsProvider
    extends
        $FunctionalProvider<
          AsyncValue<BudgetStatistics>,
          BudgetStatistics,
          FutureOr<BudgetStatistics>
        >
    with $FutureModifier<BudgetStatistics>, $FutureProvider<BudgetStatistics> {
  /// Budget Statistics Provider - Real data from database
  BudgetStatisticsProvider._({
    required BudgetStatisticsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'budgetStatisticsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$budgetStatisticsHash();

  @override
  String toString() {
    return r'budgetStatisticsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<BudgetStatistics> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<BudgetStatistics> create(Ref ref) {
    final argument = this.argument as String;
    return budgetStatistics(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is BudgetStatisticsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$budgetStatisticsHash() => r'49aa288111b9545351b0b32faa47f7d96d9a63d3';

/// Budget Statistics Provider - Real data from database

final class BudgetStatisticsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<BudgetStatistics>, String> {
  BudgetStatisticsFamily._()
    : super(
        retry: null,
        name: r'budgetStatisticsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Budget Statistics Provider - Real data from database

  BudgetStatisticsProvider call(String budgetId) =>
      BudgetStatisticsProvider._(argument: budgetId, from: this);

  @override
  String toString() => r'budgetStatisticsProvider';
}

/// Category Breakdown Provider - Real spending by category

@ProviderFor(categoryBreakdown)
final categoryBreakdownProvider = CategoryBreakdownFamily._();

/// Category Breakdown Provider - Real spending by category

final class CategoryBreakdownProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<CategorySpending>>,
          List<CategorySpending>,
          FutureOr<List<CategorySpending>>
        >
    with
        $FutureModifier<List<CategorySpending>>,
        $FutureProvider<List<CategorySpending>> {
  /// Category Breakdown Provider - Real spending by category
  CategoryBreakdownProvider._({
    required CategoryBreakdownFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'categoryBreakdownProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$categoryBreakdownHash();

  @override
  String toString() {
    return r'categoryBreakdownProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<CategorySpending>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<CategorySpending>> create(Ref ref) {
    final argument = this.argument as String;
    return categoryBreakdown(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CategoryBreakdownProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$categoryBreakdownHash() => r'59511f1bd0851f6f606711c50126523f48fd772d';

/// Category Breakdown Provider - Real spending by category

final class CategoryBreakdownFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<CategorySpending>>, String> {
  CategoryBreakdownFamily._()
    : super(
        retry: null,
        name: r'categoryBreakdownProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Category Breakdown Provider - Real spending by category

  CategoryBreakdownProvider call(String budgetId) =>
      CategoryBreakdownProvider._(argument: budgetId, from: this);

  @override
  String toString() => r'categoryBreakdownProvider';
}

/// Health Score Provider - Calculated from real data

@ProviderFor(healthScore)
final healthScoreProvider = HealthScoreFamily._();

/// Health Score Provider - Calculated from real data

final class HealthScoreProvider
    extends
        $FunctionalProvider<
          AsyncValue<HealthScoreData>,
          HealthScoreData,
          FutureOr<HealthScoreData>
        >
    with $FutureModifier<HealthScoreData>, $FutureProvider<HealthScoreData> {
  /// Health Score Provider - Calculated from real data
  HealthScoreProvider._({
    required HealthScoreFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'healthScoreProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$healthScoreHash();

  @override
  String toString() {
    return r'healthScoreProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<HealthScoreData> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<HealthScoreData> create(Ref ref) {
    final argument = this.argument as String;
    return healthScore(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is HealthScoreProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$healthScoreHash() => r'4ce683c5ad2eabb900ce9ec959aa6d221785f5ad';

/// Health Score Provider - Calculated from real data

final class HealthScoreFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<HealthScoreData>, String> {
  HealthScoreFamily._()
    : super(
        retry: null,
        name: r'healthScoreProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Health Score Provider - Calculated from real data

  HealthScoreProvider call(String budgetId) =>
      HealthScoreProvider._(argument: budgetId, from: this);

  @override
  String toString() => r'healthScoreProvider';
}
