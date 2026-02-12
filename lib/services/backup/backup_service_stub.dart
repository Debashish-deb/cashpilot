/// Stub for Backup Service
library;

import 'backup_service.dart';

class PlatformBackupService implements BackupService {
  @override
  Future<String> createBackupFile(String jsonData, String fileName) {
    throw UnimplementedError('Platform not supported');
  }

  @override
  Future<String> readBackupFile(String path) {
    throw UnimplementedError('Platform not supported');
  }
}
