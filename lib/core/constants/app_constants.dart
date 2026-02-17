/// Application-wide constants for CashPilot
library;

import 'dart:math' as math;

// APP CONSTANTS

class AppConstants {
  // APP INFO

  static const String appName = 'CashPilot';

  /// Semantic version components (single source of truth)
  static const int appVersionMajor = 1;
  static const int appVersionMinor = 0;
  static const int appVersionPatch = 0;

  /// Derived semantic version string
  static const String appVersion =
      '$appVersionMajor.$appVersionMinor.$appVersionPatch';

  /// Structured version tuple (safe for comparisons)
  static const List<int> appVersionTuple = [
    appVersionMajor,
    appVersionMinor,
    appVersionPatch,
  ];

  // SYNC SETTINGS

  /// Maximum retry attempts for failed sync
  static const int maxSyncRetry = 3;

  /// Sync interval in seconds (battery + network safe)
  static const int syncIntervalSeconds = 15;

  /// Offline threshold in days before warning user
  static const int offlineThresholdDays = 7;

  /// Derived helpers
  static Duration get syncInterval =>
      Duration(seconds: syncIntervalSeconds);

  static Duration get offlineThreshold =>
      Duration(days: offlineThresholdDays);

  /// Defensive sync validation
  static bool isValidSyncInterval(int seconds) =>
      seconds >= 10 && seconds <= 300;

  // CURRENCY


  static const String defaultCurrency = 'EUR';

  
  // BUDGET THRESHOLDS


  static const double safeThreshold = 0.60;     // Green
  static const double cautionThreshold = 0.85;  // Yellow
  static const double warningThreshold = 1.0;   // Orange
  // > 100% = Red

  /// Defensive ratio normalization
  static double clampRatio(double ratio) =>
      ratio.isNaN ? 0.0 : ratio.clamp(0.0, 10.0);

  static bool isSafe(double ratio) =>
      clampRatio(ratio) <= safeThreshold;

  static bool isCaution(double ratio) {
    final r = clampRatio(ratio);
    return r > safeThreshold && r <= cautionThreshold;
  }

  static bool isWarning(double ratio) {
    final r = clampRatio(ratio);
    return r > cautionThreshold && r <= warningThreshold;
  }

  static bool isOverLimit(double ratio) =>
      clampRatio(ratio) > warningThreshold;

  // OCR SETTINGS

  /// Minimum confidence required to auto-accept OCR results
  static const double ocrConfidenceThreshold = 0.65;

  /// Max OCR processing time (prevent UI blocking)
  static const int ocrMaxProcessingTimeMs = 1200;

  static Duration get ocrTimeout =>
      Duration(milliseconds: ocrMaxProcessingTimeMs);

  static bool isValidOcrConfidence(double value) =>
      value >= 0.0 && value <= 1.0;

  static bool shouldAutoAcceptOcr(double confidence) =>
      isValidOcrConfidence(confidence) &&
      confidence >= ocrConfidenceThreshold;

  // UI / UX SETTINGS

  /// Minimum tappable target size (Material + iOS HIG)
  static const double minTapTarget = 44.0;

  /// Default animation duration
  static const int animationDurationMs = 300;

  static Duration get animationDuration =>
      Duration(milliseconds: animationDurationMs);

  static Duration get animationFast =>
      const Duration(milliseconds: 180);

  static Duration get animationSlow =>
      const Duration(milliseconds: 450);

  // DATABASE

  static const String databaseName = 'cashpilot.db';

  /// V25: Precision Overhaul Fix (Missing columns in migration)
  static const int databaseVersion = 25;

  // PAGINATION

  static const int defaultPageSize = 20;

  static int clampPageSize(int requested) =>
      math.max(1, math.min(requested, 100));

  // DATE FORMATS (intl)

  static const String dateFormatShort = 'MMM d';
  static const String dateFormatLong = 'MMMM d, yyyy';
  static const String dateFormatFull = 'EEEE, MMMM d, yyyy';

  // FEATURE FLAGS

  static const bool enableExperimentalOcr = false;
  static const bool enableRealtimeSync = true;
  static const bool enableBudgetHealthSnapshots = true;

  // DEBUG VALIDATION

  static void debugValidate() {
    assert(safeThreshold < cautionThreshold);
    assert(cautionThreshold < warningThreshold);
    assert(defaultPageSize > 0);
    assert(syncIntervalSeconds >= 10);
    assert(minTapTarget >= 44.0);
    assert(databaseVersion > 0);
    assert(isValidOcrConfidence(ocrConfidenceThreshold));
  }
}

// ENUMS

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

extension BudgetTypeX on BudgetType {
  bool get isRecurring =>
      this == BudgetType.monthly ||
      this == BudgetType.weekly ||
      this == BudgetType.annual;

  bool get isSavings => this == BudgetType.savings;
}

// ---------------------------------------------------------------------------

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

extension PaymentMethodX on PaymentMethod {
  bool get isDigital =>
      this == PaymentMethod.card ||
      this == PaymentMethod.bank ||
      this == PaymentMethod.wallet;
}

// ---------------------------------------------------------------------------

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

extension AccountTypeX on AccountType {
  bool get isLiquid => this != AccountType.card;
}

// ---------------------------------------------------------------------------

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

extension MemberRoleX on MemberRole {
  bool get canEdit =>
      this == MemberRole.owner || this == MemberRole.editor;

  bool get isOwner => this == MemberRole.owner;
}

// ---------------------------------------------------------------------------

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

extension AppLanguageX on AppLanguage {
  bool get isRtl => false; // future-proof
}

// ---------------------------------------------------------------------------

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

extension AppThemeModeX on AppThemeMode {
  bool get isDark => this == AppThemeMode.dark;
}
