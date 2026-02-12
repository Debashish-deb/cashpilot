import 'dart:convert';
import 'dart:math';

/// Result of a Vector Clock comparison
enum ClockComparison {
  equal,      // A == B
  before,     // A < B (A happened before B)
  after,      // A > B (A happened after B)
  concurrent, // A || B (Concurrent / Conflict)
}

/// Vector Clock for tracking causality in distributed systems.
/// Represents a map of {deviceId: counter}.
class VectorClock {
  final Map<String, int> _vector;

  /// Create a new Vector Clock, optionally initializing from an existing map.
  VectorClock([Map<String, int>? initial]) 
      : _vector = Map<String, int>.from(initial ?? {});

  /// Create from JSON string.
  factory VectorClock.fromJson(String jsonStr) {
    try {
      final Map<String, dynamic> decoded = json.decode(jsonStr);
      final Map<String, int> vector = {};
      decoded.forEach((k, v) {
        if (v is int) vector[k] = v;
      });
      return VectorClock(vector);
    } catch (_) {
      return VectorClock();
    }
  }

  /// Convert to JSON string.
  String toJson() => json.encode(_vector);

  /// Get the raw vector map (read-only copy).
  Map<String, int> get vector => Map.unmodifiable(_vector);

  /// Increment the counter for the given [deviceId].
  void increment(String deviceId) {
    _vector[deviceId] = (_vector[deviceId] ?? 0) + 1;
  }

  /// Update a specific entry (e.g., from a received message).
  /// Takes the maximum of current and new value.
  void update(String deviceId, int value) {
    _vector[deviceId] = max(_vector[deviceId] ?? 0, value);
  }

  /// Merge another Vector Clock into this one.
  /// For each device ID, take the maximum counter value.
  void merge(VectorClock other) {
    for (final entry in other._vector.entries) {
      update(entry.key, entry.value);
    }
  }

  /// Compare this clock with another.
  /// Returns [ClockComparison] indicating relationship (before, after, equal, concurrent).
  ClockComparison compare(VectorClock other) {
    bool thisHasNewer = false;
    bool otherHasNewer = false;

    // Get union of all keys
    final allKeys = {..._vector.keys, ...other._vector.keys};

    for (final key in allKeys) {
      final v1 = _vector[key] ?? 0;
      final v2 = other._vector[key] ?? 0;

      if (v1 > v2) thisHasNewer = true;
      if (v2 > v1) otherHasNewer = true;
    }

    if (thisHasNewer && otherHasNewer) return ClockComparison.concurrent;
    if (thisHasNewer) return ClockComparison.after;
    if (otherHasNewer) return ClockComparison.before;
    return ClockComparison.equal;
  }
  
  /// Helper to check if this clock is causally descended from [other].
  /// Returns true if this >= other (equal or after).
  bool isDescendantOf(VectorClock other) {
    final cmp = compare(other);
    return cmp == ClockComparison.after || cmp == ClockComparison.equal;
  }
}
