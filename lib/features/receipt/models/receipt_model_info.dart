/// Receipt Model Information - Versioning for extraction algorithms
/// Enables tracking and comparison of different ML model versions
library;

class ReceiptModelInfo {
  /// Current production model version
  static const String currentVersion = 'receipt_v1.0';
  
  /// Model build timestamp
  static final DateTime builtAt = DateTime(2026, 1, 1);
  
  final String version;
  final DateTime timestamp;
  
  const ReceiptModelInfo({
    this.version = currentVersion,
    required this.timestamp,
  });
  
  /// Serialize to JSON
  Map<String, dynamic> toJson() => {
    'version': version,
    'timestamp': timestamp.toIso8601String(),
  };
  
  /// Deserialize from JSON
  factory ReceiptModelInfo.fromJson(Map<String, dynamic> json) => ReceiptModelInfo(
    version: json['version'] as String? ?? currentVersion,
    timestamp: json['timestamp'] != null
        ? DateTime.parse(json['timestamp'] as String)
        : DateTime.now(),
  );
  
  @override
  String toString() => 'ReceiptModelInfo(version: $version, built: ${timestamp.toIso8601String()})';
}
