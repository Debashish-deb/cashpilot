/// Feature Flags
/// Controls feature availability based on build configuration
library;

import 'build_config.dart';

/// Feature flag system for CashPilot
/// 
/// Controls which features are available in different build types.
/// Features can be:
/// - Always enabled (core features)
/// - Debug/internal only (dev tools)
/// - Release only (production optimizations)
class FeatureFlags {
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // CORE FEATURES (Always Enabled)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  /// Receipt scanning (core feature)
  static const bool receiptScanning = true;
  
  /// Basic expense tracking
  static const bool expenseTracking = true;
  
  /// Budget management
  static const bool budgetManagement = true;
  
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // DEVELOPMENT FEATURES (Debug/Internal Only)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  /// ML/Analytics dashboard (dev tool)
  static bool get mlDashboard => BuildConfig.kDevFeaturesEnabled;
  
  /// A/B testing dashboard
  static bool get abTestingDashboard => BuildConfig.kDevFeaturesEnabled;
  
  /// Debug tools screen
  static bool get debugTools => BuildConfig.kDevFeaturesEnabled;
  
  /// Performance monitoring screen
  static bool get performanceMonitoring => BuildConfig.kDevFeaturesEnabled;
  
  /// Database inspector
  static bool get databaseInspector => BuildConfig.kDevFeaturesEnabled;
  
  /// Network inspector
  static bool get networkInspector => BuildConfig.kDevFeaturesEnabled;
  
  /// Error log viewer
  static bool get errorLogViewer => BuildConfig.kDevFeaturesEnabled;
  
  /// Feature flag toggle UI
  static bool get featureFlagUI => BuildConfig.kDevFeaturesEnabled;
  
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // PREMIUM FEATURES (Tier-based)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  /// Barcode scanning (Pro+)
  static const bool barcodeScanning = true; // Enabled, but tier-gated
  
  /// ML analytics (Pro+)
  static const bool mlAnalytics = true; // Enabled, but tier-gated
  
  /// Advanced reports (Pro+)
  static const bool advancedReports = true; // Enabled, but tier-gated
  
  /// Bank integration (Pro Plus)
  static const bool bankIntegration = true; // Enabled, but tier-gated
  
  /// Family sharing (Pro+)
  static const bool familySharing = true; // Enabled, but tier-gated
  
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // EXPERIMENTAL FEATURES (Can be toggled)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  /// New ML model (experimental)
  static bool get experimentalMLModel => BuildConfig.kInternalBuild;
  
  /// Currency auto-detection
  static bool get currencyAutoDetection => BuildConfig.kDevFeaturesEnabled;
  
  /// Offline ML processing
  static bool get offlineMLProcessing => BuildConfig.kInternalBuild;
  
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // PRODUCTION OPTIMIZATIONS
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  /// Enable Crashlytics reporting
  static bool get crashlyticsEnabled => BuildConfig.kProductionBuild;
  
  /// Enable Sentry reporting
  static bool get sentryEnabled => BuildConfig.kProductionBuild;
  
  /// Enable analytics
  static bool get analyticsEnabled => BuildConfig.kProductionBuild;
  
  /// Enable performance tracing
  static bool get performanceTracing => BuildConfig.kProductionBuild;
  
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // HELPER METHODS
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  /// Check if a feature is enabled by name
  static bool isEnabled(String featureName) {
    return switch (featureName.toLowerCase()) {
      'ml_dashboard' => mlDashboard,
      'ab_testing' => abTestingDashboard,
      'debug_tools' => debugTools,
      'database_inspector' => databaseInspector,
      'network_inspector' => networkInspector,
      'error_log_viewer' => errorLogViewer,
      'barcode_scanning' => barcodeScanning,
      'ml_analytics' => mlAnalytics,
      'advanced_reports' => advancedReports,
      'bank_integration' => bankIntegration,
      'family_sharing' => familySharing,
      _ => false,
    };
  }
  
  /// Get all enabled dev features
  static List<String> getEnabledDevFeatures() {
    final features = <String>[];
    
    if (mlDashboard) features.add('ML Dashboard');
    if (abTestingDashboard) features.add('A/B Testing');
    if (debugTools) features.add('Debug Tools');
    if (databaseInspector) features.add('Database Inspector');
    if (networkInspector) features.add('Network Inspector');
    if (errorLogViewer) features.add('Error Log Viewer');
    
    return features;
  }
}
