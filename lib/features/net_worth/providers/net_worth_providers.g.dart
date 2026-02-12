// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'net_worth_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$netWorthRepositoryHash() =>
    r'3c94c23f404004cec761afc53688d033f731ca2b';

/// See also [netWorthRepository].
@ProviderFor(netWorthRepository)
final netWorthRepositoryProvider = Provider<NetWorthRepository>.internal(
  netWorthRepository,
  name: r'netWorthRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$netWorthRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef NetWorthRepositoryRef = ProviderRef<NetWorthRepository>;
String _$assetsStreamHash() => r'e211b022b4750307942694de4506151bf23c4f01';

/// See also [assetsStream].
@ProviderFor(assetsStream)
final assetsStreamProvider = AutoDisposeStreamProvider<List<Asset>>.internal(
  assetsStream,
  name: r'assetsStreamProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$assetsStreamHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AssetsStreamRef = AutoDisposeStreamProviderRef<List<Asset>>;
String _$liabilitiesStreamHash() => r'470d5eb6a5f4f96f4bf1034fbdf4817345f8c1f7';

/// See also [liabilitiesStream].
@ProviderFor(liabilitiesStream)
final liabilitiesStreamProvider =
    AutoDisposeStreamProvider<List<Liability>>.internal(
      liabilitiesStream,
      name: r'liabilitiesStreamProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$liabilitiesStreamHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef LiabilitiesStreamRef = AutoDisposeStreamProviderRef<List<Liability>>;
String _$liveNetWorthHash() => r'efac234115cbe3c9ff374cefc6202c3cdc02d825';

/// See also [liveNetWorth].
@ProviderFor(liveNetWorth)
final liveNetWorthProvider = AutoDisposeStreamProvider<int>.internal(
  liveNetWorth,
  name: r'liveNetWorthProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$liveNetWorthHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef LiveNetWorthRef = AutoDisposeStreamProviderRef<int>;
String _$netWorthHistoryHash() => r'5f03f05fbaa41ba7f12c88cd22db2b1b4beeaca3';

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

/// See also [netWorthHistory].
@ProviderFor(netWorthHistory)
const netWorthHistoryProvider = NetWorthHistoryFamily();

/// See also [netWorthHistory].
class NetWorthHistoryFamily
    extends Family<AsyncValue<List<NetWorthHistoryPoint>>> {
  /// See also [netWorthHistory].
  const NetWorthHistoryFamily();

  /// See also [netWorthHistory].
  NetWorthHistoryProvider call({int days = 30}) {
    return NetWorthHistoryProvider(days: days);
  }

  @override
  NetWorthHistoryProvider getProviderOverride(
    covariant NetWorthHistoryProvider provider,
  ) {
    return call(days: provider.days);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'netWorthHistoryProvider';
}

/// See also [netWorthHistory].
class NetWorthHistoryProvider
    extends AutoDisposeFutureProvider<List<NetWorthHistoryPoint>> {
  /// See also [netWorthHistory].
  NetWorthHistoryProvider({int days = 30})
    : this._internal(
        (ref) => netWorthHistory(ref as NetWorthHistoryRef, days: days),
        from: netWorthHistoryProvider,
        name: r'netWorthHistoryProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$netWorthHistoryHash,
        dependencies: NetWorthHistoryFamily._dependencies,
        allTransitiveDependencies:
            NetWorthHistoryFamily._allTransitiveDependencies,
        days: days,
      );

  NetWorthHistoryProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.days,
  }) : super.internal();

  final int days;

  @override
  Override overrideWith(
    FutureOr<List<NetWorthHistoryPoint>> Function(NetWorthHistoryRef provider)
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: NetWorthHistoryProvider._internal(
        (ref) => create(ref as NetWorthHistoryRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        days: days,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<NetWorthHistoryPoint>> createElement() {
    return _NetWorthHistoryProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is NetWorthHistoryProvider && other.days == days;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, days.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin NetWorthHistoryRef
    on AutoDisposeFutureProviderRef<List<NetWorthHistoryPoint>> {
  /// The parameter `days` of this provider.
  int get days;
}

class _NetWorthHistoryProviderElement
    extends AutoDisposeFutureProviderElement<List<NetWorthHistoryPoint>>
    with NetWorthHistoryRef {
  _NetWorthHistoryProviderElement(super.provider);

  @override
  int get days => (origin as NetWorthHistoryProvider).days;
}

String _$netWorthSummaryHash() => r'a136d940038a0d140db6ace9f1cabf331fe7d596';

/// See also [netWorthSummary].
@ProviderFor(netWorthSummary)
final netWorthSummaryProvider =
    AutoDisposeStreamProvider<NetWorthSummaryData>.internal(
      netWorthSummary,
      name: r'netWorthSummaryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$netWorthSummaryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef NetWorthSummaryRef = AutoDisposeStreamProviderRef<NetWorthSummaryData>;
String _$forecastingServiceHash() =>
    r'57da0e1b17584129288edf26abac0633a7af44e7';

/// See also [forecastingService].
@ProviderFor(forecastingService)
final forecastingServiceProvider = Provider<ForecastingService>.internal(
  forecastingService,
  name: r'forecastingServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$forecastingServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ForecastingServiceRef = ProviderRef<ForecastingService>;
String _$netWorthForecastHash() => r'c493d27a9dd5e43d7159bbf5bb48e478fc06d303';

/// See also [netWorthForecast].
@ProviderFor(netWorthForecast)
const netWorthForecastProvider = NetWorthForecastFamily();

/// See also [netWorthForecast].
class NetWorthForecastFamily extends Family<AsyncValue<double>> {
  /// See also [netWorthForecast].
  const NetWorthForecastFamily();

  /// See also [netWorthForecast].
  NetWorthForecastProvider call({required DateTime targetDate}) {
    return NetWorthForecastProvider(targetDate: targetDate);
  }

  @override
  NetWorthForecastProvider getProviderOverride(
    covariant NetWorthForecastProvider provider,
  ) {
    return call(targetDate: provider.targetDate);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'netWorthForecastProvider';
}

/// See also [netWorthForecast].
class NetWorthForecastProvider extends AutoDisposeFutureProvider<double> {
  /// See also [netWorthForecast].
  NetWorthForecastProvider({required DateTime targetDate})
    : this._internal(
        (ref) => netWorthForecast(
          ref as NetWorthForecastRef,
          targetDate: targetDate,
        ),
        from: netWorthForecastProvider,
        name: r'netWorthForecastProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$netWorthForecastHash,
        dependencies: NetWorthForecastFamily._dependencies,
        allTransitiveDependencies:
            NetWorthForecastFamily._allTransitiveDependencies,
        targetDate: targetDate,
      );

  NetWorthForecastProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.targetDate,
  }) : super.internal();

  final DateTime targetDate;

  @override
  Override overrideWith(
    FutureOr<double> Function(NetWorthForecastRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: NetWorthForecastProvider._internal(
        (ref) => create(ref as NetWorthForecastRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        targetDate: targetDate,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<double> createElement() {
    return _NetWorthForecastProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is NetWorthForecastProvider && other.targetDate == targetDate;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, targetDate.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin NetWorthForecastRef on AutoDisposeFutureProviderRef<double> {
  /// The parameter `targetDate` of this provider.
  DateTime get targetDate;
}

class _NetWorthForecastProviderElement
    extends AutoDisposeFutureProviderElement<double>
    with NetWorthForecastRef {
  _NetWorthForecastProviderElement(super.provider);

  @override
  DateTime get targetDate => (origin as NetWorthForecastProvider).targetDate;
}

String _$daysToNetWorthGoalHash() =>
    r'a8df9c7f5377d5245d03a4a494e595478dafc789';

/// See also [daysToNetWorthGoal].
@ProviderFor(daysToNetWorthGoal)
const daysToNetWorthGoalProvider = DaysToNetWorthGoalFamily();

/// See also [daysToNetWorthGoal].
class DaysToNetWorthGoalFamily extends Family<AsyncValue<int>> {
  /// See also [daysToNetWorthGoal].
  const DaysToNetWorthGoalFamily();

  /// See also [daysToNetWorthGoal].
  DaysToNetWorthGoalProvider call({required double goal}) {
    return DaysToNetWorthGoalProvider(goal: goal);
  }

  @override
  DaysToNetWorthGoalProvider getProviderOverride(
    covariant DaysToNetWorthGoalProvider provider,
  ) {
    return call(goal: provider.goal);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'daysToNetWorthGoalProvider';
}

/// See also [daysToNetWorthGoal].
class DaysToNetWorthGoalProvider extends AutoDisposeFutureProvider<int> {
  /// See also [daysToNetWorthGoal].
  DaysToNetWorthGoalProvider({required double goal})
    : this._internal(
        (ref) => daysToNetWorthGoal(ref as DaysToNetWorthGoalRef, goal: goal),
        from: daysToNetWorthGoalProvider,
        name: r'daysToNetWorthGoalProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$daysToNetWorthGoalHash,
        dependencies: DaysToNetWorthGoalFamily._dependencies,
        allTransitiveDependencies:
            DaysToNetWorthGoalFamily._allTransitiveDependencies,
        goal: goal,
      );

  DaysToNetWorthGoalProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.goal,
  }) : super.internal();

  final double goal;

  @override
  Override overrideWith(
    FutureOr<int> Function(DaysToNetWorthGoalRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: DaysToNetWorthGoalProvider._internal(
        (ref) => create(ref as DaysToNetWorthGoalRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        goal: goal,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<int> createElement() {
    return _DaysToNetWorthGoalProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is DaysToNetWorthGoalProvider && other.goal == goal;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, goal.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin DaysToNetWorthGoalRef on AutoDisposeFutureProviderRef<int> {
  /// The parameter `goal` of this provider.
  double get goal;
}

class _DaysToNetWorthGoalProviderElement
    extends AutoDisposeFutureProviderElement<int>
    with DaysToNetWorthGoalRef {
  _DaysToNetWorthGoalProviderElement(super.provider);

  @override
  double get goal => (origin as DaysToNetWorthGoalProvider).goal;
}

String _$netWorthControllerHash() =>
    r'b70fc00f8300175480e4419689969cdc36cc12b8';

/// See also [NetWorthController].
@ProviderFor(NetWorthController)
final netWorthControllerProvider =
    AutoDisposeAsyncNotifierProvider<NetWorthController, void>.internal(
      NetWorthController.new,
      name: r'netWorthControllerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$netWorthControllerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$NetWorthController = AutoDisposeAsyncNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
