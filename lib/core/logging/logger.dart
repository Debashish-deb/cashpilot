/// Structured Logger for CashPilot
/// Replaces debugPrint with proper log levels and context
library;

import 'package:flutter/foundation.dart';

/// Log levels
enum LogLevel {
  debug(0, '🔍'),
  info(1, 'ℹ️'),
  warning(2, '⚠️'),
  error(3, '❌'),
  critical(4, '🔥');

  final int severity;
  final String emoji;
  
  const LogLevel(this.severity, this.emoji);
}

/// Log entry model
class LogEntry {
  final DateTime timestamp;
  final LogLevel level;
  final String module;
  final String message;
  final Map<String, dynamic>? context;
  final Object? error;
  final StackTrace? stackTrace;

  LogEntry({
    required this.timestamp,
    required this.level,
    required this.module,
    required this.message,
    this.context,
    this.error,
    this.stackTrace,
  });

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.write('[${timestamp.toIso8601String()}] ');
    buffer.write('${level.emoji} ${level.name.toUpperCase()} ');
    buffer.write('[$module] ');
    buffer.write(message);
    
    if (context != null && context!.isNotEmpty) {
      buffer.write(' | Context: $context');
    }
    
    if (error != null) {
      buffer.write('\n  Error: $error');
    }
    
    if (stackTrace != null) {
      final lines = stackTrace.toString().split('\n').take(3).join('\n');
      buffer.write('\n  Stack: $lines');
    }
    
    return buffer.toString();
  }

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'level': level.name,
    'module': module,
    'message': message,
    if (context != null) 'context': context,
    if (error != null) 'error': error.toString(),
    if (stackTrace != null) 'stackTrace': stackTrace.toString(),
  };
}

/// Structured Logger
class Logger {
  final String module;
  final LogLevel minLevel;
  
  static LogLevel _globalMinLevel = LogLevel.debug;
  static final List<LogEntry> _buffer = [];
  static const int _maxBufferSize = 1000;

  Logger(this.module, {this.minLevel = LogLevel.debug});

  /// Set global minimum log level
  static void setGlobalLevel(LogLevel level) {
    _globalMinLevel = level;
  }

  /// Enable file logging (Stubbed for Web Compatibility)
  static Future<void> enableFileLogging() async {
    // File logging disabled for web compatibility
    debugPrint('File logging is not supported in this version');
  }

  /// Disable file logging
  static void disableFileLogging() {
    // No-op
  }

  /// Log debug message
  void debug(String message, {Map<String, dynamic>? context}) {
    _log(LogLevel.debug, message, context: context);
  }

  /// Log info message
  void info(String message, {Map<String, dynamic>? context}) {
    _log(LogLevel.info, message, context: context);
  }

  /// Log warning
  void warning(String message, {Map<String, dynamic>? context, Object? error}) {
    _log(LogLevel.warning, message, context: context, error: error);
  }

  /// Log error
  void error(String message, {Map<String, dynamic>? context, Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.error, message, context: context, error: error, stackTrace: stackTrace);
  }

  /// Log critical error
  void critical(String message, {Map<String, dynamic>? context, Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.critical, message, context: context, error: error, stackTrace: stackTrace);
  }

  /// Internal log method
  void _log(
    LogLevel level,
    String message, {
    Map<String, dynamic>? context,
    Object? error,
    StackTrace? stackTrace,
  }) {
    // Check level filtering
    if (level.severity < minLevel.severity || level.severity < _globalMinLevel.severity) {
      return;
    }

    final entry = LogEntry(
      timestamp: DateTime.now(),
      level: level,
      module: module,
      message: message,
      context: context,
      error: error,
      stackTrace: stackTrace,
    );

    // Add to buffer
    _buffer.add(entry);
    if (_buffer.length > _maxBufferSize) {
      _buffer.removeAt(0);
    }

    // Output to console in debug mode
    if (kDebugMode) {
      debugPrint(entry.toString());
    }
  }

  /// Get recent logs
  static List<LogEntry> getRecentLogs({int limit = 100, LogLevel? minLevel}) {
    var logs = _buffer.toList();
    
    if (minLevel != null) {
      logs = logs.where((entry) => entry.level.severity >= minLevel.severity).toList();
    }
    
    return logs.reversed.take(limit).toList();
  }

  /// Clear log buffer
  static void clearLogs() {
    _buffer.clear();
  }

  /// Export logs to string
  static String exportLogs({LogLevel? minLevel}) {
    final logs = getRecentLogs(limit: _maxBufferSize, minLevel: minLevel);
    return logs.map((e) => e.toString()).join('\n');
  }
}

/// Logger factory for creating module-specific loggers
class LoggerFactory {
  static final Map<String, Logger> _loggers = {};

  static Logger getLogger(String module, {LogLevel minLevel = LogLevel.debug}) {
    return _loggers.putIfAbsent(
      module,
      () => Logger(module, minLevel: minLevel),
    );
  }
}

/// Common logger instances
class Loggers {
  static final sync = LoggerFactory.getLogger('Sync');
  static final auth = LoggerFactory.getLogger('Auth');
  static final database = LoggerFactory.getLogger('Database');
  static final network = LoggerFactory.getLogger('Network');
  static final ml = LoggerFactory.getLogger('ML');
  static final receipt = LoggerFactory.getLogger('Receipt');
  static final budget = LoggerFactory.getLogger('Budget');
  static final expense = LoggerFactory.getLogger('Expense');
  static final subscription = LoggerFactory.getLogger('Subscription');
  static final storage = LoggerFactory.getLogger('Storage');
}
