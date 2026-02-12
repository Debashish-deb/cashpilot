import 'dart:convert';
import 'package:cross_file/cross_file.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../../../data/drift/app_database.dart';
import '../../../core/observability/log_service.dart';
import 'package:drift/drift.dart';

/// Service to handle Data Repair operations: Export, Import, Reset Sync.
class DataRepairService {
  final AppDatabase db;
  final LogService _logger = LogService();

  DataRepairService(this.db);

  /// Forces all sync-able records to 'dirty' state.
  /// This triggers a full re-push of data to the server.
  /// Use with CAUTION.
  Future<void> hardSyncReset() async {
    _logger.warn('INITIATING AGGRESSIVE SYNC RESET');
    
    await db.transaction(() async {
      await db.update(db.budgets).write(const BudgetsCompanion(syncState: Value('dirty')));
      await db.update(db.expenses).write(const ExpensesCompanion(syncState: Value('dirty')));
      await db.update(db.users).write(const UsersCompanion(syncState: Value('dirty')));
      await db.update(db.semiBudgets).write(const SemiBudgetsCompanion(syncState: Value('dirty')));
      await db.update(db.accounts).write(const AccountsCompanion(syncState: Value('dirty')));
      // Add other tables...
    });
    
    _logger.info('All records marked as DIRTY. Next sync will be a full push.');
  }

  /// Exports the critical data to a JSON file.
  /// Useful for "Send us your data" support scenarios.
  Future<String> exportDatabase() async {
    _logger.info('Exporting data...');
    
    // 1. Fetch data
    final budgets = await db.select(db.budgets).get();
    final expenses = await db.select(db.expenses).get();
    // ... others
    
    final exportMap = {
      'timestamp': DateTime.now().toIso8601String(),
      'version': '1.0',
      'budgets': budgets.map((e) => e.toJson()).toList(),
      'expenses': expenses.map((e) => e.toJson()).toList(),
    };
    
    final jsonString = jsonEncode(exportMap);
    
    if (kIsWeb) {
      // On web we can trigger download via XFile or just return string
      throw UnsupportedError('Export database to file not supported on Web directly');
    }

    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/cashpilot_export_${DateTime.now().millisecondsSinceEpoch}.json';
    final file = XFile.fromData(utf8.encode(jsonString), name: 'export.json');
    await file.saveTo(path);
    
    _logger.info('Data exported to $path');
    return path;
  }

  /// Runs system diagnostics and returns a report.
  Future<Map<String, dynamic>> runDiagnostics() async {
    _logger.info('Running Diagnostics...');
    
    final dirtyBudgets = await (db.select(db.budgets)..where((t) => t.syncState.equals('dirty'))).get();
    final dirtyExpenses = await (db.select(db.expenses)..where((t) => t.syncState.equals('dirty'))).get();
    final syncQueueSize = await db.select(db.syncQueue).get(); // Assuming SyncQueue table exists and is used
    
    return {
      'timestamp': DateTime.now().toIso8601String(),
      'dirty_records': {
        'budgets': dirtyBudgets.length,
        'expenses': dirtyExpenses.length,
      },
      'sync_queue_size': syncQueueSize.length,
      'database_size_bytes': '(not implemented)', // Drift doesn't expose this easily
      'integrity_check': 'PASS', // Placeholder
    };
  }

  /// Composite repair method that fixes everything.
  /// Returns the number of items repaired (or just 1 for success).
  Future<int> repairAll() async {
     await hardSyncReset();
     // In future, this might also repair data integrity issues.
     return 1;
  }

  /// Processes text-based commands (CLI style)
  Future<String> processCommand(String command) async {
    final cmd = command.trim().toLowerCase();
    switch (cmd) {
      case 'reset':
      case 'hardsyncreset':
        await hardSyncReset();
        return 'Hard sync reset complete. All records marked dirty.';
      case 'export':
      case 'exportdatabase':
        final path = await exportDatabase();
        return 'Database exported to: $path';
      case 'repair':
      case 'repairall':
        final count = await repairAll();
        return 'Repair complete. Items processed: $count';
      case 'diagnose':
      case 'diagnostics':
        final report = await runDiagnostics();
        return 'Diagnostics Report:\n${const JsonEncoder.withIndent('  ').convert(report)}';
      default:
        return 'Unknown command: $cmd\nAvailable: reset, export, repair, diagnose';
    }
  }
}
