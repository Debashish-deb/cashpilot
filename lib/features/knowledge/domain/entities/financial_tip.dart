import 'package:freezed_annotation/freezed_annotation.dart';

part 'financial_tip.freezed.dart';
part 'financial_tip.g.dart';

@freezed
abstract class FinancialTip with _$FinancialTip {
  const factory FinancialTip({
    required String id,
    required String title,
    required String content,
    required String category, 
    required String actionLabel, 
    required String actionRoute, 
    @Default('info') String type, 
    @Default('en') String languageCode,
    required DateTime createdAt,
    required DateTime? expiresAt,
  }) = _FinancialTip;

  factory FinancialTip.fromJson(Map<String, dynamic> json) =>
      _$FinancialTipFromJson(json);
}
