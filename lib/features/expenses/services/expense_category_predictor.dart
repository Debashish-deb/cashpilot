/// Expense Category Predictor Service
/// ML-enhanced expense categorization using pattern matching and heuristics
library;

import 'package:flutter/foundation.dart';
import '../data/merchant_patterns.dart';
import '../data/heuristic_rules.dart';
import '../models/prediction_result.dart';
import 'category_learning_service.dart';
import '../../../data/drift/app_database.dart';

import '../../ml/services/naive_bayes_classifier.dart';
import '../../../data/global_category_knowledge.dart';

class ExpenseCategoryPredictor {
  late final CategoryLearningService _learningService;
  final NaiveBayesClassifier _classifier = NaiveBayesClassifier();
  bool _isInitialized = false;
  
  ExpenseCategoryPredictor(AppDatabase db) {
    _learningService = CategoryLearningService(db);
    // Initialize in background
    _initializeClassifier();
  }

  /// Load learned patterns and global knowledge into Naive Bayes Classifier
  Future<void> _initializeClassifier() async {
    try {
      // 1. Train on Global Knowledge Base (Base Truth)
      // We give this a base weight.
      // Since Naive Bayes treats each "train" call as a document, 
      // we can simulate frequency by training multiple times or just once.
      // Training once establishes the vocabulary and association.
      
      final globalData = GlobalCategoryKnowledge.keywords;
      for (final entry in globalData.entries) {
        final category = entry.key;
        final keywords = entry.value;
        for (final keyword in keywords) {
          // Training on keyword -> category
          _classifier.train(keyword, category);
        }
      }

      // 2. Train on User-Specific Patterns (Personalization)
      if (kDebugMode) {
        debugPrint('[CategoryPredictor] Seeding classifier with ${GlobalCategoryKnowledge.allKeywords.length} global keywords');
      }

      final patterns = await _learningService.getAllPatterns();
      for (final p in patterns) {
        // Train on the merchant pattern associated with the category
        // We might want to weigh it by usage count? 
        // For simple NB, repeated training effectively weights it.
        for (var i = 0; i < p.usageCount; i++) {
           _classifier.train(p.merchantPattern, p.categoryName);
        }
      }
      _isInitialized = true;
      if (kDebugMode) {
        debugPrint('[CategoryPredictor] Naive Bayes Classifier initialized with ${patterns.length} patterns');
      }
    } catch (e) {
      debugPrint('[CategoryPredictor] Failed to initialize classifier: $e');
    }
  }

  /// Predict category for an expense
  /// Returns top 3 predictions sorted by confidence
  Future<List<PredictionResult>> predict({
    required String merchant,
    required int amountInCents,
    String? description,
    DateTime? timestamp,
  }) async {
    // Ensure initialized if called too early
    if (!_isInitialized) await _initializeClassifier();
    
    final predictions = <String, _PredictionScore>{};
    
    // 0. Check learned patterns first (highest priority - Exact Match)
    final learnedBoosts = await _learningService.getLearnedBoosts(merchant);
    for (final entry in learnedBoosts.entries) {
      predictions[entry.key] = _PredictionScore(
        category: entry.key,
        baseScore: 70, // Very high for learned patterns
        source: 'learned',
      );
      predictions[entry.key]!.addBoost(entry.value, 'user_learning');
    }
    
    // 0.5 Naive Bayes Classification (Probabilistic Match)
    // Useful for "Uber Eats" vs "Uber" where exact match might fail or partial match is ambiguous
    final nbPrediction = _classifier.predict(merchant + (description != null ? " $description" : ""));
    if (nbPrediction != null) {
      final category = nbPrediction.category;
      final probability = nbPrediction.probability;
      
      // Scale probability to a boost (0-1.0 -> 0-40 points)
      final boost = (probability * 40).round();
      
      if (predictions.containsKey(category)) {
        predictions[category]!.addBoost(boost, 'naive_bayes (prob: ${probability.toStringAsFixed(2)})');
      } else {
         predictions[category] = _PredictionScore(
          category: category,
          baseScore: 50 + boost, // Base 50 + up to 40 = 90 max
          source: 'naive_bayes',
        );
      }
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
  
  /// Feed feedback loop: Train classifier on user selection
  Future<void> train(String merchant, String category) async {
    // Also delegate to learning service for persisted patterns
    // The learning service will persist it, and next time we load, we'll get it.
    // But we should also update the in-memory classifier immediately.
    _classifier.train(merchant, category);
    await _learningService.learnPattern(merchant: merchant, selectedCategory: category);
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
