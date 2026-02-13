
import 'package:freezed_annotation/freezed_annotation.dart';

part 'asset.freezed.dart';
part 'asset.g.dart';

@freezed
class Asset with _$Asset {
  const factory Asset({
    required String id,
    required String userId,
    required String name,
    required AssetType type,
    required int currentValue, 
    @Default('EUR') String currency,
    
    // Metadata
    required DateTime createdAt,
    required DateTime updatedAt,
    String? institutionName,
    String? notes,
    
    // Sync
    @Default(false) bool isDeleted,
    @Default(0) int revision,
  }) = _Asset;

  factory Asset.fromJson(Map<String, dynamic> json) => _$AssetFromJson(json);
}

enum AssetType {
  realEstate,
  vehicle,
  investment,
  cash,
  crypto,
  other;
  
  String get displayName {
    switch (this) {
      case AssetType.realEstate: return 'Real Estate';
      case AssetType.vehicle: return 'Vehicle';
      case AssetType.investment: return 'Investment';
      case AssetType.cash: return 'Cash';
      case AssetType.crypto: return 'Crypto';
      case AssetType.other: return 'Other';
    }
  }
}
