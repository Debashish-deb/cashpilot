/// Duplicate Receipt Detector - Prevents duplicate expense entries
/// Uses multiple signals to detect likely duplicates
library;

/// Duplicate detection result
class DuplicateCheckResult {
  final bool isDuplicate;
  final double confidence;
  final String? reason;
  final String? duplicateId;
  
  const DuplicateCheckResult({
    required this.isDuplicate,
    required this.confidence,
    this.reason,
    this.duplicateId,
  });
  
  const DuplicateCheckResult.notDuplicate()
      : isDuplicate = false,
        confidence = 0.0,
        reason = null,
        duplicateId = null;
}

/// Service for detecting duplicate receipts
class DuplicateDetector {
  /// Check if receipt is likely a duplicate
  /// 
  /// Signals used:
  /// - Same merchant (fuzzy match)
  /// - Same total (±1%)
  /// - Same date (±2 hours)
  /// - Same currency
  /// - Same category/budget (optional)
  static Future<DuplicateCheckResult> checkDuplicate({
    required Future<List<Map<String, dynamic>>> Function() getRecentExpenses,
    required String? merchant,
    required double total,
    required DateTime date,
    required String currency,
    String? category,
    String? budgetId,
  }) async {
    try {
      final recentExpenses = await getRecentExpenses();
      
      // Only check expenses from last 24 hours
      final cutoffTime = date.subtract(const Duration(hours: 24));
      
      for (final expense in recentExpenses) {
        // Skip old expenses (>24 hours)
        final expenseDate = expense['expense_date'] != null
            ? DateTime.parse(expense['expense_date'] as String)
            : null;
        
        if (expenseDate != null && expenseDate.isBefore(cutoffTime)) {
          continue; // Skip expenses older than 24 hours
        }
        final signals = _calculateDuplicateSignals(
          merchant: merchant,
          total: total,
          date: date,
          currency: currency,
          category: category,
          budgetId: budgetId,
          existingMerchant: expense['merchant_name'] as String?,
          existingTotal: expense['amount'] != null
              ? (expense['amount'] as int) / 100.0
              : null,
          existingDate: expenseDate,
          existingCurrency: expense['currency_code'] as String?,
          existingCategory: expense['category_key'] as String?,
          existingBudgetId: expense['budget_id'] as String?,
        );
        
        // If cumulative score is high, it's likely a duplicate
        if (signals['score']! >= 0.75) {
          return DuplicateCheckResult(
            isDuplicate: true,
            confidence: signals['score']!,
            reason: _buildDuplicateReason(signals),
            duplicateId: expense['id'] as String?,
          );
        }
      }
      
      return const DuplicateCheckResult.notDuplicate();
    } catch (e) {
      // If check fails, assume not duplicate (fail open)
      return const DuplicateCheckResult.notDuplicate();
    }
  }
  
  /// Calculate duplicate signals
  static Map<String, double> _calculateDuplicateSignals({
    required String? merchant,
    required double total,
    required DateTime date,
    required String currency,
    String? category,
    String? budgetId,
    required String? existingMerchant,
    required double? existingTotal,
    required DateTime? existingDate,
    required String? existingCurrency,
    String? existingCategory,
    String? existingBudgetId,
  }) {
    final signals = <String, double>{};
    double totalScore = 0.0;
    
    // Signal 1: Same merchant (40% weight)
    if (merchant != null && existingMerchant != null) {
      final merchantMatch = _fuzzyMatchMerchant(merchant, existingMerchant);
      signals['merchant'] = merchantMatch;
      totalScore += merchantMatch * 0.40;
    }
    
    // Signal 2: Same total within 1% (30% weight)
    if (existingTotal != null && total > 0) {
      final diff = (total - existingTotal).abs();
      final percentDiff = diff / total;
      if (percentDiff <= 0.01) {  // Within 1%
        signals['total'] = 1.0;
        totalScore += 0.30;
      } else if (percentDiff <= 0.05) {  // Within 5%
        signals['total'] = 0.5;
        totalScore += 0.15;
      }
    }
    
    // Signal 3: Same date within 2 hours (20% weight)
    if (existingDate != null) {
      final timeDiff = date.difference(existingDate).abs();
      if (timeDiff.inHours <= 2) {
        signals['date'] = 1.0;
        totalScore += 0.20;
      } else if (timeDiff.inHours <= 24) {
        signals['date'] = 0.3;
        totalScore += 0.06;
      }
    }
    
    // Signal 4: Same currency (5% weight)
    if (currency == existingCurrency) {
      signals['currency'] = 1.0;
      totalScore += 0.05;
    }
    
    // Signal 5: Same category/budget (5% weight)
    if (category != null && category == existingCategory) {
      signals['category'] = 1.0;
      totalScore += 0.025;
    }
    if (budgetId != null && budgetId == existingBudgetId) {
      signals['budget'] = 1.0;
      totalScore += 0.025;
    }
    
    signals['score'] = totalScore.clamp(0.0, 1.0);
    return signals;
  }
  
  /// Fuzzy match merchant names
  static double _fuzzyMatchMerchant(String a, String b) {
    final cleanA = _cleanForMatch(a);
    final cleanB = _cleanForMatch(b);
    
    // Exact match
    if (cleanA == cleanB) return 1.0;
    
    // Contains match
    if (cleanA.contains(cleanB) || cleanB.contains(cleanA)) return 0.85;
    
    // Levenshtein-like simple similarity
    final similarity = _simpleSimilarity(cleanA, cleanB);
    return similarity;
  }
  
  static String _cleanForMatch(String text) {
    return text
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z0-9]'), '')
        .trim();
  }
  
  static double _simpleSimilarity(String a, String b) {
    if (a.isEmpty || b.isEmpty) return 0.0;
    
    final longer = a.length > b.length ? a : b;
    final shorter = a.length > b.length ? b : a;
    
    int matches = 0;
    for (int i = 0; i < shorter.length; i++) {
      if (i < longer.length && shorter[i] == longer[i]) {
        matches++;
      }
    }
    
    return matches / longer.length;
  }
  
  static String _buildDuplicateReason(Map<String, double> signals) {
    final reasons = <String>[];
    
    if ((signals['merchant'] ?? 0) >= 0.8) reasons.add('same merchant');
    if ((signals['total'] ?? 0) >= 0.8) reasons.add('same amount');
    if ((signals['date'] ?? 0) >= 0.8) reasons.add('same time');
    
    if (reasons.isEmpty) return 'Similar to recent expense';
    return 'Possibly duplicate: ${reasons.join(", ")}';
  }
}
