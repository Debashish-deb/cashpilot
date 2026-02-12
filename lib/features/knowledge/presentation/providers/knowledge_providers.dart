import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/providers/intelligence_providers.dart';
import '../../domain/repositories/knowledge_repository.dart';
import '../../infrastructure/repositories/knowledge_repository_impl.dart';
import '../../domain/entities/knowledge_article.dart';
import '../../domain/entities/financial_tip.dart';

part 'knowledge_providers.g.dart';

@Riverpod(keepAlive: true)
KnowledgeRepository knowledgeRepository(KnowledgeRepositoryRef ref) {
  final db = ref.watch(databaseProvider);
  return KnowledgeRepositoryImpl(db);
}

@riverpod
Future<FinancialTip?> dailyTip(DailyTipRef ref) {
  final language = ref.watch(languageProvider);
  return ref.watch(knowledgeRepositoryProvider).getDailyTip(
    languageCode: language.code,
  );
}

@riverpod
Future<List<KnowledgeArticle>> suggestedArticles(
  SuggestedArticlesRef ref, {
  String topic = 'budgeting',
}) async {
  final language = ref.watch(languageProvider);
  
  if (topic == 'for_you') {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) return [];
    
    final engine = ref.watch(intelligenceEngineProvider);
    
    // Use Financial Intelligence Engine for personalized suggestions
    final articles = await engine.suggestArticles(userId: userId);
    return articles.where((a) => a.languageCode == language.code).toList();
  }
  
  return ref.watch(knowledgeRepositoryProvider).getArticles(
    topic: topic,
    languageCode: language.code,
  );
}
