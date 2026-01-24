/// Idempotency Tracker
/// Prevents duplicate execution of operations
library;

import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../logging/logger.dart';

/// Idempotency key generator
class IdempotencyKey {
  /// Generate key for expense operation
  static String forExpense(String expenseId, String operation) {
    return 'expense:$expenseId:$operation';
  }

  /// Generate key for budget operation
  static String forBudget(String budgetId, String operation) {
    return 'budget:$budgetId:$operation';
  }

  /// Generate key for sync operation
  static String forSync(String table, String recordId, String operation) {
    return 'sync:$table:$recordId:$operation';
  }

  /// Generate key for any entity
  static String forEntity(String entityType, String entityId, String operation) {
    return '$entityType:$entityId:$operation';
  }

  /// Generate timestamp-based key
  static String timestamped(String prefix, DateTime timestamp) {
    return '$prefix:${timestamp.millisecondsSinceEpoch}';
  }
}

/// Operation record for idempotency tracking
class OperationRecord {
  final String key;
  final DateTime executedAt;
  final Map<String, dynamic>? result;
  final String? error;

  OperationRecord({
    required this.key,
    required this.executedAt,
    this.result,
    this.error,
  });

  Map<String, dynamic> toJson() => {
    'key': key,
    'executedAt': executedAt.toIso8601String(),
    if (result != null) 'result': result,
    if (error != null) 'error': error,
  };

  factory OperationRecord.fromJson(Map<String, dynamic> json) {
    return OperationRecord(
      key: json['key'] as String,
      executedAt: DateTime.parse(json['executedAt'] as String),
      result: json['result'] as Map<String, dynamic>?,
      error: json['error'] as String?,
    );
  }
}

/// Idempotency tracker service
class IdempotencyTracker {
  final SharedPreferences prefs;
  final Logger _logger = Loggers.sync;
  
  static const String _keyPrefix = 'idempotency_';
  static const Duration _defaultTTL = Duration(hours: 24);

  IdempotencyTracker(this.prefs);

  /// Check if operation was already executed
  Future<bool> wasExecuted(String key) async {
    final record = await _getRecord(key);
    
    if (record == null) {
      return false;
    }

    // Check if record is still valid (not expired)
    final age = DateTime.now().difference(record.executedAt);
    if (age > _defaultTTL) {
      // Expired, remove it
      await _removeRecord(key);
      return false;
    }

    _logger.debug('Operation already executed: $key', context: {
      'executedAt': record.executedAt.toIso8601String(),
      'ageMinutes': age.inMinutes,
    });

    return true;
  }

  /// Mark operation as executed
  Future<void> markExecuted(
    String key, {
    Map<String, dynamic>? result,
    String? error,
  }) async {
    final record = OperationRecord(
      key: key,
      executedAt: DateTime.now(),
      result: result,
      error: error,
    );

    await _saveRecord(record);

    _logger.debug('Marked operation as executed: $key', context: {
      'hasResult': result != null,
      'hasError': error != null,
    });
  }

  /// Execute operation with idempotency protection
  /// 
  /// Returns cached result if operation was already executed,
  /// otherwise executes the operation and caches the result
  Future<T> executeOnce<T>({
    required String key,
    required Future<T> Function() operation,
    T Function(Map<String, dynamic>)? resultDeserializer,
  }) async {
    // Check if already executed
    final record = await _getRecord(key);
    
    if (record != null) {
      final age = DateTime.now().difference(record.executedAt);
      
      if (age <= _defaultTTL) {
        _logger.info('Using cached result for: $key', context: {
          'ageMinutes': age.inMinutes,
        });

        // Return cached result if available and deserializer provided
        if (record.result != null && resultDeserializer != null) {
          return resultDeserializer(record.result!);
        }

        // If there was an error, rethrow it
        if (record.error != null) {
          throw Exception('Cached error: ${record.error}');
        }
      }
    }

    // Execute operation
    try {
      _logger.debug('Executing operation: $key');
      final result = await operation();

      // Cache successful result
      await markExecuted(
        key,
        result: result is Map<String, dynamic> ? result : {'value': result},
      );

      return result;
    } catch (e) {
      // Cache error
      await markExecuted(key, error: e.toString());
      rethrow;
    }
  }

  /// Clear expired records
  Future<void> cleanupExpired() async {
    final keys = prefs.getKeys()
        .where((key) => key.startsWith(_keyPrefix))
        .toList();

    int removed = 0;
    final now = DateTime.now();

    for (final key in keys) {
      final rawKey = key.substring(_keyPrefix.length);
      final record = await _getRecord(rawKey);

      if (record != null) {
        final age = now.difference(record.executedAt);
        if (age > _defaultTTL) {
          await _removeRecord(rawKey);
          removed++;
        }
      }
    }

    if (removed > 0) {
      _logger.info('Cleaned up expired idempotency records', context: {
        'removed': removed,
      });
    }
  }

  /// Get all tracked operations (for debugging)
  Future<List<OperationRecord>> getAllRecords() async {
    final keys = prefs.getKeys()
        .where((key) => key.startsWith(_keyPrefix))
        .toList();

    final records = <OperationRecord>[];

    for (final key in keys) {
      final rawKey = key.substring(_keyPrefix.length);
      final record = await _getRecord(rawKey);
      if (record != null) {
        records.add(record);
      }
    }

    return records;
  }

  /// Clear all records
  Future<void> clearAll() async {
    final keys = prefs.getKeys()
        .where((key) => key.startsWith(_keyPrefix))
        .toList();

    for (final key in keys) {
      await prefs.remove(key);
    }

    _logger.info('Cleared all idempotency records', context: {
      'count': keys.length,
    });
  }

  /// Internal: Get record
  Future<OperationRecord?> _getRecord(String key) async {
    final storageKey = '$_keyPrefix$key';
    final json = prefs.getString(storageKey);

    if (json == null) {
      return null;
    }

    try {
      final data = jsonDecode(json) as Map<String, dynamic>;
      return OperationRecord.fromJson(data);
    } catch (e) {
      _logger.warning('Failed to parse idempotency record: $key', error: e);
      return null;
    }
  }

  /// Internal: Save record
  Future<void> _saveRecord(OperationRecord record) async {
    final storageKey = '$_keyPrefix${record.key}';
    final json = jsonEncode(record.toJson());
    await prefs.setString(storageKey, json);
  }

  /// Internal: Remove record
  Future<void> _removeRecord(String key) async {
    final storageKey = '$_keyPrefix$key';
    await prefs.remove(storageKey);
  }
}
