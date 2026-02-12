import 'package:freezed_annotation/freezed_annotation.dart';

part 'knowledge_article.freezed.dart';
part 'knowledge_article.g.dart';

@freezed
abstract class KnowledgeArticle with _$KnowledgeArticle {
  const factory KnowledgeArticle({
    required String id,
    required String title,
    required String summary,
    required String content,
    required String topic, // e.g., 'budgeting', 'investing', 'savings'
    required List<String> tags,
    required String? imageUrl,
    @Default(0) int readTimeMinutes,
    @Default('en') String languageCode,
    @Default(false) bool isPremium,
    required DateTime publishedAt,
    required DateTime updatedAt,
  }) = _KnowledgeArticle;

  factory KnowledgeArticle.fromJson(Map<String, dynamic> json) =>
      _$KnowledgeArticleFromJson(json);
}
