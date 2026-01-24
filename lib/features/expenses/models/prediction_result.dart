/// Prediction Result Model
/// Represents a category prediction with confidence score
library;

class PredictionResult {
  final String category;
  final int confidence; // 0-100
  final String source; // 'merchant_pattern', 'heuristic', 'learned'

  const PredictionResult({
    required this.category,
    required this.confidence,
    required this.source,
  });

  /// Create from JSON
  factory PredictionResult.fromJson(Map<String, dynamic> json) {
    return PredictionResult(
      category: json['category'] as String,
      confidence: json['confidence'] as int,
      source: json['source'] as String,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'confidence': confidence,
      'source': source,
    };
  }

  @override
  String toString() => 'PredictionResult($category: $confidence% from $source)';
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PredictionResult &&
          runtimeType == other.runtimeType &&
          category == other.category &&
          confidence == other.confidence &&
          source == other.source;

  @override
  int get hashCode => Object.hash(category, confidence, source);
}
