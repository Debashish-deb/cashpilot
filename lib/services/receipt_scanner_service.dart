/// Receipt Scanner Service
/// Accuracy-first offline extraction with:
/// - Hybrid merchant classifier (rule + fuzzy)
/// - Category suggestion (merchant + keyword)
/// - Confidence-driven prompt hints
/// - Subscription gating + scan limits (using CashPilot tiers)
library;

import 'package:drift/drift.dart' show Variable;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/providers/app_providers.dart';

import '../core/constants/subscription.dart';
import '../features/receipt/models/receipt_extraction_meta.dart';
import '../features/receipt/models/receipt_field_meta.dart';
import '../features/receipt/models/receipt_data.dart';
import '../features/receipt/services/duplicate_detector.dart';
import '../data/drift/app_database.dart';
import '../core/scan_pipeline/scan_pipeline.dart';

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
  // OCR is now handled by ScanPipeline, but we keep ImagePicker
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

    final result = await _processImage(image);
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

    final result = await _processImage(image);
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

  Future<ReceiptScanResult> _processImage(XFile imageFile) async {
    // [NEW] Use the Scan Pipeline
    final pipeline = ScanPipeline();
    
    try {
      final result = await pipeline.run(imageFile);
      return await _mapPipelineResult(result);
    } finally {
      pipeline.dispose();
    }
  }

  // ================================
  // MAPPING & ENRICHMENT
  // ================================

  Future<ReceiptScanResult> _mapPipelineResult(ScanResult scanResult) async {
    final data = scanResult.data;
    
    // 1. Merchant Detection
    final merchantName = data.merchantName;

    // 2. Category Suggestion
    final suggestedCategory = _suggestCategory(merchantName, scanResult.rawText.split('\n'));

    // 3. Currency Detection
    final currency = data.currencyCode ?? 'EUR';

    // 4. Duplicate Check
    String? duplicateWarning;
    try {
      final recentExpenses = await _fetchRecentExpenses();
      
      // Convert recent expenses (history) to ReceiptData
      final history = recentExpenses.map((e) => ReceiptData(
        total: (e.amount / 100.0), // stored as cents
        merchantName: e.merchantName,
        date: e.date,
        currencyCode: e.currency,
      )).toList();

      // Current receipt data
      final current = ReceiptData(
        total: data.total,
        merchantName: merchantName,
        date: data.date,
        currencyCode: currency,
      );
      
      final result = DuplicateDetector.detect(
        current: current,
        history: history,
      );
      
      if (result.isDuplicate) {
        duplicateWarning = result.reason;
      }
    } catch (e) {
      if (enableDebug) debugPrint('Duplicate check failed: $e');
    }

    // 5. Confidence Calculation
    final confidence = ReceiptConfidence(
      total: data.total != null ? 0.9 : 0.0,
      date: data.date != null ? 0.9 : 0.0,
      merchant: merchantName != null ? 0.8 : 0.0,
      subtotal: data.subtotal != null ? 0.8 : 0.0,
      vat: data.tax != null ? 0.8 : 0.0,
      category: suggestedCategory != null ? 0.7 : 0.0,
    );

    // 6. Detailed Extraction Meta for Learning
    final extractionMeta = ReceiptExtractionMeta(
      total: data.total != null ? ReceiptFieldMeta<double>(field: 'total', value: data.total!, confidence: 0.9) : null,
      subtotal: data.subtotal != null ? ReceiptFieldMeta<double>(field: 'subtotal', value: data.subtotal!, confidence: 0.8) : null,
      tax: data.tax != null ? ReceiptFieldMeta<double>(field: 'tax', value: data.tax!, confidence: 0.8) : null,
      merchant: merchantName != null ? ReceiptFieldMeta<String>(field: 'merchant', value: merchantName, confidence: 0.8) : null,
      date: data.date != null ? ReceiptFieldMeta<String>(field: 'date', value: data.date!.toIso8601String(), confidence: 0.9) : null,
      currency: currency != 'EUR' ? ReceiptFieldMeta<String>(field: 'currency', value: currency, confidence: 0.9) : null,
      modelVersion: '2.0-pipeline',
      extractedAt: DateTime.now(),
    );


    return ReceiptScanResult(
      rawText: scanResult.rawText,
      overallConfidence: confidence.overall,
      extractedAmount: data.total != null ? (data.total! * 100).round() : null,
      extractedSubtotal: data.subtotal != null ? (data.subtotal! * 100).round() : null,
      extractedVat: data.tax != null ? (data.tax! * 100).round() : null,
      merchantName: merchantName,
      transactionDate: data.date,
      suggestedCategoryKey: suggestedCategory,
      currencyCode: currency,
      lineItems: const [], // Parser doesn't do lines yet
      confidence: confidence,
      flags: ReceiptFlags(
        isDuplicateLikely: duplicateWarning != null,
        needsUserReview: confidence.needsUserReview,
      ),
      extraction: extractionMeta,
      duplicateWarning: duplicateWarning,
    );
  }

  Future<List<Expense>> _fetchRecentExpenses() async {
      final cutoff = DateTime.now().subtract(const Duration(days: 7));
      final rows = await database.customSelect(
        'SELECT * FROM expenses WHERE date >= ? ORDER BY date DESC LIMIT 100',
        variables: [Variable.withDateTime(cutoff)],
        readsFrom: {database.expenses},
      ).get();
      
      return rows.map((row) => database.expenses.map(row.data)).toList();
  }

  /// Suggest category based on merchant name and keywords
  String? _suggestCategory(String? merchant, List<String> lines) {
    if (merchant == null && lines.isEmpty) return null;
    
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

  void dispose() {}
}

// ================================
// MODELS
// ================================

class ReceiptScanResult {
  final String rawText;
  final double overallConfidence;
  final int? extractedAmount; // cents
  final int? extractedSubtotal; // cents
  final int? extractedVat; // cents

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
