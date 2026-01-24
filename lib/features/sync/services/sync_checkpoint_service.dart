/// Sync Checkpoint Service
/// Manages per-table per-device sync checkpoints for efficient incremental pulls.
library;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../services/device_info_service.dart';

/// Checkpoint data for a single table
class SyncCheckpoint {
  final String tableName;
  final DateTime? lastSyncAt;
  final int? lastRevision;

  SyncCheckpoint({
    required this.tableName,
    this.lastSyncAt,
    this.lastRevision,
  });
}

class SyncCheckpointService {
  final SharedPreferences _prefs;
  final DeviceInfoService _deviceInfoService = DeviceInfoService();
  
  String? _deviceId;
  
  SyncCheckpointService(this._prefs);
  
  /// Get device-specific key prefix
  Future<String> _getKeyPrefix() async {
    _deviceId ??= await _deviceInfoService.getDeviceId();
    return 'sync_checkpoint_${_deviceId}_';
  }
  
  /// Get checkpoint for a specific table
  Future<SyncCheckpoint> getCheckpoint(String tableName) async {
    final prefix = await _getKeyPrefix();
    final timeKey = '$prefix${tableName}_time';
    final revKey = '$prefix${tableName}_rev';
    
    final timeStr = _prefs.getString(timeKey);
    final rev = _prefs.getInt(revKey);
    
    return SyncCheckpoint(
      tableName: tableName,
      lastSyncAt: timeStr != null ? DateTime.tryParse(timeStr) : null,
      lastRevision: rev,
    );
  }
  
  /// Update checkpoint after successful sync
  Future<void> updateCheckpoint(String tableName, {
    DateTime? lastSyncAt,
    int? lastRevision,
  }) async {
    final prefix = await _getKeyPrefix();
    final timeKey = '$prefix${tableName}_time';
    final revKey = '$prefix${tableName}_rev';
    
    if (lastSyncAt != null) {
      await _prefs.setString(timeKey, lastSyncAt.toIso8601String());
    }
    if (lastRevision != null) {
      await _prefs.setInt(revKey, lastRevision);
    }
    
    if (kDebugMode) {
      debugPrint('[SyncCheckpoint] Updated $tableName: time=$lastSyncAt, rev=$lastRevision');
    }
  }
  
  /// Get checkpoints for all tables
  Future<Map<String, SyncCheckpoint>> getAllCheckpoints() async {
    const tables = [
      'budgets',
      'expenses',
      'accounts',
      'categories',
      'semi_budgets',
      'savings_goals',
      'budget_members',
      'recurring_expenses',
    ];
    
    final result = <String, SyncCheckpoint>{};
    for (final table in tables) {
      result[table] = await getCheckpoint(table);
    }
    return result;
  }
  
  /// Clear all checkpoints (force full sync)
  Future<void> clearAllCheckpoints() async {
    final prefix = await _getKeyPrefix();
    final keys = _prefs.getKeys().where((k) => k.startsWith(prefix));
    
    for (final key in keys) {
      await _prefs.remove(key);
    }
    
    if (kDebugMode) {
      debugPrint('[SyncCheckpoint] Cleared all checkpoints');
    }
  }
  
  /// Clear checkpoint for a specific table
  Future<void> clearCheckpoint(String tableName) async {
    final prefix = await _getKeyPrefix();
    await _prefs.remove('$prefix${tableName}_time');
    await _prefs.remove('$prefix${tableName}_rev');
  }
}
