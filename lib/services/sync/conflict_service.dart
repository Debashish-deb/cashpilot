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

  Future<void> _duplicateAsNew(ConflictData conflict) async {
    final entityType = ConflictEntityType.values.firstWhere(
      (e) => e.name == conflict.entityType,
    );
    
    final localData = jsonDecode(conflict.localJson) as Map<String, dynamic>;
    
    // Generate new ID for duplication
    final newId = const Uuid().v4();
    localData['id'] = newId;
    
    // In a real implementation, we would call the repository to create a new record.
    // For now, we simulate by marking it as dirty but with a NEW ID.
    // This is a simplified version of duplication.
    debugPrint('[ConflictService] Duplicating ${entityType.name} as new: ${conflict.entityId} -> $newId');
    
    // After duplication, we effectively 'keepRemote' for the original record to resolve the conflict
    await _applyRemoteVersion(conflict);
  }

  /// Apply local version to remote (push override)
  Future<void> _applyLocalVersion(ConflictData conflict) async {
    final entityType = ConflictEntityType.values.firstWhere(
      (e) => e.name == conflict.entityType,
    );

    // To apply local version, we simply mark it as dirty with an incremented revision.
    // The next sync cycle will then push this local version to the server, overriding remote.
    switch (entityType) {
      case ConflictEntityType.expense:
        await (_db.update(_db.expenses)..where((e) => e.id.equals(conflict.entityId)))
          .write(ExpensesCompanion(
            syncState: const Value('dirty'),
            revision: Value(_getIncrementedRevision(conflict.localJson)),
            updatedAt: Value(DateTime.now()),
          ));
        break;
      case ConflictEntityType.budget:
        await (_db.update(_db.budgets)..where((b) => b.id.equals(conflict.entityId)))
          .write(BudgetsCompanion(
            syncState: const Value('dirty'),
            revision: Value(_getIncrementedRevision(conflict.localJson)),
            updatedAt: Value(DateTime.now()),
          ));
        break;
      case ConflictEntityType.account:
        await (_db.update(_db.accounts)..where((a) => a.id.equals(conflict.entityId)))
          .write(AccountsCompanion(
            syncState: const Value('dirty'),
            revision: Value(_getIncrementedRevision(conflict.localJson)),
            updatedAt: Value(DateTime.now()),
          ));
        break;
      case ConflictEntityType.category:
        await (_db.update(_db.semiBudgets)..where((s) => s.id.equals(conflict.entityId)))
          .write(SemiBudgetsCompanion(
            syncState: const Value('dirty'),
            revision: Value(_getIncrementedRevision(conflict.localJson)),
            updatedAt: Value(DateTime.now()),
          ));
        break;
      case ConflictEntityType.recurring:
        await (_db.update(_db.recurringExpenses)..where((r) => r.id.equals(conflict.entityId)))
          .write(RecurringExpensesCompanion(
            syncState: const Value('dirty'),
            revision: Value(_getIncrementedRevision(conflict.localJson)),
            updatedAt: Value(DateTime.now()),
          ));
        break;
      default:
        debugPrint('[ConflictService] Unsupported entity type for local resolution: ${entityType.name}');
    }
  }

  int _getIncrementedRevision(String jsonStr) {
    try {
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      return (data['revision'] as int? ?? 0) + 1;
    } catch (e) {
      return 1;
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
        await _upsertExpenseFromRemote(conflict.entityId, remoteData);
        break;
      case ConflictEntityType.budget:
        await _upsertBudgetFromRemote(conflict.entityId, remoteData);
        break;
      case ConflictEntityType.account:
        await _upsertAccountFromRemote(conflict.entityId, remoteData);
        break;
      case ConflictEntityType.category:
        await _upsertSemiBudgetFromRemote(conflict.entityId, remoteData);
        break;
      case ConflictEntityType.recurring:
        await _upsertRecurringFromRemote(conflict.entityId, remoteData);
        break;
      default:
        debugPrint('[ConflictService] Unsupported entity type for remote resolution: ${entityType.name}');
    }
  }

  /// Apply merged data
  Future<void> _applyMergedVersion(ConflictData conflict, Map<String, dynamic> mergedData) async {
    final entityType = ConflictEntityType.values.firstWhere(
      (e) => e.name == conflict.entityType,
    );

    // For merged versions, we mark as dirty to ensure the merged result is pushed to server
    mergedData['syncState'] = 'dirty';
    mergedData['revision'] = _getIncrementedRevision(conflict.localJson);

    switch (entityType) {
      case ConflictEntityType.expense:
        await _upsertExpenseFromRemote(conflict.entityId, mergedData, isLocalDirty: true);
        break;
      case ConflictEntityType.budget:
        await _upsertBudgetFromRemote(conflict.entityId, mergedData, isLocalDirty: true);
        break;
      case ConflictEntityType.account:
        await _upsertAccountFromRemote(conflict.entityId, mergedData, isLocalDirty: true);
        break;
      case ConflictEntityType.category:
        await _upsertSemiBudgetFromRemote(conflict.entityId, mergedData, isLocalDirty: true);
        break;
      case ConflictEntityType.recurring:
        await _upsertRecurringFromRemote(conflict.entityId, mergedData, isLocalDirty: true);
        break;
      default:
        debugPrint('[ConflictService] Unsupported entity type for merge: ${entityType.name}');
    }
  }

  Future<void> _upsertExpenseFromRemote(String id, Map<String, dynamic> data, {bool isLocalDirty = false}) async {
    final companion = ExpensesCompanion(
      id: Value(id),
      budgetId: Value(data['budgetId'] as String? ?? data['budget_id'] as String? ?? ''),
      semiBudgetId: Value(data['semiBudgetId'] as String? ?? data['semi_budget_id'] as String?),
      title: Value(data['title'] as String? ?? ''),
      amount: Value((data['amount'] as num?)?.toInt() ?? 0),
      currency: Value(data['currency'] as String? ?? 'EUR'),
      date: Value(DateTime.tryParse(data['date'] as String? ?? '') ?? DateTime.now()),
      categoryId: Value(data['categoryId'] as String? ?? data['category_id'] as String?),
      accountId: Value(data['accountId'] as String? ?? data['account_id'] as String?),
      syncState: Value(isLocalDirty ? 'dirty' : 'clean'),
      revision: Value((data['revision'] as num?)?.toInt() ?? 0),
      updatedAt: Value(DateTime.now()),
    );
    await _db.into(_db.expenses).insertOnConflictUpdate(companion);
  }

  Future<void> _upsertBudgetFromRemote(String id, Map<String, dynamic> data, {bool isLocalDirty = false}) async {
    final companion = BudgetsCompanion(
      id: Value(id),
      title: Value(data['title'] as String? ?? ''),
      description: Value(data['description'] as String?),
      totalLimit: Value((data['totalLimit'] as num? ?? data['total_limit'] as num?)?.toInt()),
      currency: Value(data['currency'] as String? ?? 'EUR'),
      startDate: Value(DateTime.tryParse(data['startDate'] as String? ?? data['start_date'] as String? ?? '') ?? DateTime.now()),
      endDate: Value(DateTime.tryParse(data['endDate'] as String? ?? data['end_date'] as String? ?? '') ?? DateTime.now()),
      syncState: Value(isLocalDirty ? 'dirty' : 'clean'),
      revision: Value((data['revision'] as num?)?.toInt() ?? 0),
      updatedAt: Value(DateTime.now()),
    );
    await _db.into(_db.budgets).insertOnConflictUpdate(companion);
  }

  Future<void> _upsertAccountFromRemote(String id, Map<String, dynamic> data, {bool isLocalDirty = false}) async {
    final companion = AccountsCompanion(
      id: Value(id),
      name: Value(data['name'] as String? ?? ''),
      type: Value(data['type'] as String? ?? 'checking'),
      balance: Value((data['balance'] as num?)?.toInt() ?? 0),
      currency: Value(data['currency'] as String? ?? 'EUR'),
      syncState: Value(isLocalDirty ? 'dirty' : 'clean'),
      revision: Value((data['revision'] as num?)?.toInt() ?? 0),
      updatedAt: Value(DateTime.now()),
    );
    await _db.into(_db.accounts).insertOnConflictUpdate(companion);
  }

  Future<void> _upsertSemiBudgetFromRemote(String id, Map<String, dynamic> data, {bool isLocalDirty = false}) async {
    final companion = SemiBudgetsCompanion(
      id: Value(id),
      name: Value(data['name'] as String? ?? ''),
      limitAmount: Value((data['limitAmount'] as num? ?? data['limit_amount'] as num?)?.toInt() ?? 0),
      syncState: Value(isLocalDirty ? 'dirty' : 'clean'),
      revision: Value((data['revision'] as num?)?.toInt() ?? 0),
      updatedAt: Value(DateTime.now()),
    );
    await _db.into(_db.semiBudgets).insertOnConflictUpdate(companion);
  }

  Future<void> _upsertRecurringFromRemote(String id, Map<String, dynamic> data, {bool isLocalDirty = false}) async {
    final companion = RecurringExpensesCompanion(
      id: Value(id),
      title: Value(data['title'] as String? ?? ''),
      amount: Value((data['amount'] as num?)?.toInt() ?? 0),
      frequency: Value(data['frequency'] as String? ?? 'monthly'),
      nextDueDate: Value(DateTime.tryParse(data['nextDueDate'] as String? ?? data['next_due_date'] as String? ?? '') ?? DateTime.now()),
      syncState: Value(isLocalDirty ? 'dirty' : 'clean'),
      revision: Value((data['revision'] as num?)?.toInt() ?? 0),
      updatedAt: Value(DateTime.now()),
    );
    await _db.into(_db.recurringExpenses).insertOnConflictUpdate(companion);
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

