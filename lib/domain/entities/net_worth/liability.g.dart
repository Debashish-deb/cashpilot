// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'liability.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$LiabilityImpl _$$LiabilityImplFromJson(Map<String, dynamic> json) =>
    _$LiabilityImpl(
      id: json['id'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String,
      type: $enumDecode(_$LiabilityTypeEnumMap, json['type']),
      currentBalance: (json['currentBalance'] as num).toInt(),
      currency: json['currency'] as String? ?? 'EUR',
      interestRate: (json['interestRate'] as num?)?.toDouble(),
      dueDate: json['dueDate'] == null
          ? null
          : DateTime.parse(json['dueDate'] as String),
      minPayment: (json['minPayment'] as num?)?.toInt(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      notes: json['notes'] as String?,
      isDeleted: json['isDeleted'] as bool? ?? false,
      revision: (json['revision'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$LiabilityImplToJson(_$LiabilityImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'name': instance.name,
      'type': _$LiabilityTypeEnumMap[instance.type]!,
      'currentBalance': instance.currentBalance,
      'currency': instance.currency,
      'interestRate': instance.interestRate,
      'dueDate': instance.dueDate?.toIso8601String(),
      'minPayment': instance.minPayment,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'notes': instance.notes,
      'isDeleted': instance.isDeleted,
      'revision': instance.revision,
    };

const _$LiabilityTypeEnumMap = {
  LiabilityType.mortgage: 'mortgage',
  LiabilityType.loan: 'loan',
  LiabilityType.creditCard: 'creditCard',
  LiabilityType.other: 'other',
};
