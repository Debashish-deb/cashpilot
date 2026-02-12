import 'dart:math';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../models/receipt_data.dart';

class DuplicateDetectionResult {
  final bool isDuplicate;
  final double confidence;
  final String reason;
  final String? matchedReceiptId;

  const DuplicateDetectionResult({
    required this.isDuplicate,
    required this.confidence,
    required this.reason,
    this.matchedReceiptId,
  });
}

class DuplicateDetector {
  /// Compute full receipt fingerprint
  static String computeFingerprint({
    required String imageHash,
    required String ocrText,
    required double? total,
    required String? merchant,
  }) {
    final payload = '$imageHash|${ocrText.substring(0, min(200, ocrText.length))}|$total|$merchant';
    return sha256.convert(utf8.encode(payload)).toString();
  }

  /// Industrial duplicate detection
  static DuplicateDetectionResult detect({
    required ReceiptData current,
    required List<ReceiptData> history,
  }) {
    double bestScore = 0;
    ReceiptData? bestMatch;

    for (final prev in history) {
      final score = _compareReceipts(current, prev);
      if (score > bestScore) {
        bestScore = score;
        bestMatch = prev;
      }
    }

    if (bestScore > 0.92) {
      return DuplicateDetectionResult(
        isDuplicate: true,
        confidence: bestScore,
        reason: 'Strong fingerprint + semantic match',
        matchedReceiptId: bestMatch?.merchantName,
      );
    }

    if (bestScore > 0.80) {
      return DuplicateDetectionResult(
        isDuplicate: true,
        confidence: bestScore,
        reason: 'High semantic similarity',
      );
    }

    return const DuplicateDetectionResult(
      isDuplicate: false,
      confidence: 0,
      reason: 'No duplicate pattern detected',
    );
  }

  static double _compareReceipts(ReceiptData a, ReceiptData b) {
    double score = 0;

    if (a.total != null && b.total != null) {
      score += _similarity(a.total!, b.total!) * 0.35;
    }

    if (a.merchantName != null && b.merchantName != null) {
      score += _stringSim(a.merchantName!, b.merchantName!) * 0.35;
    }

    if (a.date != null && b.date != null) {
      final diff = a.date!.difference(b.date!).abs().inMinutes;
      score += (1 - min(diff / 1440, 1)) * 0.2;
    }

    return score.clamp(0, 1);
  }

  static double _similarity(double a, double b) {
    return 1 - (a - b).abs() / max(a, b);
  }

  static double _stringSim(String a, String b) {
    a = a.toLowerCase();
    b = b.toLowerCase();
    final maxLen = max(a.length, b.length);
    int matches = 0;
    for (int i = 0; i < min(a.length, b.length); i++) {
      if (a[i] == b[i]) matches++;
    }
    return matches / maxLen;
  }
}
