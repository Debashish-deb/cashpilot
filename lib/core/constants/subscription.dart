
library;

/// Subscription tier levels (aligned with payment plan)
enum SubscriptionTier {
  free('free'),       // 🆓 Basic personal budgeting with local control
  pro('pro'),         // ⭐ Advanced personal finance, insights, automation
  proPlus('pro_plus'); // 🚀 Families, shared budgets, banking, full automation

  final String value;
  const SubscriptionTier(this.value);

  static SubscriptionTier fromString(String value) {
    return SubscriptionTier.values.firstWhere(
      (e) => e.value == value,
      orElse: () => SubscriptionTier.free,
    );
  }

  /// Display name for UI
  String get displayName => switch (this) {
    SubscriptionTier.free => 'Free',
    SubscriptionTier.pro => 'Pro',
    SubscriptionTier.proPlus => 'Pro+',
  };

  /// Emoji icon for tier
  String get emoji => switch (this) {
    SubscriptionTier.free => '🆓',
    SubscriptionTier.pro => '⭐',
    SubscriptionTier.proPlus => '🚀',
  };
}

/// Subscription status
enum SubscriptionStatus {
  active('active'),
  expired('expired'),
  canceled('canceled'),
  gracePeriod('grace_period');

  final String value;
  const SubscriptionStatus(this.value);

  static SubscriptionStatus fromString(String value) {
    return SubscriptionStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => SubscriptionStatus.active,
    );
  }
}

/// Features that can be gated (aligned with payment plan table)
enum Feature {
  // Core Features (1-3)
  accountCreation,         
  biometricAuth,         
  multiColorTheme,        

  // Budget Features (4-5)
  familyBudgetMode,        
  budgetPeriods,     

  // Account Mode (6)
  expertModeFull,         

  // Sync Features (7-11)
  cloudSync,             
  multiDeviceSync,         
  dataProtection,       
  dataLossPrevention,    
  localOnlyStorage,  

  // Export Features (12-13)
  fullDataExport,          
  accountDeletion,          

  // Analytics (14-15)
  categoryDetailedAnalytics, 
  predictionsInsights,     

  // Scanning (16-18)
  ocrScanning,        
  receiptScanning,          
  manualExpenseEntry,       

  // Connectivity (19)
  bankConnectivity,         

  // Other (20-24)
  multiLanguage,           
  prioritySupport,         
  familyBudgetCreation,  
  inviteFreeUsersToFamily, 
  realTimeCurrencyConversion, 
}

/// Subscription Manager - Single source of truth for feature gating

class SubscriptionManager {
  // ================================================================
  // QUANTITATIVE LIMITS
  // ================================================================

  /// Max budgets per tier
  static int maxBudgets(SubscriptionTier tier) => switch (tier) {
    SubscriptionTier.free => 1,  
    _ => -1,                    
  };

  /// Max expenses per tier 
  static int maxExpenses(SubscriptionTier tier) => switch (tier) {
    SubscriptionTier.free => 500,
    _ => -1, 
  };

  /// OCR scans per month
  /// Free: 0, Pro: Limited (10/month), Pro Plus: Unlimited
  static int ocrScansPerMonth(SubscriptionTier tier) => switch (tier) {
    SubscriptionTier.free => 0,
    SubscriptionTier.pro => 10,    // Limited monthly cap
    SubscriptionTier.proPlus => -1, // Unlimited
  };

  /// Export data range in months
  /// Free: 3 months max, Pro+: Full/Custom
  static int exportDataMonthsLimit(SubscriptionTier tier) => switch (tier) {
    SubscriptionTier.free => 3,
    _ => -1, // Unlimited (full)
  };

  /// Max bank accounts per tier
  static int maxBankAccounts(SubscriptionTier tier) => switch (tier) {
    SubscriptionTier.free => 1,
    SubscriptionTier.pro => 2,
    SubscriptionTier.proPlus => 5,
  };

  /// Bank sync interval in hours
  static int bankSyncIntervalHours(SubscriptionTier tier) => switch (tier) {
    SubscriptionTier.proPlus => 24,
    SubscriptionTier.pro => 48,
    SubscriptionTier.free => 72,
  };

  /// Bank sync retry interval in hours (after failure)
  static int bankSyncRetryIntervalHours(SubscriptionTier tier) => switch (tier) {
    SubscriptionTier.free => 12,
    _ => 6, // Pro and Pro+
  };

