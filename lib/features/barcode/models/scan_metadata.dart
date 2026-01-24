/// Barcode Scan Metadata - Typed replacement for `Map<String, dynamic>`
/// Stores ML-related metadata with proper typing
library;

class ScanMetadata {
  final double confidence;
  final String? gs1Region;
  final double gs1Confidence;
  final LookupMeta? lookup;
  final String modelVersion;
  final DateTime scannedAt;
  
  const ScanMetadata({
    required this.confidence,
    this.gs1Region,
    required this.gs1Confidence,
    this.lookup,
    required this.modelVersion,
    required this.scannedAt,
  });
  
  /// Serialize to JSON for database storage
  Map<String, dynamic> toJson() => {
    'confidence': confidence,
    if (gs1Region != null) 'gs1_region': gs1Region,
    'gs1_confidence': gs1Confidence,
    if (lookup != null) 'lookup': lookup!.toJson(),
    'model_version': modelVersion,
    'scanned_at': scannedAt.toIso8601String(),
  };
  
  /// Deserialize from JSON
  factory ScanMetadata.fromJson(Map<String, dynamic> json) => ScanMetadata(
    confidence: (json['confidence'] as num).toDouble(),
    gs1Region: json['gs1_region'] as String?,
    gs1Confidence: (json['gs1_confidence'] as num).toDouble(),
    lookup: json['lookup'] != null
        ? LookupMeta.fromJson(json['lookup'] as Map<String, dynamic>)
        : null,
    modelVersion: json['model_version'] as String,
    scannedAt: DateTime.parse(json['scanned_at'] as String),
  );
  
  @override
  String toString() => 'ScanMetadata(confidence: $confidence, gs1Region: $gs1Region)';
}

/// Product Lookup Metadata
class LookupMeta {
  final String source;  // 'openfoodfacts', 'cache', 'manual', 'none'
  final DateTime queriedAt;
  final bool wasSuccessful;
  final int? matchCount;
  final Duration? responseTime;
  
  const LookupMeta({
    required this.source,
    required this.queriedAt,
    required this.wasSuccessful,
    this.matchCount,
    this.responseTime,
  });
  
  Map<String,dynamic> toJson() => {
    'source': source,
    'queried_at': queriedAt.toIso8601String(),
    'was_successful': wasSuccessful,
    if (matchCount != null) 'match_count': matchCount,
    if (responseTime != null) 'response_time_ms': responseTime!.inMilliseconds,
  };
  
  factory LookupMeta.fromJson(Map<String, dynamic> json) => LookupMeta(
    source: json['source'] as String,
    queriedAt: DateTime.parse(json['queried_at'] as String),
    wasSuccessful: json['was_successful'] as bool,
    matchCount: json['match_count'] as int?,
    responseTime: json['response_time_ms'] != null
        ? Duration(milliseconds: json['response_time_ms'] as int)
        : null,
  );
}

/// Barcode Model Information - Version tracking
class BarcodeModelInfo {
  static const String currentVersion = 'barcode_v1.0';
  static final DateTime builtAt = DateTime(2026, 1, 1);
  
  final String version;
  final DateTime timestamp;
  
  const BarcodeModelInfo({
    this.version = currentVersion,
    required this.timestamp,
  });
  
  Map<String, dynamic> toJson() => {
    'version': version,
    'timestamp': timestamp.toIso8601String(),
  };
  
  factory BarcodeModelInfo.fromJson(Map<String, dynamic> json) => BarcodeModelInfo(
    version: json['version'] as String? ?? currentVersion,
    timestamp: json['timestamp'] != null
        ? DateTime.parse(json['timestamp'] as String)
        : DateTime.now(),
  );
}
