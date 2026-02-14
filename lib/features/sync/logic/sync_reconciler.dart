import 'dart:convert';
import '../../../core/sync/vector_clock.dart';

/// Stateless helper to reconcile local constraints with remote updates
/// using Vector Clocks.
class SyncReconciler {
  
  /// Reconciles a list of local items against a map of remote items.
  /// 
  /// [locals]: List of local Drift objects/companions.
  /// [remotes]: Map of {id: remote_data_map}.
  /// [copier]: Function to create a new local object from remote data.
  ///           Signature: (localItem, remoteRevision, remoteVectorJson) -> newItem
  /// 
  /// Returns a new list of items that should be persisted locally.
  List<T> rebase<T>(
    List<T> locals, 
    Map<String, dynamic> remotes, 
    T Function(T local, int remoteRev, String? remoteVecStr) copier
  ) {
     List<T> reconciled = [];
     
     for (var local in locals) {
       // 1. Defensively get ID
       final dynamic item = local;
       String? id;
       try {
         id = item.id;
       } catch (_) {
         // If item doesn't have an ID, we can't reconcile it
         reconciled.add(local);
         continue;
       }
       
       if (id == null) {
         reconciled.add(local);
         continue;
       }

       // 2. Defensively get local version vector
       String? localVecJson;
       try {
         localVecJson = item.versionVector;
       } catch (_) {
         // If entity lacks versionVector field (e.g. AuditLog, SubCategory before migration)
         // We treat it as an empty vector
         localVecJson = null;
       }
       
       // Parse local clock (default to empty if missing)
       final localClock = VectorClock.fromJson(localVecJson ?? '{}');
       
       // Get remote data matching this ID
       final remoteData = remotes[id]; 
       
       if (remoteData != null) {
          final int remoteRev = remoteData['revision'] ?? 0;
          final String? remoteVecJson = remoteData['version_vector'] != null 
              ? json.encode(remoteData['version_vector']) 
              : null;
          final remoteClock = VectorClock.fromJson(remoteVecJson ?? '{}');

          // Vector Clock Comparison
          final comparison = remoteClock.compare(localClock);
          
          if (comparison == ClockComparison.after) {
             // Remote is strictly newer.
             // Action: Overwrite local with remote (Fast-forward).
             reconciled.add(copier(local, remoteRev, remoteVecJson));
             
          } else if (comparison == ClockComparison.concurrent) {
             // Conflict (Both modified concurrently).
             // Action (Phase 1): Server Wins / LWW.
             // TODO: In Phase 2/3, implement smarter merging strategies here.
             reconciled.add(copier(local, remoteRev, remoteVecJson)); 
             
          } else if (comparison == ClockComparison.before) {
             // Local is newer.
             // Action: Keep local. (Will eventually be pushed to server).
             reconciled.add(local);
             
          } else {
             // Equal.
             // Action: Keep local (Already in sync).
             reconciled.add(local);
          }
       } else {
          // No remote record found for this local ID.
          // This implies it's a new local item not yet synced, OR remote deleted (if we handled deletes via this map).
          // For now, assume it's local-only data waiting to push.
          reconciled.add(local);
       }
     }
     return reconciled;
  }
}
