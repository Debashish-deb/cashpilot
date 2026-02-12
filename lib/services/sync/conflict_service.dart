/// Conflict Service
/// Handles conflict detection, storage, and resolution
library;

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart';

import '../../data/drift/app_database.dart';

/// Entity types that can have conflicts
enum ConflictEntityType {
  expense,
  budget,
  account,
  category,
  recurring,
  setting,
}

/// Resolution actions for conflicts
enum ConflictResolution {
  pending,
  keepLocal,
  keepRemote,
  merge,
  duplicate,
}

/// Represents a field-level diff for conflict display
class ConflictDiff {
  final String fieldName;
  final String? localValue;
  final String? remoteValue;
  final bool isDifferent;

  ConflictDiff({
    required this.fieldName,
    required this.localValue,
    required this.remoteValue,
  }) : isDifferent = localValue != remoteValue;
}

/// Service for managing sync conflicts
class ConflictService {
  final AppDatabase _db;
  final _uuid = const Uuid();

  ConflictService(this._db);

  /// Create a new conflict record
  Future<String> createConflict({
    required ConflictEntityType entityType,
    required String entityId,
    required Map<String, dynamic> localData,
    required Map<String, dynamic> remoteData,
    String? deviceId,
  }) async {
    final id = _uuid.v4();
    final diff = _computeDiff(localData, remoteData);

    await _db.into(_db.conflicts).insert(ConflictsCompanion.insert(
      id: id,
      entityType: entityType.name,
      entityId: entityId,
      localJson: jsonEncode(localData),
      remoteJson: jsonEncode(remoteData),
      diffJson: Value(jsonEncode(diff)),
      detectedByDeviceId: Value(deviceId),
    ));

    debugPrint('[ConflictService] Created conflict: $id for ${entityType.name}:$entityId');
    return id;
  }

  /// Get all open conflicts
  Future<List<ConflictData>> getOpenConflicts() async {
    final rows = await (_db.select(_db.conflicts)
      ..where((c) => c.status.equals('open'))
      ..orderBy([(c) => OrderingTerm.desc(c.createdAt)])
    ).get();
    return rows;
  }

  /// Get open conflict count stream
  Stream<int> watchOpenConflictCount() {
    return (_db.selectOnly(_db.conflicts)
      ..addColumns([_db.conflicts.id.count()])
      ..where(_db.conflicts.status.equals('open'))
    ).watchSingle().map((row) => row.read(_db.conflicts.id.count()) ?? 0);
  }

  /// Get current conflict count
  Future<int> getConflictCount() async {
    final result = await (_db.selectOnly(_db.conflicts)
      ..addColumns([_db.conflicts.id.count()])
      ..where(_db.conflicts.status.equals('open'))
    ).getSingle();
    return result.read(_db.conflicts.id.count()) ?? 0;
  }

  /// Resolve a conflict with the chosen action
  Future<void> resolveConflict({
    required String conflictId,
    required ConflictResolution resolution,
    Map<String, dynamic>? mergedData,
  }) async {
    final conflict = await (_db.select(_db.conflicts)
      ..where((c) => c.id.equals(conflictId))
    ).getSingleOrNull();

    if (conflict == null) {
      debugPrint('[ConflictService] Conflict not found: $conflictId');
      return;
    }

    // Apply resolution
    switch (resolution) {
      case ConflictResolution.keepLocal:
        await _applyLocalVersion(conflict);
        break;
      case ConflictResolution.keepRemote:
        await _applyRemoteVersion(conflict);
        break;
      case ConflictResolution.duplicate:
        await _duplicateAsNew(conflict);
        break;
      case ConflictResolution.merge:
        if (mergedData != null) {
          await _applyMergedVersion(conflict, mergedData);
        }
        break;
      case ConflictResolution.pending:
        return; // No action
    }

    // Mark conflict as resolved
    await (_db.update(_db.conflicts)..where((c) => c.id.equals(conflictId)))
      .write(ConflictsCompanion(
        status: const Value('resolved'),
        resolutionType: Value(resolution.name),
        resolvedAt: Value(DateTime.now()),
      ));

    debugPrint('[ConflictService] Resolved conflict: $conflictId with ${resolution.name}');
  }

