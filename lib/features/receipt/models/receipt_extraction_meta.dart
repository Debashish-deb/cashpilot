import 'package:flutter/material.dart' show immutable;
import 'receipt_field_meta.dart';

@immutable
class ReceiptExtractionMeta {
  // Field-level metadata
  final ReceiptFieldMeta<double>? total;
  final ReceiptFieldMeta<double>? subtotal;
  final ReceiptFieldMeta<double>? tax;
  final ReceiptFieldMeta<String>? merchant;
  final ReceiptFieldMeta<String>? date;
  final ReceiptFieldMeta<String>? currency;
  
  // Model info
  final String modelVersion;
  final DateTime extractedAt;

  // Telemetry (legacy/optional)
  final Duration? processingTime;
  final double globalConfidence;

  const ReceiptExtractionMeta({
    this.total,
    this.subtotal,
    this.tax,
    this.merchant,
    this.date,
    this.currency,
    required this.modelVersion,
    required this.extractedAt,
    this.processingTime,
    this.globalConfidence = 0.0,
  });

  bool get isProductionQuality => globalConfidence > 0.8;
  
  bool get requiresUserReview => 
      (total?.confidence ?? 0) < 0.7 || 
      (date?.confidence ?? 0) < 0.7;

  // For compatibility if needed
  Map<String, dynamic> toTelemetryJson() => {
    'modelVersion': modelVersion,
    'total': total?.confidence,
    'merchant': merchant?.confidence,
    'global': globalConfidence,
  };
}
