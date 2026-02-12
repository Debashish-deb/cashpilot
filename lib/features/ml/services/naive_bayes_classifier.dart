/// Naive Bayes Classifier for Expense Categorization
/// 
/// Uses probabilistic learning to classify text descriptions/merchants into categories.
/// P(Category | Tokens) ∝ P(Category) * Π P(Token | Category)
library;

import 'dart:math';

class NaiveBayesClassifier {
  // Map<Category, Count> - How many times each category has been seen
  final Map<String, int> _categoryCounts = {};
  
  // Map<Category, Map<Token, Count>> - Word frequencies per category
  final Map<String, Map<String, int>> _tokenCounts = {};
  
  // Map<Category, int> - Total number of tokens in each category (for denominator)
  final Map<String, int> _totalTokensByCategory = {};
  
  // Total number of documents (transactions) trained
  // Total number of documents (transactions) trained
  int _totalDocuments = 0;

  int _vocabularySize = 0;
  final Set<String> _vocabulary = {};

  NaiveBayesClassifier();

  /// Train the model with a single sample
  void train(String text, String category) {
    _totalDocuments++;
    _categoryCounts[category] = (_categoryCounts[category] ?? 0) + 1;
    
    // Initialize maps if needed
    _tokenCounts.putIfAbsent(category, () => {});
    _totalTokensByCategory.putIfAbsent(category, () => 0);
    
    final tokens = _tokenize(text);
    
    for (final token in tokens) {
      _vocabulary.add(token);
      _tokenCounts[category]![token] = (_tokenCounts[category]![token] ?? 0) + 1;
      _totalTokensByCategory[category] = _totalTokensByCategory[category]! + 1;
    }
    
    _vocabularySize = _vocabulary.length;
  }

  /// Bulk train model
  void trainBatch(List<({String text, String category})> samples) {
    for (final sample in samples) {
      train(sample.text, sample.category);
    }
  }

  /// Predict category for new text
  /// Returns a map of Category -> Log Probability (higher is better)
  Map<String, double> predictProbabilities(String text) {
    if (_totalDocuments == 0) return {};

    final tokens = _tokenize(text);
    
    // Check if any tokens exist in vocabulary
    // If not, we have absolutely no signal -> return empty
    final knownTokens = tokens.where((t) => _vocabulary.contains(t));
    if (knownTokens.isEmpty) return {};

    final scores = <String, double>{};

    // Use uniform prior to prevent large categories (like Food) from dominating
    // small categories (like Rent) just because they have more training keywords.
    final logUniformPrior = log(1.0 / _categoryCounts.length);
    
    for (final category in _categoryCounts.keys) {
      // 1. Prior Probability P(Category)
      // We use uniform prior instead of frequency-based prior
      double logPrior = logUniformPrior; 
      
      // 2. Likelihood P(Tokens | Category)
      double logLikelihood = 0.0;
      
      final categoryTokenCount = _totalTokensByCategory[category] ?? 0;
      // Laplace Smoothing (Add-1) denominator: Total tokens in class + Vocabulary size
      final denominator = categoryTokenCount + _vocabularySize;

      for (final token in tokens) {
        // Count of this token in this category
        final count = _tokenCounts[category]?[token] ?? 0;
        
        // P(Token | Category) with Laplace smoothing
        // prob = (count + 1) / (total_tokens_in_category + unique_tokens_in_vocab)
        logLikelihood += log((count + 1) / denominator);
      }
      
      scores[category] = logPrior + logLikelihood;
    }
    
    return scores;
  }
  
  /// Get top prediction
  ({String category, double probability})? predict(String text) {
    final scores = predictProbabilities(text);
    if (scores.isEmpty) return null;
    
    // Find category with max score
    var maxScore = double.negativeInfinity;
    var bestCategory = '';
    
    scores.forEach((category, score) {
      if (score > maxScore) {
        maxScore = score;
        bestCategory = category;
      }
    });

    if (bestCategory.isEmpty) return null;
    
    // Convert log score back to relative probability (simplified)
    // Note: True probability requires normalization over all classes, 
    // but for ranking, raw log score is sufficient. 
    // We return a normalized confidence score scaled 0.0-1.0 roughly.
    
    return (category: bestCategory, probability: _normalizeScore(maxScore, scores.values));
  }
  
  /// Simple tokenizer: lowercase, strip punctuation, split by space
  List<String> _tokenize(String text) {
    return text.toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ') // Replace non-alphanumeric with space
        .split(RegExp(r'\s+')) // Split by whitespace
        .where((t) => t.isNotEmpty) // Remove empty tokens
        .where((t) => t.length > 2) // Ignore very short words (stop words approximation)
        .toList();
  }
  
  /// Normalize log scores to a 0-1 confidence-like scale
  double _normalizeScore(double maxLogScore, Iterable<double> allScores) {
    // Softmax-ish approach or relative difference check
    // If the difference between top 1 and top 2 is large -> high confidence
    final sorted = allScores.toList()..sort();
    if (sorted.length < 2) return 1.0;
    
    final secondBest = sorted[sorted.length - 2];
    final diff = maxLogScore - secondBest;
    
    // Log difference of ~2.3 means 10x more likely. 
    // Log difference of ~0.7 means 2x more likely.
    if (diff > 2.3) return 0.95;
    if (diff > 1.5) return 0.85;
    if (diff > 0.7) return 0.65;
    return 0.45;
  }
  
  // Serialization
  Map<String, dynamic> toJson() {
    // Convert nested maps to JSON-encodable format
    final tokenCountsJson = _tokenCounts.map((k, v) => MapEntry(k, v));
    
    return {
      'categoryCounts': _categoryCounts,
      'tokenCounts': tokenCountsJson,
      'totalTokensByCategory': _totalTokensByCategory,
      'totalDocuments': _totalDocuments,
      'vocabulary': _vocabulary.toList(),
    };
  }

  factory NaiveBayesClassifier.fromJson(Map<String, dynamic> json) {
    final classifier = NaiveBayesClassifier();
    
    classifier._totalDocuments = json['totalDocuments'] as int;
    classifier._vocabulary.addAll((json['vocabulary'] as List).cast<String>());
    
    (json['categoryCounts'] as Map).forEach((k, v) {
      classifier._categoryCounts[k as String] = v as int;
    });

    (json['totalTokensByCategory'] as Map).forEach((k, v) {
      classifier._totalTokensByCategory[k as String] = v as int;
    });

    (json['tokenCounts'] as Map).forEach((category, tokens) {
      classifier._tokenCounts[category as String] = Map<String, int>.from(tokens as Map);
    });

    // Reconstruct vocabulary size
    classifier._vocabularySize = classifier._vocabulary.length;
    
    return classifier;
  }
}
