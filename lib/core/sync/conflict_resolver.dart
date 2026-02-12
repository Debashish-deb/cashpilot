import 'package:flutter/foundation.dart';
import 'dart:convert';

/// Result of conflict resolution
sealed class ConflictResolutionResult {
  const ConflictResolutionResult();
}

/// Accept the remote version (discard local changes)
class AcceptRemote extends ConflictResolutionResult {
  final Map<String, dynamic> remoteData;
  const AcceptRemote(this.remoteData);
}

/// Accept the local version (push local, reject remote)
class AcceptLocal extends ConflictResolutionResult {
  final Map<String, dynamic> localData;
  const AcceptLocal(this.localData);
}

/// Merge both versions (field-level merge)
class MergeVersions extends ConflictResolutionResult {
  final Map<String, dynamic> mergedData;
  const MergeVersions(this.mergedData);
}

/// Conflict cannot be resolved automatically
class ManualResolutionRequired extends ConflictResolutionResult {
  final String reason;
  const ManualResolutionRequired(this.reason);
}

/// Record representing a sync conflict
class ConflictRecord {
  final Map<String, dynamic> localData;
  final Map<String, dynamic> remoteData;
  final String entityId;
  final String entityType;

  ConflictRecord({
    required this.localData,
    required this.remoteData,
    required this.entityId,
    required this.entityType,
  });

  int? get localVersion => localData['revision'] as int?;
  int? get remoteVersion => remoteData['revision'] as int?;
  
  DateTime? get localUpdatedAt => localData['updated_at'] != null
      ? DateTime.tryParse(localData['updated_at'] as String)
      : null;
      
  DateTime? get remoteUpdatedAt => remoteData['server_updated_at'] != null
      ? DateTime.tryParse(remoteData['server_updated_at'] as String)
      : null;
      
  String? get localDeviceId => localData['last_modified_by_device_id'] as String?;
  String? get remoteDeviceId => remoteData['last_modified_by_device_id'] as String?;
  
  String? get localOpId => localData['operation_id'] as String?;
  String? get remoteOpId => remoteData['operation_id'] as String?;
}

