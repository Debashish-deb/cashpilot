/// Conflict Detection Service
/// Detects and persists sync conflicts for resolution.
library;

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../services/auth_service.dart';
import '../../../services/device_info_service.dart';

/// Conflict status
enum ConflictStatus { pending, resolved, dismissed }

/// A detected sync conflict
class SyncConflict {
  final String id;
  final String tableName;
  final String recordId;
  final Map<String, dynamic> localData;
  final Map<String, dynamic> remoteData;
  final String localDeviceId;
  final String? remoteDeviceId;
  final int localRevision;
  final int remoteRevision;
  final ConflictStatus status;
  final DateTime detectedAt;
  final Map<String, dynamic>? resolvedData;
  final DateTime? resolvedAt;

  SyncConflict({
    required this.id,
    required this.tableName,
    required this.recordId,
    required this.localData,
    required this.remoteData,
    required this.localDeviceId,
    this.remoteDeviceId,
    required this.localRevision,
    required this.remoteRevision,
    this.status = ConflictStatus.pending,
    required this.detectedAt,
    this.resolvedData,
    this.resolvedAt,
  });

  factory SyncConflict.fromJson(Map<String, dynamic> json) {
    return SyncConflict(
      id: json['id'],
      tableName: json['table_name'],
      recordId: json['record_id'],
      localData: json['local_data'] is String 
          ? jsonDecode(json['local_data']) 
          : json['local_data'],
      remoteData: json['remote_data'] is String 
          ? jsonDecode(json['remote_data']) 
          : json['remote_data'],
      localDeviceId: json['local_device_id'],
      remoteDeviceId: json['remote_device_id'],
      localRevision: json['local_revision'] ?? 0,
      remoteRevision: json['remote_revision'] ?? 0,
      status: ConflictStatus.values.firstWhere(
        (e) => e.name == json['resolution'],
        orElse: () => ConflictStatus.pending,
      ),
      detectedAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      resolvedData: json['resolved_data'] is String 
          ? jsonDecode(json['resolved_data']) 
          : json['resolved_data'],
      resolvedAt: json['resolved_at'] != null 
          ? DateTime.tryParse(json['resolved_at'] ?? '') 
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'table_name': tableName,
    'record_id': recordId,
    'local_data': localData,
    'remote_data': remoteData,
    'local_device_id': localDeviceId,
    'remote_device_id': remoteDeviceId,
    'local_revision': localRevision,
    'remote_revision': remoteRevision,
    'resolution': status.name,
    'created_at': detectedAt.toIso8601String(),
    'resolved_data': resolvedData,
    'resolved_at': resolvedAt?.toIso8601String(),
  };

  /// Get fields that differ between local and remote
  List<String> get conflictingFields {
    final fields = <String>[];
    for (final key in localData.keys) {
      if (remoteData.containsKey(key) && localData[key] != remoteData[key]) {
        fields.add(key);
      }
    }
    return fields;
  }
}

class ConflictDetectionService {
  static final ConflictDetectionService _instance = ConflictDetectionService._internal();
  factory ConflictDetectionService() => _instance;
  ConflictDetectionService._internal();

  final _client = Supabase.instance.client;
  final _deviceInfoService = DeviceInfoService();

  /// Check if there's a conflict between local and remote versions
  /// Returns true if conflict detected (remote has higher revision than our base)
  bool hasConflict({
    required int localBaseRevision,
    required int remoteRevision,
    required bool localIsDirty,
  }) {
    // Conflict if:
    // 1. We have local changes (dirty)
    // 2. Remote has newer revision than what we based our edits on
    return localIsDirty && remoteRevision > localBaseRevision;
  }

  /// Detect and persist a conflict
  Future<SyncConflict?> detectAndPersist({
    required String tableName,
    required String recordId,
    required Map<String, dynamic> localData,
    required Map<String, dynamic> remoteData,
    required int localRevision,
    required int remoteRevision,
    String? remoteDeviceId,
  }) async {
    final userId = authService.currentUser?.id;
    if (userId == null) return null;

    final localDeviceId = await _deviceInfoService.getDeviceId();

    try {
      final conflictId = '${tableName}_${recordId}_${DateTime.now().millisecondsSinceEpoch}';
      
      await _client.from('sync_conflicts').insert({
        'id': conflictId,
        'user_id': userId,
        'table_name': tableName,
        'record_id': recordId,
        'local_data': localData,
        'remote_data': remoteData,
        'local_device_id': localDeviceId,
        'remote_device_id': remoteDeviceId,
        'local_revision': localRevision,
        'remote_revision': remoteRevision,
        'resolution': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      });

      if (kDebugMode) {
        debugPrint('[ConflictDetection] Persisted conflict for $tableName:$recordId');
      }

      return SyncConflict(
        id: conflictId,
        tableName: tableName,
        recordId: recordId,
        localData: localData,
        remoteData: remoteData,
        localDeviceId: localDeviceId,
        remoteDeviceId: remoteDeviceId,
        localRevision: localRevision,
        remoteRevision: remoteRevision,
        detectedAt: DateTime.now(),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ConflictDetection] Failed to persist conflict: $e');
      }
      return null;
    }
  }

  /// Get all pending conflicts for current user
  Future<List<SyncConflict>> getPendingConflicts() async {
    final userId = authService.currentUser?.id;
    if (userId == null) return [];

    try {
      final response = await _client
          .from('sync_conflicts')
          .select()
          .eq('user_id', userId)
          .eq('resolution', 'pending')
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => SyncConflict.fromJson(json))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ConflictDetection] Failed to get conflicts: $e');
      }
      return [];
    }
  }

  /// Resolve a conflict with chosen data
  Future<bool> resolveConflict({
    required String conflictId,
    required Map<String, dynamic> resolvedData,
  }) async {
    try {
      await _client.from('sync_conflicts').update({
        'resolution': 'resolved',
        'resolved_data': resolvedData,
        'resolved_at': DateTime.now().toIso8601String(),
      }).eq('id', conflictId);

      if (kDebugMode) {
        debugPrint('[ConflictDetection] Resolved conflict: $conflictId');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ConflictDetection] Failed to resolve conflict: $e');
      }
      return false;
    }
  }

  /// Dismiss a conflict (use remote version)
  Future<bool> dismissConflict(String conflictId) async {
    try {
      await _client.from('sync_conflicts').update({
        'resolution': 'dismissed',
        'resolved_at': DateTime.now().toIso8601String(),
      }).eq('id', conflictId);

      return true;
    } catch (e) {
      return false;
    }
  }
}

/// Global instance
final conflictDetectionService = ConflictDetectionService();
