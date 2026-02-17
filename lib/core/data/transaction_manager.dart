import 'dart:async';
import 'package:drift/drift.dart';
import '../../core/observability/log_service.dart';

class TransactionManager {
  final DatabaseConnectionUser _db;
  final LogService _logger;

  TransactionManager(this._db, this._logger);

  /// Execute a set of operations within an atomic transaction with retry logic
  Future<T> execute<T>(Future<T> Function() action, {int maxRetries = 3}) async {
    int attempts = 0;
    
    while (attempts < maxRetries) {
      attempts++;
      try {
        return await _db.transaction(() async {
          return await action();
        });
      } catch (e) {
        if (_isRetryableError(e) && attempts < maxRetries) {
          _logger.warn('Transaction failed, retrying (attempt $attempts): $e');
          await Future.delayed(Duration(milliseconds: 100 * attempts));
          continue;
        }
        _logger.error('Transaction failed permanently after $attempts attempts', error: e);
        rethrow;
      }
    }
    throw TransactionException('Max retries exceeded');
  }

  /// Execute with a row-level lock (Optimistic Locking via revision columns)
  Future<T> executeWithLock<T>({
    required String table,
    required String id,
    required Future<T> Function(int currentRevision) action,
  }) async {
    return await execute(() async {
      // 1. Fetch current revision
      final result = await _db.customSelect(
        'SELECT revision FROM $table WHERE id = ?',
        variables: [Variable.withString(id)],
      ).getSingleOrNull();

      if (result == null) {
        throw TransactionException('Entity not found: $id in $table');
      }

      final currentRevision = result.read<int>('revision');

      // 2. Perform action
      final data = await action(currentRevision);

      // 3. Update with revision check is handled by the caller's update statement,
      // but we can verify here if we want to ensure atomicity.
      // Most Drift updates with companions already support this pattern.
      
      return data;
    });
  }

  bool _isRetryableError(Object e) {
    final errorStr = e.toString().toLowerCase();
    return errorStr.contains('locked') || 
           errorStr.contains('busy') || 
           errorStr.contains('deadlock') ||
           errorStr.contains('concurrent modification');
  }
}

class TransactionException implements Exception {
  final String message;
  TransactionException(this.message);
  @override
  String toString() => 'TransactionException: $message';
}

class ConcurrentModificationException implements Exception {
  final String message;
  ConcurrentModificationException(this.message);
  @override
  String toString() => 'ConcurrentModificationException: $message';
}
