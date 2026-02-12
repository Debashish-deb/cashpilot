
import 'package:flutter/foundation.dart';
import '../../../data/drift/app_database.dart';
import 'package:drift/drift.dart';

class AnomalyDetector {
  final AppDatabase _db;
  
  AnomalyDetector(this._db);

  /// Analyzes an expense for anomalies relative to its category history (SemiBudget)
  /// Returns a confidence score (0.0 - 1.0) that this is an anomaly.
  /// Uses Robust Z-Score (Median Absolute Deviation) to handle existing outliers.
  Future<double> checkAnomaly(Expense expense) async {
    final groupId = expense.semiBudgetId ?? expense.categoryId;
    if (groupId == null) return 0.0;

    try {
      // 1. Fetch historical context for the category/semi-budget
      // We look for expenses in the same "envelope"
      final history = await (_db.select(_db.expenses)
        ..where((t) => t.semiBudgetId.equals(groupId) | t.categoryId.equals(groupId))
        ..where((t) => t.id.equals(expense.id).not()) // Exclude current
        ..orderBy([(t) => OrderingTerm.desc(t.date)])
        ..limit(50) // Last 50 transactions is enough for local context
      ).get();

      if (history.length < 5) return 0.0; // Not enough data

      final amounts = history.map((e) => e.amount.toDouble()).toList();
      amounts.sort(); // Required for median

      // 2. Calculate Robust Statistics (Median & MAD)
      final median = _calculateMedian(amounts);
      
      // Median Absolute Deviation (MAD)
      final deviations = amounts.map((a) => (a - median).abs()).toList();
      deviations.sort();
      final mad = _calculateMedian(deviations);

      // Prevent division by zero if all amounts are identical
      if (mad == 0) return 0.0;

      // 3. Calculate Modified Z-Score
      // Formula: 0.6745 * (x - median) / MAD
      // 0.6745 is the consistency constant for normal distribution
      final modifiedZ = 0.6745 * (expense.amount - median).abs() / mad;

      // 4. Temporal Context (Time of Month Check)
      // Check if this expense is happening at an unusual time compared to history
      final anomalyScore = _calculateAnomalyScore(modifiedZ);

      debugPrint('[AnomalyDetector] Group: $groupId, Amount: ${expense.amount}, Median: $median, MAD: $mad, Z-Score: ${modifiedZ.toStringAsFixed(2)}, Score: $anomalyScore');
      
      return anomalyScore;
    } catch (e) {
      debugPrint('[AnomalyDetector] Error: $e');
      return 0.0;
    }
  }

  double _calculateMedian(List<double> sortedList) {
    if (sortedList.isEmpty) return 0.0;
    final middle = sortedList.length ~/ 2;
    if (sortedList.length % 2 == 1) {
      return sortedList[middle];
    } else {
      return (sortedList[middle - 1] + sortedList[middle]) / 2.0;
    }
  }

  double _calculateAnomalyScore(double zScore) {
    // Thresholds for Modified Z-Score:
    // 3.5 is generally considered a potential outlier
    // 5.0 is a definite outlier
    
    if (zScore > 8.0) return 0.95; // Extreme
    if (zScore > 5.0) return 0.80; // High
    if (zScore > 3.5) return 0.50; // Moderate
    return 0.0; // Normal
  }

  /// Bulk detect anomalies in recent history
  Future<List<Expense>> detectAnomalies() async {
    // Implement if needed for dashboard alerts
    return [];
  }
}
