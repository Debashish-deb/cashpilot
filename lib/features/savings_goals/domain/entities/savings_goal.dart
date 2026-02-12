/// Domain Entity: Savings Goal
/// Business Truth Layer
library;
import '../failures/savings_goal_failure.dart';

class SavingsGoal {
  final String id;
  final String userId;
  final String title;
  final int targetAmount;
  final int currentAmount;
  final DateTime? deadline;
  final String? iconName;
  final String? colorHex;
  final String currency;
  final int revision;
  final bool isArchived;
  final bool isDeleted;

  SavingsGoal({
    required this.id,
    required this.userId,
    required this.title,
    required this.targetAmount,
    required this.currentAmount,
    this.deadline,
    this.iconName,
    this.colorHex,
    this.currency = 'EUR',
    this.revision = 1,
    this.isArchived = false,
    this.isDeleted = false,
  });

  void validate() {
    if (title.isEmpty) {
      throw const ValidationFailure("Title cannot be empty");
    }
    if (targetAmount <= 0) {
      throw const ValidationFailure("Target must be positive");
    }
    if (currentAmount < 0) {
      throw const ValidationFailure("Current cannot be negative");
    }
    // We might allow current > target if they over-saved, so optional:
    // if (currentAmount > targetAmount) {
    //   throw const ValidationFailure("Current exceeds target");
    // }
  }

  // CopyWith for immutability
  SavingsGoal copyWith({
    String? title,
    int? targetAmount,
    int? currentAmount,
    DateTime? deadline,
    String? iconName,
    String? colorHex,
    bool? isArchived,
    bool? isDeleted,
  }) {
    return SavingsGoal(
      id: id,
      userId: userId,
      title: title ?? this.title,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      deadline: deadline ?? this.deadline,
      iconName: iconName ?? this.iconName,
      colorHex: colorHex ?? this.colorHex,
      isArchived: isArchived ?? this.isArchived,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}


