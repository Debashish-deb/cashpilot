/// Receipt Scanner Service
/// Accuracy-first offline extraction with:
/// - Hybrid merchant classifier (rule + fuzzy)
/// - Category suggestion (merchant + keyword)
/// - Confidence-driven prompt hints
/// - Subscription gating + scan limits (using CashPilot tiers)
library;

import 'dart:io';
import 'package:drift/drift.dart' show Variable;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/providers/app_providers.dart';

import '../core/constants/subscription.dart';
import '../features/receipt/models/receipt_extraction_meta.dart';
import '../features/receipt/models/receipt_field_meta.dart';
import '../features/receipt/models/receipt_model_info.dart';
import '../features/receipt/services/merchant_detector.dart';
import '../features/receipt/services/duplicate_detector.dart';
import '../data/drift/app_database.dart';

/// Provider for receipt scanner
final receiptScannerProvider = Provider((ref) {
  final database = ref.watch(databaseProvider);
  return AdvancedReceiptScanner(
    database: database,
    enableDebug: kDebugMode,
  );
});

/// Advanced Receipt Scanner with ML Kit OCR
class AdvancedReceiptScanner {
  final TextRecognizer _textRecognizer =
      TextRecognizer(script: TextRecognitionScript.latin);
  final ImagePicker _picker = ImagePicker();
  final AppDatabase database;
  final bool enableDebug;

  AdvancedReceiptScanner({
    required this.database,
    this.enableDebug = false,
  });

  // ================================
  // PUBLIC API (gated by subscription)
  // ================================

  /// Scan receipt from camera
  /// Returns null if user cancels, ReceiptScanResult.gated if not allowed
  Future<ReceiptScanResult?> scanFromCamera({
    required SubscriptionTier tier,
    bool isFamilyMemberOfProPlus = false,
  }) async {
    // Check subscription access
    final gateResult = await _checkScanAccess(tier, isFamilyMemberOfProPlus);
    if (gateResult != null) return gateResult;

    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image == null) return null;

