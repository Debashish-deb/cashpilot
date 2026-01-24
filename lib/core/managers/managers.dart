/// Managers Barrel File
/// Export all managers for easy importing
/// 
/// Manager Architecture:
/// - AppManager: App initialization (entry point)
/// - DeviceManager: Haptics, sounds, device info (widely used)
/// - FormatManager: Date/currency formatting utilities
/// - PermissionManager: Runtime permissions
/// 
/// Note: AuthManager, SecurityManager, DataManager exist but are
/// typically accessed via their providers, not direct import.
library;

// ============================================================================
// CORE MANAGERS (commonly used across UI)
// ============================================================================

export 'device_manager.dart';
export 'format_manager.dart';
export 'permission_manager.dart';

// ============================================================================
// SPECIALIZED MANAGERS (used in specific contexts)
// Access via providers: authManagerProvider, securityManagerProvider, etc.
// ============================================================================

export 'app_manager.dart' show AppManager;
export 'analytics_manager.dart' show AnalyticsManager, analyticsManager;
export 'auth_manager.dart' show AuthManager, authManagerProvider;
export 'data_manager.dart' show DataManager, dataManagerProvider;
export 'error_manager.dart' show ErrorManager, errorManager;
export 'notification_manager.dart' show NotificationManager, notificationManager;
export 'security_manager.dart' show SecurityManager, securityManagerProvider;
