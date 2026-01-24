/// Operation Result model for controller responses
library;

enum OperationStatus {
  success,
  failure,
  partial,
  cancelled,
  pending,
}

/// Restore mode options
enum RestoreMode {
  /// Replace all existing data with backup
  replace,
  /// Merge backup with existing data (upsert by ID)
  merge,
}

class OperationResult<T> {
  final OperationStatus status;
  final String? message;
  final T? data;
  final Object? error;
  final DateTime timestamp;

  OperationResult({
    required this.status,
    this.message,
    this.data,
    this.error,
  }) : timestamp = DateTime.now();

  bool get isSuccess => status == OperationStatus.success;
  bool get isFailure => status == OperationStatus.failure;
  bool get isPartial => status == OperationStatus.partial;

  factory OperationResult.success({String? message, T? data}) => OperationResult(
        status: OperationStatus.success,
        message: message,
        data: data,
      );

  factory OperationResult.failure({String? message, Object? error}) => OperationResult(
        status: OperationStatus.failure,
        message: message,
        error: error,
      );

  factory OperationResult.partial({String? message, T? data, Object? error}) => OperationResult(
        status: OperationStatus.partial,
        message: message,
        data: data,
        error: error,
      );
}

/// Delete account result
class DeleteAccountResult extends OperationResult<void> {
  final bool cloudWiped;
  final bool localWiped;
  final bool keysWiped;

  DeleteAccountResult({
    required super.status,
    super.message,
    super.error,
    this.cloudWiped = false,
    this.localWiped = false,
    this.keysWiped = false,
  });
}

/// Backup file analysis result (for restore preview)
class BackupFileResult extends OperationResult<String> {
  final String? filePath;
  final int itemCount;
  final int sizeBytes;
  
  /// Manifest data from backup
  final Map<String, dynamic> manifest;
  
  /// Entity counts
  final int budgetCount;
  final int accountCount;
  final int expenseCount;
  final int categoryCount;
  
  /// Whether checksum validated
  final bool checksumValid;

  BackupFileResult({
    required super.status,
    super.message,
    super.error,
    this.filePath,
    this.itemCount = 0,
    this.sizeBytes = 0,
    this.manifest = const {},
    this.budgetCount = 0,
    this.accountCount = 0,
    this.expenseCount = 0,
    this.categoryCount = 0,
    this.checksumValid = false,
  }) : super(data: filePath);
}

/// Restore plan result
class RestorePlan {
  final int budgetCount;
  final int expenseCount;
  final int accountCount;
  final int categoryCount;
  final String? backupVersion;
  final DateTime? backupDate;
  final bool isCompatible;
  final List<String> warnings;

  RestorePlan({
    this.budgetCount = 0,
    this.expenseCount = 0,
    this.accountCount = 0,
    this.categoryCount = 0,
    this.backupVersion,
    this.backupDate,
    this.isCompatible = true,
    this.warnings = const [],
  });

  int get totalItems => budgetCount + expenseCount + accountCount + categoryCount;
}

/// Restore result
class RestoreResult extends OperationResult<RestoreReport> {
  RestoreResult({
    required super.status,
    super.message,
    super.error,
    RestoreReport? report,
  }) : super(data: report);
}

class RestoreReport {
  final int budgetsRestored;
  final int expensesRestored;
  final int accountsRestored;
  final int categoriesRestored;
  final int orphansFixed;
  final List<String> warnings;

  RestoreReport({
    this.budgetsRestored = 0,
    this.expensesRestored = 0,
    this.accountsRestored = 0,
    this.categoriesRestored = 0,
    this.orphansFixed = 0,
    this.warnings = const [],
  });
}

/// Currency change result
class CurrencyChangeResult {
  final int budgetsUpdated;
  final int accountsUpdated;
  final String fromCurrency;
  final String toCurrency;

  CurrencyChangeResult({
    this.budgetsUpdated = 0,
    this.accountsUpdated = 0,
    this.fromCurrency = '',
    this.toCurrency = '',
  });
}
