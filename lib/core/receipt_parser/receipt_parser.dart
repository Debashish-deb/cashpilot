import 'package:cashpilot/features/receipt/models/receipt_data.dart' show ReceiptData;
import 'dart:math';

/// ================================================================
/// CORE ENGINE
/// ================================================================

class ReceiptParser {
  ReceiptData parse(String raw) {
    final lines = _preprocess(raw);
    if (lines.length < 3) return const ReceiptData();

    double? total;
    double? subtotal;
    double? tax;
    DateTime? date;
    String? merchant;
    String? currency;

    // ... Extraction logic ...
    final totalRes = _extractTotal(lines);
    if (totalRes != null) total = totalRes.value;

    final dateRes = _extractDate(raw);
    if (dateRes != null) date = dateRes.value;

    final merchantRes = _extractMerchant(lines);
    if (merchantRes != null) merchant = merchantRes.value;

    final currencyRes = _detectCurrency(raw);
    currency = currencyRes.value;

    if (total != null) {
      final subRes = _extractSubtotal(lines, total);
      if (subRes != null) subtotal = subRes.value;

      final taxRes = _extractTax(lines, total);
      if (taxRes != null) tax = taxRes.value;
    }

    return ReceiptData(
      total: total,
      subtotal: subtotal,
      tax: tax,
      date: date,
      merchantName: merchant,
      currencyCode: currency,
    );
  }

  List<String> _preprocess(String text) => text
      .replaceAll(RegExp(r'\r\n|\r'), '\n')
      .split('\n')
      .map((e) => e.trim())
      .where((e) => e.length > 1)
      .toList();

  // ================================================================
  // TOTAL EXTRACTION
  // ================================================================

  ExtractionResult<double>? _extractTotal(List<String> lines) {
    final regex = _priceRegex();
    final candidates = <ExtractionResult<double>>[];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].toLowerCase();

      final keywordScore = _totalKeywordScore(line);
      if (keywordScore <= 0) continue;

      for (final m in regex.allMatches(lines[i])) {
        final price = _parsePrice(m.group(0)!);
        if (price <= 0) continue;

        double confidence = 0.4 + keywordScore;
        confidence += (i / lines.length) * 0.2;
        confidence += log(price + 1) / 20;

        candidates.add(
          ExtractionResult(price, confidence.clamp(0, 1), KeywordBasedStrategy),
        );
      }
    }

    if (candidates.isEmpty) return null;

    candidates.sort((a, b) => b.confidence.compareTo(a.confidence));
    return candidates.first;
  }

  double _totalKeywordScore(String line) {
    const keywords = [
      'total',
      'amount',
      'grand',
      'sum',
      'balance',
      'due',
      'pay'
    ];

    return keywords.any(line.contains) ? 0.5 : 0.0;
  }

  // ================================================================
  // SUBTOTAL & TAX
  // ================================================================

  ExtractionResult<double>? _extractSubtotal(List<String> lines, double total) {
    return _extractByKeyword(lines, total, ['subtotal', 'net']);
  }

  ExtractionResult<double>? _extractTax(List<String> lines, double total) {
    return _extractByKeyword(lines, total, ['tax', 'vat', 'mwst', 'iva']);
  }

  ExtractionResult<double>? _extractByKeyword(
      List<String> lines, double total, List<String> keys) {
    final regex = _priceRegex();

    for (final line in lines) {
      if (!keys.any(line.toLowerCase().contains)) continue;

      for (final m in regex.allMatches(line)) {
        final val = _parsePrice(m.group(0)!);
        if (val > 0 && val < total) {
          return ExtractionResult(val, 0.85, KeywordBasedStrategy);
        }
      }
    }
    return null;
  }

  // ================================================================
  // DATE EXTRACTION
  // ================================================================

  ExtractionResult<DateTime>? _extractDate(String text) {
    final patterns = [
      RegExp(r'(\d{4})[-/.](\d{2})[-/.](\d{2})'),
      RegExp(r'(\d{2})[-/.](\d{2})[-/.](\d{4})'),
      RegExp(r'(\d{2})\s([A-Za-z]{3,9})\s(\d{4})'),
    ];

    for (final p in patterns) {
      final m = p.firstMatch(text);
      if (m != null) {
        try {
          final d = DateTime.parse(_normalizeDate(m));
          return ExtractionResult(d, 0.85, ISODateStrategy);
        } catch (_) {}
      }
    }
    return null;
  }

  String _normalizeDate(RegExpMatch m) {
    if (m.groupCount == 3) {
      return "${m.group(1)}-${m.group(2)}-${m.group(3)}";
    }
    return "";
  }

  // ================================================================
  // MERCHANT EXTRACTION
  // ================================================================

  ExtractionResult<String>? _extractMerchant(List<String> lines) {
    for (int i = 0; i < min(4, lines.length); i++) {
      final l = lines[i];
      if (_looksLikeMerchant(l)) {
        return ExtractionResult(l, 0.9, HeaderBasedStrategy);
      }
    }
    return null;
  }

  bool _looksLikeMerchant(String line) {
    if (line.length < 4 || line.length > 50) return false;
    if (RegExp(r'\d').hasMatch(line)) return false;
    return true;
  }

  // ================================================================
  // CURRENCY DETECTION
  // ================================================================

  ExtractionResult<String> _detectCurrency(String text) {
    if (text.contains('€')) return ExtractionResult('EUR', 0.95, CurrencySymbolStrategy);
    if (text.contains('\$')) return ExtractionResult('USD', 0.95, CurrencySymbolStrategy);
    if (text.contains('£')) return ExtractionResult('GBP', 0.95, CurrencySymbolStrategy);
    return ExtractionResult('EUR', 0.3, FallbackStrategy);
  }

  // ================================================================
  // PRICE PARSING
  // ================================================================

  RegExp _priceRegex() {
    return RegExp(
        r'([\$€£¥₹]?\s*\d{1,3}(?:[.,]\d{3})*(?:[.,]\d{2})?)');
  }

  double _parsePrice(String raw) {
    raw = raw.replaceAll(RegExp(r'[^\d.,]'), '');
    if (raw.contains(',') && raw.contains('.')) {
      raw = raw.replaceAll(',', '');
    } else if (raw.contains(',')) {
      raw = raw.replaceAll(',', '.');
    }
    return double.tryParse(raw) ?? 0.0;
  }
}

/// ================================================================
/// STRATEGY SUPPORT CLASSES
/// ================================================================

class ExtractionResult<T> {
  final T value;
  final double confidence;
  final Type sourceStrategy;
  const ExtractionResult(this.value, this.confidence, this.sourceStrategy);
}

class KeywordBasedStrategy {}
class ISODateStrategy {}
class HeaderBasedStrategy {}
class CurrencySymbolStrategy {}
class FallbackStrategy {}
