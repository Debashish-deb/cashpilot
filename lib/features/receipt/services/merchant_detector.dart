import 'dart:math' show min;

class MerchantDetectionResult {
  final String name;
  final double confidence;
  final String source;

  const MerchantDetectionResult({
    required this.name,
    required this.confidence,
    required this.source,
  });
}

class MerchantDetector {
  static const _blacklist = [
    'receipt',
    'invoice',
    'thank you',
    'welcome',
    'date',
    'total'
  ];

  static MerchantDetectionResult? detect(List<String> lines) {
    final candidates = <MerchantDetectionResult>[];

    for (int i = 0; i < min(5, lines.length); i++) {
      final line = _normalize(lines[i]);

      if (_isLikelyMerchant(line)) {
        final confidence = _score(line, i);
        candidates.add(MerchantDetectionResult(
          name: line,
          confidence: confidence,
          source: 'header',
        ));
      }
    }

    if (candidates.isEmpty) return null;

    candidates.sort((a, b) => b.confidence.compareTo(a.confidence));
    return candidates.first;
  }

  static String _normalize(String text) {
    return text
        .replaceAll(RegExp(r'\d'), '')
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static bool _isLikelyMerchant(String line) {
    if (line.length < 4 || line.length > 40) return false;
    if (_blacklist.any(line.toLowerCase().contains)) return false;
    return true;
  }

  static double _score(String name, int position) {
    double score = 0.6;
    score += (1 - position / 5) * 0.3;
    if (name == name.toUpperCase()) score += 0.1;
    return score.clamp(0, 1);
  }
}
