// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'knowledge_article.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_KnowledgeArticle _$KnowledgeArticleFromJson(Map<String, dynamic> json) =>
    _KnowledgeArticle(
      id: json['id'] as String,
      title: json['title'] as String,
      summary: json['summary'] as String,
      content: json['content'] as String,
      topic: json['topic'] as String,
      tags: (json['tags'] as List<dynamic>).map((e) => e as String).toList(),
      imageUrl: json['imageUrl'] as String?,
      readTimeMinutes: (json['readTimeMinutes'] as num?)?.toInt() ?? 0,
      languageCode: json['languageCode'] as String? ?? 'en',
      isPremium: json['isPremium'] as bool? ?? false,
      publishedAt: DateTime.parse(json['publishedAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$KnowledgeArticleToJson(_KnowledgeArticle instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'summary': instance.summary,
      'content': instance.content,
      'topic': instance.topic,
      'tags': instance.tags,
      'imageUrl': instance.imageUrl,
      'readTimeMinutes': instance.readTimeMinutes,
      'languageCode': instance.languageCode,
      'isPremium': instance.isPremium,
      'publishedAt': instance.publishedAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
