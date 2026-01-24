// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'computed_analytics_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$budgetStatisticsHash() => r'49aa288111b9545351b0b32faa47f7d96d9a63d3';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// Budget Statistics Provider - Real data from database
///
/// Copied from [budgetStatistics].
@ProviderFor(budgetStatistics)
const budgetStatisticsProvider = BudgetStatisticsFamily();

/// Budget Statistics Provider - Real data from database
///
/// Copied from [budgetStatistics].
class BudgetStatisticsFamily extends Family<AsyncValue<BudgetStatistics>> {
  /// Budget Statistics Provider - Real data from database
  ///
  /// Copied from [budgetStatistics].
  const BudgetStatisticsFamily();

  /// Budget Statistics Provider - Real data from database
  ///
  /// Copied from [budgetStatistics].
  BudgetStatisticsProvider call(String budgetId) {
    return BudgetStatisticsProvider(budgetId);
  }

  @override
  BudgetStatisticsProvider getProviderOverride(
    covariant BudgetStatisticsProvider provider,
  ) {
    return call(provider.budgetId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'budgetStatisticsProvider';
}

/// Budget Statistics Provider - Real data from database
///
/// Copied from [budgetStatistics].
class BudgetStatisticsProvider
    extends AutoDisposeFutureProvider<BudgetStatistics> {
  /// Budget Statistics Provider - Real data from database
  ///
  /// Copied from [budgetStatistics].
  BudgetStatisticsProvider(String budgetId)
    : this._internal(
        (ref) => budgetStatistics(ref as BudgetStatisticsRef, budgetId),
        from: budgetStatisticsProvider,
        name: r'budgetStatisticsProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$budgetStatisticsHash,
        dependencies: BudgetStatisticsFamily._dependencies,
        allTransitiveDependencies:
            BudgetStatisticsFamily._allTransitiveDependencies,
        budgetId: budgetId,
      );

  BudgetStatisticsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.budgetId,
  }) : super.internal();

  final String budgetId;

