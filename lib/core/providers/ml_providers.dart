/// Category Prediction Provider
/// Riverpod provider for ExpenseCategoryPredictor
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/expenses/services/expense_category_predictor.dart';
import 'app_providers.dart';

final categoryPredictorProvider = Provider<ExpenseCategoryPredictor>((ref) {
  final db = ref.watch(databaseProvider);
  return ExpenseCategoryPredictor(db);
});
