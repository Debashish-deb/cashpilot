import 'package:flutter/foundation.dart';

/// Barcode format type
enum BarcodeFormat {
  ean13,
  ean8,
  upca,
  upce,
  qrCode,
  code128,
  code39,
  dataMatrix,
  unknown,
}

/// Product information from barcode lookup
@immutable
class ProductInfo {
  final String name;
  final String? brand;
  final String? category;
  final double? suggestedPrice;
  final String? currency;
  final String? imageUrl;
  final String? description;

  const ProductInfo({
    required this.name,
    this.brand,
    this.category,
    this.suggestedPrice,
    this.currency,
    this.imageUrl,
    this.description,
  });

  factory ProductInfo.fromJson(Map<String, dynamic> json) => ProductInfo(
        name: json['name'] as String,
        brand: json['brand'] as String?,
        category: json['category'] as String?,
        suggestedPrice: (json['suggested_price'] as num?)?.toDouble(),
        currency: json['currency'] as String?,
        imageUrl: json['image_url'] as String?,
        description: json['description'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        if (brand != null) 'brand': brand,
        if (category != null) 'category': category,
        if (suggestedPrice != null) 'suggested_price': suggestedPrice,
        if (currency != null) 'currency': currency,
        if (imageUrl != null) 'image_url': imageUrl,
        if (description != null) 'description': description,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductInfo &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          brand == other.brand &&
          category == other.category &&
          suggestedPrice == other.suggestedPrice &&
          currency == other.currency &&
          imageUrl == other.imageUrl &&
          description == other.description;

  @override
  int get hashCode => Object.hash(
        name,
        brand,
        category,
        suggestedPrice,
        currency,
        imageUrl,
        description,
      );
}

/// Typed barcode extras - replaces Map<String, dynamic>
@immutable
class BarcodeExtras {
  final BarcodeFormat format;
  final int? checksum;
  final String? rawBytes;
  final Map<String, String>? additionalData;

  const BarcodeExtras({
    required this.format,
    this.checksum,
    this.rawBytes,
    this.additionalData,
  });

  factory BarcodeExtras.fromJson(Map<String, dynamic> json) {
    final additionalDataRaw = json['additional_data'];
    Map<String, String>? additionalData;
    if (additionalDataRaw != null) {
      additionalData = (additionalDataRaw as Map<String, dynamic>)
          .map((k, v) => MapEntry(k, v.toString()));
    }

    return BarcodeExtras(
      format: BarcodeFormat.values.byName(
        json['format'] as String? ?? 'unknown',
      ),
      checksum: json['checksum'] as int?,
      rawBytes: json['raw_bytes'] as String?,
      additionalData: additionalData,
    );
  }

  Map<String, dynamic> toJson() => {
        'format': format.name,
        if (checksum != null) 'checksum': checksum,
        if (rawBytes != null) 'raw_bytes': rawBytes,
        if (additionalData != null) 'additional_data': additionalData,
      };

  /// Create from legacy Map format for backward compatibility
  factory BarcodeExtras.fromLegacyMap(Map<String, dynamic> legacy) {
    return BarcodeExtras.fromJson(legacy);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BarcodeExtras &&
          runtimeType == other.runtimeType &&
          format == other.format &&
          checksum == other.checksum &&
          rawBytes == other.rawBytes &&
          mapEquals(additionalData, other.additionalData);

  @override
  int get hashCode => Object.hash(
        format,
        checksum,
        rawBytes,
        additionalData != null ? Object.hashAll(additionalData!.entries) : null,
      );
}

/// Typed barcode metadata - replaces Map<String, dynamic>
@immutable
class BarcodeMetadata {
  final String scanId;
  final DateTime scannedAt;
  final String modelVersion;
  final String source; // 'camera', 'image', 'manual'
  final double? scanQuality; // 0.0-1.0
  final int? processingTimeMs;
  final bool wasOffline;

  const BarcodeMetadata({
    required this.scanId,
    required this.scannedAt,
    required this.modelVersion,
    required this.source,
    this.scanQuality,
    this.processingTimeMs,
    this.wasOffline = false,
  });

  factory BarcodeMetadata.fromJson(Map<String, dynamic> json) =>
      BarcodeMetadata(
        scanId: json['scan_id'] as String,
        scannedAt: DateTime.parse(json['scanned_at'] as String),
        modelVersion: json['model_version'] as String? ?? 'unknown',
        source: json['source'] as String? ?? 'camera',
        scanQuality: (json['scan_quality'] as num?)?.toDouble(),
        processingTimeMs: json['processing_time_ms'] as int?,
        wasOffline: json['was_offline'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'scan_id': scanId,
        'scanned_at': scannedAt.toIso8601String(),
        'model_version': modelVersion,
        'source': source,
        if (scanQuality != null) 'scan_quality': scanQuality,
        if (processingTimeMs != null) 'processing_time_ms': processingTimeMs,
        'was_offline': wasOffline,
      };

  /// Create from legacy Map format for backward compatibility
  factory BarcodeMetadata.fromLegacyMap(Map<String, dynamic> legacy) {
    return BarcodeMetadata.fromJson(legacy);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BarcodeMetadata &&
          runtimeType == other.runtimeType &&
          scanId == other.scanId &&
          scannedAt == other.scannedAt &&
          modelVersion == other.modelVersion &&
          source == other.source &&
          scanQuality == other.scanQuality &&
          processingTimeMs == other.processingTimeMs &&
          wasOffline == other.wasOffline;

  @override
  int get hashCode => Object.hash(
        scanId,
        scannedAt,
        modelVersion,
        source,
        scanQuality,
        processingTimeMs,
        wasOffline,
      );

  @override
  String toString() => 'BarcodeMetadata('
      'id: $scanId, '
      'source: $source, '
      'offline: $wasOffline'
      ')';
}
