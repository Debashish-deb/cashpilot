/// Receipt Extraction Metadata - Complete typed extraction results
/// Replaces `Map<String, dynamic>` for receipt field extraction
library;

import 'receipt_field_meta.dart';

class ReceiptExtractionMeta {
  final ReceiptFieldMeta? total;
  final ReceiptFieldMeta? subtotal;
  final ReceiptFieldMeta? tax;  // VAT/sales tax
  final ReceiptStringFieldMeta? merchant;
  final ReceiptStringFieldMeta? date;
  final ReceiptStringFieldMeta? currency;
  final String modelVersion;
  final DateTime extractedAt;
  
  const ReceiptExtractionMeta({
    this.total,
    this.subtotal,
    this.tax,
    this.merchant,
    this.date,
    this.currency,
    required this.modelVersion,
    required this.extractedAt,
  });
  
  /// Serialize to JSON for database storage
  Map<String, dynamic> toJson() => {
    if (total != null) 'total': total!.toJson(),
    if (subtotal != null) 'subtotal': subtotal!.toJson(),
    if (tax != null) 'tax': tax!.toJson(),
    if (merchant != null) 'merchant': merchant!.toJson(),
    if (date != null) 'date': date!.toJson(),
    if (currency != null) 'currency': currency!.toJson(),
    'model_version': modelVersion,
    'extracted_at': extractedAt.toIso8601String(),
  };
  
  /// Deserialize from JSON
  factory ReceiptExtractionMeta.fromJson(Map<String, dynamic> json) => ReceiptExtractionMeta(
    total: json['total'] != null 
        ? ReceiptFieldMeta.fromJson(json['total'] as Map<String, dynamic>)
        : null,
    subtotal: json['subtotal'] != null
        ? ReceiptFieldMeta.fromJson(json['subtotal'] as Map<String, dynamic>)
        : null,
    tax: json['tax'] != null
        ? ReceiptFieldMeta.fromJson(json['tax'] as Map<String, dynamic>)
        : null,
    merchant: json['merchant'] != null
        ? ReceiptStringFieldMeta.fromJson(json['merchant'] as Map<String, dynamic>)
        : null,
    date: json['date'] != null
        ? ReceiptStringFieldMeta.fromJson(json['date'] as Map<String, dynamic>)
        : null,
    currency: json['currency'] != null
        ? ReceiptStringFieldMeta.fromJson(json['currency'] as Map<String, dynamic>)
        : null,
    modelVersion: json['model_version'] as String,
    extractedAt: DateTime.parse(json['extracted_at'] as String),
  );
  
  /// Calculate overall extraction confidence
  double get overallConfidence {
    final confidences = [
      total?.confidence,
      subtotal?.confidence,
      tax?.confidence,
      merchant?.confidence,
      date?.confidence,
    ].whereType<double>().toList();
    
    if (confidences.isEmpty) return 0.0;
    return confidences.reduce((a, b) => a + b) / confidences.length;
  }
  
  /// Check if extraction needs user review
  bool get needsReview => overallConfidence < 0.70;
  
  @override
  String toString() => 'ReceiptExtractionMeta(merchant: ${merchant?.value}, '
      'total: ${total?.value}, confidence: ${overallConfidence.toStringAsFixed(2)})';
}
