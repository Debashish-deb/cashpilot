// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subcategory_intelligence_engine.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(subcategoryIntelligenceEngine)
final subcategoryIntelligenceEngineProvider =
    SubcategoryIntelligenceEngineProvider._();

final class SubcategoryIntelligenceEngineProvider
    extends
        $FunctionalProvider<
          SubcategoryIntelligenceEngine,
          SubcategoryIntelligenceEngine,
          SubcategoryIntelligenceEngine
        >
    with $Provider<SubcategoryIntelligenceEngine> {
  SubcategoryIntelligenceEngineProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'subcategoryIntelligenceEngineProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$subcategoryIntelligenceEngineHash();

  @$internal
  @override
  $ProviderElement<SubcategoryIntelligenceEngine> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SubcategoryIntelligenceEngine create(Ref ref) {
    return subcategoryIntelligenceEngine(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SubcategoryIntelligenceEngine value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SubcategoryIntelligenceEngine>(
        value,
      ),
    );
  }
}

String _$subcategoryIntelligenceEngineHash() =>
    r'80d91d9625e3399f15a7dbdc7fe08d80f7a742f5';
