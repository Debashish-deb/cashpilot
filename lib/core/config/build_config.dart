/// Build Configuration
/// Provides compile-time and runtime configuration flags
library;

import 'package:flutter/foundation.dart';

/// Build configuration for CashPilot
/// 
/// This class provides:
/// - Environment detection (debug, release, profile)
/// - Build flavor detection (internal builds)
/// - Feature toggles based on build type
class BuildConfig {
  /// Whether this is an internal build (for developers/QA)
  /// 
  /// Set via dart-define:
  /// flutter run --dart-define=INTERNAL_BUILD=true
  static const bool kInternalBuild = bool.fromEnvironment(
    'INTERNAL_BUILD',
    defaultValue: false,
  );
  
  /// Whether developer features should be enabled
  /// 
  /// Enabled in:
  /// - Debug builds
  /// - Internal builds
  /// 
  /// Disabled in:
  /// - Release builds (unless INTERNAL_BUILD=true)
  static const bool kDevFeaturesEnabled = kDebugMode || kInternalBuild;
  
  /// Whether this is a production build
  static const bool kProductionBuild = kReleaseMode && !kInternalBuild;
  
  /// App version (from dart-define or default)
  static const String appVersion = String.fromEnvironment(
    'APP_VERSION',
    defaultValue: '1.0.0',
  );
  
  /// Build number (from dart-define or default)
  static const String buildNumber = String.fromEnvironment(
    'BUILD_NUMBER',
    defaultValue: '1',
  );
  
  /// Environment name
  static String get environmentName {
    if (kProductionBuild) return 'production';
    if (kInternalBuild) return 'internal';
    if (kReleaseMode) return 'release';
    if (kProfileMode) return 'profile';
    return 'debug';
  }
  
  /// Whether to show debug info in UI
  static bool get showDebugInfo => kDevFeaturesEnabled;
  
  /// Whether to allow test/dev routes
  static bool get allowDevRoutes => kDevFeaturesEnabled;
  
  /// Whether to enable verbose logging
  static bool get verboseLogging => kDebugMode;
  
  /// Whether to enable performance overlay
  static bool get enablePerformanceOverlay => kDebugMode && !kInternalBuild;
  
  /// Log configuration on startup
  static void logConfiguration() {
    if (kDebugMode) {
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('🔧 Build Configuration');
      debugPrint('   Environment: $environmentName');
      debugPrint('   Version: $appVersion ($buildNumber)');
      debugPrint('   Debug Mode: $kDebugMode');
      debugPrint('   Release Mode: $kReleaseMode');
      debugPrint('   Profile Mode: $kProfileMode');
      debugPrint('   Internal Build: $kInternalBuild');
      debugPrint('   Dev Features: $kDevFeaturesEnabled');
      debugPrint('   Production: $kProductionBuild');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    }
  }
}
