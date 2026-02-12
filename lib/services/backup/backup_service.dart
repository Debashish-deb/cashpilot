/// Backup Service Interface
/// Abstract base class for platform-specific backup implementations
library;

import 'package:cross_file/cross_file.dart';

abstract class BackupService {
  Future<String> createBackupFile(String jsonData, String fileName);
}
