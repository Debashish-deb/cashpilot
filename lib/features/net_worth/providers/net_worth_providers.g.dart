// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'net_worth_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(netWorthRepository)
final netWorthRepositoryProvider = NetWorthRepositoryProvider._();

final class NetWorthRepositoryProvider
    extends
        $FunctionalProvider<
          NetWorthRepository,
          NetWorthRepository,
          NetWorthRepository
        >
    with $Provider<NetWorthRepository> {
  NetWorthRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'netWorthRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$netWorthRepositoryHash();

  @$internal
  @override
  $ProviderElement<NetWorthRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  NetWorthRepository create(Ref ref) {
    return netWorthRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NetWorthRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NetWorthRepository>(value),
    );
  }
}

String _$netWorthRepositoryHash() =>
    r'3c94c23f404004cec761afc53688d033f731ca2b';

@ProviderFor(assetsStream)
final assetsStreamProvider = AssetsStreamProvider._();

final class AssetsStreamProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Asset>>,
          List<Asset>,
          Stream<List<Asset>>
        >
    with $FutureModifier<List<Asset>>, $StreamProvider<List<Asset>> {
  AssetsStreamProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'assetsStreamProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$assetsStreamHash();

  @$internal
  @override
  $StreamProviderElement<List<Asset>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Asset>> create(Ref ref) {
    return assetsStream(ref);
  }
}

String _$assetsStreamHash() => r'e211b022b4750307942694de4506151bf23c4f01';

@ProviderFor(liabilitiesStream)
final liabilitiesStreamProvider = LiabilitiesStreamProvider._();

final class LiabilitiesStreamProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Liability>>,
          List<Liability>,
          Stream<List<Liability>>
        >
    with $FutureModifier<List<Liability>>, $StreamProvider<List<Liability>> {
  LiabilitiesStreamProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'liabilitiesStreamProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$liabilitiesStreamHash();

  @$internal
  @override
  $StreamProviderElement<List<Liability>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Liability>> create(Ref ref) {
    return liabilitiesStream(ref);
  }
}

String _$liabilitiesStreamHash() => r'470d5eb6a5f4f96f4bf1034fbdf4817345f8c1f7';

@ProviderFor(liveNetWorth)
final liveNetWorthProvider = LiveNetWorthProvider._();

final class LiveNetWorthProvider
    extends $FunctionalProvider<AsyncValue<int>, int, Stream<int>>
    with $FutureModifier<int>, $StreamProvider<int> {
  LiveNetWorthProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'liveNetWorthProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$liveNetWorthHash();

  @$internal
  @override
  $StreamProviderElement<int> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<int> create(Ref ref) {
    return liveNetWorth(ref);
  }
}

String _$liveNetWorthHash() => r'efac234115cbe3c9ff374cefc6202c3cdc02d825';

@ProviderFor(netWorthHistory)
final netWorthHistoryProvider = NetWorthHistoryFamily._();

