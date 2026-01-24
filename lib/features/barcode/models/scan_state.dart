/// Formal scanning states for the barcode scanner FSM
enum ScanState {
  /// Scanner is initialized but not yet looking for barcodes
  idle,

  /// Active search for barcodes in the camera frame
  scanning,

  /// A potential barcode has been detected but not yet processed
  detecting,

  /// Barcode is being validated and product lookup is in progress
  validating,

  /// Scan successful and result processed
  completed,

  /// Scan failed (parsing error or product not found in mandatory mode)
  failed,

  /// Scanner timed out (no barcode found within window)
  timeout
}

/// Specific error types for the scanner
enum ScannerError {
  permissionDenied,
  cameraUnavailable,
  cameraFailure,
  decodingFailure,
  unknown, invalidBarcode
}
