import 'dart:convert';

/// Three-Way Merge Service
/// Automatically resolves conflicts when one side hasn't changed
class ThreeWayMergeService {
  /// Attempt to auto-merge based on base, local, and remote versions
  /// Returns MergeResult with resolution or conflict details
  MergeResult attemptAutoMerge({
    required Map<String, dynamic>? base,
    required Map<String, dynamic> local,
    required Map<String, dynamic> remote,
  }) {
    // If no base (shouldn't happen), can't do three-way merge
    if (base == null) {
      return MergeResult.conflict(
        reason: 'No base version available',
        conflictingFields: _getAllFields(local, remote),
      );
    }

    // Quick check: if local == remote, no conflict
    if (_areEqual(local, remote)) {
      return MergeResult.resolved(
        data: local,
        strategy: 'identical',
      );
    }

    // Check if local unchanged (use remote)
    if (_areEqual(local, base)) {
      return MergeResult.resolved(
        data: remote,
        strategy: 'remote_only_changed',
      );
    }

    // Check if remote unchanged (use local)
    if (_areEqual(remote, base)) {
      return MergeResult.resolved(
        data: local,
        strategy: 'local_only_changed',
      );
    }

    // Both changed - need field-by-field analysis
    final conflicts = <String>[];
    final merged = <String, dynamic>{};

    final allKeys = {...local.keys, ...remote.keys};
    final skipFields = {'revision', 'updated_at', 'last_modified_by_device_id'};

    for (final key in allKeys) {
      if (skipFields.contains(key)) {
        // Always use higher value for revision, latest for updated_at
        if (key == 'revision') {
          final localRev = local[key] as int? ?? 0;
          final remoteRev = remote[key] as int? ?? 0;
          merged[key] = localRev > remoteRev ? localRev : remoteRev;
        } else {
          merged[key] = local[key]; // Use local for metadata
        }
        continue;
      }

      final localVal = local[key];
      final remoteVal = remote[key];
      final baseVal = base[key];

      // Both same = no conflict
      if (_valuesEqual(localVal, remoteVal)) {
        merged[key] = localVal;
        continue;
      }

      // Local unchanged = use remote
      if (_valuesEqual(localVal, baseVal)) {
        merged[key] = remoteVal;
        continue;
      }

      // Remote unchanged = use local
      if (_valuesEqual(remoteVal, baseVal)) {
        merged[key] = localVal;
        continue;
      }

      // Both changed = CONFLICT
      conflicts.add(key);
      merged[key] = localVal; // Default to local, user must resolve
    }

    if (conflicts.isEmpty) {
      return MergeResult.resolved(
        data: merged,
        strategy: 'auto_merged',
      );
    }

    return MergeResult.conflict(
      reason: 'Both versions modified: ${conflicts.join(", ")}',
      conflictingFields: conflicts,
      partialMerge: merged,
    );
  }

  bool _areEqual(Map<String, dynamic> a, Map<String, dynamic> b) {
    if (a.length != b.length) return false;

    for (final key in a.keys) {
      if (key == 'updated_at' || key == 'revision') continue; // Skip metadata
      if (!_valuesEqual(a[key], b[key])) return false;
    }

    return true;
  }

  bool _valuesEqual(dynamic a, dynamic b) {
    if (a == b) return true;
    if (a == null || b == null) return a == b;

    // Compare strings
    if (a is String && b is String) return a == b;

    // Compare numbers
    if (a is num && b is num) return a == b;

    // Compare bools
    if (a is bool && b is bool) return a == b;

    // For complex types, compare JSON
    try {
      return jsonEncode(a) == jsonEncode(b);
    } catch (e) {
      return false;
    }
  }

  List<String> _getAllFields(Map<String, dynamic> local, Map<String, dynamic> remote) {
    return {...local.keys, ...remote.keys}
        .where((k) => k != 'revision' && k != 'updated_at')
        .toList();
  }
}

/// Result of a three-way merge attempt
class MergeResult {
  final bool isResolved;
  final Map<String, dynamic>? data;
  final String? strategy;
  final String? conflictReason;
  final List<String>? conflictingFields;
  final Map<String, dynamic>? partialMerge;

  MergeResult._({
    required this.isResolved,
    this.data,
    this.strategy,
    this.conflictReason,
    this.conflictingFields,
    this.partialMerge,
  });

  factory MergeResult.resolved({
    required Map<String, dynamic> data,
    required String strategy,
  }) {
    return MergeResult._(
      isResolved: true,
      data: data,
      strategy: strategy,
    );
  }

  factory MergeResult.conflict({
    required String reason,
    required List<String> conflictingFields,
    Map<String, dynamic>? partialMerge,
  }) {
    return MergeResult._(
      isResolved: false,
      conflictReason: reason,
      conflictingFields: conflictingFields,
      partialMerge: partialMerge,
    );
  }
}
