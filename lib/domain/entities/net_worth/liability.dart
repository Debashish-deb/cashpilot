
import 'package:freezed_annotation/freezed_annotation.dart';

part 'liability.freezed.dart';
part 'liability.g.dart';

@freezed
class Liability with _$Liability {
  const factory Liability({
    required String id,
    required String userId,
    required String name,
    required LiabilityType type,
    required int currentBalance, // in cents
    @Default('EUR') String currency,
    
    double? interestRate,
    DateTime? dueDate,
    int? minPayment, // in cents
    
    // Metadata
    required DateTime createdAt,
    required DateTime updatedAt,
    String? notes,
    
    // Sync
    @Default(false) bool isDeleted,
    @Default(0) int revision,
  }) = _Liability;

  factory Liability.fromJson(Map<String, dynamic> json) => _$LiabilityFromJson(json);
}

enum LiabilityType {
  mortgage,
  loan,
  creditCard,
  other;
  
  String get displayName {
    switch (this) {
      case LiabilityType.mortgage: return 'Mortgage';
      case LiabilityType.loan: return 'Personal Loan';
      case LiabilityType.creditCard: return 'Credit Card';
      case LiabilityType.other: return 'Other Debt';
    }
  }
}
