/// Application-wide constants for CashPilot
library;

class AppConstants {
  // ---------------------------------------------------------------------------
  // APP INFO
  // ---------------------------------------------------------------------------

  static const String appName = 'CashPilot';

  /// Semantic version components (single source of truth)
  static const int appVersionMajor = 1;
  static const int appVersionMinor = 0;
  static const int appVersionPatch = 0;

  /// Derived semantic version string
  static const String appVersion =
      '$appVersionMajor.$appVersionMinor.$appVersionPatch';

  // ---------------------------------------------------------------------------
  // SYNC SETTINGS
  // ---------------------------------------------------------------------------

  /// Maximum retry attempts for failed sync
  static const int maxSyncRetry = 3;

  /// Sync interval in seconds (keep conservative for battery + network)
  static const int syncIntervalSeconds = 15;

  /// Offline threshold in days before warning user
  static const int offlineThresholdDays = 7;

  /// Derived helpers
  static Duration get syncInterval =>
      Duration(seconds: syncIntervalSeconds);

  static Duration get offlineThreshold =>
      Duration(days: offlineThresholdDays);

  // ---------------------------------------------------------------------------
  // CURRENCY
  // ---------------------------------------------------------------------------

  static const String defaultCurrency = 'EUR';

  // ---------------------------------------------------------------------------
  // BUDGET THRESHOLDS
  // Order matters: SAFE < CAUTION < WARNING
  // ---------------------------------------------------------------------------

  static const double safeThreshold = 0.60;     // 0–60%  = Green
  static const double cautionThreshold = 0.85;  // 61–85% = Yellow
  static const double warningThreshold = 1.0;   // 86–100% = Orange
  // > 100% = Red

  /// Derived helpers (non-breaking)
  static bool isSafe(double ratio) => ratio <= safeThreshold;

  static bool isCaution(double ratio) =>
      ratio > safeThreshold && ratio <= cautionThreshold;

  static bool isWarning(double ratio) =>
      ratio > cautionThreshold && ratio <= warningThreshold;

  static bool isOverLimit(double ratio) => ratio > warningThreshold;

  // ---------------------------------------------------------------------------
  // OCR SETTINGS
  // ---------------------------------------------------------------------------

  /// Minimum confidence required to auto-accept OCR results
  static const double ocrConfidenceThreshold = 0.65;

  /// Max OCR processing time (guard against UI blocking)
  static const int ocrMaxProcessingTimeMs = 1200;

  static Duration get ocrTimeout =>
      Duration(milliseconds: ocrMaxProcessingTimeMs);

  // ---------------------------------------------------------------------------
  // UI / UX SETTINGS
  // ---------------------------------------------------------------------------

  /// Minimum tappable target size (Material + iOS HIG compliant)
  static const double minTapTarget = 44.0;

  /// Default animation duration
  static const int animationDurationMs = 300;

  static Duration get animationDuration =>
      Duration(milliseconds: animationDurationMs);

  // ---------------------------------------------------------------------------
  // DATABASE
  // ---------------------------------------------------------------------------

  static const String databaseName = 'cashpilot.db';

  /// V8: Added state machine columns (base_revision, operation_id)
  static const int databaseVersion = 9; // v9: Added sync state tables

  // ---------------------------------------------------------------------------
  // PAGINATION
  // ---------------------------------------------------------------------------

  static const int defaultPageSize = 20;

  // ---------------------------------------------------------------------------
  // DATE FORMATS (for intl)
  // ---------------------------------------------------------------------------

  static const String dateFormatShort = 'MMM d';
  static const String dateFormatLong = 'MMMM d, yyyy';
  static const String dateFormatFull = 'EEEE, MMMM d, yyyy';

  // ---------------------------------------------------------------------------
  // SAFETY VALIDATION (DEBUG ONLY)
  // ---------------------------------------------------------------------------

  /// Debug-only sanity checks for critical constants
  static void debugValidate() {
    assert(safeThreshold < cautionThreshold);
    assert(cautionThreshold < warningThreshold);
    assert(defaultPageSize > 0);
    assert(syncIntervalSeconds >= 10); // protect battery
    assert(minTapTarget >= 44.0);
    assert(databaseVersion > 0);
  }
}

// =============================================================================
// ENUMS
// =============================================================================

/// Supported budget types
enum BudgetType {
  monthly('monthly'),
  weekly('weekly'),
  annual('annual'),
  custom('custom'),
  event('event'),
  savings('savings');

  final String value;
  const BudgetType(this.value);

  static BudgetType fromString(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized.isEmpty) return BudgetType.monthly;
    return BudgetType.values.firstWhere(
      (e) => e.value == normalized,
      orElse: () => BudgetType.monthly,
    );
  }
}

/// Payment methods
enum PaymentMethod {
  cash('cash'),
  card('card'),
  bank('bank'),
  wallet('wallet');

  final String value;
  const PaymentMethod(this.value);

  static PaymentMethod fromString(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized.isEmpty) return PaymentMethod.cash;
    return PaymentMethod.values.firstWhere(
      (e) => e.value == normalized,
      orElse: () => PaymentMethod.cash,
    );
  }
}

/// Account types
enum AccountType {
  cash('cash'),
  bank('bank'),
  card('card'),
  wallet('wallet');

  final String value;
  const AccountType(this.value);

  static AccountType fromString(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized.isEmpty) return AccountType.cash;
    return AccountType.values.firstWhere(
      (e) => e.value == normalized,
      orElse: () => AccountType.cash,
    );
  }
}

/// Family member roles
enum MemberRole {
  owner('owner'),
  editor('editor'),
  viewer('viewer');

  final String value;
  const MemberRole(this.value);

  static MemberRole fromString(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized.isEmpty) return MemberRole.viewer;
    return MemberRole.values.firstWhere(
      (e) => e.value == normalized,
      orElse: () => MemberRole.viewer,
    );
  }
}

/// Supported languages
enum AppLanguage {
  english('en', 'English'),
  bengali('bn', 'বাংলা'),
  finnish('fi', 'Suomi');

  final String code;
  final String displayName;
  const AppLanguage(this.code, this.displayName);

  static AppLanguage fromCode(String code) {
    final normalized = code.trim().toLowerCase();
    if (normalized.isEmpty) return AppLanguage.english;
    return AppLanguage.values.firstWhere(
      (e) => e.code == normalized,
      orElse: () => AppLanguage.english,
    );
  }
}

/// Theme modes
enum AppThemeMode {
  light('light'),
  dark('dark');

  final String value;
  const AppThemeMode(this.value);

  static AppThemeMode fromString(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized.isEmpty) return AppThemeMode.light;
    return AppThemeMode.values.firstWhere(
      (e) => e.value == normalized,
      orElse: () => AppThemeMode.light,
    );
  }
}
