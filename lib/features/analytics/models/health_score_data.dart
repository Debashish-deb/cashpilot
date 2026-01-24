/// Health Score Data Model
/// Calculated financial health metrics
library;

class HealthScoreData {
  final int score; // 0-100
  final String level; // poor, fair, good, excellent
  final Map<String, double> componentScores;
  final int trend; // -10 to +10

  const HealthScoreData({
    required this.score,
    required this.level,
    required this.componentScores,
    this.trend = 0,
  });

  factory HealthScoreData.empty() {
    return const HealthScoreData(
      score: 0,
      level: 'unknown',
      componentScores: {},
      trend: 0,
    );
  }

  bool get isHealthy => score >= 70;
  bool get needsAttention => score < 50;
}
