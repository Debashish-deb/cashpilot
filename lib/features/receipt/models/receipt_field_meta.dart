/// Receipt Field Metadata - Typed replacement for `Map<String, dynamic>`
/// Stores extraction results with confidence and evidence
library;

class ReceiptFieldMeta {
  final double value;
  final double confidence;
  final String? evidenceLine;
  final int? lineNumber;
  
  const ReceiptFieldMeta({
    required this.value,
    required this.confidence,
    this.evidenceLine,
    this.lineNumber,
  });
  
  /// Serialize to JSON for database storage
  Map<String, dynamic> toJson() => {
    'value': value,
    'confidence': confidence,
    if (evidenceLine != null) 'evidence_line': evidenceLine,
    if (lineNumber != null) 'line_number': lineNumber,
  };
  
  /// Deserialize from JSON
  factory ReceiptFieldMeta.fromJson(Map<String, dynamic> json) => ReceiptFieldMeta(
    value: (json['value'] as num).toDouble(),
    confidence: (json['confidence'] as num).toDouble(),
    evidenceLine: json['evidence_line'] as String?,
    lineNumber: json['line_number'] as int?,
  );
  
  @override
  String toString() => 'ReceiptFieldMeta(value: $value, confidence: $confidence)';
}

/// String field metadata (for merchant, date strings, etc.)
class ReceiptStringFieldMeta {
  final String value;
  final double confidence;
  final String? evidenceLine;
  final int? lineNumber;
  
  const ReceiptStringFieldMeta({
    required this.value,
    required this.confidence,
    this.evidenceLine,
    this.lineNumber,
  });
  
  Map<String, dynamic> toJson() => {
    'value': value,
    'confidence': confidence,
    if (evidenceLine != null) 'evidence_line': evidenceLine,
    if (lineNumber != null) 'line_number': lineNumber,
  };
  
  factory ReceiptStringFieldMeta.fromJson(Map<String, dynamic> json) => ReceiptStringFieldMeta(
    value: json['value'] as String,
    confidence: (json['confidence'] as num).toDouble(),
    evidenceLine: json['evidence_line'] as String?,
    lineNumber: json['line_number'] as int?,
  );
  
  @override
  String toString() => 'ReceiptStringFieldMeta(value: $value, confidence: $confidence)';
}