    final result = await _processImage(File(image.path));
    await _consumeScanQuota(tier);
    return result;
  }

  /// Scan receipt from gallery
  Future<ReceiptScanResult?> scanFromGallery({
    required SubscriptionTier tier,
    bool isFamilyMemberOfProPlus = false,
  }) async {
    // Check subscription access
    final gateResult = await _checkScanAccess(tier, isFamilyMemberOfProPlus);
    if (gateResult != null) return gateResult;

    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return null;

    final result = await _processImage(File(image.path));
    await _consumeScanQuota(tier);
    return result;
  }

  /// Get remaining scans for the current month
  Future<int> getRemainingScans(SubscriptionTier tier) async {
    final limit = SubscriptionManager.ocrScansPerMonth(tier);
    if (limit == -1) return -1; // Unlimited

    final prefs = await SharedPreferences.getInstance();
    final monthKey = _monthKey();
    final used = prefs.getInt('ocr_used_$monthKey') ?? 0;
    return (limit - used).clamp(0, limit);
  }

  // ================================
  // SUBSCRIPTION GATING (CashPilot tiers)
  // ================================

  /// Check if user can scan based on subscription
  /// Returns ReceiptScanResult.gated if blocked, null if allowed
  Future<ReceiptScanResult?> _checkScanAccess(
    SubscriptionTier tier,
    bool isFamilyMemberOfProPlus,
  ) async {
    // Free tier: No OCR access
    if (tier == SubscriptionTier.free) {
      return ReceiptScanResult.gated(
        reason: 'OCR scanning requires Pro or Pro Plus subscription.',
      );
    }

    // Check feature access
    if (!SubscriptionManager.canUseOCR(tier)) {
      return ReceiptScanResult.gated(
        reason: 'OCR scanning is not available on your plan.',
      );
    }

    if (!SubscriptionManager.canUseReceiptScanning(tier)) {
      return ReceiptScanResult.gated(
        reason: 'Receipt scanning is not available on your plan.',
      );
    }

    // Check quota for Pro tier (10 scans/month limit)
    if (tier == SubscriptionTier.pro) {
      final remaining = await getRemainingScans(tier);
      if (remaining <= 0) {
        return ReceiptScanResult.gated(
          reason: 'Monthly scan limit reached (10/month). '
              'Upgrade to Pro Plus for unlimited scans.',
        );
      }
    }

    // Pro Plus: Unlimited, no gate
    return null;
  }

  /// Consume one scan from the monthly quota
  Future<void> _consumeScanQuota(SubscriptionTier tier) async {
    final limit = SubscriptionManager.ocrScansPerMonth(tier);
    if (limit == -1) return; // Unlimited (Pro Plus)

    final prefs = await SharedPreferences.getInstance();
    final monthKey = _monthKey();
    final used = prefs.getInt('ocr_used_$monthKey') ?? 0;
    await prefs.setInt('ocr_used_$monthKey', used + 1);
  }

  String _monthKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  // ================================
  // IMAGE PROCESSING
  // ================================

  Future<ReceiptScanResult> _processImage(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final recognizedText = await _textRecognizer.processImage(inputImage);

    return await _parseReceipt(recognizedText);
  }

  // ================================
  // RECEIPT PARSING
  // ================================

  // Token sets (multi-language support)
  static const _totalTokens = [
    // EN
    'TOTAL', 'GRAND TOTAL', 'AMOUNT', 'AMOUNT DUE', 'PAYABLE', 'BALANCE', 'VALUE',
    // FI
    'YHTEENSÄ', 'SUMMA', 'MAKSETTAVA', 'KOKONAISSUMMA',
    // SV
    'TOTALT', 'ATT BETALA', 'SUMMA',
    // DE
    'GESAMT', 'SUMME', 'BETRAG', 'ZU ZAHLEN',
    // BN
    'মোট', 'সর্বমোট', 'টোটাল', 'পরিশোধ', 'দাম', 'টাকা'
  ];

  static const _subtotalTokens = [
    'SUBTOTAL', 'SUB TOTAL',
    'VÄLISUMMA', 'VÄLISUM',
    'DELSUMMA',
    'ZWISCHENSUMME',
    'সাবটোটাল'
  ];

  static const _vatTokens = [
    'VAT', 'TAX', 'ALV', 'MOMS', 'MWST', 'IVA',
    'ভ্যাট', 'কর'
  ];

  Future<ReceiptScanResult> _parseReceipt(RecognizedText recognizedText) async {
    final rawText = recognizedText.text;

    final lines = rawText
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    // Extract merchant from header (using intelligent detector)
    final merchantName = MerchantDetector.getBestMerchant(recognizedText);

    // Amount fields (token-aware, best-score selection)
    final total = _extractMoneyField(lines, _totalTokens, fieldName: 'total');
    final subtotal = _extractMoneyField(lines, _subtotalTokens, fieldName: 'subtotal');
    final vat = _extractMoneyField(lines, _vatTokens, fieldName: 'vat');

    // Date (multi-format)
    final date = _extractDate(lines);

    // Currency
    final currency = _detectCurrency(lines);

    // Category suggestion based on merchant
    final suggestedCategory = _suggestCategory(merchantName, lines);

    // Confidence scoring
    final conf = ReceiptConfidence(
      total: total.confidence,
      subtotal: subtotal.confidence,
      vat: vat.confidence,
      date: date.confidence,
      merchant: merchantName != null ? 0.75 : 0.0,
      category: suggestedCategory != null ? 0.70 : 0.0,
    );

    // Create typed extraction metadata
    final extractionMeta = ReceiptExtractionMeta(
      total: total.value > 0 
          ? ReceiptFieldMeta(
              value: total.value,
              confidence: total.confidence,
              evidenceLine: total.evidenceLine,
            )
          : null,
      subtotal: subtotal.value > 0
          ? ReceiptFieldMeta(
              value: subtotal.value,
              confidence: subtotal.confidence,
              evidenceLine: subtotal.evidenceLine,
            )
          : null,
      tax: vat.value > 0
          ? ReceiptFieldMeta(
              value: vat.value,
              confidence: vat.confidence,
              evidenceLine: vat.evidenceLine,
            )
          : null,
      merchant: merchantName != null
          ? ReceiptStringFieldMeta(
              value: merchantName,
              confidence: 0.75,
            )
          : null,
      date: date.value != null
          ? ReceiptStringFieldMeta(
              value: date.value!.toIso8601String(),
              confidence: date.confidence,
            )
          : null,
      currency: currency != 'EUR'
          ? ReceiptStringFieldMeta(
              value: currency,
              confidence: 0.90,
            )
          : null,
      modelVersion: ReceiptModelInfo.currentVersion,
      extractedAt: DateTime.now(),
    );

    // Check for duplicates using database
    String? duplicateWarning;
    try {
      final cutoff = DateTime.now().subtract(const Duration(days: 7));
      
      // Query recent expenses using custom SQL for date comparison
      final recentExpenses = await database.customSelect(
        'SELECT * FROM expenses WHERE date >= ? ORDER BY date DESC LIMIT 100',
        variables: [Variable.withDateTime(cutoff)],
        readsFrom: {database.expenses},
      ).map((row) => database.expenses.map(row as Map<String, dynamic>)).get();
      
      final result = await DuplicateDetector.checkDuplicate(
        getRecentExpenses: () async {
          // Convert to Map format expected by DuplicateDetector
          return recentExpenses.map((exp) => {
            'id': exp.id,
            'merchant_name': exp.merchantName,
            'amount': exp.amount,
            'expense_date': exp.date.toIso8601String(),
            'currency_code': exp.currency,
            'category_key': exp.categoryId,
            'budget_id': exp.budgetId,
          }).toList();
        },
        merchant: merchantName,
        total: total.value,
        date: date.value ?? DateTime.now(),
        currency: currency,
      );
      
      if (result.isDuplicate) {
        duplicateWarning = result.reason;
        if (enableDebug) {
          debugPrint('[Scanner] ⚠️ Duplicate: ${result.reason}');
        }
      }
    } catch (e) {
      if (enableDebug) {
        debugPrint('[Scanner] Duplicate check failed: $e');
      }
      // Non-fatal: continue without duplicate warning
    }

    return ReceiptScanResult(
      rawText: rawText,
      overallConfidence: conf.overall,
      extractedAmount: total.value > 0 ? (total.value * 100).round() : null,
      extractedSubtotal: subtotal.value > 0 ? (subtotal.value * 100).round() : null,
      extractedVat: vat.value > 0 ? (vat.value * 100).round() : null,
      merchantName: merchantName,
      transactionDate: date.value,
      suggestedCategoryKey: suggestedCategory,
      currencyCode: currency,
      lineItems: const [],
      confidence: conf,
      flags: ReceiptFlags(
        isDuplicateLikely: duplicateWarning != null,  // Use actual duplicate detection
        needsUserReview: conf.needsUserReview,
      ),
      extraction: extractionMeta,
      duplicateWarning: duplicateWarning,
    );
  }

  /// Extract merchant name from receipt header
  String? _extractMerchant(RecognizedText text) {
    if (text.blocks.isEmpty) return null;

    // Usually first 1-2 lines contain merchant name
    final headerLines = <String>[];
    for (final block in text.blocks.take(2)) {
      final lines = block.text.split('\n').take(2);
      headerLines.addAll(lines.map((e) => e.trim()).where((e) => e.isNotEmpty));
    }

    if (headerLines.isEmpty) return null;

    // First line is usually the merchant name
    String candidate = headerLines.first;

    // Clean up common noise
    candidate = candidate
        .replaceAll(RegExp(r'[*#]{2,}'), '')
        .replaceAll(RegExp(r'^[\W_]+|[\W_]+$'), '')
        .trim();

    // Only return if looks like a name (not a date or number)
    if (candidate.length >= 3 && 
        RegExp(r'[A-Za-zÀ-ÿ]').hasMatch(candidate) &&
        !RegExp(r'^\d+[./-]\d+').hasMatch(candidate)) {
      return candidate;
    }

    return null;
  }

  /// Suggest category based on merchant name and keywords
  String? _suggestCategory(String? merchant, List<String> lines) {
    final text = '${merchant ?? ''} ${lines.take(20).join(' ')}';
    final lower = text.toLowerCase();

    // Category mapping based on keywords
    final categoryKeywords = {
      'groceries': ['grocery', 'supermarket', 'lidl', 'aldi', 'k-market', 's-market', 
                    'prisma', 'alepa', 'carrefour', 'walmart', 'tesco', 'ica'],
      'restaurants': ['restaurant', 'cafe', 'coffee', 'mcdonald', 'burger', 'pizza', 
                      'starbucks', 'subway', 'kfc', 'nando', 'chipotle'],
      'transport': ['uber', 'lyft', 'taxi', 'bus', 'train', 'metro', 'fuel', 'gas',
                    'shell', 'bp', 'esso', 'neste', 'abc'],
      'entertainment': ['cinema', 'movie', 'theater', 'netflix', 'spotify', 'concert'],
      'shopping': ['amazon', 'ikea', 'h&m', 'zara', 'nike', 'adidas', 'mall'],
      'health': ['pharmacy', 'apteekki', 'doctor', 'hospital', 'medical', 'health'],
      'utilities': ['electricity', 'water', 'internet', 'phone', 'mobile'],
    };

    for (final entry in categoryKeywords.entries) {
      for (final keyword in entry.value) {
        if (lower.contains(keyword)) {
          return entry.key;
        }
      }
    }

    return null;
  }

  ExtractedDouble _extractMoneyField(
    List<String> lines,
    List<String> tokens, {
    required String fieldName,
  }) {
    double bestValue = 0.0;
    double bestScore = 0.0;
    String? bestLine;

    for (final line in lines) {
      final u = line.toUpperCase();

      final tokenHit = tokens.any((t) => u.contains(t.toUpperCase()));
      final numbers = _extractLocaleNumbers(line);
      if (numbers.isEmpty) continue;

      // prefer last number on token lines (common receipt format)
      final candidate = tokenHit ? numbers.last : numbers.first;

      if (candidate <= 0 || candidate > 100000) continue;

      double score = 0.0;

      if (tokenHit) score += 0.70;
      // penalize if line looks like item line (description + price)
      if (_looksLikeLineItem(line)) score -= 0.15;
      // reward currency presence
      if (line.contains('€') || line.contains('\$') || line.contains('৳')) score += 0.10;
      // reward separators like ":" close to token
      if (line.contains(':')) score += 0.05;

      // fallback candidates still considered
      if (!tokenHit) score += 0.25;

      // small boost for large-ish totals for total field
      if (fieldName == 'total' && candidate >= 5) score += 0.05;

      if (score > bestScore) {
        bestScore = score;
        bestValue = candidate;
        bestLine = line;
      }
    }

    if (bestScore == 0.0) {
      // final fallback: largest sensible number
      final all = lines.expand(_extractLocaleNumbers)
          .where((v) => v > 0 && v < 100000).toList();
      if (all.isEmpty) return const ExtractedDouble(0.0, 0.0, null);
      final max = all.reduce((a, b) => a > b ? a : b);
      return ExtractedDouble(max, 0.45, 'fallback-largest');
    }

    final confidence = bestScore.clamp(0.0, 0.95);
    return ExtractedDouble(bestValue, confidence, bestLine);
  }

  bool _looksLikeLineItem(String line) {
    final hasLetters = RegExp(r'[A-Za-zÀ-ÖØ-öø-ÿ\u0980-\u09FF]').hasMatch(line);
    final hasNumber = RegExp(r'\d').hasMatch(line);
    return hasLetters && hasNumber && line.length > 10;
  }

  ExtractedDate _extractDate(List<String> lines) {
    // Supports: 12/10/2024, 12.10.2024, 2024-10-12, 12.10.24
    final patterns = <RegExp>[
      RegExp(r'(\d{1,2}[./-]\d{1,2}[./-]\d{2,4})'),
      RegExp(r'(\d{4}[./-]\d{1,2}[./-]\d{1,2})'),
    ];

    for (final line in lines.take(30)) {
      for (final p in patterns) {
        final m = p.firstMatch(line);
        if (m == null) continue;

        final s = m.group(1)!;
        final dt = _tryParseDate(s);
        if (dt != null) return ExtractedDate(dt, 0.85);
      }
    }
    return const ExtractedDate(null, 0.0);
  }

  DateTime? _tryParseDate(String s) {
    try {
      if (RegExp(r'^\d{4}').hasMatch(s)) {
        final parts = s.split(RegExp(r'[./-]'));
        final y = int.parse(parts[0]);
        final m = int.parse(parts[1]);
        final d = int.parse(parts[2]);
        return DateTime(y, m, d);
      } else {
        final parts = s.split(RegExp(r'[./-]'));
        int d = int.parse(parts[0]);
        int m = int.parse(parts[1]);
        int y = int.parse(parts[2]);
        if (y < 100) y += 2000;
        return DateTime(y, m, d);
      }
    } catch (_) {
      return null;
    }
  }

  String _detectCurrency(List<String> lines) {
    final text = lines.join(' ');
    if (text.contains('€')) return 'EUR';
    if (text.contains('\$')) return 'USD';
    if (text.contains('৳')) return 'BDT';
    if (text.contains('£')) return 'GBP';
    if (text.toUpperCase().contains('SEK')) return 'SEK';
    return 'EUR'; // Default to EUR for CashPilot
  }

  List<double> _extractLocaleNumbers(String line) {
    // handles: 1,234.56 | 1.234,56 | 1 234,56 | 1234.56
    final r = RegExp(r'(\d{1,3}([., ]\d{3})*[.,]\d{2})');
    final out = <double>[];
    for (final m in r.allMatches(line)) {
      final raw = m.group(0)!;
      final v = _parseLocaleNumber(raw);
      if (v != null) out.add(v);
    }
    return out;
  }

  double? _parseLocaleNumber(String input) {
    try {
      final clean = input.replaceAll(' ', '');
      if (clean.contains(',') && clean.contains('.')) {
        // decide decimal by last separator
        final lastComma = clean.lastIndexOf(',');
        final lastDot = clean.lastIndexOf('.');
        if (lastComma > lastDot) {
          // 1.234,56
          return double.parse(clean.replaceAll('.', '').replaceAll(',', '.'));
        } else {
          // 1,234.56
          return double.parse(clean.replaceAll(',', ''));
        }
      }
      return double.parse(clean.replaceAll(',', '.'));
    } catch (_) {
      return null;
    }
  }

  void dispose() => _textRecognizer.close();
}

