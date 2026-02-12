import 'package:flutter/material.dart' show immutable;

@immutable
class ReceiptFieldMeta<T> {
  final String field;
  final T? value;
  final double confidence;
  final List<String> strategiesUsed;
  final List<String> evidenceLines;
  final bool userVerified;
  final DateTime extractedAt;
  final Map<String, dynamic> diagnostics;

  ReceiptFieldMeta({
    required this.field,
    this.value,
    this.confidence = 0.0,
    this.strategiesUsed = const [],
    this.evidenceLines = const [],
    this.userVerified = false,
    DateTime? extractedAt,
    this.diagnostics = const {},
  }) : extractedAt = extractedAt ?? DateTime.now();

  bool get isReliable => confidence >= 0.75;
  bool get needsReview => confidence < 0.6;

  ReceiptFieldMeta<T> copyWith({
    T? value,
    double? confidence,
    List<String>? strategiesUsed,
    List<String>? evidenceLines,
    bool? userVerified,
    Map<String, dynamic>? diagnostics,
  }) {
    return ReceiptFieldMeta<T>(
      field: field,
      value: value ?? this.value,
      confidence: confidence ?? this.confidence,
      strategiesUsed: strategiesUsed ?? this.strategiesUsed,
      evidenceLines: evidenceLines ?? this.evidenceLines,
      userVerified: userVerified ?? this.userVerified,
      diagnostics: diagnostics ?? this.diagnostics,
    );
  }
}
