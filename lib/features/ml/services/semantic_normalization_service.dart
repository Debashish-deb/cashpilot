import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'semantic_normalization_service.g.dart';

@Riverpod(keepAlive: true)
SemanticNormalizationService semanticNormalizationService(SemanticNormalizationServiceRef ref) {
  return SemanticNormalizationService();
}

/// unified/SemanticNormalizationService
/// 
/// Responsible for transforming raw inputs (OCR text, user input, barcode titles)
/// into a standard "semantic token" format for the ML engine.
class SemanticNormalizationService {
  
  // Common noise words in receipts and product names
  static const _stopWords = {
    'the', 'a', 'an', 'and', 'or', 'of', 'for', 'in', 'on', 'at', 'to', 'by',
    'total', 'subtotal', 'price', 'amount', 'qty', 'quantity', 'item', 'items',
    'tax', 'vat', 'gst', 'card', 'cash', 'change', 'due', 'date', 'time',
    'market', 'supermarket', 'store', 'shop', 'mart', 'inc', 'ltd', 'pty',
    'reg', 'pos', 'terminal', 'receipt', 'invoice', 'copy', 'merchant',
    '0g', '1g', 'kg', 'g', 'ml', 'l', 'lb', 'oz', 'pc', 'pcs', // units might be useful, but often noise for category
  };

  /// Main entry point: converts raw text to weighted semantic tokens
  List<String> normalize(String rawInput) {
    if (rawInput.trim().isEmpty) return [];

    // 1. Lowercase and basic cleanup
    String processed = rawInput.toLowerCase().trim();

    // 2. Remove special characters (keep localized characters if possible, but strip symbols)
    // allowing alphanumeric and international characters
    processed = processed.replaceAll(RegExp(r'[^\w\s\u00C0-\u017F]+'), ' ');

    // 3. Remove digits that are likely prices or codes (e.g. "12.99", "4001")
    // Note: We might want to keep some numbers like "7up" or "v8", but standalone numbers are usually noise
    // Strategy: Remove tokens that are purely numeric
    
    // 4. Tokenize by whitespace
    final tokens = processed.split(RegExp(r'\s+'));

    // 5. Filter tokens
    final validTokens = <String>[];
    for (var token in tokens) {
      // Skip empty
      if (token.isEmpty) continue;
      
      // Skip purely numeric (dates, prices, ids)
      if (RegExp(r'^\d+$').hasMatch(token)) continue;
      
      // Skip short nonsense (unless specific)
      if (token.length < 2) continue;

      // Skip stop words
      if (_stopWords.contains(token)) continue;

      // Stemming could happen here (e.g. apples -> apple), 
      // but for now strict matching is safer for "Expert" accuracy.
      
      validTokens.add(token);
    }

    // 6. Deduplicate preserving order
    return validTokens.toSet().toList();
  }
}