// ================================
// MODELS
// ================================

class ReceiptScanResult {
  final String rawText;
  final double overallConfidence;
  final int? extractedAmount; // cents
  final int? extractedSubtotal;
  final int? extractedVat;

  final String? merchantName;
  final DateTime? transactionDate;
  final String? suggestedCategoryKey;
  final String currencyCode;

  final List<ReceiptLineItem> lineItems;
  final ReceiptConfidence confidence;
  final ReceiptFlags flags;

  
  /// Typed extraction metadata
  final ReceiptExtractionMeta? extraction;
  
  /// Duplicate warning message if similar receipt detected
  final String? duplicateWarning;
  
  final bool gated;
  final String? gatedReason;

  ReceiptScanResult({
    required this.rawText,
    required this.overallConfidence,
    this.extractedAmount,
    this.extractedSubtotal,
    this.extractedVat,
    this.merchantName,
    this.transactionDate,
    this.suggestedCategoryKey,
    this.currencyCode = 'EUR',
    this.lineItems = const [],
    this.confidence = const ReceiptConfidence(),
    this.flags = const ReceiptFlags(),
    this.extraction,
    this.duplicateWarning,
    this.gated = false,
    this.gatedReason,
  });

  factory ReceiptScanResult.gated({required String reason}) {
    return ReceiptScanResult(
      rawText: '',
      overallConfidence: 0.0,
      gated: true,
      gatedReason: reason,
      currencyCode: 'EUR',
    );
  }

