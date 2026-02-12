// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'knowledge_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$knowledgeRepositoryHash() =>
    r'75143fa051fe7e434b71bebc4c0bb5ee1816749e';

/// See also [knowledgeRepository].
@ProviderFor(knowledgeRepository)
final knowledgeRepositoryProvider = Provider<KnowledgeRepository>.internal(
  knowledgeRepository,
  name: r'knowledgeRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$knowledgeRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef KnowledgeRepositoryRef = ProviderRef<KnowledgeRepository>;
String _$dailyTipHash() => r'8b07d2b47419c2b265917fadeea971fc7310c7f0';

/// See also [dailyTip].
@ProviderFor(dailyTip)
final dailyTipProvider = AutoDisposeFutureProvider<FinancialTip?>.internal(
  dailyTip,
  name: r'dailyTipProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$dailyTipHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef DailyTipRef = AutoDisposeFutureProviderRef<FinancialTip?>;
String _$suggestedArticlesHash() => r'eaf6231a0d5d792e26a9d7c630067f9d2a974300';

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

/// See also [suggestedArticles].
@ProviderFor(suggestedArticles)
const suggestedArticlesProvider = SuggestedArticlesFamily();

/// See also [suggestedArticles].
class SuggestedArticlesFamily
    extends Family<AsyncValue<List<KnowledgeArticle>>> {
  /// See also [suggestedArticles].
  const SuggestedArticlesFamily();

  /// See also [suggestedArticles].
  SuggestedArticlesProvider call({String topic = 'budgeting'}) {
    return SuggestedArticlesProvider(topic: topic);
  }

  @override
  SuggestedArticlesProvider getProviderOverride(
    covariant SuggestedArticlesProvider provider,
  ) {
    return call(topic: provider.topic);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'suggestedArticlesProvider';
}

/// See also [suggestedArticles].
class SuggestedArticlesProvider
    extends AutoDisposeFutureProvider<List<KnowledgeArticle>> {
  /// See also [suggestedArticles].
  SuggestedArticlesProvider({String topic = 'budgeting'})
    : this._internal(
        (ref) => suggestedArticles(ref as SuggestedArticlesRef, topic: topic),
        from: suggestedArticlesProvider,
        name: r'suggestedArticlesProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$suggestedArticlesHash,
        dependencies: SuggestedArticlesFamily._dependencies,
        allTransitiveDependencies:
            SuggestedArticlesFamily._allTransitiveDependencies,
        topic: topic,
      );

  SuggestedArticlesProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.topic,
  }) : super.internal();

  final String topic;

  @override
  Override overrideWith(
    FutureOr<List<KnowledgeArticle>> Function(SuggestedArticlesRef provider)
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: SuggestedArticlesProvider._internal(
        (ref) => create(ref as SuggestedArticlesRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        topic: topic,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<KnowledgeArticle>> createElement() {
    return _SuggestedArticlesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SuggestedArticlesProvider && other.topic == topic;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, topic.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin SuggestedArticlesRef
    on AutoDisposeFutureProviderRef<List<KnowledgeArticle>> {
  /// The parameter `topic` of this provider.
  String get topic;
}

class _SuggestedArticlesProviderElement
    extends AutoDisposeFutureProviderElement<List<KnowledgeArticle>>
    with SuggestedArticlesRef {
  _SuggestedArticlesProviderElement(super.provider);

  @override
  String get topic => (origin as SuggestedArticlesProvider).topic;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