  /// Priority level for bank connections (higher is better)
  static int bankSyncPriority(SubscriptionTier tier) => switch (tier) {
    SubscriptionTier.proPlus => 10,
    SubscriptionTier.pro => 5,
    SubscriptionTier.free => 1,
  };

  // FEATURE ACCESS CHECKS (Based on payment plan table)

  // Row 1-2: Account Creation & Biometric - All tiers
  static bool canUseAccountCreation(SubscriptionTier tier) => true;
  static bool canUseBiometricAuth(SubscriptionTier tier) => true;

  // Row 3: Multi-Color Theme Mode - Pro + Pro Plus only
  static bool canUseMultiColorTheme(SubscriptionTier tier) =>
      tier != SubscriptionTier.free;

  // Row 4: Budget Mode Support

  static bool canUseFamilyBudgetMode(SubscriptionTier tier) =>
      tier == SubscriptionTier.proPlus;

  // Row 5: Budget Periods - All tiers
  static bool canUseBudgetPeriods(SubscriptionTier tier) => true;

  // Row 6: Account Mode (Expert mode)

  static bool hasFullExpertMode(SubscriptionTier tier) =>
      tier != SubscriptionTier.free;

  // Row 7: Cloud Sync - Pro + Pro Plus
  static bool canUseCloudSync(SubscriptionTier tier) =>
      tier != SubscriptionTier.free;

  // Row 8: Multi-Device Support - Pro + Pro Plus
  static bool canUseMultiDeviceSync(SubscriptionTier tier) =>
      tier != SubscriptionTier.free;

  // Row 9: Data Protection - All tiers
  static bool hasDataProtection(SubscriptionTier tier) => true;

  // Row 10: Data Loss Prevention
  /// Free: Partial, Pro+: Full
  static bool hasFullDataLossPrevention(SubscriptionTier tier) =>
      tier != SubscriptionTier.free;

  // Row 11: Data Storage
  /// Free: Local only, Pro+: Local + Cloud
  static bool hasCloudStorage(SubscriptionTier tier) =>
      tier != SubscriptionTier.free;

  // Row 12: Data Download / Export
  
  static bool hasFullExportAccess(SubscriptionTier tier) =>
      tier != SubscriptionTier.free;

  // Row 13: Account Deletion - All tiers
  static bool canDeleteAccount(SubscriptionTier tier) => true;

  // Row 14: Category-Level Detailed Analytics - Pro + Pro Plus
  static bool canUseCategoryAnalytics(SubscriptionTier tier) =>
      tier != SubscriptionTier.free;

  // Row 15: Predictions & Insights
  /// Free: Limited, Pro+: Full
  static bool hasFullPredictions(SubscriptionTier tier) =>
      tier != SubscriptionTier.free;

  // Row 16: OCR (Text Recognition)
  static bool canUseOCR(SubscriptionTier tier) =>
      tier != SubscriptionTier.free;

  // Row 17: Receipt Scanning - Pro + Pro Plus
  static bool canUseReceiptScanning(SubscriptionTier tier) =>
      tier != SubscriptionTier.free;

  // Row 18: Manual Expense Entry - All tiers
  static bool canUseManualExpenseEntry(SubscriptionTier tier) => true;

  // Row 19: Bank Connectivity - All tiers (with tiered limits)
  static bool canUseBankConnectivity(SubscriptionTier tier) => true;

  // Row 20: Multi-Language Support - All tiers
  static bool canUseMultiLanguage(SubscriptionTier tier) => true;

  // Row 21: Technical Support
  static bool hasPrioritySupport(SubscriptionTier tier) =>
      tier != SubscriptionTier.free;

  // Row 22: Family Budget Creation - Pro Plus only
  static bool canCreateFamilyBudget(SubscriptionTier tier) =>
      tier == SubscriptionTier.proPlus;

  // Row 23: Invite Free Users to Family Budget - Pro Plus only
  static bool canInviteFreeUsersToFamily(SubscriptionTier tier) =>
      tier == SubscriptionTier.proPlus;

  // Row 24: Real-Time Currency Conversion - Pro + Pro Plus
  static bool canUseRealTimeCurrency(SubscriptionTier tier) =>
      tier != SubscriptionTier.free;


