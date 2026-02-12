import 'dart:async';
import 'dart:convert';
import 'package:cross_file/cross_file.dart';
import 'package:flutter/foundation.dart';
import '../../../data/drift/app_database.dart';
import 'anomaly_detector.dart';
import 'spending_forecaster.dart';
import 'naive_bayes_classifier.dart';
import '../../../core/services/audit_logger.dart';
import '../../../features/expenses/services/category_learning_service.dart';
import 'package:drift/drift.dart';
import '../../../domain/cfse/i_financial_state_engine.dart';
import '../plugins/intelligence_registry.dart';
import '../plugins/native_classification_plugin.dart';

class IntelligenceOrchestrator {
  final AppDatabase _db;
  final AnomalyDetector _anomalyDetector;
  final SpendingForecaster _forecaster;
  NaiveBayesClassifier _classifier;
  final AuditLogger _auditLogger;
  final CategoryLearningService _learningService;
  final IFinancialStateEngine _cfse;



  final IntelligenceRegistry _registry = IntelligenceRegistry();

  IntelligenceOrchestrator(
    this._db,
    this._anomalyDetector,
    this._forecaster,
    this._classifier,
    this._auditLogger,
    this._learningService,
    this._cfse,
  ) {
    // Register Default Core Plugins
    _registry.register(NativeClassificationPlugin(_classifier, _learningService));
    // _registry.register(AnomalyDetectionPlugin(_anomalyDetector)); // Can extract later
  }

  /// Central processing pipeline for any new or updated expense
  Future<Expense> processExpense(Expense expense, {bool isCorrection = false}) async {
    debugPrint('[Intelligence] Processing pipeline for: ${expense.id} (Correction: $isCorrection)');

    // 0. Handle Learning Loop (Correction) - Kept outside pipeline for now as it's a side effect
    if (isCorrection && expense.categoryId != null) {
      await _learningService.learnPattern(
        merchant: expense.merchantName ?? expense.title,
        selectedCategory: expense.categoryId!,
      );
    }

    // 1. Run Plugin Pipeline
    final pipelinedExpense = await _registry.runPipeline(expense, isCorrection: isCorrection);

    // 2. Legacy/Side-effect logic (Anomaly, Forecast, Audit) 
    // TODO: Move these to plugins fully in next iteration
    
    // Anomaly Detection
    final anomalyScore = await _anomalyDetector.checkAnomaly(pipelinedExpense);
    
    // Budget Impact & CFSE Grounding
    final forecast = await _forecaster.predictNextMonthSpending();
    final cfseWarning = await _cfse.validateProposedChange(expense.enteredBy, pipelinedExpense);
    
    // Final verification flag logic
    final updatedExpense = pipelinedExpense.copyWith(
      isVerified: !pipelinedExpense.isAiAssigned || isCorrection,
    );

    // Save update to DB if changed
    if (updatedExpense != expense) {
      await (_db.update(_db.expenses)..where((t) => t.id.equals(expense.id))).write(updatedExpense);
    }

    // Audit Logging
    await _auditLogger.log(
      entityType: 'expense',
      entityId: expense.id,
      action: isCorrection ? 'correction' : 'ai_processing',
      userId: expense.enteredBy,
      oldValue: jsonEncode(expense.toJson()),
      newValue: jsonEncode(updatedExpense.toJson()),
      metadata: {
        'anomaly_score': anomalyScore,
        'forecast_next_month': forecast,
        'cfse_grounding': cfseWarning ?? 'verified',
        'pipeline_execution': true,
      },
    );

    return updatedExpense;
  }

  // ... existing code

  /// Load a locally trained model from file
  Future<void> loadLocalModel(String path) async {
    if (kIsWeb) return;
    
    try {
      final file = XFile(path);
      // XFile from path works on native.
      final jsonString = await file.readAsString();
      final jsonMap = jsonDecode(jsonString);
      _classifier = NaiveBayesClassifier.fromJson(jsonMap);
      debugPrint('[Intelligence] Loaded local model from $path');
    } catch (e) {
      debugPrint('[Intelligence] Failed to load local model: $e');
    }
  }

  // Helper to run anomaly check on what will be the new state
  Expense updatedExpenseToProcess(Expense e, String? catId) {
    return e.copyWith(categoryId: Value(catId));
  }
}
