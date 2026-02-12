import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/services/audit_logger.dart';
import '../../expenses/services/category_learning_service.dart';
import '../services/intelligence_orchestrator.dart';
import '../services/anomaly_detector.dart';
import '../services/spending_forecaster.dart';
import '../services/naive_bayes_classifier.dart';
import '../../cfse/providers/cfse_providers.dart';

final anomalyDetectorProvider = Provider((ref) {
  final db = ref.watch(databaseProvider);
  return AnomalyDetector(db);
});

final spendingForecasterProvider = Provider((ref) {
  final db = ref.watch(databaseProvider);
  return SpendingForecaster(db);
});

final classifierProvider = Provider((ref) {
  return NaiveBayesClassifier();
});

final auditLoggerProvider = Provider((ref) {
  final db = ref.watch(databaseProvider);
  return AuditLogger(db);
});

final categoryLearningServiceProvider = Provider((ref) {
  final db = ref.watch(databaseProvider);
  return CategoryLearningService(db);
});

final intelligenceOrchestratorProvider = Provider((ref) {
  final db = ref.watch(databaseProvider);
  final anomaly = ref.watch(anomalyDetectorProvider);
  final forecaster = ref.watch(spendingForecasterProvider);
  final classifier = ref.watch(classifierProvider);
  final audit = ref.watch(auditLoggerProvider);
  final learning = ref.watch(categoryLearningServiceProvider);
  
  return IntelligenceOrchestrator(
    db,
    anomaly,
    forecaster,
    classifier,
    audit,
    learning,
    ref.watch(financialStateEngineProvider),
  );
});
