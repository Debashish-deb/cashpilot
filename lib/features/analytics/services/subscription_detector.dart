/// Subscription Detector — Pro Edition
/// Smarter, safer, more accurate recurring subscription detection.
library;

import 'package:cashpilot/data/drift/app_database.dart' show Expense;

class DetectedSubscription {
  final String merchant;
  final double amount; // cents
  final int intervalDays;
  final List<DateTime> occurrences;
  final double confidence;

  const DetectedSubscription({
    required this.merchant,
    required this.amount,
    required this.intervalDays,
    required this.occurrences,
    required this.confidence,
  });

  // Enhanced frequency classification
  bool get isWeekly => intervalDays >= 6 && intervalDays <= 8;
  bool get isBiWeekly => intervalDays >= 13 && intervalDays <= 15;
  bool get isMonthly => intervalDays >= 28 && intervalDays <= 32;
  bool get isQuarterly => intervalDays >= 85 && intervalDays <= 95;
  bool get isYearly => intervalDays >= 360 && intervalDays <= 370;

  String get frequency {
    if (isWeekly) return "Weekly";
    if (isBiWeekly) return "Bi-Weekly";
    if (isMonthly) return "Monthly";
    if (isQuarterly) return "Quarterly";
    if (isYearly) return "Yearly";
    return "$intervalDays days";
  }
}

class SubscriptionDetector {
  // ============================================================================
  // PUBLIC API
  // ============================================================================

  static List<DetectedSubscription> detectSubscriptions(List<Expense> expenses) {
    if (expenses.isEmpty) return [];

    // ---------------------------------------------------------
    // Normalize merchants & group
    // ---------------------------------------------------------
    final groups = <String, List<Expense>>{};

    for (final e in expenses) {
      final merchant = _normalizeMerchant(e.title);
      groups.putIfAbsent(merchant, () => []).add(e);
    }

    final detected = <DetectedSubscription>[];

    // ---------------------------------------------------------
    // Process each merchant
    // ---------------------------------------------------------
    for (final entry in groups.entries) {
      final merchantName = entry.value.first.title; // original case
      final merchantExpenses = entry.value;

      if (merchantExpenses.length < 2) continue;

      // Sort by date (ascending)
      merchantExpenses.sort((a, b) => a.date.compareTo(b.date));

      // Group by amount clusters (±5% tolerance)
      final amountGroups = _clusterAmounts(merchantExpenses);

      for (final cluster in amountGroups.entries) {
        final amount = cluster.key;
        final expGroup = cluster.value;

        if (expGroup.length < 2) continue;

        final occurrences = expGroup.map((e) => e.date).toList()
          ..sort();

        final intervals = _calculateIntervals(occurrences);

        if (intervals.isEmpty) continue;

        final avg = intervals.reduce((a, b) => a + b) / intervals.length;
        final variance = _calculateVariance(intervals, avg);

        // Require minimum days between recurrences
        if (avg < 5) continue;

        final confidence = _calculateConfidence(
          occurrences: occurrences.length,
          variance: variance,
          intervalDays: avg.round(),
        );

        if (confidence < 0.6) continue;

        detected.add(
          DetectedSubscription(
            merchant: merchantName,
            amount: amount,
            intervalDays: avg.round(),
            occurrences: occurrences,
            confidence: confidence,
          ),
        );
      }
    }

    detected.sort((a, b) => b.confidence.compareTo(a.confidence));
    return detected;
  }

  // ============================================================================
  // LOAD INDEX (unchanged but improved)
  // ============================================================================

  static Map<String, dynamic> calculateSubscriptionLoad({
    required List<DetectedSubscription> subscriptions,
    required double totalBudget,
  }) {
    double monthlyCost = 0.0;

    for (final sub in subscriptions) {
      if (sub.isMonthly) {
        monthlyCost += sub.amount;
      } else if (sub.isWeekly) {
        monthlyCost += sub.amount * 4.33;
      } else if (sub.isBiWeekly) {
        monthlyCost += sub.amount * 2.165;
      } else if (sub.isQuarterly) {
        monthlyCost += sub.amount / 3;
      } else if (sub.isYearly) {
        monthlyCost += sub.amount / 12;
      } else {
        // Generic interval conversion
        monthlyCost += sub.amount * (30 / sub.intervalDays);
      }
    }

    final percent = totalBudget > 0 ? monthlyCost / totalBudget : 0.0;

    return {
      'total_subscriptions': subscriptions.length,
      'monthly_cost': monthlyCost,
      'percent_of_budget': percent,
      'subscriptions': subscriptions,
    };
  }

  // ============================================================================
  // INTERNAL HELPERS (improved)
  // ============================================================================

  static String _normalizeMerchant(String title) {
    return title
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .trim();
  }

  static Map<double, List<Expense>> _clusterAmounts(List<Expense> expenses) {
    final groups = <double, List<Expense>>{};

    for (final e in expenses) {
      final amount = e.amount.toDouble();

      bool placed = false;

      for (final existing in groups.keys.toList()) {
        final diff = (amount - existing).abs() / existing;
        if (diff <= 0.05) { // 5% tolerance
          groups[existing]!.add(e);
          placed = true;
          break;
        }
      }

      if (!placed) {
        groups[amount] = [e];
      }
    }
    return groups;
  }

  static List<int> _calculateIntervals(List<DateTime> dates) {
    final intervals = <int>[];
    for (int i = 1; i < dates.length; i++) {
      int d = dates[i].difference(dates[i - 1]).inDays;
      if (d > 0) intervals.add(d);
    }
    return intervals;
  }

  static double _calculateVariance(List<int> intervals, double mean) {
    if (intervals.isEmpty) return 999;
    double sum = 0;
    for (final i in intervals) {
      sum += (i - mean).abs();
    }
    return sum / intervals.length;
  }

  static double _calculateConfidence({
    required int occurrences,
    required double variance,
    required int intervalDays,
  }) {
    double c = 0.5;

    // More occurrences = higher confidence
    if (occurrences >= 5) {
      c += 0.30;
    } else if (occurrences >= 3) c += 0.20;
    else c += 0.10;

    // Variance improvement
    if (variance <= 1) {
      c += 0.20;
    } else if (variance <= 2) c += 0.10;

    // Standard subscription intervals
    if ((intervalDays >= 28 && intervalDays <= 32) || // monthly
        (intervalDays >= 6 && intervalDays <= 8) ||   // weekly
        (intervalDays >= 13 && intervalDays <= 15) || // biweekly
        (intervalDays >= 85 && intervalDays <= 95) || // quarterly
        (intervalDays >= 360 && intervalDays <= 370)) // yearly
    {
      c += 0.10;
    }

    return c.clamp(0.0, 1.0);
  }
}
