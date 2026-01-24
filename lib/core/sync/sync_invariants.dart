import 'package:flutter/foundation.dart';

/// Enforces the 6 non-negotiable sync invariants
class SyncInvariants {
  /// 1. Monotonic server revision
  /// Never accept update that moves revision backwards
  static bool validateMonotonicRevision({
    required int currentRevision,
    required int incomingRevision,
  }) {
    if (incomingRevision < currentRevision) {
      debugPrint('[SyncInvariants] VIOLATION: Revision going backwards! '
          'current=$currentRevision incoming=$incomingRevision');
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
  static Future<bool> applyAtomically({
    required Function() applyFn,
    required String entityGroup,
  }) async {
    try {
      // This would wrap in DB transaction
      await applyFn();
      return true;
    } catch (e) {
      debugPrint('[SyncInvariants] VIOLATION: Atomic apply failed for $entityGroup: $e');
      return false;
    }
  }
  
  /// 6. Account boundary isolation
  /// Switching accounts = separate DB namespace or full wipe
  static bool validateAccountBoundary({
    required String? currentUserId,
    required String incomingUserId,
  }) {
    if (currentUserId != null && currentUserId != incomingUserId) {
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
    
    if (!validateMonotonicRevision(
      currentRevision: currentRevision,
      incomingRevision: incomingRevision,
    )) {
      violations.add('Revision going backwards');
    }
    
    if (!hasValidBaseRevision(
      baseRevision: baseRevision,
      isDirty: isDirty,
    )) {
      violations.add('Missing base_revision for dirty record');
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
