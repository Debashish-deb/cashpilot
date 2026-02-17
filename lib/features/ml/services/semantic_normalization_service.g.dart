// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'semantic_normalization_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(semanticNormalizationService)
final semanticNormalizationServiceProvider =
    SemanticNormalizationServiceProvider._();

final class SemanticNormalizationServiceProvider
    extends
        $FunctionalProvider<
          SemanticNormalizationService,
          SemanticNormalizationService,
          SemanticNormalizationService
        >
    with $Provider<SemanticNormalizationService> {
  SemanticNormalizationServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'semanticNormalizationServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$semanticNormalizationServiceHash();

  @$internal
  @override
  $ProviderElement<SemanticNormalizationService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SemanticNormalizationService create(Ref ref) {
    return semanticNormalizationService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SemanticNormalizationService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SemanticNormalizationService>(value),
    );
  }
}

String _$semanticNormalizationServiceHash() =>
    r'7b3cf587582180c06cc612d6aa74afc5b0f20474';