  /// Apply local version to remote (push override)
  Future<void> _applyLocalVersion(ConflictData conflict) async {
    final localData = jsonDecode(conflict.localJson) as Map<String, dynamic>;
    final entityType = ConflictEntityType.values.firstWhere(
      (e) => e.name == conflict.entityType,
    );

    switch (entityType) {
      case ConflictEntityType.expense:
        // Update local expense with incremented revision, mark dirty for sync
        await (_db.update(_db.expenses)..where((e) => e.id.equals(conflict.entityId)))
          .write(ExpensesCompanion(
            syncState: const Value('dirty'),
            revision: Value((localData['revision'] as int? ?? 0) + 1),
            updatedAt: Value(DateTime.now()),
          ));
        break;
      case ConflictEntityType.budget:
        await (_db.update(_db.budgets)..where((b) => b.id.equals(conflict.entityId)))
          .write(BudgetsCompanion(
            syncState: const Value('dirty'),
            revision: Value((localData['revision'] as int? ?? 0) + 1),
            updatedAt: Value(DateTime.now()),
          ));
        break;
      default:
        debugPrint('[ConflictService] Unsupported entity type for local resolution: ${entityType.name}');
    }
  }

  /// Apply remote version locally (discard local changes)
  Future<void> _applyRemoteVersion(ConflictData conflict) async {
    final remoteData = jsonDecode(conflict.remoteJson) as Map<String, dynamic>;
    final entityType = ConflictEntityType.values.firstWhere(
      (e) => e.name == conflict.entityType,
    );

    switch (entityType) {
      case ConflictEntityType.expense:
        // Replace local with remote data
        await _updateExpenseFromJson(conflict.entityId, remoteData);
        break;
      case ConflictEntityType.budget:
        await _updateBudgetFromJson(conflict.entityId, remoteData);
        break;
      default:
        debugPrint('[ConflictService] Unsupported entity type for remote resolution: ${entityType.name}');
    }
  }

  /// Create duplicate (for expenses: keep both versions)
  Future<void> _duplicateAsNew(ConflictData conflict) async {
    final localData = jsonDecode(conflict.localJson) as Map<String, dynamic>;
    
    // Only supported for expenses and budgets
    if (conflict.entityType != 'expense' && conflict.entityType != 'budget') {
      debugPrint('[ConflictService] Duplicate only supported for expenses and budgets');
      return;
    }

    if (conflict.entityType == 'expense') {
      final newId = _uuid.v4();
      localData['id'] = newId;
      localData['syncState'] = 'dirty';
      localData['revision'] = 1;

      // Insert as new expense
      await _db.into(_db.expenses).insert(
        ExpensesCompanion.insert(
          id: newId,
          budgetId: localData['budgetId'] as String? ?? '',
          semiBudgetId: Value(localData['semiBudgetId'] as String?),
          title: localData['title'] as String? ?? '',
          amount: (localData['amount'] as num?)?.toInt() ?? 0,
          currency: Value(localData['currency'] as String? ?? 'USD'),
          date: DateTime.tryParse(localData['date'] as String? ?? '') ?? DateTime.now(),
          categoryId: Value(localData['categoryId'] as String?),
          accountId: Value(localData['accountId'] as String?),
          enteredBy: localData['enteredBy'] as String? ?? '',
          tags: Value(localData['tags'] as String?),
          syncState: const Value('dirty'),
        ),
      );
      debugPrint('[ConflictService] Created duplicate expense: $newId');
    } else if (conflict.entityType == 'budget') {
      final newId = _uuid.v4();
      localData['id'] = newId;

      await _db.into(_db.budgets).insert(
        BudgetsCompanion.insert(
          id: newId,
          title: localData['title'] as String? ?? '',
          description: Value(localData['description'] as String?),
          type: localData['type'] as String? ?? 'monthly',
          totalLimit: Value((localData['total_limit'] as num?)?.toInt() ?? 0),
          currency: Value(localData['currency'] as String? ?? 'USD'),
          startDate: DateTime.tryParse(localData['start_date'] as String? ?? '') ?? DateTime.now(),
          endDate: DateTime.tryParse(localData['end_date'] as String? ?? '') ?? DateTime.now(),
          ownerId: localData['owner_id'] as String? ?? localData['user_id'] as String? ?? '',
          syncState: const Value('dirty'),
          revision: const Value(1),
        ),
      );
      debugPrint('[ConflictService] Created duplicate budget: $newId');
    }
  }

