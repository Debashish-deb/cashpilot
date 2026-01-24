/// Receipt Outcome Tracking - Captures user feedback for ML learning
/// Enables the system to learn from corrections and improve over time
library;

/// Outcome of a receipt scan from user perspective
enum ReceiptOutcome {
  /// User accepted the scan as-is without changes
  accepted,
  
  /// User corrected some fields
  edited,
  
  /// User discarded the scan entirely
  rejected,
}

extension ReceiptOutcomeExtensions on ReceiptOutcome {
  String get displayName {
    switch (this) {
      case ReceiptOutcome.accepted:
        return 'Accepted';
      case ReceiptOutcome.edited:
        return 'Edited';
      case ReceiptOutcome.rejected:
        return 'Rejected';
    }
  }
  
  String toJson() => name;
  
  static ReceiptOutcome fromJson(String json) {
    return ReceiptOutcome.values.firstWhere(
      (e) => e.name == json,
      orElse: () => ReceiptOutcome.rejected,
    );
  }
}

/// Correction made to a specific field
class ReceiptFieldCorrection {
  final String fieldName;  // 'total', 'merchant', 'date', etc.
  final dynamic originalValue;
  final double originalConfidence;
  final dynamic correctedValue;
  final String? userNote;
  
  const ReceiptFieldCorrection({
    required this.fieldName,
    required this.originalValue,
    required this.originalConfidence,
    required this.correctedValue,
    this.userNote,
  });
  
  Map<String, dynamic> toJson() => {
    'field_name': fieldName,
    'original_value': originalValue,
    'original_confidence': originalConfidence,
    'corrected_value': correctedValue,
    if (userNote != null) 'user_note': userNote,
  };
  
  factory ReceiptFieldCorrection.fromJson(Map<String, dynamic> json) {
    return ReceiptFieldCorrection(
      fieldName: json['field_name'] as String,
      originalValue: json['original_value'],
      originalConfidence: (json['original_confidence'] as num).toDouble(),
      correctedValue: json['corrected_value'],
      userNote: json['user_note'] as String?,
    );
  }
}

/// Complete correction event for learning
class ReceiptCorrectionEvent {
  final String receiptId;  // UUID of the receipt/expense
  final ReceiptOutcome outcome;
  final Map<String, ReceiptFieldCorrection> corrections;
  final DateTime timestamp;
  final String modelVersion;  // Which model version was used
  
  const ReceiptCorrectionEvent({
    required this.receiptId,
    required this.outcome,
    required this.corrections,
    required this.timestamp,
    required this.modelVersion,
  });
  
  Map<String, dynamic> toJson() => {
    'receipt_id': receiptId,
    'outcome': outcome.toJson(),
    'corrections': corrections.map((k, v) => MapEntry(k, v.toJson())),
    'timestamp': timestamp.toIso8601String(),
    'model_version': modelVersion,
  };
  
  factory ReceiptCorrectionEvent.fromJson(Map<String, dynamic> json) {
    final correctionsJson = json['corrections'] as Map<String, dynamic>;
    final corrections = correctionsJson.map(
      (k, v) => MapEntry(k, ReceiptFieldCorrection.fromJson(v as Map<String, dynamic>)),
    );
    
    return ReceiptCorrectionEvent(
      receiptId: json['receipt_id'] as String,
      outcome: ReceiptOutcomeExtensions.fromJson(json['outcome'] as String),
      corrections: corrections,
      timestamp: DateTime.parse(json['timestamp'] as String),
      modelVersion: json['model_version'] as String,
    );
  }
  
  /// Check if this was a significant correction (low confidence corrected)
  bool get isSignificantCorrection {
    return corrections.values.any((c) => c.originalConfidence < 0.7);
  }
  
  /// Count of fields corrected
  int get correctionCount => corrections.length;
}
