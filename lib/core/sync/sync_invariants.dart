import 'package:flutter/foundation.dart';

/// Enforces the non-negotiable sync invariants defined in technical_contract.md
class SyncInvariants {
  
  /// 1. Monotonic server revision
  /// Never accept update that moves revision backwards or stays same (unless idempotent)
  /// Returns TRUE if incoming > current
  static bool validateMonotonicRevision({
    required int currentRevision,
    required int incomingRevision,
  }) {
    if (incomingRevision <= currentRevision) {
      // Idempotency check should be handled by caller (if ==, it's a dupe/no-op)
      // But for "New Data", this is a violation/staleness
      return false;
    }
    return true;
  }
  
  /// 2. Base revision tracking (for conflict detection)
  /// Record must know what revision the edit was based on
  static bool hasValidBaseRevision({
    required int? baseRevision,
    required bool isDirty,
  }) {
    if (isDirty && baseRevision == null) {
      debugPrint('[SyncInvariants] VIOLATION: Dirty record without base_revision');
      return false;
    }
    return true;
  }
  
  /// 3. Idempotent push
  /// Same operation sent twice must be safe
  static String generateOperationId({
    required String recordId,
    required int revision,
    required String operation,
  }) {
    // Deterministic ID: sending same change twice gets same ID
    return '$recordId-$revision-$operation';
  }
  
  /// 4. Tombstones over hard delete
  /// For syncable entities, delete = set tombstone + sync
  static bool isTombstone(Map<String, dynamic> record) {
    return record['is_deleted'] == true || record['tombstone'] == true;
  }
  
  /// 5. Transactional apply
  /// Applying remote batch must be atomic per entity group
  /// usage: await db.transaction(() async { ... });
  
  /// 6. Account boundary isolation
  /// Switching accounts = separate DB namespace or full wipe
  static bool validateAccountBoundary({
    required String? currentUserId,
    required String incomingUserId,
  }) {
    if (currentUserId != null && currentUserId.isNotEmpty && currentUserId != incomingUserId) {
      debugPrint('[SyncInvariants] VIOLATION: Account boundary crossed! '
          'current=$currentUserId incoming=$incomingUserId');
      return false;
    }
    return true;
  }
  
  /// Combined validation for sync safety
  static SyncValidationResult validateSync({
    required int currentRevision,
    required int incomingRevision,
    required int? baseRevision,
    required bool isDirty,
    required String? currentUserId,
    required String incomingUserId,
  }) {
    final violations = <String>[];
    
    // Strict revision check for INGEST
    // If incoming <= current, it's stale or duplicate. 
    // We don't "fail" validation as in "error", but we signal it's not applicable.
    // However, for purposes of "Is this a valid NEW update?", it is false.
    if (incomingRevision <= currentRevision) {
       violations.add('Stale revision: incoming($incomingRevision) <= current($currentRevision)');
    }
    
    if (!validateAccountBoundary(
      currentUserId: currentUserId,
      incomingUserId: incomingUserId,
    )) {
      violations.add('Account boundary crossed');
    }
    
    return SyncValidationResult(
      isValid: violations.isEmpty,
      violations: violations,
    );
  }
}

class SyncValidationResult {
  final bool isValid;
  final List<String> violations;
  
  const SyncValidationResult({
    required this.isValid,
    required this.violations,
  });
  
  @override
  String toString() => isValid 
      ? 'Valid' 
      : 'Invalid: ${violations.join(', ')}';
}