  bool get hasAmount => extractedAmount != null && extractedAmount! > 0;
  bool get hasMerchant => merchantName != null && merchantName!.trim().isNotEmpty;
  bool get hasDate => transactionDate != null;

  /// Create a copy with updated values
  ReceiptScanResult copyWith({
    String? rawText,
    double? overallConfidence,
    int? extractedAmount,
    int? extractedSubtotal,
    int? extractedVat,
    String? merchantName,
    DateTime? transactionDate,
    String? suggestedCategoryKey,
    String? currencyCode,
    List<ReceiptLineItem>? lineItems,
    ReceiptConfidence? confidence,
    ReceiptFlags? flags,
    Map<String, dynamic>? metadata,
    ReceiptExtractionMeta? extraction,
  }) {
    return ReceiptScanResult(
      rawText: rawText ?? this.rawText,
      overallConfidence: overallConfidence ?? this.overallConfidence,
      extractedAmount: extractedAmount ?? this.extractedAmount,
      extractedSubtotal: extractedSubtotal ?? this.extractedSubtotal,
      extractedVat: extractedVat ?? this.extractedVat,
      merchantName: merchantName ?? this.merchantName,
      transactionDate: transactionDate ?? this.transactionDate,
      suggestedCategoryKey: suggestedCategoryKey ?? this.suggestedCategoryKey,
      currencyCode: currencyCode ?? this.currencyCode,
      lineItems: lineItems ?? this.lineItems,
      confidence: confidence ?? this.confidence,
      flags: flags ?? this.flags,
      extraction: extraction ?? this.extraction,
      gated: gated,
      gatedReason: gatedReason,
    );
  }
}

