/// Insight Card Model — Enterprise-Ready Edition
/// Fully stable, mobile-optimized, predictable, and analytics-ready.
/// ✔ No structural breaking changes
/// ✔ Stronger serialization
/// ✔ Value comparison + sorting helpers added
library;

import 'dart:math';

/// Insight severity level
enum InsightSeverity { info, warning, critical }

/// Insight category (expandable safely)
enum InsightCategory { budget, subscription, behavior, location, trend }

class InsightCard {
  final String id;
  final String title;
  final String message;

  final InsightSeverity severity;
  final InsightCategory category;

  /// Confidence score: 0.0–1.0
  final double confidenceScore;

  final DateTime createdAt;

  /// Optional UI actions
  final String? actionLabel;
  final String? actionRoute;

  /// Optional deep explanation (for premium users)
  final String? explanation;

  /// Additional analytics metadata (safe key/value)
  final Map<String, dynamic>? metadata;

  const InsightCard({
    required this.id,
    required this.title,
    required this.message,
    required this.severity,
    required this.category,
    required this.confidenceScore,
    required this.createdAt,
    this.actionLabel,
    this.actionRoute,
    this.explanation,
    this.metadata,
  });



  // ---------------------------------------------------------------------------
  // 🔹 CONFIDENCE TIERS
  // ---------------------------------------------------------------------------
  bool get isHighConfidence => confidenceScore >= 0.80;
  bool get isMediumConfidence => confidenceScore >= 0.60 && confidenceScore < 0.80;
  bool get isLowConfidence => confidenceScore < 0.60;

  /// Normalized 0–100 for UI bars
  int get confidencePercent => (confidenceScore * 100).round().clamp(0, 100);

  // ---------------------------------------------------------------------------
  // 🔹 UI COLOR ROLE (mapped in theme)
  // ---------------------------------------------------------------------------
  String get uiColorRole => switch (severity) {
        InsightSeverity.info => "info",
        InsightSeverity.warning => "warning",
        InsightSeverity.critical => "danger",
      };

  // ---------------------------------------------------------------------------
  // 🔹 SORTING HELPERS
  // ---------------------------------------------------------------------------
  int get severityRank => switch (severity) {
        InsightSeverity.info => 1,
        InsightSeverity.warning => 2,
        InsightSeverity.critical => 3,
      };

  // Sort newest → oldest
  int compareByDate(InsightCard other) =>
      other.createdAt.compareTo(createdAt);

  // Sort by severity first, then confidence
  int compareBySeverity(InsightCard other) {
    final s = other.severityRank.compareTo(severityRank);
    if (s != 0) return s;
    return other.confidenceScore.compareTo(confidenceScore);
  }

  // ---------------------------------------------------------------------------
  // 🔹 SAFE METADATA ACCESS
  // ---------------------------------------------------------------------------
  T? meta<T>(String key) {
    final data = metadata;
    if (data == null) return null;

    final value = data[key];
    if (value is T) return value;

    return null;
  }

  // ---------------------------------------------------------------------------
  // 🔹 COPY WITH
  // ---------------------------------------------------------------------------
  InsightCard copyWith({
    String? id,
    String? title,
    String? message,
    InsightSeverity? severity,
    InsightCategory? category,
    double? confidenceScore,
    DateTime? createdAt,
    String? actionLabel,
    String? actionRoute,
    String? explanation,
    Map<String, dynamic>? metadata,
  }) {
    return InsightCard(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      severity: severity ?? this.severity,
      category: category ?? this.category,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      createdAt: createdAt ?? this.createdAt,
      actionLabel: actionLabel ?? this.actionLabel,
      actionRoute: actionRoute ?? this.actionRoute,
      explanation: explanation ?? this.explanation,
      metadata: metadata ?? this.metadata,
    );
  }

  // ---------------------------------------------------------------------------
  // 🔹 SERIALIZATION (Supabase + Isar/Drift safe)
  // ---------------------------------------------------------------------------
  Map<String, dynamic> toJson() => {
        "id": id,
        "title": title,
        "message": message,
        "severity": severity.name,
        "category": category.name,
        "confidenceScore": confidenceScore,
        "createdAt": createdAt.toIso8601String(),
        "actionLabel": actionLabel,
        "actionRoute": actionRoute,
        "explanation": explanation,
        "metadata": metadata,
      };

  factory InsightCard.fromJson(Map<String, dynamic> json) {
    return InsightCard(
      id: json["id"] ?? InsightCard.generateId(),
      title: json["title"] ?? "",
      message: json["message"] ?? "",
      severity: InsightSeverity.values
          .firstWhere((e) => e.name == json["severity"], orElse: () => InsightSeverity.info),
      category: InsightCategory.values
          .firstWhere((e) => e.name == json["category"], orElse: () => InsightCategory.behavior),
      confidenceScore: (json["confidenceScore"] as num?)?.toDouble() ?? 0.5,
      createdAt: DateTime.tryParse(json["createdAt"] ?? "") ?? DateTime.now(),
      actionLabel: json["actionLabel"],
      actionRoute: json["actionRoute"],
      explanation: json["explanation"],
      metadata: json["metadata"] is Map ? Map<String, dynamic>.from(json["metadata"]) : null,
    );
  }

  // ---------------------------------------------------------------------------
  // 🔹 HASH + EQUALITY (needed for Riverpod state comparison)
  // ---------------------------------------------------------------------------
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InsightCard &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          message == other.message &&
          severity == other.severity &&
          category == other.category &&
          confidenceScore == other.confidenceScore &&
          createdAt == other.createdAt;

  @override
  int get hashCode =>
      Object.hash(id, title, message, severity, category, confidenceScore, createdAt);

  // ---------------------------------------------------------------------------
  // 🔹 BETTER ID GENERATOR (collision-resistant)
  // ---------------------------------------------------------------------------
  static String generateId() {
    final ts = DateTime.now().microsecondsSinceEpoch.toString();
    final rnd = Random.secure().nextInt(0xFFFFFF).toRadixString(16).padLeft(6, '0');
    return "ins_${ts}_$rnd";
  }
}
