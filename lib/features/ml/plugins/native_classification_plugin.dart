import 'package:drift/drift.dart';
import '../../../data/drift/app_database.dart';
import '../services/naive_bayes_classifier.dart';
import '../../expenses/services/category_learning_service.dart';
import 'intelligence_plugin.dart';

class NativeClassificationPlugin implements IntelligencePlugin {
  @override
  String get id => 'native_classifier';

  @override
  int get priority => 10; // Run early

  final NaiveBayesClassifier _classifier;
  final CategoryLearningService _learningService;

  NativeClassificationPlugin(this._classifier, this._learningService);

  @override
  Future<Expense> process(Expense expense, {bool isCorrection = false}) async {
    // If already categorized by user or correction, skip classification
    if (isCorrection || (expense.categoryId != null && !expense.isAiAssigned)) {
      return expense;
    }

    String? inferredCategoryId = expense.categoryId;
    double confidence = expense.confidence;
    bool isAiAssigned = expense.isAiAssigned;

    // 1. Check learned patterns
    final learnedCategory = await _learningService.getTopLearnedCategory(expense.merchantName ?? expense.title);
    
    if (learnedCategory != null) {
      inferredCategoryId = learnedCategory;
      confidence = 0.95; 
      isAiAssigned = true;
    } else {
      // 2. Fallback to Naive Bayes
      final prediction = _classifier.predict(expense.title);
      if (prediction != null) {
        inferredCategoryId = prediction.category;
        confidence = prediction.probability;
        isAiAssigned = true;
      }
    }

    return expense.copyWith(
      categoryId: Value(inferredCategoryId),
      confidence: confidence,
      isAiAssigned: isAiAssigned,
    );
  }

  @override
  Future<void> dispose() async {}
}
