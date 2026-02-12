import 'package:drift/drift.dart' as drift;
import '../../../../data/drift/app_database.dart' as drift_db;
import '../../domain/entities/savings_goal.dart';

class CreateGoalCmd {
  final String userId;
  final String title;
  final int targetAmount;
  final int currentAmount;
  final DateTime? deadline;
  final String? iconName;
  final String? colorHex;

  CreateGoalCmd({
    required this.userId,
    required this.title,
    required this.targetAmount,
    this.currentAmount = 0,
    this.deadline,
    this.iconName,
    this.colorHex,
  });

  // Convert to Domain for validation
  SavingsGoal toDomain(String id) {
    return SavingsGoal(
      id: id,
      userId: userId,
      title: title,
      targetAmount: targetAmount,
      currentAmount: currentAmount,
      deadline: deadline,
      iconName: iconName,
      colorHex: colorHex,
    );
  }

  // Convert to Drift Companion for DB
  drift_db.SavingsGoalsCompanion toCompanion(String id) {
    return drift_db.SavingsGoalsCompanion(
      id: drift.Value(id),
      userId: drift.Value(userId),
      title: drift.Value(title),
      targetAmount: drift.Value(targetAmount),
      currentAmount: drift.Value(currentAmount),
      deadline: drift.Value(deadline),
      iconName: drift.Value(iconName),
      colorHex: drift.Value(colorHex),
      isDeleted: const drift.Value(false),
      syncState: const drift.Value('dirty'),
      revision: const drift.Value(1),
    );
  }
  
  // For Sync Queue Payload
  Map<String, dynamic> toJson(String id) {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'target_amount': targetAmount,
      'current_amount': currentAmount,
      'deadline': deadline?.toIso8601String(),
      'icon_name': iconName,
      'color_hex': colorHex,
    };
  }
}
