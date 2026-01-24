/// Confidence Engine - Single source of truth for barcode confidence
/// Centralizes all confidence computation logic
library;

class ConfidenceEngine {
  /// Minimum acceptable confidence threshold
  static const double minAcceptable = 0.70;
  
  /// High confidence threshold
  static const double highConfidence = 0.85;
  
  /// Medium confidence threshold
  static const double mediumConfidence = 0.65;
  
  /// Low confidence threshold
  static const double lowConfidence = 0.35;
  
  /// Compute overall confidence for a barcode scan
  /// This is the ONLY place confidence should be calculated
  /// Takes metadata map until BarcodeScanResult is updated to use typed metadata
  static double compute(Map<String, dynamic> metadata, {
    bool? isValidChecksum,
    bool? hasProductInfo,
  }) {
    double baseConfidence = 0.0;
    
    // Signal 1: Scanner confidence (if available from metadata)
    final scannerConfidence = metadata['confidence'] as double? ?? 0.5;
    baseConfidence += scannerConfidence * 0.30;  // 30% weight
    
    // Signal 2: Validation quality
    final validationWeight = (isValidChecksum ?? false) ? 0.25 : 0.0;
    baseConfidence += validationWeight;  // 25% weight
    
    // Signal 3: GS1 inference confidence
    final gs1Confidence = metadata['gs1_confidence'] as double? ?? 0.0;
    baseConfidence += gs1Confidence * 0.20;  // 20% weight
    
    // Signal 4: Lookup success
    final lookupWeight = (hasProductInfo ?? false) ? 0.25 : 0.0;
    baseConfidence += lookupWeight;  // 25% weight
    
    return baseConfidence.clamp(0.0, 1.0);
  }
  
  /// Get confidence level category
  static ConfidenceLevel getLevel(double confidence) {
    if (confidence >= highConfidence) return ConfidenceLevel.high;
    if (confidence >= mediumConfidence) return ConfidenceLevel.medium;
    if (confidence >= lowConfidence) return ConfidenceLevel.low;
    return ConfidenceLevel.veryLow;
  }
  
  /// Check if confidence requires user review
  static bool needsReview(double confidence) => confidence < minAcceptable;
}

/// Confidence level enum
enum ConfidenceLevel {
  veryLow,
  low,
  medium,
  high,
}

extension ConfidenceLevelExtensions on ConfidenceLevel {
  String get displayName {
    switch (this) {
      case ConfidenceLevel.veryLow:
        return 'Very Low';
      case ConfidenceLevel.low:
        return 'Low';
      case ConfidenceLevel.medium:
        return 'Medium';
      case ConfidenceLevel.high:
        return 'High';
    }
  }
}
