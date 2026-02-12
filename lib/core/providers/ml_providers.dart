import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/expenses/services/expense_category_predictor.dart';
import '../../features/ml/services/anomaly_detector.dart';
import '../../features/ml/services/spending_forecaster.dart';
import 'app_providers.dart';

final categoryPredictorProvider = Provider<ExpenseCategoryPredictor>((ref) {
  final db = ref.watch(databaseProvider);
  return ExpenseCategoryPredictor(db);
});

final anomalyDetectorProvider = Provider<AnomalyDetector>((ref) {
  final db = ref.watch(databaseProvider);
  return AnomalyDetector(db);
});

final spendingForecasterProvider = Provider<SpendingForecaster>((ref) {
  final db = ref.watch(databaseProvider);
  return SpendingForecaster(db);
});