final class NetWorthHistoryProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<NetWorthHistoryPoint>>,
          List<NetWorthHistoryPoint>,
          FutureOr<List<NetWorthHistoryPoint>>
        >
    with
        $FutureModifier<List<NetWorthHistoryPoint>>,
        $FutureProvider<List<NetWorthHistoryPoint>> {
  NetWorthHistoryProvider._({
    required NetWorthHistoryFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'netWorthHistoryProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$netWorthHistoryHash();

  @override
  String toString() {
    return r'netWorthHistoryProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<NetWorthHistoryPoint>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<NetWorthHistoryPoint>> create(Ref ref) {
    final argument = this.argument as int;
    return netWorthHistory(ref, days: argument);
  }

  @override
  bool operator ==(Object other) {
    return other is NetWorthHistoryProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$netWorthHistoryHash() => r'5f03f05fbaa41ba7f12c88cd22db2b1b4beeaca3';

final class NetWorthHistoryFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<NetWorthHistoryPoint>>, int> {
  NetWorthHistoryFamily._()
    : super(
        retry: null,
        name: r'netWorthHistoryProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  NetWorthHistoryProvider call({int days = 30}) =>
      NetWorthHistoryProvider._(argument: days, from: this);

  @override
  String toString() => r'netWorthHistoryProvider';
}

@ProviderFor(netWorthSummary)
final netWorthSummaryProvider = NetWorthSummaryProvider._();

final class NetWorthSummaryProvider
    extends
        $FunctionalProvider<
          AsyncValue<NetWorthSummaryData>,
          NetWorthSummaryData,
          Stream<NetWorthSummaryData>
        >
    with
        $FutureModifier<NetWorthSummaryData>,
        $StreamProvider<NetWorthSummaryData> {
  NetWorthSummaryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'netWorthSummaryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$netWorthSummaryHash();

  @$internal
  @override
  $StreamProviderElement<NetWorthSummaryData> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<NetWorthSummaryData> create(Ref ref) {
    return netWorthSummary(ref);
  }
}

String _$netWorthSummaryHash() => r'a136d940038a0d140db6ace9f1cabf331fe7d596';

@ProviderFor(forecastingService)
final forecastingServiceProvider = ForecastingServiceProvider._();

final class ForecastingServiceProvider
    extends
        $FunctionalProvider<
          ForecastingService,
          ForecastingService,
          ForecastingService
        >
    with $Provider<ForecastingService> {
  ForecastingServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'forecastingServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$forecastingServiceHash();

  @$internal
  @override
  $ProviderElement<ForecastingService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ForecastingService create(Ref ref) {
    return forecastingService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ForecastingService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ForecastingService>(value),
    );
  }
}

String _$forecastingServiceHash() =>
    r'57da0e1b17584129288edf26abac0633a7af44e7';

@ProviderFor(netWorthForecast)
final netWorthForecastProvider = NetWorthForecastFamily._();

final class NetWorthForecastProvider
    extends $FunctionalProvider<AsyncValue<double>, double, FutureOr<double>>
    with $FutureModifier<double>, $FutureProvider<double> {
  NetWorthForecastProvider._({
    required NetWorthForecastFamily super.from,
    required DateTime super.argument,
  }) : super(
         retry: null,
         name: r'netWorthForecastProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$netWorthForecastHash();

  @override
  String toString() {
    return r'netWorthForecastProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<double> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<double> create(Ref ref) {
    final argument = this.argument as DateTime;
    return netWorthForecast(ref, targetDate: argument);
  }

  @override
  bool operator ==(Object other) {
    return other is NetWorthForecastProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$netWorthForecastHash() => r'c493d27a9dd5e43d7159bbf5bb48e478fc06d303';

final class NetWorthForecastFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<double>, DateTime> {
  NetWorthForecastFamily._()
    : super(
        retry: null,
        name: r'netWorthForecastProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  NetWorthForecastProvider call({required DateTime targetDate}) =>
      NetWorthForecastProvider._(argument: targetDate, from: this);

  @override
  String toString() => r'netWorthForecastProvider';
}

@ProviderFor(daysToNetWorthGoal)
final daysToNetWorthGoalProvider = DaysToNetWorthGoalFamily._();

final class DaysToNetWorthGoalProvider
    extends $FunctionalProvider<AsyncValue<int>, int, FutureOr<int>>
    with $FutureModifier<int>, $FutureProvider<int> {
  DaysToNetWorthGoalProvider._({
    required DaysToNetWorthGoalFamily super.from,
    required double super.argument,
  }) : super(
         retry: null,
         name: r'daysToNetWorthGoalProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$daysToNetWorthGoalHash();

  @override
  String toString() {
    return r'daysToNetWorthGoalProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<int> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<int> create(Ref ref) {
    final argument = this.argument as double;
    return daysToNetWorthGoal(ref, goal: argument);
  }

  @override
  bool operator ==(Object other) {
    return other is DaysToNetWorthGoalProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$daysToNetWorthGoalHash() =>
    r'a8df9c7f5377d5245d03a4a494e595478dafc789';

final class DaysToNetWorthGoalFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<int>, double> {
  DaysToNetWorthGoalFamily._()
    : super(
        retry: null,
        name: r'daysToNetWorthGoalProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  DaysToNetWorthGoalProvider call({required double goal}) =>
      DaysToNetWorthGoalProvider._(argument: goal, from: this);

  @override
  String toString() => r'daysToNetWorthGoalProvider';
}

@ProviderFor(NetWorthController)
final netWorthControllerProvider = NetWorthControllerProvider._();

final class NetWorthControllerProvider
    extends $AsyncNotifierProvider<NetWorthController, void> {
  NetWorthControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'netWorthControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$netWorthControllerHash();

  @$internal
  @override
  NetWorthController create() => NetWorthController();
}

String _$netWorthControllerHash() =>
    r'b70fc00f8300175480e4419689969cdc36cc12b8';

abstract class _$NetWorthController extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