  /// Check if user can use a feature
  static bool canUseFeature(SubscriptionTier tier, Feature feature) {
    return switch (feature) {
      Feature.accountCreation => canUseAccountCreation(tier),
      Feature.biometricAuth => canUseBiometricAuth(tier),
      Feature.multiColorTheme => canUseMultiColorTheme(tier),
      Feature.familyBudgetMode => canUseFamilyBudgetMode(tier),
      Feature.budgetPeriods => canUseBudgetPeriods(tier),
      Feature.expertModeFull => hasFullExpertMode(tier),
      Feature.cloudSync => canUseCloudSync(tier),
      Feature.multiDeviceSync => canUseMultiDeviceSync(tier),
      Feature.dataProtection => hasDataProtection(tier),
      Feature.dataLossPrevention => hasFullDataLossPrevention(tier),
      Feature.localOnlyStorage => tier == SubscriptionTier.free,
      Feature.fullDataExport => hasFullExportAccess(tier),
      Feature.accountDeletion => canDeleteAccount(tier),
      Feature.categoryDetailedAnalytics => canUseCategoryAnalytics(tier),
      Feature.predictionsInsights => hasFullPredictions(tier),
      Feature.ocrScanning => canUseOCR(tier),
      Feature.receiptScanning => canUseReceiptScanning(tier),
      Feature.manualExpenseEntry => canUseManualExpenseEntry(tier),
      Feature.bankConnectivity => canUseBankConnectivity(tier),
      Feature.multiLanguage => canUseMultiLanguage(tier),
      Feature.prioritySupport => hasPrioritySupport(tier),
      Feature.familyBudgetCreation => canCreateFamilyBudget(tier),
      Feature.inviteFreeUsersToFamily => canInviteFreeUsersToFamily(tier),
      Feature.realTimeCurrencyConversion => canUseRealTimeCurrency(tier),
    };
  }



  /// Get user-friendly feature name
  static String getFeatureName(Feature feature) {
    return switch (feature) {
      Feature.accountCreation => 'Account Creation',
      Feature.biometricAuth => 'Biometric Authentication',
      Feature.multiColorTheme => 'Multi-Color Themes',
      Feature.familyBudgetMode => 'Family Budget Mode',
      Feature.budgetPeriods => 'Budget Periods',
      Feature.expertModeFull => 'Full Expert Mode',
      Feature.cloudSync => 'Cloud Sync',
      Feature.multiDeviceSync => 'Multi-Device Support',
      Feature.dataProtection => 'Data Protection',
      Feature.dataLossPrevention => 'Data Loss Prevention',
      Feature.localOnlyStorage => 'Local Storage',
      Feature.fullDataExport => 'Full Data Export',
      Feature.accountDeletion => 'Account Deletion',
      Feature.categoryDetailedAnalytics => 'Detailed Analytics',
      Feature.predictionsInsights => 'AI Predictions & Insights',
      Feature.ocrScanning => 'OCR Receipt Scanning',
      Feature.receiptScanning => 'Receipt Scanning',
      Feature.manualExpenseEntry => 'Manual Expense Entry',
      Feature.bankConnectivity => 'Bank Connectivity',
      Feature.multiLanguage => 'Multi-Language Support',
      Feature.prioritySupport => 'Priority Support',
      Feature.familyBudgetCreation => 'Create Family Budgets',
      Feature.inviteFreeUsersToFamily => 'Invite Free Users',
      Feature.realTimeCurrencyConversion => 'Real-Time Currency Conversion',
    };
  }

  /// Get feature description for paywall
  static String getFeatureDescription(Feature feature) {
    return switch (feature) {
      Feature.accountCreation => 'Create and manage your account',
      Feature.biometricAuth => 'Secure login with fingerprint or face',
      Feature.multiColorTheme => 'Personalize your app with multiple themes',
      Feature.familyBudgetMode => 'Share budgets with family members',
      Feature.budgetPeriods => 'Weekly, monthly, annual, or custom periods',
      Feature.expertModeFull => 'Access advanced controls and settings',
      Feature.cloudSync => 'Sync your data across all devices',
      Feature.multiDeviceSync => 'Access from phone, tablet, and desktop',
      Feature.dataProtection => 'Your data is encrypted and secure',
      Feature.dataLossPrevention => 'Automatic backups to prevent data loss',
      Feature.localOnlyStorage => 'Data stored only on your device',
      Feature.fullDataExport => 'Export all your data anytime',
      Feature.accountDeletion => 'Delete your account and all data',
      Feature.categoryDetailedAnalytics => 'Deep insights by spending category',
      Feature.predictionsInsights => 'AI-powered spending predictions',
      Feature.ocrScanning => 'Scan receipts to auto-extract amounts',
      Feature.receiptScanning => 'Capture and store receipt images',
      Feature.manualExpenseEntry => 'Add expenses manually',
      Feature.bankConnectivity => 'Connect your bank accounts directly',
      Feature.multiLanguage => 'Use the app in your preferred language',
      Feature.prioritySupport => 'Get faster responses from our team',
      Feature.familyBudgetCreation => 'Create budgets the whole family can use',
      Feature.inviteFreeUsersToFamily => 'Invite free users to join your budget',
      Feature.realTimeCurrencyConversion => 'Auto-convert expenses to your base currency',
    };
  }