/// Version-based conflict resolver
/// 
/// Strategy: Use deterministic tie-break chain
/// 1. Higher revision (version) wins
/// 2. Newer updated_at wins
/// 3. Lexicographically larger deviceId wins
/// 4. Lexicographically larger opId wins
class ConflictResolver {
  /// Resolve a conflict using deterministic strategy
  ConflictResolutionResult resolve(ConflictRecord conflict) {
    try {
      final result = _resolveDeterministic(conflict);

      if (kDebugMode) {
        final winner = result is AcceptRemote ? 'REMOTE' : 
                      result is AcceptLocal ? 'LOCAL' : 'MERGE';
        debugPrint(
          '[ConflictResolver] Resolved ${conflict.entityType}:${conflict.entityId} → $winner '
          '(local v${conflict.localVersion} @ ${conflict.localUpdatedAt}, '
          'remote v${conflict.remoteVersion} @ ${conflict.remoteUpdatedAt})'
        );
      }

      return result;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ConflictResolver] Resolution failed: $e');
      }
      return ManualResolutionRequired('Resolution error: $e');
    }
  }

  /// Core deterministic resolution logic with 4-step tie-breaker
  ConflictResolutionResult _resolveDeterministic(ConflictRecord conflict) {
    // 0. Safety Check: If NO metadata is present on either side (valid for some edge cases)
    // We cannot safely determine a winner automatically without risking data loss/overwrite.
    if (conflict.localVersion == null && conflict.remoteVersion == null &&
        conflict.localUpdatedAt == null && conflict.remoteUpdatedAt == null) {
      return const ManualResolutionRequired(
          'Missing version and timestamp metadata on both records');
    }

    // 1. Version Comparison (Higher wins)
    final localV = conflict.localVersion;
    final remoteV = conflict.remoteVersion;
    
    if (localV != null && remoteV != null) {
      if (remoteV > localV) return AcceptRemote(conflict.remoteData);
      if (localV > remoteV) return AcceptLocal(conflict.localData);
    }
    // Handle partial version cases (prefer versioned over unversioned)
    else if (remoteV != null && localV == null) return AcceptRemote(conflict.remoteData);
    else if (localV != null && remoteV == null) return AcceptLocal(conflict.localData);

    // 2. Timestamp Comparison (Newer wins)
    final localT = conflict.localUpdatedAt;
    final remoteT = conflict.remoteUpdatedAt;
    
    if (localT != null && remoteT != null) {
      if (remoteT.isAfter(localT)) return AcceptRemote(conflict.remoteData);
      if (localT.isAfter(remoteT)) return AcceptLocal(conflict.localData);
    }
    // Handle partial timestamp cases
    else if (remoteT != null && localT == null) return AcceptRemote(conflict.remoteData);
    else if (localT != null && remoteT == null) return AcceptLocal(conflict.localData);

    // 3. Device ID Comparison (Lexicographical sort)
    final localDev = conflict.localDeviceId ?? '';
    final remoteDev = conflict.remoteDeviceId ?? '';
    
    // Skip if both empty
    if (localDev.isNotEmpty || remoteDev.isNotEmpty) {
      final comparison = remoteDev.compareTo(localDev);
      if (comparison > 0) return AcceptRemote(conflict.remoteData);
      if (comparison < 0) return AcceptLocal(conflict.localData);
    }

    // 4. Operation ID Comparison (Lexicographical sort)
    final localOp = conflict.localOpId ?? '';
    final remoteOp = conflict.remoteOpId ?? '';
    
    if (localOp.isNotEmpty || remoteOp.isNotEmpty) {
      final comparison = remoteOp.compareTo(localOp);
      if (comparison > 0) return AcceptRemote(conflict.remoteData);
      if (comparison < 0) return AcceptLocal(conflict.localData);
    }
    
    // 5. Fallback: If absolutely identical in metadata, assume remote wins (safest convergence)
    // or manual resolution if suspicious.
    // For syncing, converging to server is safer.
    return AcceptRemote(conflict.remoteData);
  }

  /// Detect if two records are in conflict
  bool isConflict(ConflictRecord record) {
    if (record.localVersion == record.remoteVersion) {
      // Deep compare data to be sure
      final localJson = jsonEncode(record.localData);
      final remoteJson = jsonEncode(record.remoteData);
      if (localJson == remoteJson) {
        return false; // Identical
      }
    }
    return true;
  }

  /// Get human-readable conflict summary
  String getConflictSummary(ConflictRecord conflict) {
    final localV = conflict.localVersion ?? '?';
    final remoteV = conflict.remoteVersion ?? '?';
    final localT = conflict.localUpdatedAt?.toIso8601String().substring(0, 19) ?? 'unknown';
    final remoteT = conflict.remoteUpdatedAt?.toIso8601String().substring(0, 19) ?? 'unknown';

    return '${conflict.entityType} ${conflict.entityId}: '
           'Local(v$localV @ $localT) vs Remote(v$remoteV @ $remoteT)';
  }

  /// Validate that resolution was deterministic
  /// 
  /// Given the same input, resolution should always produce the exact same outcome payload
  bool validateDeterministic(ConflictRecord conflict) {
    final result1 = resolve(conflict);
    final result2 = resolve(conflict);

    // 1. Check types match
    if (result1.runtimeType != result2.runtimeType) return false;
    
    // 2. Check payload hash (content match)
    String? hash1;
    String? hash2;
    
    if (result1 is AcceptRemote && result2 is AcceptRemote) {
      hash1 = jsonEncode(result1.remoteData);
      hash2 = jsonEncode(result2.remoteData);
    } else if (result1 is AcceptLocal && result2 is AcceptLocal) {
      hash1 = jsonEncode(result1.localData);
      hash2 = jsonEncode(result2.localData);
    } else if (result1 is MergeVersions && result2 is MergeVersions) {
      hash1 = jsonEncode(result1.mergedData);
      hash2 = jsonEncode(result2.mergedData);
    } else {
      // Manual resolution or mixed types (already failed step 1)
      return true; // Manual requests are "deterministic" in that they are both Requests
    }
    
    return hash1 == hash2;
  }
}
