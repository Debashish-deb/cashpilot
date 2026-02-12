import 'package:drift/drift.dart';
import '../../../../data/drift/app_database.dart';

/// Dead Letter Queue Manager for Sync.
/// Handles fallback from Batch Mode -> Single Item Mode -> Error State.
class SyncDLQManager {
  final AppDatabase db;
  
  SyncDLQManager(this.db);

  /// Mark a specific record as 'error' (Dead Letter).
  /// This removes it from the 'dirty' queue so it doesn't block other items.
  Future<void> markAsError({
    required String table,
    required String id,
    required String errorReason,
  }) async {
    // We update the syncState to 'error' and potentially log the reason (conceptually).
    // In a real implementation, we might have a strict 'sync_errors' table.
    // For now, setting syncState='error' prevents it from being picked up by 'dirty' queries.
    
    final updateCompanion = _getCompanionForTable(table, id, errorReason);
    if (updateCompanion != null) {
      await _executeTableUpdate(table, updateCompanion, id);
    }
  }
  
  // Helper to map string table names to Drift table updates
  dynamic _getCompanionForTable(String tableName, String id, String error) {
    // This is a simplified mapping. In a full system, we might use a more generic approach or Reflection.
    switch (tableName) {
      case 'budgets':
        return db.budgets;
      case 'expenses':
        return db.expenses;
      case 'profiles':
        return db.users;
      // ... Add others as needed
      default:
        return null;
    }
  }

  Future<void> _executeTableUpdate(String tableName, dynamic table, String id) async {
     // Because Drift's `Updateable` is generic, we can't easily perform a generic `.where`.
     // We have to iterate the known tables.
     
     switch (tableName) {
       case 'budgets':
         await (db.update(db.budgets)..where((t) => t.id.equals(id)))
             .write(const BudgetsCompanion(syncState: Value('error')));
         break;
       case 'expenses':
         await (db.update(db.expenses)..where((t) => t.id.equals(id)))
             .write(const ExpensesCompanion(syncState: Value('error')));
         break;
       case 'users':
         await (db.update(db.users)..where((t) => t.id.equals(id)))
             .write(const UsersCompanion(syncState: Value('error')));
         break;
       case 'accounts':
         await (db.update(db.accounts)..where((t) => t.id.equals(id)))
             .write(const AccountsCompanion(syncState: Value('error')));
         break;
       // Add other critical tables as needed
     }
  }
}