  /// Get the icon for a feature
  static String getFeatureIcon(Feature feature) {
    return switch (feature) {
      Feature.accountCreation => 'person_add',
      Feature.biometricAuth => 'fingerprint',
      Feature.multiColorTheme => 'palette',
      Feature.familyBudgetMode => 'family_restroom',
      Feature.budgetPeriods => 'calendar_month',
      Feature.expertModeFull => 'tune',
      Feature.cloudSync => 'cloud_sync',
      Feature.multiDeviceSync => 'devices',
      Feature.dataProtection => 'security',
      Feature.dataLossPrevention => 'backup',
      Feature.localOnlyStorage => 'folder',
      Feature.fullDataExport => 'download',
      Feature.accountDeletion => 'delete_forever',
      Feature.categoryDetailedAnalytics => 'analytics',
      Feature.predictionsInsights => 'insights',
      Feature.ocrScanning => 'document_scanner',
      Feature.receiptScanning => 'receipt_long',
      Feature.manualExpenseEntry => 'edit_note',
      Feature.bankConnectivity => 'account_balance',
      Feature.multiLanguage => 'translate',
      Feature.prioritySupport => 'support_agent',
      Feature.familyBudgetCreation => 'group_add',
      Feature.inviteFreeUsersToFamily => 'person_add',
      Feature.realTimeCurrencyConversion => 'currency_exchange',
    };
  }
}

/// Plan pricing configuration
class PlanPricing {
  // Pro Plan
  static const double proMonthly = 0.99;
  static const double proYearly = 10.99;
  static const int proYearlySavingsPercent = 8; // ~8% savings

  // Pro Plus Plan
  static const double proPlusMonthly = 1.99;
  static const double proPlusYearly = 21.99;
  static const int proPlusYearlySavingsPercent = 8;

  /// Get formatted price string
  static String formatPrice(double price, {String currency = '€'}) {
    return '$currency${price.toStringAsFixed(2)}';
  }
}

/// Trial configuration
class TrialConfig {
  static const int trialDurationDays = 14;
  static const int gracePeriodDays = 7;
  static const int dataRetentionDays = 30;
}

/// Family Budget Rules (from payment plan)
class FamilyBudgetRules {
  /// Only Pro Plus users can create Family Budgets
  static bool canCreateFamilyBudget(SubscriptionTier tier) =>
      tier == SubscriptionTier.proPlus;

  /// Pro users cannot create or join family budgets
  static bool canJoinFamilyBudget(SubscriptionTier tier) =>
      tier == SubscriptionTier.proPlus || tier == SubscriptionTier.free;

  /// Free users can only join if invited by Pro Plus
  /// When a Free user joins:
  /// - They receive limited cloud sync (shared family budget data only)
  /// - Access lasts only while they are a member
  /// - Personal cloud sync still disabled
  /// - Multi-device sync for personal budgets still disabled
  /// - Leaving the family budget instantly revokes cloud access
  static bool freeUserHasFamilyCloudAccess(bool isMemberOfProPlusFamily) =>
      isMemberOfProPlusFamily;
}

/// Currency Conversion Rules (from payment plan)
class CurrencyConversionRules {
  /// Available in Pro and Pro Plus only
  static bool isAvailable(SubscriptionTier tier) =>
      tier != SubscriptionTier.free;

  /// Uses live exchange rates (daily refresh minimum)
  static const Duration refreshInterval = Duration(hours: 24);

  /// Original currency is always preserved
  /// Historical data remains accurate (no retroactive distortion)
}
