import 'package:drift/drift.dart' as drift;
import '../../../../data/drift/app_database.dart' as drift_db;

class UpdateGoalCmd {
  final String id;
  final String title;
  final int targetAmount;
  final int currentAmount;
  final DateTime? deadline;
  final String? iconName;
  final String? colorHex;
  final int revision; // Needed for optimistic concurrency

  UpdateGoalCmd({
    required this.id,
    required this.title,
    required this.targetAmount,
    required this.currentAmount,
    this.deadline,
    this.iconName,
    this.colorHex,
    required this.revision,
  });

  // Convert to Drift Companion for DB
  drift_db.SavingsGoalsCompanion toCompanion() {
    return drift_db.SavingsGoalsCompanion(
      title: drift.Value(title),
      targetAmount: drift.Value(targetAmount),
      currentAmount: drift.Value(currentAmount),
      deadline: drift.Value(deadline),
      iconName: drift.Value(iconName),
      colorHex: drift.Value(colorHex),
      syncState: const drift.Value('dirty'),
      revision: drift.Value(revision + 1), // Increment revision
    );
  }
  
  // For Sync Queue Payload
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'target_amount': targetAmount,
      'current_amount': currentAmount,
      'deadline': deadline?.toIso8601String(),
      'icon_name': iconName,
      'color_hex': colorHex,
      'revision': revision + 1,
    };
  }
}