  /// Apply merged data
  Future<void> _applyMergedVersion(ConflictData conflict, Map<String, dynamic> mergedData) async {
    final entityType = ConflictEntityType.values.firstWhere(
      (e) => e.name == conflict.entityType,
    );

    switch (entityType) {
      case ConflictEntityType.expense:
        await _updateExpenseFromJson(conflict.entityId, mergedData);
        break;
      case ConflictEntityType.budget:
        await _updateBudgetFromJson(conflict.entityId, mergedData);
        break;
      default:
        debugPrint('[ConflictService] Unsupported entity type for merge: ${entityType.name}');
    }
  }

  /// Update expense from JSON data
  Future<void> _updateExpenseFromJson(String id, Map<String, dynamic> data) async {
    await (_db.update(_db.expenses)..where((e) => e.id.equals(id)))
      .write(ExpensesCompanion(
        title: Value(data['title'] as String? ?? ''),
        amount: Value((data['amount'] as num?)?.toInt() ?? 0),
        currency: Value(data['currency'] as String? ?? 'USD'),
        date: Value(DateTime.tryParse(data['date'] as String? ?? '') ?? DateTime.now()),
        categoryId: Value(data['categoryId'] as String?),
        syncState: const Value('synced'),
        updatedAt: Value(DateTime.now()),
      ));
  }

  /// Update budget from JSON data
  Future<void> _updateBudgetFromJson(String id, Map<String, dynamic> data) async {
    await (_db.update(_db.budgets)..where((b) => b.id.equals(id)))
      .write(BudgetsCompanion(
        title: Value(data['title'] as String? ?? ''),
        totalLimit: Value((data['totalLimit'] as num?)?.toInt()),
        currency: Value(data['currency'] as String? ?? 'USD'),
        syncState: const Value('synced'),
        updatedAt: Value(DateTime.now()),
      ));
  }

  /// Compute diff between local and remote
  List<Map<String, dynamic>> _computeDiff(
    Map<String, dynamic> local,
    Map<String, dynamic> remote,
  ) {
    final diffs = <Map<String, dynamic>>[];
    final allKeys = {...local.keys, ...remote.keys};
    
    // Skip metadata fields
    final skipFields = {'id', 'createdAt', 'updatedAt', 'revision', 'syncState', 'isDeleted'};
    
    for (final key in allKeys) {
      if (skipFields.contains(key)) continue;
      
      final localVal = local[key]?.toString();
      final remoteVal = remote[key]?.toString();
      
      if (localVal != remoteVal) {
        diffs.add({
          'field': key,
          'local': localVal,
          'remote': remoteVal,
        });
      }
    }
    
    return diffs;
  }

  /// Parse diffs from conflict record
  List<ConflictDiff> parseDiffs(ConflictData conflict) {
    if (conflict.diffJson == null) return [];
    
    try {
      final diffList = jsonDecode(conflict.diffJson!) as List;
      return diffList.map((d) => ConflictDiff(
        fieldName: d['field'] as String,
        localValue: d['local'] as String?,
        remoteValue: d['remote'] as String?,
      )).toList();
    } catch (e) {
      return [];
    }
  }
}

// Providers

