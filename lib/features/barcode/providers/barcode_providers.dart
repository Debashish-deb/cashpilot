/// Barcode Providers
/// Riverpod providers for barcode scanning state management (Enterprise-grade)
library;
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/barcode_scan_result.dart';
import '../services/barcode_scanner_service.dart';

/// ---------------------------------------------------------------------------
/// SCANNER SERVICE PROVIDER
/// ---------------------------------------------------------------------------

/// Singleton barcode scanner service
final barcodeScannerProvider = Provider<BarcodeScannerService>((ref) {
  final service = BarcodeScannerService();

  // Ensure cleanup when provider is disposed
  ref.onDispose(service.dispose);

  return service;
});

/// ---------------------------------------------------------------------------
/// CURRENT SCAN STATE
/// ---------------------------------------------------------------------------

/// Holds the most recent scan result (raw or enriched)
final currentScanProvider = StateProvider<BarcodeScanResult?>((ref) => null);

/// Indicates whether a lookup or enrichment is in progress
final productLookupLoadingProvider = StateProvider<bool>((ref) => false);

/// In-flight lookup counter (industrial-grade concurrency safety)
final productLookupInFlightCountProvider = StateProvider<int>((ref) => 0);

/// Indicates whether scanner is actively detecting barcodes
final scanningActiveProvider = StateProvider<bool>((ref) => false);

/// ---------------------------------------------------------------------------
/// SCAN HISTORY (ENTERPRISE HARDENED)
/// ---------------------------------------------------------------------------

final scanHistoryProvider =
    StateNotifierProvider<ScanHistoryNotifier, List<BarcodeScanResult>>((ref) {
  return ScanHistoryNotifier();
});

class ScanHistoryNotifier extends StateNotifier<List<BarcodeScanResult>> {
  ScanHistoryNotifier() : super([]);

  static const int _maxHistory = 50;

  /// Add scan with deduplication + confidence preference
  void addScan(BarcodeScanResult result) {
    final duplicateIndex = state.indexWhere((existing) {
      return existing.rawValue == result.rawValue;
    });

    bool isBetter(BarcodeScanResult newer, BarcodeScanResult older) {
      if (newer.confidence > older.confidence) return true;
      if (newer.productInfo != null && older.productInfo == null) return true;
      final newerLookup = newer.scanMetadata?.lookup;
      final olderLookup = older.scanMetadata?.lookup;
      if (newerLookup != null && olderLookup == null) return true;
      return false;
    }

    if (duplicateIndex != -1) {
      final existing = state[duplicateIndex];
      if (isBetter(result, existing)) {
        final updated = [...state];
        updated[duplicateIndex] = result;
        state = updated;
      }
      return;
    }

    state = [result, ...state].take(_maxHistory).toList();
  }

  void removeScan(int index) {
    if (index >= 0 && index < state.length) {
      final updated = [...state]..removeAt(index);
      state = updated;
    }
  }

  void clearHistory() {
    state = [];
  }

  /// Check if barcode was already scanned recently
  bool hasRecentScan(String rawValue, {Duration window = const Duration(seconds: 3)}) {
    final now = DateTime.now();
    return state.any(
      (e) => e.rawValue == rawValue && now.difference(e.scannedAt) <= window,
    );
  }
}

/// ---------------------------------------------------------------------------
/// LIVE SCAN STREAM WIRING
/// ---------------------------------------------------------------------------

/// Listens to scanner stream and updates providers automatically
final barcodeScanStreamProvider = Provider<StreamSubscription>((ref) {
  final scanner = ref.read(barcodeScannerProvider);
  final history = ref.read(scanHistoryProvider.notifier);

  final subscription = scanner.scanStream.listen((scan) {
    history.addScan(scan);
    ref.read(currentScanProvider.notifier).state = scan;
  });

  ref.onDispose(subscription.cancel);
  return subscription;
});

/// ---------------------------------------------------------------------------
/// PRODUCT LOOKUP PIPELINE
/// ---------------------------------------------------------------------------

/// Enriched product lookup with lifecycle & confidence handling
final productLookupProvider =
    FutureProvider.family<ProductInfo?, BarcodeScanResult>((ref, scan) async {
  final scanner = ref.read(barcodeScannerProvider);

  // Skip lookup if not a product barcode
  if (!scan.isProductBarcode || !scan.isValid) return null;

  final countN = ref.read(productLookupInFlightCountProvider.notifier);
  countN.state = countN.state + 1;
  ref.read(productLookupLoadingProvider.notifier).state = true;

  try {
    final product = await scanner.lookupProduct(scan.rawValue);

    if (product != null) {
      final enriched = scan.copyWith(
        productInfo: product,
      );

      // Update current scan & history
      ref.read(currentScanProvider.notifier).state = enriched;
      ref.read(scanHistoryProvider.notifier).addScan(enriched);
    }

    return product;
  } finally {
    final countN = ref.read(productLookupInFlightCountProvider.notifier);
    countN.state = (countN.state - 1).clamp(0, 1 << 30);
    ref.read(productLookupLoadingProvider.notifier).state = countN.state > 0;
  }
});

/// ---------------------------------------------------------------------------
/// CONFIDENCE & UI SIGNAL PROVIDERS
/// ---------------------------------------------------------------------------

/// Whether UI should prompt user confirmation
final scanNeedsConfirmationProvider = Provider<bool>((ref) {
  final scan = ref.watch(currentScanProvider);
  if (scan == null) return false;
  return scan.needsUserConfirmation;
});

/// Whether scan can be auto-applied safely
final scanAutoFillSafeProvider = Provider<bool>((ref) {
  final scan = ref.watch(currentScanProvider);
  if (scan == null) return false;
  return scan.isAutoFillSafe;
});
