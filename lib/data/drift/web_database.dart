/// Web Database Implementation for Drift
/// Uses drift_wasm or sql.js for web support
library;

import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';

DatabaseConnection connect() {
  return DatabaseConnection.delayed(Future(() async {
    final result = await WasmDatabase.open(
      databaseName: 'cashpilot_db',
      sqlite3Uri: Uri.parse('sqlite3.wasm'),
      driftWorkerUri: Uri.parse('drift_worker.js'),
    );

    if (result.missingFeatures.isNotEmpty) {
      print('Using ${result.chosenImplementation} due to missing features: ${result.missingFeatures}');
    }

    return DatabaseConnection(result.resolvedExecutor);
  }));
}

void initializeDatabaseSync() {
  // Web does not need synchronous initialization for SQLCipher
}
