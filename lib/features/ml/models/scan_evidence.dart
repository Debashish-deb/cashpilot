import 'package:flutter/foundation.dart';
import 'ocr_metadata.dart';
import 'confidence_breakdown.dart';

/// Validation result for extracted data
@immutable
class ValidationResult {
  final String field;
  final bool isValid;
  final String? errorMessage;
  final String? validatedValue;

  const ValidationResult({
    required this.field,
    required this.isValid,
    this.errorMessage,
    this.validatedValue,
  });

  factory ValidationResult.fromJson(Map<String, dynamic> json) =>
      ValidationResult(
        field: json['field'] as String,
        isValid: json['is_valid'] as bool,
        errorMessage: json['error_message'] as String?,
        validatedValue: json['validated_value'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'field': field,
        'is_valid': isValid,
        if (errorMessage != null) 'error_message': errorMessage,
        if (validatedValue != null) 'validated_value': validatedValue,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ValidationResult &&
          runtimeType == other.runtimeType &&
          field == other.field &&
          isValid == other.isValid &&
          errorMessage == other.errorMessage &&
          validatedValue == other.validatedValue;

  @override
  int get hashCode => Object.hash(field, isValid, errorMessage, validatedValue);
}

/// Quality issue detected in scan
@immutable
class QualityIssue {
  final String type;
  final String description;
  final double severity; // 0.0-1.0
  final String? recommendation;

  const QualityIssue({
    required this.type,
    required this.description,
    required this.severity,
    this.recommendation,
  });

  factory QualityIssue.fromJson(Map<String, dynamic> json) => QualityIssue(
        type: json['type'] as String,
        description: json['description'] as String,
        severity: (json['severity'] as num?)?.toDouble() ?? 0.5,
        recommendation: json['recommendation'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'type': type,
        'description': description,
        'severity': severity,
        if (recommendation != null) 'recommendation': recommendation,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QualityIssue &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          description == other.description &&
          severity == other.severity &&
          recommendation == other.recommendation;

  @override
  int get hashCode => Object.hash(type, description, severity, recommendation);
}

/// Typed scan evidence - replaces Map<String, dynamic>
/// Complete audit trail for ML training and debugging
@immutable
class ScanEvidence {
  final String scanId;
  final DateTime timestamp;
  final String imageHash;
  final OcrMetadata ocrMeta;
  final ConfidenceBreakdown confidence;
  final List<ValidationResult> validations;
  final List<QualityIssue> qualityIssues;
  final String? userId;

  const ScanEvidence({
    required this.scanId,
    required this.timestamp,
    required this.imageHash,
    required this.ocrMeta,
    required this.confidence,
    required this.validations,
    required this.qualityIssues,
    this.userId,
  });

  factory ScanEvidence.fromJson(Map<String, dynamic> json) {
    final validationsList = (json['validations'] as List?)
            ?.map((v) => ValidationResult.fromJson(v as Map<String, dynamic>))
            .toList() ??
        [];

    final issuesList = (json['quality_issues'] as List?)
            ?.map((i) => QualityIssue.fromJson(i as Map<String, dynamic>))
            .toList() ??
        [];

    return ScanEvidence(
      scanId: json['scan_id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      imageHash: json['image_hash'] as String,
      ocrMeta: OcrMetadata.fromJson(json['ocr_meta'] as Map<String, dynamic>),
      confidence: ConfidenceBreakdown.fromJson(
          json['confidence'] as Map<String, dynamic>),
      validations: validationsList,
      qualityIssues: issuesList,
      userId: json['user_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'scan_id': scanId,
        'timestamp': timestamp.toIso8601String(),
        'image_hash': imageHash,
        'ocr_meta': ocrMeta.toJson(),
        'confidence': confidence.toJson(),
        'validations': validations.map((v) => v.toJson()).toList(),
        'quality_issues': qualityIssues.map((i) => i.toJson()).toList(),
        if (userId != null) 'user_id': userId,
      };

  /// Whether scan passed all validations
  bool get isValid => validations.every((v) => v.isValid);

  /// Critical quality issues (severity > 0.7)
  List<QualityIssue> get criticalIssues =>
      qualityIssues.where((i) => i.severity > 0.7).toList();

  /// Overall scan quality score (0.0-1.0)
  double get qualityScore {
    if (qualityIssues.isEmpty) return confidence.overall;
    final avgSeverity =
        qualityIssues.map((i) => i.severity).reduce((a, b) => a + b) /
            qualityIssues.length;
    return confidence.overall * (1.0 - avgSeverity * 0.3);
  }

  /// Create from legacy Map format for backward compatibility
  factory ScanEvidence.fromLegacyMap(Map<String, dynamic> legacy) {
    return ScanEvidence.fromJson(legacy);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScanEvidence &&
          runtimeType == other.runtimeType &&
          scanId == other.scanId &&
          timestamp == other.timestamp &&
          imageHash == other.imageHash &&
          ocrMeta == other.ocrMeta &&
          confidence == other.confidence &&
          listEquals(validations, other.validations) &&
          listEquals(qualityIssues, other.qualityIssues) &&
          userId == other.userId;

  @override
  int get hashCode => Object.hash(
        scanId,
        timestamp,
        imageHash,
        ocrMeta,
        confidence,
        Object.hashAll(validations),
        Object.hashAll(qualityIssues),
        userId,
      );

  @override
  String toString() => 'ScanEvidence('
      'id: $scanId, '
      'quality: ${(qualityScore * 100).toStringAsFixed(1)}%, '
      'valid: $isValid'
      ')';
}
