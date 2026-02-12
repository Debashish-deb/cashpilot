import 'dart:math';

/// Lamport Clock for Distributed Systems
/// 
/// Provides monotonically increasing counters for partial ordering of events
/// across multiple devices.
class LamportClock {
  int _counter;
  String deviceId;

  LamportClock({
    required this.deviceId,
    int initialValue = 0,
  }) : _counter = initialValue;

  void updateDeviceId(String newId) {
    deviceId = newId;
  }

  int get value => _counter;

  /// Increment counter for a local event
  int tick() {
    _counter++;
    return _counter;
  }

  /// Update counter based on a received message (sync)
  /// Aligns local clock with the global maximum known.
  void update(int remoteValue) {
    _counter = max(_counter, remoteValue) + 1;
  }

  /// Compare two clocks for LWW (Last Write Wins)
  /// Returns 1 if this is newer, -1 if remote is newer, 0 if identical.
  static int compare(int local, int remote) {
    if (local > remote) return 1;
    if (remote > local) return -1;
    return 0;
  }
}

/// Version Vector for Multi-Device Conflict Resolution
class VersionVector {
  final Map<String, int> _vector;

  VersionVector([Map<String, int>? initial]) : _vector = Map.from(initial ?? {});

  Map<String, int> get vector => _vector;

  /// Update vector with a new value from a specific device
  void update(String deviceId, int clockValue) {
    final current = _vector[deviceId] ?? 0;
    _vector[deviceId] = max(current, clockValue);
  }

  /// Merge another vector into this one
  void merge(VersionVector other) {
    other._vector.forEach((deviceId, clockValue) {
      update(deviceId, clockValue);
    });
  }

  /// Check if this vector is strictly newer than another
  bool isNewerThan(VersionVector other) {
    bool strict = false;
    for (final entry in _vector.entries) {
      final otherVal = other._vector[entry.key] ?? 0;
      if (entry.value < otherVal) return false;
      if (entry.value > otherVal) strict = true;
    }
    // Also check if other has keys we don't
    for (final key in other._vector.keys) {
      if (!_vector.containsKey(key) && other._vector[key]! > 0) return false;
    }
    return strict;
  }

  /// Check if vectors are concurrent (conflicting)
  bool isConcurrent(VersionVector other) {
    bool thisNewer = false;
    bool otherNewer = false;

    final allKeys = {..._vector.keys, ...other._vector.keys};
    for (final key in allKeys) {
      final v1 = _vector[key] ?? 0;
      final v2 = other._vector[key] ?? 0;
      if (v1 > v2) thisNewer = true;
      if (v2 > v1) otherNewer = true;
    }

    return thisNewer && otherNewer;
  }
}
