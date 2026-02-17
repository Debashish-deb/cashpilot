// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'knowledge_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(knowledgeRepository)
final knowledgeRepositoryProvider = KnowledgeRepositoryProvider._();

final class KnowledgeRepositoryProvider
    extends
        $FunctionalProvider<
          KnowledgeRepository,
          KnowledgeRepository,
          KnowledgeRepository
        >
    with $Provider<KnowledgeRepository> {
  KnowledgeRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'knowledgeRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$knowledgeRepositoryHash();

  @$internal
  @override
  $ProviderElement<KnowledgeRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  KnowledgeRepository create(Ref ref) {
    return knowledgeRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(KnowledgeRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<KnowledgeRepository>(value),
    );
  }
}

String _$knowledgeRepositoryHash() =>
    r'75143fa051fe7e434b71bebc4c0bb5ee1816749e';

@ProviderFor(dailyTip)
final dailyTipProvider = DailyTipProvider._();

final class DailyTipProvider
    extends
        $FunctionalProvider<
          AsyncValue<FinancialTip?>,
          FinancialTip?,
          FutureOr<FinancialTip?>
        >
    with $FutureModifier<FinancialTip?>, $FutureProvider<FinancialTip?> {
  DailyTipProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dailyTipProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dailyTipHash();

  @$internal
  @override
  $FutureProviderElement<FinancialTip?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<FinancialTip?> create(Ref ref) {
    return dailyTip(ref);
  }
}

String _$dailyTipHash() => r'8b07d2b47419c2b265917fadeea971fc7310c7f0';

@ProviderFor(suggestedArticles)
final suggestedArticlesProvider = SuggestedArticlesFamily._();

final class SuggestedArticlesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<KnowledgeArticle>>,
          List<KnowledgeArticle>,
          FutureOr<List<KnowledgeArticle>>
        >
    with
        $FutureModifier<List<KnowledgeArticle>>,
        $FutureProvider<List<KnowledgeArticle>> {
  SuggestedArticlesProvider._({
    required SuggestedArticlesFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'suggestedArticlesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$suggestedArticlesHash();

  @override
  String toString() {
    return r'suggestedArticlesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<KnowledgeArticle>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<KnowledgeArticle>> create(Ref ref) {
    final argument = this.argument as String;
    return suggestedArticles(ref, topic: argument);
  }

  @override
  bool operator ==(Object other) {
    return other is SuggestedArticlesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$suggestedArticlesHash() => r'eaf6231a0d5d792e26a9d7c630067f9d2a974300';

final class SuggestedArticlesFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<KnowledgeArticle>>, String> {
  SuggestedArticlesFamily._()
    : super(
        retry: null,
        name: r'suggestedArticlesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  SuggestedArticlesProvider call({String topic = 'budgeting'}) =>
      SuggestedArticlesProvider._(argument: topic, from: this);

  @override
  String toString() => r'suggestedArticlesProvider';
}
