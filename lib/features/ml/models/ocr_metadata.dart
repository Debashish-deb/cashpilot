import 'package:flutter/foundation.dart';

/// Text orientation detected in OCR
enum TextOrientation {
  portrait,
  landscape,
  upsideDown,
  landscapeReversed,
}

/// Bounding box for text regions
@immutable
class BoundingBox {
  final double x;
  final double y;
  final double width;
  final double height;

  const BoundingBox({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  factory BoundingBox.fromJson(Map<String, dynamic> json) => BoundingBox(
        x: (json['x'] as num).toDouble(),
        y: (json['y'] as num).toDouble(),
        width: (json['width'] as num).toDouble(),
        height: (json['height'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'x': x,
        'y': y,
        'width': width,
        'height': height,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BoundingBox &&
          runtimeType == other.runtimeType &&
          x == other.x &&
          y == other.y &&
          width == other.width &&
          height == other.height;

  @override
  int get hashCode => Object.hash(x, y, width, height);
}

/// Individual text block detected by OCR
@immutable
class TextBlock {
  final String text;
  final double confidence;
  final BoundingBox? bounds;
  final int? blockIndex;

  const TextBlock({
    required this.text,
    required this.confidence,
    this.bounds,
    this.blockIndex,
  });

  factory TextBlock.fromJson(Map<String, dynamic> json) => TextBlock(
        text: json['text'] as String,
        confidence: (json['confidence'] as num).toDouble(),
        bounds: json['bounds'] != null
            ? BoundingBox.fromJson(json['bounds'] as Map<String, dynamic>)
            : null,
        blockIndex: json['block_index'] as int?,
      );

  Map<String, dynamic> toJson() => {
        'text': text,
        'confidence': confidence,
        if (bounds != null) 'bounds': bounds!.toJson(),
        if (blockIndex != null) 'block_index': blockIndex,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TextBlock &&
          runtimeType == other.runtimeType &&
          text == other.text &&
          confidence == other.confidence &&
          bounds == other.bounds &&
          blockIndex == other.blockIndex;

  @override
  int get hashCode => Object.hash(text, confidence, bounds, blockIndex);
}

/// Typed OCR metadata - replaces Map<String, dynamic>
/// This provides compile-time safety and enables ML training
@immutable
class OcrMetadata {
  final String modelVersion;
  final DateTime scannedAt;
  final int processingTimeMs;
  final TextOrientation? orientation;
  final List<TextBlock> blocks;
  final int totalCharacters;
  final double averageConfidence;

  const OcrMetadata({
    required this.modelVersion,
    required this.scannedAt,
    required this.processingTimeMs,
    this.orientation,
    required this.blocks,
    required this.totalCharacters,
    required this.averageConfidence,
  });

  factory OcrMetadata.fromJson(Map<String, dynamic> json) {
    final blocks = (json['blocks'] as List?)
            ?.map((b) => TextBlock.fromJson(b as Map<String, dynamic>))
            .toList() ??
        [];

    return OcrMetadata(
      modelVersion: json['model_version'] as String? ?? 'unknown',
      scannedAt: json['scanned_at'] != null
          ? DateTime.parse(json['scanned_at'] as String)
          : DateTime.now(),
      processingTimeMs: json['processing_time_ms'] as int? ?? 0,
      orientation: json['orientation'] != null
          ? TextOrientation.values.byName(json['orientation'] as String)
          : null,
      blocks: blocks,
      totalCharacters: json['total_characters'] as int? ?? 0,
      averageConfidence: (json['average_confidence'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'model_version': modelVersion,
        'scanned_at': scannedAt.toIso8601String(),
        'processing_time_ms': processingTimeMs,
        if (orientation != null) 'orientation': orientation!.name,
        'blocks': blocks.map((b) => b.toJson()).toList(),
        'total_characters': totalCharacters,
        'average_confidence': averageConfidence,
      };

  /// Create from legacy Map format for backward compatibility
  factory OcrMetadata.fromLegacyMap(Map<String, dynamic> legacy) {
    return OcrMetadata.fromJson(legacy);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OcrMetadata &&
          runtimeType == other.runtimeType &&
          modelVersion == other.modelVersion &&
          scannedAt == other.scannedAt &&
          processingTimeMs == other.processingTimeMs &&
          orientation == other.orientation &&
          listEquals(blocks, other.blocks) &&
          totalCharacters == other.totalCharacters &&
          averageConfidence == other.averageConfidence;

  @override
  int get hashCode => Object.hash(
        modelVersion,
        scannedAt,
        processingTimeMs,
        orientation,
        Object.hashAll(blocks),
        totalCharacters,
        averageConfidence,
      );

  @override
  String toString() => 'OcrMetadata('
      'model: $modelVersion, '
      'blocks: ${blocks.length}, '
      'confidence: ${(averageConfidence * 100).toStringAsFixed(1)}%'
      ')';
}
