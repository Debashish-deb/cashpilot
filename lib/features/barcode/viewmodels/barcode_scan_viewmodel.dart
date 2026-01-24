import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart' as ms;
import '../models/scan_state.dart';
import '../models/barcode_scan_result.dart';
import '../services/barcode_scanner_service.dart';

class BarcodeScanViewState {
  final ScanState status;
  final BarcodeScanResult? lastResult;
  final ScannerError? error;
  final bool isProcessingFrame;

  const BarcodeScanViewState({
    this.status = ScanState.idle,
    this.lastResult,
    this.error,
    this.isProcessingFrame = false,
  });

  BarcodeScanViewState copyWith({
    ScanState? status,
    BarcodeScanResult? lastResult,
    ScannerError? error,
    bool? isProcessingFrame,
  }) {
    return BarcodeScanViewState(
      status: status ?? this.status,
      lastResult: lastResult ?? this.lastResult,
      error: error ?? this.error,
      isProcessingFrame: isProcessingFrame ?? this.isProcessingFrame,
    );
  }
}

class BarcodeScanViewModel extends StateNotifier<BarcodeScanViewState> {
  final BarcodeScannerService _service;
  Timer? _timeoutTimer;
  static const _scanTimeout = Duration(seconds: 15);
  static const _scanDebounceDuration = Duration(milliseconds: 900);
  static const _consensusThreshold = 3; // Number of frames required for consensus
  
  DateTime? _lastScanTime;
  final Map<String, int> _detectionBuffer = {};
  final Map<String, DateTime> _detectionTimestamps = {};
  static const _consensusWindow = Duration(milliseconds: 500); 

  BarcodeScanViewModel(this._service) : super(const BarcodeScanViewState());

  void initialize() {
    state = state.copyWith(status: ScanState.scanning);
    _startTimeoutTimer();
  }

  void onDetect(ms.BarcodeCapture capture) {
    if (state.isProcessingFrame || state.status != ScanState.scanning) return;

    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;

    final rawValue = barcode.rawValue!;
    final now = DateTime.now();

    // 1. Clean up stale detections (rolling window)
    _detectionTimestamps.removeWhere((val, time) => now.difference(time) > _consensusWindow);
    _detectionBuffer.removeWhere((val, count) => !_detectionTimestamps.containsKey(val));

    // 2. Increment count for current detection
    _detectionBuffer[rawValue] = (_detectionBuffer[rawValue] ?? 0) + 1;
    _detectionTimestamps[rawValue] = now;

    // 3. Check for consensus
    if (_detectionBuffer[rawValue]! >= _consensusThreshold) {
      // Consensus reached!
      _detectionBuffer.clear();
      _detectionTimestamps.clear();

      // Debounce check
      if (_lastScanTime != null && now.difference(_lastScanTime!) < _scanDebounceDuration) {
        return;
      }

      _lastScanTime = now;
      state = state.copyWith(isProcessingFrame: true);
      _handleBarcodeDetected(rawValue, barcode.format);
    }
  }

  Future<void> _handleBarcodeDetected(String rawValue, ms.BarcodeFormat format) async {
    // Transition to Detecting
    state = state.copyWith(status: ScanState.detecting);

    // Visual confirmation pause
    await Future.delayed(const Duration(milliseconds: 200));

    // Transition to Validating
    state = state.copyWith(status: ScanState.validating);

    // Prepare to capture result from stream BEFORE processing to avoid race condition
    final resultFuture = _service.scanStream
        .firstWhere((r) => r.rawValue.contains(rawValue.replaceAll(RegExp(r'[^0-9]'), '')))
        .timeout(const Duration(seconds: 5));

    // Use service to process (logic decoupling)
    _service.processDetectedBarcode(rawValue, format);
    
    // Wait for the result
    final result = await resultFuture.catchError((e) {
      if (e is TimeoutException) {
        throw TimeoutException('Lookup failed for $rawValue');
      }
      throw e;
    });

    if (result.isValid) {
      state = state.copyWith(
        status: ScanState.completed,
        lastResult: result,
        isProcessingFrame: false,
      );
      _timeoutTimer?.cancel();
    } else {
      state = state.copyWith(
        status: ScanState.failed,
        error: ScannerError.invalidBarcode,
        isProcessingFrame: false,
      );
    }
  }

  void retryProductLookup() async {
    if (state.lastResult != null && state.lastResult!.productInfo == null) {
      state = state.copyWith(status: ScanState.validating);
      try {
        final productInfo = await _service.lookupProduct(state.lastResult!.rawValue);
        if (productInfo != null) {
          state = state.copyWith(
            lastResult: state.lastResult!.copyWith(productInfo: productInfo),
            status: ScanState.completed,
          );
        } else {
          state = state.copyWith(status: ScanState.completed);
        }
      } catch (e) {
        state = state.copyWith(status: ScanState.completed);
      }
    }
  }

  void onManualEntry(String barcode) {
    _handleBarcodeDetected(barcode, ms.BarcodeFormat.unknown);
  }

  void _startTimeoutTimer() {
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(_scanTimeout, () {
      if (state.status == ScanState.scanning && state.lastResult == null) {
        state = state.copyWith(status: ScanState.timeout);
      }
    });
  }

  void resetScanner() {
    _detectionBuffer.clear();
    _detectionTimestamps.clear();
    state = const BarcodeScanViewState(status: ScanState.scanning);
    _startTimeoutTimer();
  }

  void startBatchScan() {
    state = state.copyWith(
      lastResult: null,
      status: ScanState.scanning,
      isProcessingFrame: false,
    );
    _startTimeoutTimer();
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }
}

final barcodeScanViewModelProvider =
    StateNotifierProvider.autoDispose<BarcodeScanViewModel, BarcodeScanViewState>((ref) {
  return BarcodeScanViewModel(barcodeScannerService);
});
