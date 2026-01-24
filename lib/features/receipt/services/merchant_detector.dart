/// Merchant Detector - Multi-candidate scoring for accurate merchant extraction
/// Replaces naive "take first 2 lines" approach with intelligent scoring
library;

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Merchant name candidate with confidence score
class MerchantCandidate {
  final String text;
  final double score;
  final int lineNumber;
  final bool isAllCaps;
  final bool hasAddress;
  final bool hasPhone;
  final bool hasUrl;
  
  const MerchantCandidate({
    required this.text,
    required this.score,
    required this.lineNumber,
    this.isAllCaps = false,
    this.hasAddress = false,
    this.hasPhone = false,
    this.hasUrl = false,
  });
  
  @override
  String toString() => 'MerchantCandidate($text, score: ${score.toStringAsFixed(2)})';
}

/// Intelligent merchant name detector
class MerchantDetector {
  /// Known merchant cache for faster recognition
  static final Set<String> _knownMerchants = {
    // Groceries
    'LIDL', 'ALDI', 'CARREFOUR', 'WALMART', 'TESCO', 'ICA', 'COOP',
    'K-MARKET', 'S-MARKET', 'PRISMA', 'ALEPA', 'SALE',
    // Restaurants
    'MCDONALDS', 'BURGER KING', 'SUBWAY', 'KFC', 'PIZZA HUT',
    'STARBUCKS', 'COSTA COFFEE', 'NANDOS',
    // Transport
    'SHELL', 'BP', 'ESSO', 'NESTE', 'ABC',
    // Retail
    'IKEA', 'H&M', 'ZARA', 'NIKE', 'ADIDAS',
  };
  
  /// Extract merchant candidates from OCR text
  static List<MerchantCandidate> extractCandidates(RecognizedText text) {
    final candidates = <MerchantCandidate>[];
    
    // Process first 5 lines (merchant usually in header)
    int lineNum = 0;
    for (final block in text.blocks.take(3)) {
      for (final line in block.lines.take(2)) {
        final lineText = line.text.trim();
        if (lineText.isEmpty || lineText.length < 2) continue;
        
        final score = _scoreMerchantCandidate(lineText, lineNum);
        
        // Only consider candidates with reasonable scores
        if (score > 0.1) {
          candidates.add(MerchantCandidate(
            text: _cleanMerchantName(lineText),
            score: score,
            lineNumber: lineNum,
            isAllCaps: _isAllCaps(lineText),
            hasAddress: _looksLikeAddress(lineText),
            hasPhone: _looksLikePhone(lineText),
            hasUrl: _looksLikeUrl(lineText),
          ));
        }
        
        lineNum++;
        if (lineNum >= 5) break;
      }
      if (lineNum >= 5) break;
    }
    
    // Sort by score descending
    candidates.sort((a, b) => b.score.compareTo(a.score));
    
    return candidates;
  }
  
  /// Get best merchant candidate
  static String? getBestMerchant(RecognizedText text) {
    final candidates = extractCandidates(text);
    return candidates.isNotEmpty ? candidates.first.text : null;
  }
  
  /// Score a potential merchant line
  static double _scoreMerchantCandidate(String line, int lineNumber) {
    double score = 0.0;
    
    // Position matters - first lines more likely
    if (lineNumber == 0) {
      score += 0.40;
    } else if (lineNumber == 1) {
      score += 0.25;
    } else if (lineNumber == 2) {
      score += 0.15;
    } else {
      score += 0.05;
    }
    
    // All caps suggests merchant name
    if (_isAllCaps(line)) score += 0.20;
    
    // Known merchant - strong signal
    final upperLine = line.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9&\s]'), '');
    if (_knownMerchants.any((m) => upperLine.contains(m))) {
      score += 0.30;
    }
    
    // Penalties for non-merchant patterns
    if (_looksLikeAddress(line)) score -= 0.25;
    if (_looksLikePhone(line)) score -= 0.30;
    if (_looksLikeUrl(line)) score -= 0.30;
    if (_looksLikeDate(line)) score -= 0.35;
    if (_looksLikeVatNumber(line)) score -= 0.35;
    if (_looksLikeNumber(line)) score -= 0.20;
    
    // Length heuristics
    if (line.length < 3) score -= 0.30;  // Too short
    if (line.length > 40) score -= 0.15;  // Too long
    
    // Has letters (not just numbers)
    if (RegExp(r'[A-Za-z]').hasMatch(line)) score += 0.10;
    
    return score.clamp(0.0, 1.0);
  }
  
  /// Clean merchant name
  static String _cleanMerchantName(String text) {
    // Remove common noise
    String cleaned = text
        .replaceAll(RegExp(r'[*#]{2,}'), '')  // Remove decorations
        .replaceAll(RegExp(r'^[^\w]+|[^\w]+$'), '')  // Trim non-word chars
        .trim();
    
    // Capitalize properly if all caps and short
    if (_isAllCaps(cleaned) && cleaned.length <= 15) {
      return cleaned
          .split(' ')
          .map((w) => w.isEmpty ? '' : '${w[0]}${w.substring(1).toLowerCase()}')
          .join(' ');
    }
    
    return cleaned;
  }
  
  static bool _isAllCaps(String text) {
    final letters = text.replaceAll(RegExp(r'[^A-Za-z]'), '');
    if (letters.isEmpty) return false;
    return letters == letters.toUpperCase();
  }
  
  static bool _looksLikeAddress(String text) {
    final lower = text.toLowerCase();
    return RegExp(r'\d+\s+(street|st|road|rd|avenue|ave|lane|ln|drive|dr|way|blvd|boulevard)', 
        caseSensitive: false).hasMatch(text) ||
        lower.contains('p.o. box') ||
        lower.contains('po box');
  }
  
  static bool _looksLikePhone(String text) {
    // Phone numbers have many digits with minimal letters
    final digits = text.replaceAll(RegExp(r'[^0-9]'), '');
    return digits.length >= 8 && digits.length <= 15;
  }
  
  static bool _looksLikeUrl(String text) {
    final lower = text.toLowerCase();
    return lower.contains('www.') || 
           lower.contains('.com') || 
           lower.contains('.net') ||
           lower.contains('http');
  }
  
  static bool _looksLikeDate(String text) {
    return RegExp(r'\d{1,2}[./-]\d{1,2}[./-]\d{2,4}').hasMatch(text) ||
           RegExp(r'\d{4}[./-]\d{1,2}[./-]\d{1,2}').hasMatch(text);
  }
  
  static bool _looksLikeVatNumber(String text) {
    final upper = text.toUpperCase();
    return upper.contains('VAT') && text.replaceAll(RegExp(r'[^0-9]'), '').length >= 8;
  }
  
  static bool _looksLikeNumber(String text) {
    final cleaned = text.replaceAll(RegExp(r'[^0-9]'), '');
    return cleaned.length >= 6;  // Mostly numbers
  }
  
  /// Remember confirmed merchant for future scans
  static void rememberMerchant(String merchant) {
    final cleaned = merchant.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9&\s]'), '').trim();
    if (cleaned.isNotEmpty) {
      _knownMerchants.add(cleaned);
    }
  }
}
