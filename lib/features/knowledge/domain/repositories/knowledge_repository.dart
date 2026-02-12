import '../entities/knowledge_article.dart';
import '../entities/financial_tip.dart';

abstract class KnowledgeRepository {
  /// Get articles by topic or tags
  Future<List<KnowledgeArticle>> getArticles({
    String? topic,
    List<String>? tags,
    String? languageCode,
    String? localeCode,
    int limit = 10,
    int offset = 0,
  });

  /// Get specific article
  Future<KnowledgeArticle?> getArticleById(String id);

  /// Search articles
  Future<List<KnowledgeArticle>> searchArticles(String query);

  /// Get financial tips relevant to user context
  Future<List<FinancialTip>> getContextualTips({
    required String context,
    String? languageCode,
    String? localeCode,
    int limit = 3,
  });
  
  /// Get daily tip
  Future<FinancialTip?> getDailyTip({
    String? languageCode,
    String? localeCode,
  });
}
