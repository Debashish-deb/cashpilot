import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';

/// Represents a single unit of work in a trace.
class TraceSpan {
  final String traceId;
  final String spanId;
  final String name;
  final DateTime startTime;
  DateTime? endTime;
  final Map<String, dynamic> attributes;
  final String? parentSpanId;

  TraceSpan({
    required this.traceId,
    required this.name,
    required this.spanId,
    this.parentSpanId,
    Map<String, dynamic>? attributes,
  }) : startTime = DateTime.now(),
       attributes = attributes ?? {};

  void end() {
    endTime = DateTime.now();
  }

  void addAttribute(String key, dynamic value) {
    attributes[key] = value;
  }

  Duration get duration => (endTime ?? DateTime.now()).difference(startTime);

  Map<String, dynamic> toJson() => {
    'trace_id': traceId,
    'span_id': spanId,
    'parent_span_id': parentSpanId,
    'name': name,
    'start_time': startTime.toIso8601String(),
    'end_time': endTime?.toIso8601String(),
    'duration_ms': duration.inMilliseconds,
    'attributes': attributes,
  };
}

/// Singleton manager for Distributed Tracing.
class TraceManager {
  static final TraceManager _instance = TraceManager._internal();
  factory TraceManager() => _instance;
  TraceManager._internal();

  final _uuid = const Uuid();
  final Map<String, TraceSpan> _activeSpans = {};

  /// Start a new Trace with a Root Span.
  TraceSpan startTrace(String name, {Map<String, dynamic>? attributes}) {
    final traceId = _uuid.v4();
    final spanId = _uuid.v4();
    
    final span = TraceSpan(
      traceId: traceId,
      spanId: spanId, 
      name: name,
      attributes: attributes,
    );
    
    _activeSpans[spanId] = span;
    _logSpanStart(span);
    return span;
  }

  /// Start a Child Span.
  TraceSpan startSpan(String name, {required String traceId, String? parentSpanId, Map<String, dynamic>? attributes}) {
    final spanId = _uuid.v4();
    final span = TraceSpan(
      traceId: traceId,
      spanId: spanId,
      name: name,
      parentSpanId: parentSpanId,
      attributes: attributes,
    );
    
    _activeSpans[spanId] = span;
    _logSpanStart(span);
    return span;
  }

  void endSpan(TraceSpan span) {
    span.end();
    _activeSpans.remove(span.spanId);
    _logSpanEnd(span);
  }

  // --- Internal Logging Hook ---
  // In a real system, this would push to an OTel collector.
  // Here, we just structured-log it.
  void _logSpanStart(TraceSpan span) {
    if (kDebugMode) {
      print('[TRACE_START] ${span.name} (Trace: ${span.traceId})');
    }
  }

  void _logSpanEnd(TraceSpan span) {
    if (kDebugMode) {
      print('[TRACE_END]   ${span.name} (${span.duration.inMilliseconds}ms) (Trace: ${span.traceId}) ${span.attributes}');
    }
  }
}
