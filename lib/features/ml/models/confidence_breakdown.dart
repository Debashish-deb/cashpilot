import 'package:flutter/foundation.dart';

/// Source of confidence value
enum ConfidenceSource {
  ocr,        // From OCR engine
  pattern,    // From pattern matching
  lookup,     // From database lookup
  learned,    // From ML learning
  manual,     // User-provided
}

/// Issue affecting confidence
@immutable
class ConfidenceIssue {
  final String field;
  final String reason;
  final String? suggestion;
  final double impact; // 0.0-1.0, how much this affects confidence

  const ConfidenceIssue({
    required this.field,
    required this.reason,
    this.suggestion,
    required this.impact,
  });

  factory ConfidenceIssue.fromJson(Map<String, dynamic> json) =>
      ConfidenceIssue(
        field: json['field'] as String,
        reason: json['reason'] as String,
        suggestion: json['suggestion'] as String?,
        impact: (json['impact'] as num?)?.toDouble() ?? 0.5,
      );

  Map<String, dynamic> toJson() => {
        'field': field,
        'reason': reason,
        if (suggestion != null) 'suggestion': suggestion,
        'impact': impact,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConfidenceIssue &&
          runtimeType == other.runtimeType &&
          field == other.field &&
          reason == other.reason &&
          suggestion == other.suggestion &&
          impact == other.impact;

  @override
  int get hashCode => Object.hash(field, reason, suggestion, impact);
}

/// Confidence for a specific field
@immutable
class FieldConfidence {
  final double value; // 0.0-1.0
  final ConfidenceSource source;
  final String? reason;
  final DateTime? lastUpdated;

  const FieldConfidence({
    required this.value,
    required this.source,
    this.reason,
    this.lastUpdated,
  });

  factory FieldConfidence.fromJson(Map<String, dynamic> json) =>
      FieldConfidence(
        value: (json['value'] as num).toDouble(),
        source: ConfidenceSource.values.byName(json['source'] as String),
        reason: json['reason'] as String?,
        lastUpdated: json['last_updated'] != null
            ? DateTime.parse(json['last_updated'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'value': value,
        'source': source.name,
        if (reason != null) 'reason': reason,
        if (lastUpdated != null) 'last_updated': lastUpdated!.toIso8601String(),
      };

  /// Confidence level category
  String get level {
    if (value >= 0.85) return 'high';
    if (value >= 0.65) return 'medium';
    return 'low';
  }

  /// Whether this field needs review
  bool get needsReview => value < 0.65;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FieldConfidence &&
          runtimeType == other.runtimeType &&
          value == other.value &&
          source == other.source &&
          reason == other.reason &&
          lastUpdated == other.lastUpdated;

  @override
  int get hashCode => Object.hash(value, source, reason, lastUpdated);
}

/// Typed confidence breakdown - replaces Map<String, dynamic>
/// Provides structured confidence information for ML training
@immutable
class ConfidenceBreakdown {
  final double overall;
  final Map<String, FieldConfidence> fields;
  final List<ConfidenceIssue> issues;
  final DateTime calculatedAt;

  const ConfidenceBreakdown({
    required this.overall,
    required this.fields,
    required this.issues,
    required this.calculatedAt,
  });

  factory ConfidenceBreakdown.fromJson(Map<String, dynamic> json) {
    final fieldsMap = (json['fields'] as Map<String, dynamic>?)?.map(
          (k, v) => MapEntry(
            k,
            FieldConfidence.fromJson(v as Map<String, dynamic>),
          ),
        ) ??
        {};

    final issuesList = (json['issues'] as List?)
            ?.map((i) => ConfidenceIssue.fromJson(i as Map<String, dynamic>))
            .toList() ??
        [];

    return ConfidenceBreakdown(
      overall: (json['overall'] as num?)?.toDouble() ?? 0.0,
      fields: fieldsMap,
      issues: issuesList,
      calculatedAt: json['calculated_at'] != null
          ? DateTime.parse(json['calculated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'overall': overall,
        'fields': fields.map((k, v) => MapEntry(k, v.toJson())),
        'issues': issues.map((i) => i.toJson()).toList(),
        'calculated_at': calculatedAt.toIso8601String(),
      };

  /// Get confidence for a specific field
  FieldConfidence? getFieldConfidence(String fieldName) => fields[fieldName];

  /// Get all fields that need review
  List<String> get fieldsNeedingReview =>
      fields.entries.where((e) => e.value.needsReview).map((e) => e.key).toList();

  /// Whether overall scan needs review
  bool get needsReview => overall < 0.65;

  /// Overall confidence level
  String get level {
    if (overall >= 0.85) return 'high';
    if (overall >= 0.65) return 'medium';
    return 'low';
  }

  /// Create from legacy Map format for backward compatibility
  factory ConfidenceBreakdown.fromLegacyMap(Map<String, dynamic> legacy) {
    return ConfidenceBreakdown.fromJson(legacy);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConfidenceBreakdown &&
          runtimeType == other.runtimeType &&
          overall == other.overall &&
          mapEquals(fields, other.fields) &&
          listEquals(issues, other.issues) &&
          calculatedAt == other.calculatedAt;

  @override
  int get hashCode => Object.hash(
        overall,
        Object.hashAll(fields.entries),
        Object.hashAll(issues),
        calculatedAt,
      );

  @override
  String toString() => 'ConfidenceBreakdown('
      'overall: ${(overall * 100).toStringAsFixed(1)}%, '
      'fields: ${fields.length}, '
      'issues: ${issues.length}'
      ')';
}
