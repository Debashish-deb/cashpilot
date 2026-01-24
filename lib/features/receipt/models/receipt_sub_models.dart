/// Receipt Sub-Models - Refactored from God Object
/// Addresses technical debt issue #3: God objects
library;

import 'package:flutter/foundation.dart';
import '../../ml/models/ocr_metadata.dart';
import '../../ml/models/confidence_breakdown.dart';

/// Core receipt data - extracted fields only
@immutable
class ReceiptData {
  final String rawText;
  final double? total;
  final String? merchant;
  final DateTime? date;
  final String? currency;
  final List<String>? items;
  final String? category;

  const ReceiptData({
    required this.rawText,
    this.total,
    this.merchant,
    this.date,
    this.currency,
    this.items,
    this.category,
  });

  factory ReceiptData.fromJson(Map<String, dynamic> json) {
    return ReceiptData(
      rawText: json['raw_text'] as String,
      total: (json['total'] as num?)?.toDouble(),
      merchant: json['merchant'] as String?,
      date: json['date'] != null ? DateTime.parse(json['date'] as String) : null,
      currency: json['currency'] as String?,
      items: (json['items'] as List?)?.cast<String>(),
      category: json['category'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'raw_text': rawText,
        if (total != null) 'total': total,
        if (merchant != null) 'merchant': merchant,
        if (date != null) 'date': date!.toIso8601String(),
        if (currency != null) 'currency': currency,
        if (items != null) 'items': items,
        if (category != null) 'category': category,
      };

  ReceiptData copyWith({
    String? rawText,
    double? total,
    String? merchant,
    DateTime? date,
    String? currency,
    List<String>? items,
    String? category,
  }) {
    return ReceiptData(
      rawText: rawText ?? this.rawText,
      total: total ?? this.total,
      merchant: merchant ?? this.merchant,
      date: date ?? this.date,
      currency: currency ?? this.currency,
      items: items ?? this.items,
      category: category ?? this.category,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReceiptData &&
          runtimeType == other.runtimeType &&
          rawText == other.rawText &&
          total == other.total &&
          merchant == other.merchant &&
          date == other.date &&
          currency == other.currency &&
          listEquals(items, other.items) &&
          category == other.category;

  @override
  int get hashCode => Object.hash(
        rawText,
        total,
        merchant,
        date,
        currency,
        Object.hashAll(items ?? []),
        category,
      );
}

/// Processing metadata - how the receipt was scanned
@immutable
class ReceiptProcessing {
  final String scanId;
  final DateTime scannedAt;
  final String modelVersion;
  final int processingTimeMs;
  final String source; // 'camera', 'gallery', 'manual'
  final OcrMetadata? ocrMetadata;

  const ReceiptProcessing({
    required this.scanId,
    required this.scannedAt,
    required this.modelVersion,
    required this.processingTimeMs,
    this.source = 'camera',
    this.ocrMetadata,
  });

  factory ReceiptProcessing.fromJson(Map<String, dynamic> json) {
    return ReceiptProcessing(
      scanId: json['scan_id'] as String,
      scannedAt: DateTime.parse(json['scanned_at'] as String),
      modelVersion: json['model_version'] as String,
      processingTimeMs: json['processing_time_ms'] as int,
      source: json['source'] as String? ?? 'camera',
      ocrMetadata: json['ocr_metadata'] != null
          ? OcrMetadata.fromJson(json['ocr_metadata'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'scan_id': scanId,
        'scanned_at': scannedAt.toIso8601String(),
        'model_version': modelVersion,
        'processing_time_ms': processingTimeMs,
        'source': source,
        if (ocrMetadata != null) 'ocr_metadata': ocrMetadata!.toJson(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReceiptProcessing &&
          runtimeType == other.runtimeType &&
          scanId == other.scanId &&
          scannedAt == other.scannedAt &&
          modelVersion == other.modelVersion &&
          processingTimeMs == other.processingTimeMs &&
          source == other.source &&
          ocrMetadata == other.ocrMetadata;

  @override
  int get hashCode => Object.hash(
        scanId,
        scannedAt,
        modelVersion,
        processingTimeMs,
        source,
        ocrMetadata,
      );
}

/// Quality assessment - confidence and validation
@immutable
class ReceiptQuality {
  final double overallConfidence;
  final Map<String, double> fieldConfidences;
  final bool needsReview;
  final List<String> issues;
  final ConfidenceBreakdown? breakdown;

  const ReceiptQuality({
    required this.overallConfidence,
    required this.fieldConfidences,
    required this.needsReview,
    required this.issues,
    this.breakdown,
  });

  factory ReceiptQuality.fromJson(Map<String, dynamic> json) {
    final fieldConfsRaw = json['field_confidences'] as Map<String, dynamic>?;
    final fieldConfs = fieldConfsRaw?.map(
          (k, v) => MapEntry(k, (v as num).toDouble()),
        ) ??
        {};

    return ReceiptQuality(
      overallConfidence: (json['overall_confidence'] as num).toDouble(),
      fieldConfidences: fieldConfs,
      needsReview: json['needs_review'] as bool,
      issues: (json['issues'] as List?)?.cast<String>() ?? [],
      breakdown: json['breakdown'] != null
          ? ConfidenceBreakdown.fromJson(json['breakdown'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'overall_confidence': overallConfidence,
        'field_confidences': fieldConfidences,
        'needs_review': needsReview,
        'issues': issues,
        if (breakdown != null) 'breakdown': breakdown!.toJson(),
      };

  /// Get confidence level category
  String get level {
    if (overallConfidence >= 0.85) return 'high';
    if (overallConfidence >= 0.65) return 'medium';
    return 'low';
  }

  /// Get fields that need review
  List<String> get fieldsNeedingReview =>
      fieldConfidences.entries.where((e) => e.value < 0.65).map((e) => e.key).toList();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReceiptQuality &&
          runtimeType == other.runtimeType &&
          overallConfidence == other.overallConfidence &&
          mapEquals(fieldConfidences, other.fieldConfidences) &&
          needsReview == other.needsReview &&
          listEquals(issues, other.issues) &&
          breakdown == other.breakdown;

  @override
  int get hashCode => Object.hash(
        overallConfidence,
        Object.hashAll(fieldConfidences.entries),
        needsReview,
        Object.hashAll(issues),
        breakdown,
      );
}

/// User guidance - UI hints and suggestions
@immutable
class ReceiptGuidance {
  final String? duplicateWarning;
  final List<String> suggestions;
  final Map<String, String> fieldHints;
  final bool isGated; // Subscription limit reached

  const ReceiptGuidance({
    this.duplicateWarning,
    this.suggestions = const [],
    this.fieldHints = const {},
    this.isGated = false,
  });

  factory ReceiptGuidance.fromJson(Map<String, dynamic> json) {
    final hintsRaw = json['field_hints'] as Map<String, dynamic>?;
    final hints = hintsRaw?.map((k, v) => MapEntry(k, v.toString())) ?? {};

    return ReceiptGuidance(
      duplicateWarning: json['duplicate_warning'] as String?,
      suggestions: (json['suggestions'] as List?)?.cast<String>() ?? [],
      fieldHints: hints,
      isGated: json['is_gated'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        if (duplicateWarning != null) 'duplicate_warning': duplicateWarning,
        'suggestions': suggestions,
        'field_hints': fieldHints,
        'is_gated': isGated,
      };

  /// Has any guidance to show
  bool get hasGuidance =>
      duplicateWarning != null || suggestions.isNotEmpty || fieldHints.isNotEmpty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReceiptGuidance &&
          runtimeType == other.runtimeType &&
          duplicateWarning == other.duplicateWarning &&
          listEquals(suggestions, other.suggestions) &&
          mapEquals(fieldHints, other.fieldHints) &&
          isGated == other.isGated;

  @override
  int get hashCode => Object.hash(
        duplicateWarning,
        Object.hashAll(suggestions),
        Object.hashAll(fieldHints.entries),
        isGated,
      );
}
