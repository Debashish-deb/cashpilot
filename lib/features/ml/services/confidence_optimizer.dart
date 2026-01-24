/// Confidence Optimizer - Dynamically adjusts confidence thresholds
/// Based on user feedback and model performance
library;

/// Optimized confidence thresholds
class ConfidenceThresholds {
  final double minAcceptable;  // Below this, show warning
  final double highConfidence;  // Above this, auto-fill
  final double needsReview;    // Below this, force review
  final String modelVersion;
  final DateTime optimizedAt;
  
  const ConfidenceThresholds({
    required this.minAcceptable,
    required this.highConfidence,
    required this.needsReview,
    required this.modelVersion,
    required this.optimizedAt,
  });
  
  /// Default conservative thresholds
  factory ConfidenceThresholds.defaultThresholds() {
    return ConfidenceThresholds(
      minAcceptable: 0.60,
      highConfidence: 0.85,
      needsReview: 0.50,
      modelVersion: 'default',
      optimizedAt: DateTime.now(),
    );
  }
  
  Map<String, dynamic> toJson() => {
    'min_acceptable': minAcceptable,
    'high_confidence': highConfidence,
    'needs_review': needsReview,
    'model_version': modelVersion,
    'optimized_at': optimizedAt.toIso8601String(),
  };
}

/// Service for optimizing confidence thresholds
class ConfidenceOptimizer {
  /// Optimize thresholds based on learning data
  /// 
  /// Algorithm:
  /// - Analyze correction patterns
  /// - Find confidence range where most accepted scans occur
  /// - Find confidence range where most rejections occur
  /// - Set thresholds to maximize acceptance while minimizing false positives
  static Future<ConfidenceThresholds> optimizeThresholds({
    required Future<List<Map<String, dynamic>>> Function() getLearningEvents,
    required String modelVersion,
  }) async {
    try {
      final events = await getLearningEvents();
      
      if (events.length < 50) {
        // Not enough data, use defaults
        return ConfidenceThresholds.defaultThresholds();
      }
      
      // Collect confidence scores by outcome
      final acceptedConfidences = <double>[];
      final editedConfidences = <double>[];
      final rejectedConfidences = <double>[];
      
      for (final event in events) {
        final outcome = event['outcome'] as String;
        final metadata = event['metadata'] as Map<String, dynamic>?;
        
        if (metadata != null && metadata['confidence'] != null) {
          final confidence = (metadata['confidence'] as num).toDouble();
          
          if (outcome == 'accepted') {
            acceptedConfidences.add(confidence);
          } else if (outcome == 'edited') {
            editedConfidences.add(confidence);
          } else if (outcome == 'rejected') {
            rejectedConfidences.add(confidence);
          }
        }
      }
      
      // Calculate percentiles
      acceptedConfidences.sort();
      rejectedConfidences.sort();
      
      // High confidence: 90th percentile of accepted scans
      final highConfidence = acceptedConfidences.isNotEmpty
          ? _percentile(acceptedConfidences, 0.90)
          : 0.85;
      
      // Min acceptable: 50th percentile of accepted scans
      final minAcceptable = acceptedConfidences.isNotEmpty
          ? _percentile(acceptedConfidences, 0.50)
          : 0.60;
      
      // Needs review: 75th percentile of rejected scans (avoid this range)
      final needsReview = rejectedConfidences.isNotEmpty
          ? _percentile(rejectedConfidences, 0.75)
          : 0.50;
      
      return ConfidenceThresholds(
        minAcceptable: minAcceptable.clamp(0.50, 0.75),
        highConfidence: highConfidence.clamp(0.80,1.00),
        needsReview: needsReview.clamp(0.30, 0.60),
        modelVersion: modelVersion,
        optimizedAt: DateTime.now(),
      );
    } catch (e) {
      print('Failed to optimize thresholds: $e');
      return ConfidenceThresholds.defaultThresholds();
    }
  }
  
  /// Calculate percentile
  static double _percentile(List<double> values, double percentile) {
    if (values.isEmpty) return 0.0;
    final index = ((values.length - 1) * percentile).round();
    return values[index];
  }
  
  /// Recommend optimal threshold adjustments
  static Map<String, dynamic> recommendAdjustments({
    required ConfidenceThresholds current,
    required double currentAcceptanceRate,
    required double currentRejectionRate,
  }) {
    final recommendations = <String, dynamic>{};
    
    // If too many rejections, lower thresholds
    if (currentRejectionRate > 0.20) {
      recommendations['min_acceptable'] = {
        'current': current.minAcceptable,
        'recommended': (current.minAcceptable - 0.05).clamp(0.40, 0.70),
        'reason': 'High rejection rate - lower threshold to be more lenient',
      };
    }
    
    // If acceptance rate is low, investigate
    if (currentAcceptanceRate < 0.60) {
      recommendations['investigation_needed'] = true;
      recommendations['reason'] = 'Low acceptance rate suggests model quality issue';
    }
    
    // If very high acceptance, can be more strict
    if (currentAcceptanceRate > 0.90 && currentRejectionRate < 0.05) {
      recommendations['high_confidence'] = {
        'current': current.highConfidence,
        'recommended': (current.highConfidence + 0.02).clamp(0.85, 0.95),
        'reason': 'Excellent performance - can raise high confidence bar',
      };
    }
    
    return recommendations;
  }
}
