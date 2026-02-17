// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cfse_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(financialStateEngine)
final financialStateEngineProvider = FinancialStateEngineProvider._();

final class FinancialStateEngineProvider
    extends
        $FunctionalProvider<
          IFinancialStateEngine,
          IFinancialStateEngine,
          IFinancialStateEngine
        >
    with $Provider<IFinancialStateEngine> {
  FinancialStateEngineProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'financialStateEngineProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$financialStateEngineHash();

  @$internal
  @override
  $ProviderElement<IFinancialStateEngine> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  IFinancialStateEngine create(Ref ref) {
    return financialStateEngine(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IFinancialStateEngine value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IFinancialStateEngine>(value),
    );
  }
}

String _$financialStateEngineHash() =>
    r'83bbd77cdb1dbf7234e5b9e191bce758b4099d60';

@ProviderFor(currentFinancialState)
final currentFinancialStateProvider = CurrentFinancialStateFamily._();

final class CurrentFinancialStateProvider
    extends
        $FunctionalProvider<
          AsyncValue<FinancialState>,
          FinancialState,
          Stream<FinancialState>
        >
    with $FutureModifier<FinancialState>, $StreamProvider<FinancialState> {
  CurrentFinancialStateProvider._({
    required CurrentFinancialStateFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'currentFinancialStateProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$currentFinancialStateHash();

  @override
  String toString() {
    return r'currentFinancialStateProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<FinancialState> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<FinancialState> create(Ref ref) {
    final argument = this.argument as String;
    return currentFinancialState(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CurrentFinancialStateProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$currentFinancialStateHash() =>
    r'c597da777c9a968cf19af5d0b651b50c883f3314';

final class CurrentFinancialStateFamily extends $Family
    with $FunctionalFamilyOverride<Stream<FinancialState>, String> {
  CurrentFinancialStateFamily._()
    : super(
        retry: null,
        name: r'currentFinancialStateProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  CurrentFinancialStateProvider call(String userId) =>
      CurrentFinancialStateProvider._(argument: userId, from: this);

  @override
  String toString() => r'currentFinancialStateProvider';
}
