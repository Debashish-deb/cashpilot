import 'package:cashpilot/features/receipt/models/receipt_data.dart' show ReceiptData;
import 'dart:math';

/// ================================================================
/// CORE ENGINE
/// ================================================================

class ReceiptParser {
  ReceiptData parse(String raw) {
    final lines = _preprocess(raw);
    if (lines.length < 2) return const ReceiptData();

    double? total;
    double? subtotal;
    double? tax;
    DateTime? date;
    String? merchant;
    String? currency;

    final currencyRes = _detectCurrency(raw);
    currency = currencyRes.value;

    // ... Extraction logic ...
    final totalRes = _extractTotal(lines, currencyHint: currency);
    if (totalRes != null) total = totalRes.value;

    final dateRes = _extractDate(raw);
    if (dateRes != null) date = dateRes.value;

    final merchantRes = _extractMerchant(lines);
    if (merchantRes != null) merchant = merchantRes.value;

    if (total != null) {
      final subRes = _extractSubtotal(lines, total, currencyHint: currency);
      if (subRes != null) subtotal = subRes.value;

      final taxRes = _extractTax(lines, total, currencyHint: currency);
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

  ExtractionResult<double>? _extractTotal(List<String> lines, {String? currencyHint}) {
    final regex = _priceRegex();
    final candidates = <ExtractionResult<double>>[];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].toLowerCase();

      final keywordScore = _totalKeywordScore(line);
      if (keywordScore <= 0) continue;

      for (final m in regex.allMatches(lines[i])) {
        final price = _parsePrice(m.group(0)!, currencyHint: currencyHint);
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
    final lower = line.toLowerCase();
    if (lower.contains('subtotal') || lower.contains('sub total') || lower.contains('sub-total')) {
      return 0.0;
    }
    if (lower.contains('grand total') || lower.contains('total due') || lower.contains('amount due') || lower.contains('endbetrag')) {
      return 0.9;
    }
    const keywords = [
      'total',
      'gesamt',
      'amount',
      'summe',
      'balance',
      'due',
      'pay'
    ];

    return keywords.any(lower.contains) ? 0.5 : 0.0;
  }

  // ================================================================
  // SUBTOTAL & TAX
  // ================================================================

  ExtractionResult<double>? _extractSubtotal(List<String> lines, double total, {String? currencyHint}) {
    return _extractByKeyword(lines, total, ['subtotal', 'net'], currencyHint: currencyHint);
  }

  ExtractionResult<double>? _extractTax(List<String> lines, double total, {String? currencyHint}) {
    return _extractByKeyword(lines, total, ['tax', 'vat', 'mwst', 'iva'], currencyHint: currencyHint);
  }

  ExtractionResult<double>? _extractByKeyword(
      List<String> lines, double total, List<String> keys, {String? currencyHint}) {
    final regex = _priceRegex();

    for (final line in lines) {
      if (!keys.any(line.toLowerCase().contains)) continue;

      for (final m in regex.allMatches(line)) {
        final val = _parsePrice(m.group(0)!, currencyHint: currencyHint);
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

  static const _monthMap = {
    'jan': '01', 'january': '01',
    'feb': '02', 'february': '02',
    'mar': '03', 'march': '03',
    'apr': '04', 'april': '04',
    'may': '05',
    'jun': '06', 'june': '06',
    'jul': '07', 'july': '07',
    'aug': '08', 'august': '08',
    'sep': '09', 'sept': '09', 'september': '09',
    'oct': '10', 'october': '10',
    'nov': '11', 'november': '11',
    'dec': '12', 'december': '12',
  };

  String _normalizeMonth(String raw) {
    final lower = raw.trim().toLowerCase();
    return _monthMap[lower] ?? raw.padLeft(2, '0');
  }

  ExtractionResult<DateTime>? _extractDate(String text) {
    final patterns = [
      RegExp(r'(\d{4})[-/.](\d{2})[-/.](\d{2})'),
      RegExp(r'(\d{2})[-/.](\d{2})[-/.](\d{4})'),
      RegExp(r'(\d{1,2})\s+([A-Za-z]{3,9})\s+(\d{4})'),
      RegExp(r'([A-Za-z]{3,9})\s+(\d{1,2}),?\s+(\d{4})'),
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
      final g1 = m.group(1)!;
      final g2 = m.group(2)!;
      final g3 = m.group(3)!;
      
      // Pattern: YYYY-MM-DD
      if (g1.length == 4) {
        return "$g1-${_normalizeMonth(g2)}-${g3.padLeft(2, '0')}";
      }
      // Pattern: Month DD, YYYY (e.g. May 15, 2026)
      if (g3.length == 4 && _monthMap.containsKey(g1.toLowerCase())) {
        return "$g3-${_normalizeMonth(g1)}-${g2.padLeft(2, '0')}";
      }
      // Pattern: DD Month YYYY (e.g. 15 May 2026) or DD/MM/YYYY
      if (g3.length == 4) {
        return "$g3-${_normalizeMonth(g2)}-${g1.padLeft(2, '0')}";
      }
      return "$g1-$g2-$g3";
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
    final trimmed = line.trim();
    if (trimmed.length < 3 || trimmed.length > 50) return false;
    
    // Allow merchants with numbers (e.g. "7-Eleven", "Forever 21", "Bar 99")
    // but reject lines that are mostly numbers (like phone numbers, barcodes, tax IDs)
    final digits = RegExp(r'\d').allMatches(trimmed).length;
    if (digits > 4 || digits > trimmed.length / 2) return false;

    // Filter out common receipt header lines that aren't merchant names
    final lower = trimmed.toLowerCase();
    const blacklist = [
      'tax invoice', 'sales receipt', 'order receipt', 'customer receipt',
      'cash receipt', 'terminal', 'welcome', 'thank you',
      'thanks for visit', 'subtotal', 'total', 'tel:', 'phone:', 'fax:',
      'www.', '.com', 'http', 'pos transaction', 'duplicate'
    ];
    if (blacklist.any(lower.contains)) return false;

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
      r'([\$€£¥₹]?\s*\d{1,3}(?:[.,\s]\d{3})*(?:[.,]\d{1,2})?|[\$€£¥₹]?\s*\d+(?:[.,]\d{1,2})?)',
    );
  }

  double _parsePrice(String raw, {String? currencyHint}) {
    final clean = raw.replaceAll(RegExp(r'[^\d.,]'), '').trim();
    if (clean.isEmpty) return 0.0;

    final hasComma = clean.contains(',');
    final hasDot = clean.contains('.');

    if (hasComma && hasDot) {
      final lastComma = clean.lastIndexOf(',');
      final lastDot = clean.lastIndexOf('.');
      if (lastComma > lastDot) {
        // European format: 1.250,50 -> 1250.50
        final normalized = clean.replaceAll('.', '').replaceAll(',', '.');
        return double.tryParse(normalized) ?? 0.0;
      } else {
        // US/UK format: 1,250.50 -> 1250.50
        final normalized = clean.replaceAll(',', '');
        return double.tryParse(normalized) ?? 0.0;
      }
    } else if (hasComma) {
      final commaCount = ','.allMatches(clean).length;
      if (commaCount > 1) {
        return double.tryParse(clean.replaceAll(',', '')) ?? 0.0;
      }
      final parts = clean.split(',');
      if (parts.length == 2 && parts[1].length == 3 && (currencyHint == 'USD' || raw.contains('\$'))) {
        return double.tryParse(clean.replaceAll(',', '')) ?? 0.0;
      }
      // Comma as decimal separator: 12,50 -> 12.50
      return double.tryParse(clean.replaceAll(',', '.')) ?? 0.0;
    } else if (hasDot) {
      final dotCount = '.'.allMatches(clean).length;
      if (dotCount > 1) {
        // European thousand separators: 1.000.000
        return double.tryParse(clean.replaceAll('.', '')) ?? 0.0;
      }
      final parts = clean.split('.');
      if (parts.length == 2 && parts[1].length == 3 && (currencyHint == 'EUR' || raw.contains('€'))) {
        // European thousand separator: 1.250 € -> 1250
        return double.tryParse(clean.replaceAll('.', '')) ?? 0.0;
      }
      return double.tryParse(clean) ?? 0.0;
    }

    return double.tryParse(clean) ?? 0.0;
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
