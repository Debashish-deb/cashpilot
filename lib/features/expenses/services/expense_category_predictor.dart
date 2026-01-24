/// Expense Category Predictor Service
/// ML-enhanced expense categorization using pattern matching and heuristics
library;

import 'package:flutter/foundation.dart';
import '../data/merchant_patterns.dart';
import '../data/heuristic_rules.dart';
import '../models/prediction_result.dart';
import 'category_learning_service.dart';
import '../../../data/drift/app_database.dart';

class ExpenseCategoryPredictor {
  late final CategoryLearningService _learningService;
  
  ExpenseCategoryPredictor(AppDatabase db) {
    _learningService = CategoryLearningService(db);
  }

  /// Predict category for an expense
  /// Returns top 3 predictions sorted by confidence
  Future<List<PredictionResult>> predict({
    required String merchant,
    required int amountInCents,
    String? description,
    DateTime? timestamp,
  }) async {
    final predictions = <String, _PredictionScore>{};
    
    // 0. Check learned patterns first (highest priority)
    final learnedBoosts = await _learningService.getLearnedBoosts(merchant);
    for (final entry in learnedBoosts.entries) {
      predictions[entry.key] = _PredictionScore(
        category: entry.key,
        baseScore: 70, // Very high for learned patterns
        source: 'learned',
      );
      predictions[entry.key]!.addBoost(entry.value, 'user_learning');
    }
    
    // 1. Merchant pattern matching (strong signal)
    final merchantMatches = MerchantPatterns.findMatchingCategories(merchant);
    for (final category in merchantMatches) {
      if (predictions.containsKey(category)) {
        predictions[category]!.addBoost(20, 'merchant_pattern');
      } else {
        predictions[category] = _PredictionScore(
          category: category,
          baseScore: 75,  // Increased for known merchants
          source: 'merchant_pattern',
        );
      }
    }
    
    // 2. Description pattern matching (if available)
    if (description != null && description.isNotEmpty) {
      final descMatches = MerchantPatterns.findMatchingCategories(description);
      for (final category in descMatches) {
        if (predictions.containsKey(category)) {
          predictions[category]!.addBoost(20, 'description_match');
        } else {
          predictions[category] = _PredictionScore(
            category: category,
            baseScore: 40,
            source: 'description_pattern',
          );
        }
      }
    }
    
    // 3. Apply heuristics
    final hour = timestamp?.hour;
    final weekday = timestamp?.weekday;
    
    final heuristics = HeuristicRules.getCombinedHeuristics(
      amountInCents: amountInCents,
      hour: hour,
      weekday: weekday,
    );
    
    for (final entry in heuristics.entries) {
      final category = entry.key;
      final boost = entry.value;
      
      if (predictions.containsKey(category)) {
        predictions[category]!.addBoost(boost, 'heuristic');
      } else {
        // Heuristic-only prediction (lower confidence)
        predictions[category] = _PredictionScore(
          category: category,
          baseScore: boost,
          source: 'heuristic',
        );
      }
    }
    
    // 4. Convert to PredictionResult and sort
    final results = predictions.values.map((score) {
      return PredictionResult(
        category: score.category,
        confidence: score.totalConfidence.clamp(0, 100),
        source: score.source,
      );
    }).toList();
    
    // Sort by confidence descending
    results.sort((a, b) => b.confidence.compareTo(a.confidence));
    
    // Return top 3
    final top3 = results.take(3).toList();
    
    if (kDebugMode) {
      debugPrint('[CategoryPredictor] Merchant: $merchant, Amount: \$${amountInCents / 100}');
      for (final result in top3) {
        debugPrint('[CategoryPredictor]   → $result');
      }
    }
    
    return top3;
  }
  
  /// Quick predict - returns only the top prediction
  Future<PredictionResult?> predictTop({
    required String merchant,
    required int amountInCents,
    String? description,
    DateTime? timestamp,
  }) async {
    final predictions = await predict(
      merchant: merchant,
      amountInCents: amountInCents,
      description: description,
      timestamp: timestamp,
    );
    
    return predictions.isNotEmpty ? predictions.first : null;
  }
  
  /// Check if prediction should auto-apply
  /// Returns true if confidence >= 85%
  bool shouldAutoApply(PredictionResult prediction) {
    return prediction.confidence >= 85;
  }
  
  /// Check if prediction should be suggested
  /// Returns true if confidence >= 50%
  bool shouldSuggest(PredictionResult prediction) {
    return prediction.confidence >= 50;
  }
}

/// Internal prediction score tracker
class _PredictionScore {
  final String category;
  final int baseScore;
  final String source;
  final List<int> boosts = [];
  
  _PredictionScore({
    required this.category,
    required this.baseScore,
    required this.source,
  });
  
  void addBoost(int boost, String reason) {
    boosts.add(boost);
    if (kDebugMode) {
      debugPrint('[CategoryPredictor]     +$boost from $reason');
    }
  }
  
  int get totalConfidence {
    final total = baseScore + boosts.fold<int>(0, (sum, boost) => sum + boost);
    return total;
  }
}
