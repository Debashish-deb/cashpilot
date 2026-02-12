import 'package:drift/drift.dart';
import 'encrypted_database.dart';
import '../../services/security/key_manager.dart';

DatabaseConnection connect() {
  return DatabaseConnection(
    EncryptedDatabaseExecutor.openEncryptedConnection(() async {
      final keyManager = KeyManager();
      await keyManager.initialize();
      return getEncryptionKeyFromKeyManager(keyManager);
    }),
  );
}

void initializeDatabaseSync() {
  EncryptedDatabaseExecutor.initializeSync();
}
