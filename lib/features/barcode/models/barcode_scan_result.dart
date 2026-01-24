/// Barcode Scan Result Model
/// Enterprise-grade model for barcode + product intelligence
library;

import 'scan_metadata.dart';

/// Barcode format types
enum BarcodeFormat {
  qr,
  ean13,
  ean8,
  upc,
  upcA,
  upcE,
  code128,
  code39,
  code93,
  codabar,
  itf,
  pdf417,
  dataMatrix,
  aztec,
  unknown,
}

/// Product information from barcode lookup
class ProductInfo {
  final String? name;
  final String? brand;
  final String? category;
  final double? price;
  final String? currency;
  final String? imageUrl;
  final String? description;
  final double? originalPrice;
  final bool? inStock;
  final Map<String, dynamic>? extras;

  const ProductInfo({
    this.name,
    this.brand,
    this.category,
    this.price,
    this.currency,
    this.imageUrl,
    this.description,
    this.originalPrice,
    this.inStock,
    this.extras,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'brand': brand,
    'category': category,
    'price': price,
    'currency': currency,
    'imageUrl': imageUrl,
    'description': description,
    'originalPrice': originalPrice,
    'inStock': inStock,
    'extras': extras,
  };

  factory ProductInfo.fromJson(Map<String, dynamic> json) {
    return ProductInfo(
      name: json['name'] as String?,
      brand: json['brand'] as String?,
      category: json['category'] as String?,
      price: (json['price'] as num?)?.toDouble(),
      currency: json['currency'] as String?,
      imageUrl: json['imageUrl'] as String?,
      description: json['description'] as String?,
      originalPrice: (json['originalPrice'] as num?)?.toDouble(),
      inStock: json['inStock'] as bool?,
      extras: json['extras'] as Map<String, dynamic>?,
    );
  }

  ProductInfo copyWith({
    String? name,
    String? brand,
    String? category,
    double? price,
    String? currency,
    String? imageUrl,
    String? description,
    double? originalPrice,
    bool? inStock,
    Map<String, dynamic>? extras,
  }) {
    return ProductInfo(
      name: name ?? this.name,
      brand: brand ?? this.brand,
      category: category ?? this.category,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      originalPrice: originalPrice ?? this.originalPrice,
      inStock: inStock ?? this.inStock,
      extras: extras ?? this.extras,
    );
  }
}

/// Barcode scan result with product intelligence
class BarcodeScanResult {
  /// Raw scanned value (normalized if applicable)
  final String rawValue;

  /// Detected barcode format
  final BarcodeFormat format;

  /// Timestamp of scan
  final DateTime scannedAt;

  
  /// Typed scan metadata
  final ScanMetadata? scanMetadata;

  /// Whether barcode passed validation rules
  final bool isValid;

  /// Enriched product information (optional)
  final ProductInfo? productInfo;

  BarcodeScanResult({
    required this.rawValue,
    required this.format,
    DateTime? scannedAt,
    this.scanMetadata,
    this.isValid = true,
    this.productInfo,
  }) : scannedAt = scannedAt ?? DateTime.now();

  // ---------------------------------------------------------------------------
  // COPY
  // ---------------------------------------------------------------------------

  BarcodeScanResult copyWith({
    String? rawValue,
    BarcodeFormat? format,
    DateTime? scannedAt,
    ScanMetadata? scanMetadata,
    bool? isValid,
    ProductInfo? productInfo,
  }) {
    return BarcodeScanResult(
      rawValue: rawValue ?? this.rawValue,
      format: format ?? this.format,
      scannedAt: scannedAt ?? this.scannedAt,
      scanMetadata: scanMetadata ?? this.scanMetadata,
      isValid: isValid ?? this.isValid,
      productInfo: productInfo ?? this.productInfo,
    );
  }

  // ---------------------------------------------------------------------------
  // TYPE INTELLIGENCE
  // ---------------------------------------------------------------------------

