/// Defines sync rules per entity type
/// This is the "Sync Contract Table" from the review
class SyncContract {
  final String entityType;
  final bool isSyncable;
  final DeleteType deleteType;
  final ConflictStrategy conflictStrategy;
  final bool requiresBaseRevision;
  
  const SyncContract({
    required this.entityType,
    required this.isSyncable,
    required this.deleteType,
    required this.conflictStrategy,
    this.requiresBaseRevision = true,
  });
  
  /// Master sync contract definition
  static const Map<String, SyncContract> contracts = {
    'budgets': SyncContract(
      entityType: 'budgets',
      isSyncable: true,
      deleteType: DeleteType.soft,
      conflictStrategy: ConflictStrategy.ownerWins,
    ),
    'semi_budgets': SyncContract(
      entityType: 'semi_budgets',
      isSyncable: true,
      deleteType: DeleteType.soft,
      conflictStrategy: ConflictStrategy.fieldMerge,
    ),
    'expenses': SyncContract(
      entityType: 'expenses',
      isSyncable: true,
      deleteType: DeleteType.soft,
      conflictStrategy: ConflictStrategy.fieldMerge,
    ),
    'categories': SyncContract(
      entityType: 'categories',
      isSyncable: true,
      deleteType: DeleteType.soft,
      conflictStrategy: ConflictStrategy.latest,
    ),
    'accounts': SyncContract(
      entityType: 'accounts',
      isSyncable: true,
      deleteType: DeleteType.soft,
      conflictStrategy: ConflictStrategy.latest,
    ),
    'savings_goals': SyncContract(
      entityType: 'savings_goals',
      isSyncable: true,
      deleteType: DeleteType.soft,
      conflictStrategy: ConflictStrategy.latest,
    ),
    'settings': SyncContract(
      entityType: 'settings',
      isSyncable: true,
      deleteType: DeleteType.replace,
      conflictStrategy: ConflictStrategy.latest,
      requiresBaseRevision: false,
    ),
  };
  
  /// Get contract for entity type
  static SyncContract? forEntity(String entityType) {
    return contracts[entityType];
  }
  
  /// Check if entity is syncable
  static bool isSyncableEntity(String entityType) {
    return contracts[entityType]?.isSyncable ?? false;
  }
  
  /// Get delete strategy for entity
  static DeleteType getDeleteType(String entityType) {
    return contracts[entityType]?.deleteType ?? DeleteType.hard;
  }
  
  /// Get conflict resolution strategy
  static ConflictStrategy getConflictStrategy(String entityType) {
    return contracts[entityType]?.conflictStrategy ?? ConflictStrategy.manual;
  }
}

enum DeleteType {
  /// Set is_deleted=true, tombstone=true, sync
  soft,
  
  /// Actually DELETE FROM table (not recommended for synced entities)
  hard,
  
  /// Just replace entire record (settings)
  replace,
}

enum ConflictStrategy {
  /// Owner of budget wins (for budgets)
  ownerWins,
  
  /// Merge non-conflicting fields, fail on conflicts
  fieldMerge,
  
  /// Latest timestamp wins (for settings, categories)
  latest,
  
  /// Always require user input (expert mode)
  manual,
}
