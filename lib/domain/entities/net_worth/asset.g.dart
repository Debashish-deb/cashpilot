// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'asset.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AssetImpl _$$AssetImplFromJson(Map<String, dynamic> json) => _$AssetImpl(
  id: json['id'] as String,
  userId: json['userId'] as String,
  name: json['name'] as String,
  type: $enumDecode(_$AssetTypeEnumMap, json['type']),
  currentValue: (json['currentValue'] as num).toInt(),
  currency: json['currency'] as String? ?? 'EUR',
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  institutionName: json['institutionName'] as String?,
  notes: json['notes'] as String?,
  isDeleted: json['isDeleted'] as bool? ?? false,
  revision: (json['revision'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$$AssetImplToJson(_$AssetImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'name': instance.name,
      'type': _$AssetTypeEnumMap[instance.type]!,
      'currentValue': instance.currentValue,
      'currency': instance.currency,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'institutionName': instance.institutionName,
      'notes': instance.notes,
      'isDeleted': instance.isDeleted,
      'revision': instance.revision,
    };

const _$AssetTypeEnumMap = {
  AssetType.realEstate: 'realEstate',
  AssetType.vehicle: 'vehicle',
  AssetType.investment: 'investment',
  AssetType.cash: 'cash',
  AssetType.crypto: 'crypto',
  AssetType.other: 'other',
};
