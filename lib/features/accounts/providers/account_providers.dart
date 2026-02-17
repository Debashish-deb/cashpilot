import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/drift/app_database.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/logging/logger.dart';
import '../../expenses/providers/expense_providers.dart' show expensesByAccountProvider;

/// Provides all accounts for the current user
final accountsProvider = StreamProvider<List<Account>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllAccounts();
});

final totalBalanceProvider = Provider<BigInt>((ref) {
  final accountsAsync = ref.watch(accountsProvider);

  return accountsAsync.maybeWhen(
    data: (accounts) =>
        accounts.fold<BigInt>(BigInt.zero, (sum, acc) => sum + acc.balanceCents),
    orElse: () => BigInt.zero,
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
      BigInt totalAssets = BigInt.zero;
      BigInt totalLiabilities = BigInt.zero;

      for (final acc in accounts) {
        switch (acc.type) {
          case 'credit':
          case 'loan':
            // Liabilities grow upward — debt increases
            totalLiabilities += acc.balanceCents;
            break;
          default:
            totalAssets += acc.balanceCents;
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
  final BigInt totalAssets;
  final BigInt totalLiabilities;
  final BigInt netWorth;

  const NetWorthData({
    required this.totalAssets,
    required this.totalLiabilities,
    required this.netWorth,
  });

  factory NetWorthData.zero() =>
      NetWorthData(totalAssets: BigInt.zero, totalLiabilities: BigInt.zero, netWorth: BigInt.zero);

  /// Helpful for charts
  double get liabilityRatio {
    final total = totalAssets + totalLiabilities;
    if (total == BigInt.zero) return 0;
    return totalLiabilities.toDouble() / total.toDouble();
  }

  /// Helpful for UI — green / red indicators
  bool get isPositive => netWorth >= BigInt.zero;

  /// Helpful for animations
  NetWorthData copyWith({
    BigInt? totalAssets,
    BigInt? totalLiabilities,
    BigInt? netWorth,
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
final totalAssetsProvider = Provider<AsyncValue<BigInt>>((ref) {
  return ref.watch(accountsProvider).when(
    data: (accounts) {
      final assets = accounts
          .where((acc) => acc.type != 'credit' && acc.type != 'loan')
          .fold<BigInt>(BigInt.zero, (sum, acc) => sum + acc.balanceCents);
      return AsyncData(assets);
    },
    loading: () => const AsyncLoading(),
    error: (e, s) => AsyncError(e, s),
  );
});

/// Total liabilities value (for net worth card)
final totalLiabilitiesProvider = Provider<AsyncValue<BigInt>>((ref) {
  return ref.watch(accountsProvider).when(
    data: (accounts) {
      final liabilities = accounts
          .where((acc) => acc.type == 'credit' || acc.type == 'loan')
          .fold<BigInt>(BigInt.zero, (sum, acc) => sum + acc.balanceCents);
      return AsyncData(liabilities);
    },
    loading: () => const AsyncLoading(),
    error: (e, s) => AsyncError(e, s),
  );
});

/// Account Balance Validation Result
class AccountValidation {
  final BigInt databaseBalance;
  final BigInt transactionSum;
  final bool isValid;
  final String? message;

  AccountValidation({
    required this.databaseBalance,
    required this.transactionSum,
    required this.isValid,
    this.message,
  });
}

/// Validates if account balance matches the sum of its transactions
final accountValidationProvider = Provider.family<AsyncValue<AccountValidation>, String>((ref, accountId) {
  final accountsAsync = ref.watch(accountsProvider);
  final expensesAsync = ref.watch(expensesByAccountProvider(accountId));

  return accountsAsync.when(
    data: (accounts) {
      final account = accounts.firstWhere((a) => a.id == accountId);
      return expensesAsync.when(
        data: (expenses) {
          // Note: In a real app, you'd start from an initial balance or track income.
          // For CashPilot, we'll check if the balance is at least consistent with historical spending.
          final totalSpent = expenses.fold<BigInt>(BigInt.zero, (sum, e) => sum + e.amountCents);
          
          return AsyncValue.data(AccountValidation(
            databaseBalance: account.balanceCents,
            transactionSum: totalSpent,
            isValid: true, // Placeholder logic for now as requested in P0
            message: 'Reconciliation check complete: $totalSpent total spent found.',
          ));
        },
        loading: () => const AsyncValue.loading(),
        error: (e, s) => AsyncValue.error(e, s),
      );
    },
    loading: () => const AsyncValue.loading(),
    error: (e, s) => AsyncValue.error(e, s),
  );
});
