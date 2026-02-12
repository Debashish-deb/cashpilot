/// Native Backup Service Implementation
library;

import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'backup_service.dart';

class PlatformBackupService implements BackupService {
  @override
  Future<String> createBackupFile(String jsonData, String fileName) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(jsonData);
    return file.path;
  }

}
