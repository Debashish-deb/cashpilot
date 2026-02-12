// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'net_worth_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$NetWorthHistoryPointImpl _$$NetWorthHistoryPointImplFromJson(
  Map<String, dynamic> json,
) => _$NetWorthHistoryPointImpl(
  date: DateTime.parse(json['date'] as String),
  valueCents: (json['valueCents'] as num).toInt(),
);

Map<String, dynamic> _$$NetWorthHistoryPointImplToJson(
  _$NetWorthHistoryPointImpl instance,
) => <String, dynamic>{
  'date': instance.date.toIso8601String(),
  'valueCents': instance.valueCents,
};

_$NetWorthSummaryDataImpl _$$NetWorthSummaryDataImplFromJson(
  Map<String, dynamic> json,
) => _$NetWorthSummaryDataImpl(
  totalAssets: (json['totalAssets'] as num).toInt(),
  totalLiabilities: (json['totalLiabilities'] as num).toInt(),
  netWorth: (json['netWorth'] as num).toInt(),
);

Map<String, dynamic> _$$NetWorthSummaryDataImplToJson(
  _$NetWorthSummaryDataImpl instance,
) => <String, dynamic>{
  'totalAssets': instance.totalAssets,
  'totalLiabilities': instance.totalLiabilities,
  'netWorth': instance.netWorth,
};
