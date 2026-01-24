import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/drift/app_database.dart';
import '../../../core/providers/app_providers.dart';


/// Provides all accounts for the current user
final accountsProvider = StreamProvider<List<Account>>((ref) {
  final db = ref.watch(databaseProvider);
  final userId = ref.watch(currentUserIdProvider);
  
  // Filter by user ID if available (for multi-user support)
  // Currently returns all accounts as user attribution is not yet implemented
  // When implementing per-user accounts, add: .where((a) => a.userId == userId)
  return db.watchAllAccounts();
});

/// ============================================================================
/// TOTAL BALANCE — optimized no-recompute + mobile-safe
/// ============================================================================

final totalBalanceProvider = Provider<int>((ref) {
  final accountsAsync = ref.watch(accountsProvider);

  return accountsAsync.maybeWhen(
    data: (accounts) =>
        accounts.fold<int>(0, (sum, acc) => sum + acc.balance.toInt()),
    orElse: () => 0,
  );
});

/// ============================================================================
/// NET WORTH PROVIDER — rebuilt for:
/// ✔ no async generators
/// ✔ no nested streams
/// ✔ instant fallback values (no UI flash)
/// ✔ future multi-currency or multi-profile support
/// ============================================================================

final netWorthProvider = Provider<NetWorthData>((ref) {
  final accountsAsync = ref.watch(accountsProvider);

  return accountsAsync.maybeWhen(
    data: (accounts) {
      int totalAssets = 0;
      int totalLiabilities = 0;

      for (final acc in accounts) {
        switch (acc.type) {
          case 'credit':
          case 'loan':
            // Liabilities grow upward — debt increases
            totalLiabilities += acc.balance.toInt();
            break;
          default:
            totalAssets += acc.balance.toInt();
        }
      }

      return NetWorthData(
        totalAssets: totalAssets,
        totalLiabilities: totalLiabilities,
        netWorth: totalAssets - totalLiabilities,
      );
    },
    orElse: () => NetWorthData.zero(),
  );
});

/// ============================================================================
/// NET WORTH MODEL — unchanged shape, but utility methods added
/// ============================================================================

class NetWorthData {
  final int totalAssets;
  final int totalLiabilities;
  final int netWorth;

  const NetWorthData({
    required this.totalAssets,
    required this.totalLiabilities,
    required this.netWorth,
  });

  factory NetWorthData.zero() =>
      const NetWorthData(totalAssets: 0, totalLiabilities: 0, netWorth: 0);

  /// Helpful for charts
  double get liabilityRatio {
    final total = totalAssets + totalLiabilities;
    if (total == 0) return 0;
    return totalLiabilities / total;
  }

  /// Helpful for UI — green / red indicators
  bool get isPositive => netWorth >= 0;

  /// Helpful for animations
  NetWorthData copyWith({
    int? totalAssets,
    int? totalLiabilities,
    int? netWorth,
  }) {
    return NetWorthData(
      totalAssets: totalAssets ?? this.totalAssets,
      totalLiabilities: totalLiabilities ?? this.totalLiabilities,
      netWorth: netWorth ?? this.netWorth,
    );
  }
}

/// ============================================================================
/// INDIVIDUAL METRIC PROVIDERS (for specific widgets)
/// ============================================================================

/// Total assets value (for net worth card)
final totalAssetsProvider = Provider<AsyncValue<int>>((ref) {
  return ref.watch(accountsProvider).when(
    data: (accounts) {
      final assets = accounts
          .where((acc) => acc.type != 'credit' && acc.type != 'loan')
          .fold<int>(0, (sum, acc) => sum + acc.balance.toInt());
      return AsyncData(assets);
    },
    loading: () => const AsyncLoading(),
    error: (e, s) => AsyncError(e, s),
  );
});

/// Total liabilities value (for net worth card)
final totalLiabilitiesProvider = Provider<AsyncValue<int>>((ref) {
  return ref.watch(accountsProvider).when(
    data: (accounts) {
      final liabilities = accounts
          .where((acc) => acc.type == 'credit' || acc.type == 'loan')
          .fold<int>(0, (sum, acc) => sum + acc.balance.toInt());
      return AsyncData(liabilities);
    },
    loading: () => const AsyncLoading(),
    error: (e, s) => AsyncError(e, s),
  );
});
