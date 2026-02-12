import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'trace_manager.dart';

enum LogLevel { info, warn, error, debug }

class LogService {
  static final LogService _instance = LogService._internal();
  factory LogService() => _instance;
  LogService._internal();

  /// Logs a structured message.
  /// 
  /// [message]: The main log message.
  /// [level]: Severity level.
  /// [span]: Optional TraceSpan to correlate this log with a specific operation.
  /// [context]: Additional key-value pairs.
  /// [error]: Optional error object.
  /// [stackTrace]: Optional stack trace.
  void log(
    String message, {
    LogLevel level = LogLevel.info,
    TraceSpan? span,
    Map<String, dynamic>? context,
    Object? error,
    StackTrace? stackTrace,
  }) {
    final logEntry = {
      'timestamp': DateTime.now().toIso8601String(),
      'level': level.name.toUpperCase(),
      'message': message,
      if (span != null) 'trace_id': span.traceId,
      if (span != null) 'span_id': span.spanId,
      if (context != null) 'context': context,
      if (error != null) 'error': error.toString(),
      if (stackTrace != null) 'stack_trace': stackTrace.toString(),
    };

    // Serialize to JSON for machine readability
    final jsonLog = jsonEncode(logEntry);

    // Output
    if (kDebugMode) {
      // In debug mode, we might want a prettier print, but standardizing on JSON is good for tools.
      // We prefix with [LOG] to easily grep using 'flutter logs'.
      print('[LOG] $jsonLog');
    } else {
      // In production, this would go to a file or remote service (Datadog/Sentry).
      print(jsonLog);
    }
  }

  void info(String message, {TraceSpan? span, Map<String, dynamic>? context, Object? error, StackTrace? stackTrace}) {
    log(message, level: LogLevel.info, span: span, context: context, error: error, stackTrace: stackTrace);
  }

  void warn(String message, {TraceSpan? span, Map<String, dynamic>? context, Object? error, StackTrace? stackTrace}) {
    log(message, level: LogLevel.warn, span: span, context: context, error: error, stackTrace: stackTrace);
  }

  void error(String message, {TraceSpan? span, Object? error, StackTrace? stackTrace, Map<String, dynamic>? context}) {
    log(message, level: LogLevel.error, span: span, context: context, error: error, stackTrace: stackTrace);
  }
}
