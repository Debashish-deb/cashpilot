/// Application Logger
/// Centralized logging system for events, errors, and analytics
library;

import 'package:flutter/foundation.dart';
import '../../services/crash_reporting_service.dart';
import '../../services/analytics_service.dart';

/// Log level
enum LogLevel {
  debug,
  info,
  warning,
  error,
  critical,
}

/// Log category for filtering
enum LogCategory {
  subscription,
  analytics,
  sync,
  payment,
  feature,
  system,
}

/// Application logger
class AppLogger {
  static final AppLogger _instance = AppLogger._internal();
  factory AppLogger() => _instance;
  AppLogger._internal();

  final List<LogEntry> _logs = [];
  static const int _maxLogs = 1000;

  /// Log a message
  void log(
    String message, {
    LogLevel level = LogLevel.info,
    LogCategory category = LogCategory.system,
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
  }) {
    final entry = LogEntry(
      message: message,
      level: level,
      category: category,
      timestamp: DateTime.now(),
      error: error,
      stackTrace: stackTrace,
      metadata: metadata,
    );

    // Add to in-memory log
    _logs.add(entry);
    if (_logs.length > _maxLogs) {
      _logs.removeAt(0);
    }

    // Print in debug mode
    if (kDebugMode) {
      _printLog(entry);
    }

    // Send critical errors to crash reporting (fire-and-forget)
    if (level == LogLevel.critical || level == LogLevel.error) {
      crashReporter.logException(
        error ?? message,
        stackTrace: stackTrace,
        context: category.name,
        extras: metadata,
      ).catchError((_) {
        // Crash reporting failed, but don't crash the app
      });
    }

    // Send important events to analytics (when analytics is implemented)
    if (category == LogCategory.subscription || 
        category == LogCategory.payment ||
        category == LogCategory.feature) {
      analyticsService.logEvent(
        '${category.name}_${level.name}',
        parameters: {
          'message': message,
          if (metadata != null) ...metadata,
        },
      );
    }
  }

  /// Print formatted log entry
  void _printLog(LogEntry entry) {
    final levelName = _getMaxLevelName(entry.level);
    final prefix = '[$levelName ${entry.category.name.toUpperCase()}]';
    
    debugPrint('$prefix ${entry.message}');
    
    if (entry.error != null) {
      debugPrint('  Error: ${entry.error}');
    }
    
    if (entry.stackTrace != null && kDebugMode) {
      debugPrint('  Stack: ${entry.stackTrace}');
    }
    
    if (entry.metadata != null) {
      debugPrint('  Metadata: ${entry.metadata}');
    }
  }

  String _getMaxLevelName(LogLevel level) {
    return switch (level) {
      LogLevel.debug => 'DEBUG',
      LogLevel.info => 'INFO',
      LogLevel.warning => 'WARNING',
      LogLevel.error => 'ERROR',
      LogLevel.critical => 'CRITICAL',
    };
  }

  /// Get recent logs
  List<LogEntry> getRecentLogs({int count = 100, LogLevel? minLevel}) {
    var filtered = _logs;
    
    if (minLevel != null) {
      final minIndex = LogLevel.values.indexOf(minLevel);
      filtered = filtered.where((log) {
        return LogLevel.values.indexOf(log.level) >= minIndex;
      }).toList();
    }
    
    return filtered.reversed.take(count).toList();
  }

  /// Debug helpers
  void debug(String message, {LogCategory? category, Map<String, dynamic>? metadata}) {
    log(message, level: LogLevel.debug, category: category ?? LogCategory.system, metadata: metadata);
  }

  void info(String message, {LogCategory? category, Map<String, dynamic>? metadata}) {
    log(message, level: LogLevel.info, category: category ?? LogCategory.system, metadata: metadata);
  }

  void warning(String message, {LogCategory? category, Map<String, dynamic>? metadata, Object? error}) {
    log(message, level: LogLevel.warning, category: category ?? LogCategory.system, metadata: metadata, error: error);
  }

  void error(String message, {LogCategory? category, Object? error, StackTrace? stackTrace, Map<String, dynamic>? metadata}) {
    log(message, level: LogLevel.error, category: category ?? LogCategory.system, error: error, stackTrace: stackTrace, metadata: metadata);
  }

  void critical(String message, {LogCategory? category, Object? error, StackTrace? stackTrace, Map<String, dynamic>? metadata}) {
    log(message, level: LogLevel.critical, category: category ?? LogCategory.system, error: error, stackTrace: stackTrace, metadata: metadata);
  }
}

/// Log entry
class LogEntry {
  final String message;
  final LogLevel level;
  final LogCategory category;
  final DateTime timestamp;
  final Object? error;
  final StackTrace? stackTrace;
  final Map<String, dynamic>? metadata;

  const LogEntry({
    required this.message,
    required this.level,
    required this.category,
    required this.timestamp,
    this.error,
    this.stackTrace,
    this.metadata,
  });
}

/// Global logger instance
final logger = AppLogger();
