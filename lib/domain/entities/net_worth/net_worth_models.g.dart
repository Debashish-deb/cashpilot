// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'net_worth_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_NetWorthHistoryPoint _$NetWorthHistoryPointFromJson(
  Map<String, dynamic> json,
) => _NetWorthHistoryPoint(
  date: DateTime.parse(json['date'] as String),
  valueCents: (json['valueCents'] as num).toInt(),
);

Map<String, dynamic> _$NetWorthHistoryPointToJson(
  _NetWorthHistoryPoint instance,
) => <String, dynamic>{
  'date': instance.date.toIso8601String(),
  'valueCents': instance.valueCents,
};

_NetWorthSummaryData _$NetWorthSummaryDataFromJson(Map<String, dynamic> json) =>
    _NetWorthSummaryData(
      totalAssets: (json['totalAssets'] as num).toInt(),
      totalLiabilities: (json['totalLiabilities'] as num).toInt(),
      netWorth: (json['netWorth'] as num).toInt(),
    );

Map<String, dynamic> _$NetWorthSummaryDataToJson(
  _NetWorthSummaryData instance,
) => <String, dynamic>{
  'totalAssets': instance.totalAssets,
  'totalLiabilities': instance.totalLiabilities,
  'netWorth': instance.netWorth,
};