  /// True if barcode is a retail product code
  bool get isProductBarcode =>
      format == BarcodeFormat.ean13 ||
      format == BarcodeFormat.ean8 ||
      format == BarcodeFormat.upc ||
      format == BarcodeFormat.upcA ||
      format == BarcodeFormat.upcE;

  /// True if QR code
  bool get isQRCode => format == BarcodeFormat.qr;

  /// True if barcode is 1D numeric retail code
  bool get isLinearRetailCode => isProductBarcode && rawValue.length >= 8;

  /// Try to parse QR as URL
  Uri? get asUrl => Uri.tryParse(rawValue);

  /// True if QR code contains a valid HTTP URL
  bool get isUrl =>
      isQRCode &&
      asUrl != null &&
      (asUrl!.scheme == 'http' || asUrl!.scheme == 'https');

  // ---------------------------------------------------------------------------
  // CONFIDENCE & QUALITY SIGNALS
  // ---------------------------------------------------------------------------

  /// Overall scan confidence (0–1)
  double get confidence {
    if (scanMetadata?.confidence != null) {
      return scanMetadata!.confidence.clamp(0.0, 1.0);
    }

    final extras = productInfo?.extras;
    if (extras != null && extras['confidence'] is num) {
      return (extras['confidence'] as num).toDouble().clamp(0.0, 1.0);
    }

    // Fallback heuristic
    if (!isValid) return 0.2;
    if (productInfo != null) return 0.85;
    return 0.6;
  }

  /// Whether UI should ask user to confirm this scan
  bool get needsUserConfirmation =>
      !isValid || confidence < 0.65 || productInfo == null;

  /// Whether result is safe for auto-fill
  bool get isAutoFillSafe =>
      isValid && confidence >= 0.8 && productInfo != null;

  // ---------------------------------------------------------------------------
  // GS1 / REGION INTELLIGENCE
  // ---------------------------------------------------------------------------

  /// GS1 inferred country / region (if available)
  String? get gs1Region => scanMetadata?.gs1Region;

  /// Confidence of GS1 inference (0–1)
  double? get gs1Confidence => scanMetadata?.gs1Confidence;

  /// Whether barcode region inference is reliable
  bool get hasReliableRegion =>
      gs1Region != null && (gs1Confidence ?? 0) >= 0.7;

  // ---------------------------------------------------------------------------
  // PRODUCT INTELLIGENCE
  // ---------------------------------------------------------------------------

  /// Whether product lookup succeeded
  bool get hasProductInfo => productInfo != null;

  /// Normalized display title for UI
  String get displayTitle {
    if (productInfo?.name != null) return productInfo!.name!;
    if (isProductBarcode) return 'Unknown product';
    if (isUrl) return asUrl!.host;
    return rawValue;
  }

  /// Suggested category (safe fallback)
  String get suggestedCategory =>
      productInfo?.category ?? 'Uncategorized';

  // ---------------------------------------------------------------------------
  // SERIALIZATION
  // ---------------------------------------------------------------------------

  Map<String, dynamic> toJson() => {
        'rawValue': rawValue,
        'format': format.name,
        'scannedAt': scannedAt.toIso8601String(),
        'scanMetadata': scanMetadata?.toJson(),
        'isValid': isValid,
        'productInfo': productInfo?.toJson(),
      };

  factory BarcodeScanResult.fromJson(Map<String, dynamic> json) {
    return BarcodeScanResult(
      rawValue: json['rawValue'] as String,
      format: BarcodeFormat.values.firstWhere(
        (f) => f.name == json['format'],
        orElse: () => BarcodeFormat.unknown,
      ),
      scannedAt: DateTime.tryParse(json['scannedAt'] as String? ?? '') ?? DateTime.now(),
      scanMetadata: json['scanMetadata'] != null 
          ? ScanMetadata.fromJson(json['scanMetadata'] as Map<String, dynamic>)
          : null,
      isValid: json['isValid'] as bool? ?? true,
      productInfo: json['productInfo'] != null
          ? ProductInfo.fromJson(json['productInfo'] as Map<String, dynamic>)
          : null,
    );
  }
}
