import 'dart:math';
import '../models/analytics_models.dart';

/// Confidence Engine - Statistically rigorous confidence calculation
/// Uses Standard Error and Margin of Error (CI = Mean ± Z*σ/√n)
class ConfidenceEngine {
  
  /// Calculate detailed confidence statistics
  ConfidenceStats calculateStats({
    required double mean,
    required double variance,
    required int sampleSize,
  }) {
    // 1. Edge Cases (Insufficient Data)
    if (sampleSize < 3 || mean.abs() < 0.01) {
      return ConfidenceStats(
        score: 0,
        level: ConfidenceLevel.low,
        marginOfError: 0,
        relativeError: 1.0,
      );
    }

    // 2. Statistical Calculation (95% CI)
    // Standard Deviation (σ)
    final sigma = sqrt(variance);
    
    // Standard Error (SE = σ / √n)
    final standardError = sigma / sqrt(sampleSize);
    
    // Margin of Error (MOE = Z * SE), Z=1.96 for 95% Confidence
    // For small n < 30, strictly should use T-distribution, but Z is acceptable for this estimation
    final zScore = 1.96; 
    final marginOfError = zScore * standardError;
    
    // Relative Error (CV of the mean) = MOE / Mean
    final relativeError = marginOfError / mean.abs();

    // 3. Scoring (0-100)
    // Map Relative Error to a Quality Score.
    // 0% Error (perfect) -> 100 Score
    // 10% Error -> 80 Score
    // 50% Error -> 0 Score
    // Formula: Score = 100 * (1 - (RelError * 2)) clamped
    double score = (1.0 - (relativeError * 2)) * 100;
    
    // Penalize extremely small sample sizes even if variance is 0 (to avoid overconfidence on 3 identical points)
    if (sampleSize < 10) {
      score *= (sampleSize / 10.0);
    }
    
    score = score.clamp(0.0, 100.0);

    // 4. Determine Level
    ConfidenceLevel level;
    if (score >= 70) {
      level = ConfidenceLevel.high; // < 15% Relative Error roughly
    } else if (score >= 40) {
      level = ConfidenceLevel.medium; // < 30% Relative Error roughly
    } else {
      level = ConfidenceLevel.low;
    }

    return ConfidenceStats(
      score: score,
      level: level,
      marginOfError: marginOfError,
      relativeError: relativeError,
    );
  }

  /// Backward compatible helper
  ConfidenceLevel calculateConfidence({
    required double mean,
    required double variance,
    required int sampleSize,
  }) {
    return calculateStats(mean: mean, variance: variance, sampleSize: sampleSize).level;
  }
}

class ConfidenceStats {
  final double score; // 0-100
  final ConfidenceLevel level;
  final double marginOfError;
  final double relativeError;

  ConfidenceStats({
    required this.score,
    required this.level,
    required this.marginOfError,
    required this.relativeError,
  });
}
