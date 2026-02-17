// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'financial_tip.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FinancialTip _$FinancialTipFromJson(Map<String, dynamic> json) =>
    _FinancialTip(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      category: json['category'] as String,
      actionLabel: json['actionLabel'] as String,
      actionRoute: json['actionRoute'] as String,
      type: json['type'] as String? ?? 'info',
      languageCode: json['languageCode'] as String? ?? 'en',
      createdAt: DateTime.parse(json['createdAt'] as String),
      expiresAt: json['expiresAt'] == null
          ? null
          : DateTime.parse(json['expiresAt'] as String),
    );

Map<String, dynamic> _$FinancialTipToJson(_FinancialTip instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'content': instance.content,
      'category': instance.category,
      'actionLabel': instance.actionLabel,
      'actionRoute': instance.actionRoute,
      'type': instance.type,
      'languageCode': instance.languageCode,
      'createdAt': instance.createdAt.toIso8601String(),
      'expiresAt': instance.expiresAt?.toIso8601String(),
    };
