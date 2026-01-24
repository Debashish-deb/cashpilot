/// Barcode Scan Outcome Tracking - Captures user feedback for ML learning
library;

import '../models/barcode_scan_result.dart' show ProductInfo;

/// Outcome of a barcode scan from user perspective
enum ScanOutcome {
  /// User used the scanned product without changes
  accepted,
  
  /// User corrected product information
  corrected,
  
  /// User rescanned or abandoned the scan
  rejected,
}

extension ScanOutcomeExtensions on ScanOutcome {
  String get displayName {
    switch (this) {
      case ScanOutcome.accepted:
        return 'Accepted';
      case ScanOutcome.corrected:
        return 'Corrected';
      case ScanOutcome.rejected:
        return 'Rejected';
    }
  }
  
  String toJson() => name;
  
  static ScanOutcome fromJson(String json) {
    return ScanOutcome.values.firstWhere(
      (e) => e.name == json,
      orElse: () => ScanOutcome.rejected,
    );
  }
}

/// Learning event for barcode scans
class ScanLearningEvent {
  final String barcode;
  final double confidence;
  final ScanOutcome outcome;
  final ProductInfo? correctedProduct;  // If user edited product info
  final DateTime timestamp;
  final String modelVersion;
  
  const ScanLearningEvent({
    required this.barcode,
    required this.confidence,
    required this.outcome,
    this.correctedProduct,
    required this.timestamp,
    required this.modelVersion,
  });
  
  Map<String, dynamic> toJson() => {
    'barcode': barcode,
    'confidence': confidence,
    'outcome': outcome.toJson(),
    if (correctedProduct != null) 'corrected_product': correctedProduct!.toJson(),
    'timestamp': timestamp.toIso8601String(),
    'model_version': modelVersion,
  };
  
  factory ScanLearningEvent.fromJson(Map<String, dynamic> json) {
    return ScanLearningEvent(
      barcode: json['barcode'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      outcome: ScanOutcomeExtensions.fromJson(json['outcome'] as String),
      correctedProduct: json['corrected_product'] != null
          ? ProductInfo.fromJson(json['corrected_product'] as Map<String, dynamic>)
          : null,
      timestamp: DateTime.parse(json['timestamp'] as String),
      modelVersion: json['model_version'] as String,
    );
  }
}
