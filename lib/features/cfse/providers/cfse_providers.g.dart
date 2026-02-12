// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cfse_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$financialStateEngineHash() =>
    r'83bbd77cdb1dbf7234e5b9e191bce758b4099d60';

/// See also [financialStateEngine].
@ProviderFor(financialStateEngine)
final financialStateEngineProvider = Provider<IFinancialStateEngine>.internal(
  financialStateEngine,
  name: r'financialStateEngineProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$financialStateEngineHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FinancialStateEngineRef = ProviderRef<IFinancialStateEngine>;
String _$currentFinancialStateHash() =>
    r'c597da777c9a968cf19af5d0b651b50c883f3314';

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

/// See also [currentFinancialState].
@ProviderFor(currentFinancialState)
const currentFinancialStateProvider = CurrentFinancialStateFamily();

/// See also [currentFinancialState].
class CurrentFinancialStateFamily extends Family<AsyncValue<FinancialState>> {
  /// See also [currentFinancialState].
  const CurrentFinancialStateFamily();

  /// See also [currentFinancialState].
  CurrentFinancialStateProvider call(String userId) {
    return CurrentFinancialStateProvider(userId);
  }

  @override
  CurrentFinancialStateProvider getProviderOverride(
    covariant CurrentFinancialStateProvider provider,
  ) {
    return call(provider.userId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'currentFinancialStateProvider';
}

/// See also [currentFinancialState].
class CurrentFinancialStateProvider
    extends AutoDisposeStreamProvider<FinancialState> {
  /// See also [currentFinancialState].
  CurrentFinancialStateProvider(String userId)
    : this._internal(
        (ref) => currentFinancialState(ref as CurrentFinancialStateRef, userId),
        from: currentFinancialStateProvider,
        name: r'currentFinancialStateProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$currentFinancialStateHash,
        dependencies: CurrentFinancialStateFamily._dependencies,
        allTransitiveDependencies:
            CurrentFinancialStateFamily._allTransitiveDependencies,
        userId: userId,
      );

  CurrentFinancialStateProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.userId,
  }) : super.internal();

  final String userId;

  @override
  Override overrideWith(
    Stream<FinancialState> Function(CurrentFinancialStateRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: CurrentFinancialStateProvider._internal(
        (ref) => create(ref as CurrentFinancialStateRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        userId: userId,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<FinancialState> createElement() {
    return _CurrentFinancialStateProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CurrentFinancialStateProvider && other.userId == userId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, userId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin CurrentFinancialStateRef on AutoDisposeStreamProviderRef<FinancialState> {
  /// The parameter `userId` of this provider.
  String get userId;
}

class _CurrentFinancialStateProviderElement
    extends AutoDisposeStreamProviderElement<FinancialState>
    with CurrentFinancialStateRef {
  _CurrentFinancialStateProviderElement(super.provider);

  @override
  String get userId => (origin as CurrentFinancialStateProvider).userId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
