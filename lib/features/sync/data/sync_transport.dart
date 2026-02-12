/// Sync Transport Interface
/// Decouples DataBatchSync from specific network implementation (Supabase)
/// allowing for easier testing and potential transport switching.
library;

import 'package:supabase_flutter/supabase_flutter.dart';

abstract class SyncTransport {
  /// Execute a batch sync (PUSH)
  /// Returns the processing result from the server
  Future<Map<String, dynamic>> batchPush({required Map<String, dynamic> payload});

  /// Execute a batch pull (PULL)
  /// Returns the data from the server
  Future<Map<String, dynamic>> batchPull({required DateTime? lastSyncTime});

  /// Fetch revisions and version vectors for specific records (Conflict Check)
  Future<List<Map<String, dynamic>>> fetchRevisions({
    required String table, 
    required List<String> ids
  });
}

/// Default Supabase Implementation
class SupabaseSyncTransport implements SyncTransport {
  final SupabaseClient client;

  SupabaseSyncTransport(this.client);

  @override
  Future<Map<String, dynamic>> batchPush({required Map<String, dynamic> payload}) async {
    final response = await client.rpc(
      'batch_sync',
      params: {'p_payload': payload},
    );
    return response as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> batchPull({required DateTime? lastSyncTime}) async {
    final response = await client.rpc('batch_pull', params: {
      'p_last_sync_timestamp': lastSyncTime?.toIso8601String(),
    });
    return (response as Map<dynamic, dynamic>?)?.cast<String, dynamic>() ?? {};
  }

  @override
  Future<List<Map<String, dynamic>>> fetchRevisions({
    required String table, 
    required List<String> ids
  }) async {
    if (ids.isEmpty) return [];
    
    // Map internal table names to Supabase table names if needed
    // Assuming they match 1:1 based on DataBatchSync code
    
    final response = await client
        .from(table)
        .select('id, revision, version_vector')
        .inFilter('id', ids);
        
    return List<Map<String, dynamic>>.from(response);
  }
}
