/// Native Backup Service Implementation
library;

import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../security/key_manager.dart';
import 'backup_service.dart';

class PlatformBackupService implements BackupService {
  @override
  Future<String> createBackupFile(String jsonData, String fileName) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$fileName');

    // Encrypt backup payload with AES-256-GCM using KeyManager backupKey
    String payloadToWrite = jsonData;
    try {
      final keyManager = KeyManager();
      await keyManager.initialize();
      final encryptedData = await keyManager.encryptData(jsonData, keyType: KeyType.backupKey);
      final envelope = {
        'encrypted': true,
        'algorithm': 'AES-256-GCM',
        'version': 1,
        'createdAt': DateTime.now().toIso8601String(),
        'payload': encryptedData,
      };
      payloadToWrite = jsonEncode(envelope);
    } catch (_) {
      // If secure storage / key manager is unavailable, fallback to direct payload
      payloadToWrite = jsonData;
    }

    await file.writeAsString(payloadToWrite);
    return file.path;
  }

}
