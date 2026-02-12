
import 'package:freezed_annotation/freezed_annotation.dart';

part 'net_worth_models.freezed.dart';
part 'net_worth_models.g.dart';

@freezed
class NetWorthHistoryPoint with _$NetWorthHistoryPoint {
  const factory NetWorthHistoryPoint({
    required DateTime date,
    required int valueCents,
  }) = _NetWorthHistoryPoint;

  factory NetWorthHistoryPoint.fromJson(Map<String, dynamic> json) => _$NetWorthHistoryPointFromJson(json);
}

@freezed
class NetWorthSummaryData with _$NetWorthSummaryData {
  const factory NetWorthSummaryData({
    required int totalAssets,
    required int totalLiabilities,
    required int netWorth,
  }) = _NetWorthSummaryData;

  factory NetWorthSummaryData.fromJson(Map<String, dynamic> json) => _$NetWorthSummaryDataFromJson(json);
}