  @override
  Override overrideWith(
    FutureOr<BudgetStatistics> Function(BudgetStatisticsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: BudgetStatisticsProvider._internal(
        (ref) => create(ref as BudgetStatisticsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        budgetId: budgetId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<BudgetStatistics> createElement() {
    return _BudgetStatisticsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is BudgetStatisticsProvider && other.budgetId == budgetId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, budgetId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin BudgetStatisticsRef on AutoDisposeFutureProviderRef<BudgetStatistics> {
  /// The parameter `budgetId` of this provider.
  String get budgetId;
}

class _BudgetStatisticsProviderElement
    extends AutoDisposeFutureProviderElement<BudgetStatistics>
    with BudgetStatisticsRef {
  _BudgetStatisticsProviderElement(super.provider);

  @override
  String get budgetId => (origin as BudgetStatisticsProvider).budgetId;
}

String _$categoryBreakdownHash() => r'59511f1bd0851f6f606711c50126523f48fd772d';

/// Category Breakdown Provider - Real spending by category
///
/// Copied from [categoryBreakdown].
@ProviderFor(categoryBreakdown)
const categoryBreakdownProvider = CategoryBreakdownFamily();

/// Category Breakdown Provider - Real spending by category
///
/// Copied from [categoryBreakdown].
class CategoryBreakdownFamily
    extends Family<AsyncValue<List<CategorySpending>>> {
  /// Category Breakdown Provider - Real spending by category
  ///
  /// Copied from [categoryBreakdown].
  const CategoryBreakdownFamily();

  /// Category Breakdown Provider - Real spending by category
  ///
  /// Copied from [categoryBreakdown].
  CategoryBreakdownProvider call(String budgetId) {
    return CategoryBreakdownProvider(budgetId);
  }

  @override
  CategoryBreakdownProvider getProviderOverride(
    covariant CategoryBreakdownProvider provider,
  ) {
    return call(provider.budgetId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'categoryBreakdownProvider';
}

/// Category Breakdown Provider - Real spending by category
///
/// Copied from [categoryBreakdown].
class CategoryBreakdownProvider
    extends AutoDisposeFutureProvider<List<CategorySpending>> {
  /// Category Breakdown Provider - Real spending by category
  ///
  /// Copied from [categoryBreakdown].
  CategoryBreakdownProvider(String budgetId)
    : this._internal(
        (ref) => categoryBreakdown(ref as CategoryBreakdownRef, budgetId),
        from: categoryBreakdownProvider,
        name: r'categoryBreakdownProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$categoryBreakdownHash,
        dependencies: CategoryBreakdownFamily._dependencies,
        allTransitiveDependencies:
            CategoryBreakdownFamily._allTransitiveDependencies,
        budgetId: budgetId,
      );

  CategoryBreakdownProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.budgetId,
  }) : super.internal();

  final String budgetId;

  @override
  Override overrideWith(
    FutureOr<List<CategorySpending>> Function(CategoryBreakdownRef provider)
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: CategoryBreakdownProvider._internal(
        (ref) => create(ref as CategoryBreakdownRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        budgetId: budgetId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<CategorySpending>> createElement() {
    return _CategoryBreakdownProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CategoryBreakdownProvider && other.budgetId == budgetId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, budgetId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin CategoryBreakdownRef
    on AutoDisposeFutureProviderRef<List<CategorySpending>> {
  /// The parameter `budgetId` of this provider.
  String get budgetId;
}

class _CategoryBreakdownProviderElement
    extends AutoDisposeFutureProviderElement<List<CategorySpending>>
    with CategoryBreakdownRef {
  _CategoryBreakdownProviderElement(super.provider);

  @override
  String get budgetId => (origin as CategoryBreakdownProvider).budgetId;
}

String _$healthScoreHash() => r'33a84938f377f6def13dc078150cd02a6603429a';

/// Health Score Provider - Calculated from real data
///
/// Copied from [healthScore].
@ProviderFor(healthScore)
const healthScoreProvider = HealthScoreFamily();

/// Health Score Provider - Calculated from real data
///
/// Copied from [healthScore].
class HealthScoreFamily extends Family<AsyncValue<HealthScoreData>> {
  /// Health Score Provider - Calculated from real data
  ///
  /// Copied from [healthScore].
  const HealthScoreFamily();

  /// Health Score Provider - Calculated from real data
  ///
  /// Copied from [healthScore].
  HealthScoreProvider call(String budgetId) {
    return HealthScoreProvider(budgetId);
  }

  @override
  HealthScoreProvider getProviderOverride(
    covariant HealthScoreProvider provider,
  ) {
    return call(provider.budgetId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'healthScoreProvider';
}

/// Health Score Provider - Calculated from real data
///
/// Copied from [healthScore].
class HealthScoreProvider extends AutoDisposeFutureProvider<HealthScoreData> {
  /// Health Score Provider - Calculated from real data
  ///
  /// Copied from [healthScore].
  HealthScoreProvider(String budgetId)
    : this._internal(
        (ref) => healthScore(ref as HealthScoreRef, budgetId),
        from: healthScoreProvider,
        name: r'healthScoreProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$healthScoreHash,
        dependencies: HealthScoreFamily._dependencies,
        allTransitiveDependencies: HealthScoreFamily._allTransitiveDependencies,
        budgetId: budgetId,
      );

  HealthScoreProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.budgetId,
  }) : super.internal();

  final String budgetId;

  @override
  Override overrideWith(
    FutureOr<HealthScoreData> Function(HealthScoreRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: HealthScoreProvider._internal(
        (ref) => create(ref as HealthScoreRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        budgetId: budgetId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<HealthScoreData> createElement() {
    return _HealthScoreProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is HealthScoreProvider && other.budgetId == budgetId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, budgetId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin HealthScoreRef on AutoDisposeFutureProviderRef<HealthScoreData> {
  /// The parameter `budgetId` of this provider.
  String get budgetId;
}

class _HealthScoreProviderElement
    extends AutoDisposeFutureProviderElement<HealthScoreData>
    with HealthScoreRef {
  _HealthScoreProviderElement(super.provider);

  @override
  String get budgetId => (origin as HealthScoreProvider).budgetId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
