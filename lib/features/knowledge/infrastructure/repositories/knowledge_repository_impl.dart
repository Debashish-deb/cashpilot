import 'dart:convert' show jsonDecode;

import '../../../../data/drift/app_database.dart' as drift;
import '../../domain/entities/knowledge_article.dart';
import '../../domain/entities/financial_tip.dart';
import '../../domain/repositories/knowledge_repository.dart';

class KnowledgeRepositoryImpl implements KnowledgeRepository {
  final drift.AppDatabase _db;

  KnowledgeRepositoryImpl(this._db);

  @override
  Future<List<KnowledgeArticle>> getArticles({
    String? topic,
    List<String>? tags,
    String? languageCode,
    String? localeCode,
    int limit = 10,
    int offset = 0,
  }) async {
    // 1. Fetch from local DB
    final driftArticles = await _db.getDriftArticles(
      topic: topic,
      tags: tags,
      languageCode: languageCode,
      localeCode: localeCode,
      limit: limit,
      offset: offset,
    );
    
    // 2. Map to Domain
    return driftArticles.map((a) => _mapArticleToDomain(a)).toList();
  }

  @override
  Future<KnowledgeArticle?> getArticleById(String id) async {
    final driftArticle = await _db.getDriftArticleById(id);
    if (driftArticle == null) return null;
    return _mapArticleToDomain(driftArticle);
  }

  @override
  Future<List<KnowledgeArticle>> searchArticles(String query) async {
    final driftArticles = await _db.searchDriftArticles(query);
    return driftArticles.map((a) => _mapArticleToDomain(a)).toList();
  }

  @override
  Future<List<FinancialTip>> getContextualTips({
    required String context,
    String? languageCode,
    String? localeCode,
    int limit = 3,
  }) async {
    // Basic mapping of context to category for now
    String? category;
    if (context.contains('budget')) category = 'budget_tip';
    if (context.contains('dashboard')) category = 'daily';
    
    final driftTips = await _db.getDriftFinancialTips(
      category: category,
      languageCode: languageCode,
      localeCode: localeCode,
      limit: limit,
    );
    
    return driftTips.map((t) => _mapTipToDomain(t)).toList();
  }

  @override
  Future<FinancialTip?> getDailyTip({
    String? languageCode,
    String? localeCode,
  }) async {
    final tips = await _db.getDriftFinancialTips(
      category: 'daily', 
      languageCode: languageCode,
      localeCode: localeCode,
      limit: 10
    );
    if (tips.isNotEmpty) {
      // Rotation based on day
      final index = DateTime.now().day % tips.length;
      return _mapTipToDomain(tips[index]);
    }
    return null;
  }
  
  // Helpers
  
  KnowledgeArticle _mapArticleToDomain(drift.KnowledgeArticleData a) {
    List<String> tagsList = [];
    if (a.tags != null) {
      try {
        tagsList = List<String>.from(jsonDecode(a.tags!));
      } catch (e) {
        // ignore error
      }
    }
    
    return KnowledgeArticle(
      id: a.id,
      title: a.title,
      summary: a.summary,
      content: a.content,
      topic: a.topic,
      tags: tagsList,
      imageUrl: a.imageUrl,
      readTimeMinutes: a.readTimeMinutes,
      languageCode: a.languageCode,
      isPremium: a.isPremium,
      publishedAt: a.publishedAt,
      updatedAt: a.updatedAt,
    );
  }
  
  FinancialTip _mapTipToDomain(drift.FinancialTipData t) {
    return FinancialTip(
      id: t.id,
      title: t.title,
      content: t.content,
      category: t.category,
      actionLabel: t.actionLabel ?? '',
      actionRoute: t.actionRoute ?? '',
      type: t.type,
      languageCode: t.languageCode,
      createdAt: t.createdAt,
      expiresAt: t.expiresAt,
    );
  }
}