class ReceiptLineItem {
  final String description;
  final int totalPrice; // cents
  ReceiptLineItem({required this.description, required this.totalPrice});
}

class ReceiptFlags {
  final bool isDuplicateLikely;
  final bool needsUserReview;
  const ReceiptFlags({this.isDuplicateLikely = false, this.needsUserReview = false});
}

class ReceiptConfidence {
  final double total;
  final double subtotal;
  final double vat;
  final double date;
  final double merchant;
  final double category;

  const ReceiptConfidence({
    this.total = 0,
    this.subtotal = 0,
    this.vat = 0,
    this.date = 0,
    this.merchant = 0,
    this.category = 0,
  });

  double get overall {
    // accuracy-first weighting
    final v = (total * 0.45) + (date * 0.20) + (merchant * 0.20) + (vat * 0.10) + (category * 0.05);
    return v.clamp(0.0, 1.0);
  }

  bool get needsUserReview {
    // total is mandatory; merchant/date are usually expected
    if (total < 0.70) return true;
    if (merchant < 0.55) return true;
    if (date < 0.55) return true;
    return false;
  }
}

class ExtractedDouble {
  final double value;
  final double confidence;
  final String? evidenceLine;
  const ExtractedDouble(this.value, this.confidence, this.evidenceLine);
}

class ExtractedDate {
  final DateTime? value;
  final double confidence;
  const ExtractedDate(this.value, this.confidence);
}
