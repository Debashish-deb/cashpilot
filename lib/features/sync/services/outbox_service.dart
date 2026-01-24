import 'dart:convert';
import 'dart:math';
import 'package:drift/drift.dart';
import '../../../data/drift/app_database.dart';
import 'package:uuid/uuid.dart';

/// Outbox Service - Manages offline event queue
/// Phase 1: Enhanced with permission epoch, exponential backoff, and better error handling
class OutboxService {
  final AppDatabase _db;
  final _uuid = const Uuid();
  
  OutboxService(this._db);
  
  /// Queue a local change for sync
  /// Now includes permission epoch tracking
  Future<String> queueEvent({
    required String entityType,
    required String entityId,
    required String operation,
    required Map<String, dynamic> payload,
    int? baseRevision,
    int? permissionEpoch,
  }) async {
    final id = _uuid.v4();
    final event = OutboxEventsCompanion.insert(
      id: id,
      entityType: entityType,
      entityId: entityId,
      operation: operation,
      payload: jsonEncode(payload),
      baseRevision: Value(baseRevision),
      permissionEpochAtEdit: Value(permissionEpoch),
    );
    
    await _db.into(_db.outboxEvents).insert(event);
    return id;
  }
  
  /// Get pending events ordered by creation time
  Future<List<OutboxEvent>> getPendingEvents() async {
    return await (_db.select(_db.outboxEvents)
      ..where((e) => e.status.equals('pending') | e.status.equals('retry'))
      ..where((e) => e.retryCount.isSmallerThan(e.maxRetries))
      ..orderBy([(e) => OrderingTerm.asc(e.createdAt)]))
      .get();
  }
  
  /// Get events that need retry with exponential backoff
  Future<List<OutboxEvent>> getEventsForRetry() async {
    final now = DateTime.now();
    
    final events = await (_db.select(_db.outboxEvents)
      ..where((e) => e.status.equals('failed'))
      ..where((e) => e.retryCount.isSmallerThan(e.maxRetries)))
      .get();
    
    // Filter by exponential backoff
    return events.where((event) {
      if (event.lastRetryAt == null) return true;
      
      final backoffMinutes = _calculateBackoff(event.retryCount);
      final nextRetry = event.lastRetryAt!.add(Duration(minutes: backoffMinutes));
      
      return now.isAfter(nextRetry);
    }).toList();
  }
  
  /// Calculate exponential backoff: 1, 2, 4, 8, 16 minutes
  int _calculateBackoff(int retryCount) {
    return min(pow(2, retryCount).toInt(), 60); // Max 60 minutes
  }
  
  /// Update event status with automatic retry management
  Future<void> updateStatus(
    String eventId, 
    String status, {
    String? error,
    bool incrementRetry = false,
  }) async {
    final updates = OutboxEventsCompanion(
      status: Value(status),
      errorMessage: Value(error),
    );
    
    if (status == 'success' || status == 'acked') {
      updates.copyWith(processedAt: Value(DateTime.now()));
    }
    
    if (status == 'failed' && incrementRetry) {
      final event = await (_db.select(_db.outboxEvents)
        ..where((e) => e.id.equals(eventId)))
        .getSingleOrNull();
      
      if (event != null) {
        await (_db.update(_db.outboxEvents)
          ..where((e) => e.id.equals(eventId)))
          .write(OutboxEventsCompanion(
            status: Value('failed'),
            errorMessage: Value(error),
            retryCount: Value(event.retryCount + 1),
            lastRetryAt: Value(DateTime.now()),
          ));
        return;
      }
    }
    
    await (_db.update(_db.outboxEvents)
      ..where((e) => e.id.equals(eventId)))
      .write(updates);
  }
  
  /// Retry failed events (with exponential backoff check)
  Future<void> retryEvent(String eventId) async {
    final event = await (_db.select(_db.outboxEvents)
      ..where((e) => e.id.equals(eventId)))
      .getSingleOrNull();
      
    if (event == null) return;
    
    // Check if max retries exceeded
    if (event.retryCount >= event.maxRetries) {
      await updateStatus(eventId, 'rejected', 
        error: 'Max retries exceeded');
      return;
    }
    
    await (_db.update(_db.outboxEvents)
      ..where((e) => e.id.equals(eventId)))
      .write(OutboxEventsCompanion(
        status: const Value('retry'),
        retryCount: Value(event.retryCount + 1),
        lastRetryAt: Value(DateTime.now()),
        errorMessage: const Value(null),
      ));
  }
  
  /// Mark event as conflict (requires user resolution)
  Future<void> markAsConflict(String eventId, String conflictDetails) async {
    await (_db.update(_db.outboxEvents)
      ..where((e) => e.id.equals(eventId)))
      .write(OutboxEventsCompanion(
        status: const Value('conflict'),
        errorMessage: Value(conflictDetails),
      ));
  }
  
  /// Mark event as rejected (permission denied, epoch mismatch, etc.)
  Future<void> markAsRejected(String eventId, String reason) async {
    await (_db.update(_db.outboxEvents)
      ..where((e) => e.id.equals(eventId)))
      .write(OutboxEventsCompanion(
        status: const Value('rejected'),
        errorMessage: Value(reason),
        processedAt: Value(DateTime.now()),
      ));
  }
  
  /// Get failed/rejected events for UI display
  Future<List<OutboxEvent>> getFailedEvents() async {
    return await (_db.select(_db.outboxEvents)
      ..where((e) => 
        e.status.equals('failed') | 
        e.status.equals('conflict') | 
        e.status.equals('rejected'))
      ..orderBy([(e) => OrderingTerm.desc(e.createdAt)]))
      .get();
  }
  
  /// Get count of pending events (for UI badge)
  Future<int> getPendingCount() async {
    final result = await (_db.selectOnly(_db.outboxEvents)
      ..addColumns([_db.outboxEvents.id.count()])
      ..where(_db.outboxEvents.status.equals('pending') | 
             _db.outboxEvents.status.equals('retry')))
      .getSingle();
    
    return result.read(_db.outboxEvents.id.count()) ?? 0;
  }
  
  /// Clear old processed events (cleanup)
  Future<void> clearProcessed({int daysOld = 7}) async {
    final cutoff = DateTime.now().subtract(Duration(days: daysOld));
    await (_db.delete(_db.outboxEvents)
      ..where((e) => 
        (e.status.equals('success') | e.status.equals('acked')) & 
        e.processedAt.isSmallerThanValue(cutoff)
      ))
      .go();
  }
  
  /// Clear all rejected events (user cleanup)
  Future<void> clearRejected() async {
    await (_db.delete(_db.outboxEvents)
      ..where((e) => e.status.equals('rejected')))
      .go();
  }
}
