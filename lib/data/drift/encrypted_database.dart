/// Encrypted Database Executor
/// Provides SQLCipher-encrypted database connection
/// Uses KeyManager for encryption key
library;

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:sqlite3/sqlite3.dart'; 
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/open.dart';
import 'package:sqlcipher_flutter_libs/sqlcipher_flutter_libs.dart';

import '../../services/security/key_manager.dart';

class EncryptedDatabaseExecutor {
  static const _dbName = 'cashpilot_encrypted.db';
  static bool _sqlCipherLoaded = false;

  /// Open an encrypted database connection
  /// 
  /// [encryptionKey] 
  static LazyDatabase openEncryptedConnection(Future<String?> Function() getEncryptionKey) {
    return LazyDatabase(() async {
      // Load SQLCipher native library
      await initialize();

      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, _dbName));

      debugPrint('[EncryptedDB] Opening encrypted database at ${file.path}');

      // Get the encryption key
      final encryptionKey = await getEncryptionKey();
      
      // CRITICAL SECURITY: Never allow plaintext database for financial data
      if (encryptionKey == null || encryptionKey.isEmpty) {
        throw EncryptionKeyMissingException(
          'Cannot open database without encryption key. '
          'This is a security requirement for financial data. '
          'Please ensure secure storage is available on this device.'
        );
      }

      // Validate encryption key format (must be 64-character hex string)
      if (!_isValidEncryptionKey(encryptionKey)) {
        throw InvalidEncryptionKeyException(
          'Encryption key must be a 64-character hexadecimal string. '
          'Current key length: ${encryptionKey.length}'
        );
      }

      // Open with SQLCipher encryption
      return NativeDatabase(
        file,
        setup: (db) {
          // SECURITY: Use passphrase format (backward compatible)
          // The key must be set BEFORE any other operations
          // Note: Validated as hex string but passed as passphrase to SQLCipher
          // This maintains compatibility with existing databases
          db.execute("PRAGMA key = '$encryptionKey';");
          
          // Performance optimizations compatible with SQLCipher
          db.execute('PRAGMA cipher_page_size = 4096;');
          db.execute('PRAGMA kdf_iter = 256000;'); // PBKDF2 iterations
          // db.execute('PRAGMA cipher_memory_security = ON;'); // Disabled to prevent mlock warnings on Android
          
          // Verify encryption is working
          try {
            db.execute('SELECT count(*) FROM sqlite_master;');
            debugPrint('[EncryptedDB] ✅ Database encrypted and accessible');
          } catch (e) {
            debugPrint('[EncryptedDB] ❌ Encryption verification failed: $e');
            rethrow;
          }
        },
      );
    });
  }

  /// Ensure SQLCipher native library is loaded (async version)
  /// This must be called before opening any database connection
  static Future<void> initialize() async {
    if (_sqlCipherLoaded) return;

    // Load the SQLCipher library
    await applyWorkaroundToOpenSqlCipherOnOldAndroidVersions();
    
    open.overrideFor(OperatingSystem.android, openCipherOnAndroid);
    
    // Also override for iOS/macOS if needed (usually handled by linker)
    // But overriding ensures we use the bundled cipher version
    // open.overrideFor(OperatingSystem.iOS, openCipherOnIOS);
    
    _sqlCipherLoaded = true;
    
    debugPrint('[EncryptedDB] SQLCipher library initialized globally');
  }

  /// Synchronous initialization for lazy loading (called from provider)
  /// This is safe because the native library loading is synchronous
  static void initializeSync() {
    if (_sqlCipherLoaded) return;

    // Load the SQLCipher library (synchronous operations only)
    open.overrideFor(OperatingSystem.android, openCipherOnAndroid);
    
    _sqlCipherLoaded = true;
    
    debugPrint('[EncryptedDB] SQLCipher library initialized (sync)');
  }

  /// Check if database file exists
  static Future<bool> databaseExists() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, _dbName));
    return file.existsSync();
  }

  /// Get database file path
  static Future<String> getDatabasePath() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    return p.join(dbFolder.path, _dbName);
  }



  /// Verifies if the database file is valid and encrypted with the specific key
  static bool _checkDatabaseIntegrity(File file, String? key) {
    if (key == null) return false;
    
    // Open simply with sqlite3
    final db = sqlite3.open(file.path);
    try {
      // SECURITY: Validate key format before using
      if (!_isValidEncryptionKey(key)) {
        return false;
      }
      // Use passphrase format (same as database creation)
      db.execute("PRAGMA key = '$key';");
      db.execute('SELECT count(*) FROM sqlite_master;');
      return true;
    } catch (e) {
      // Code 26: file is not a database (HMAC check failed)
      debugPrint('[EncryptedDB] Integrity check failed: $e');
      return false;
    } finally {
      db.dispose();
    }
  }
}

/// Helper to get encryption key from KeyManager as hex string
Future<String?> getEncryptionKeyFromKeyManager(KeyManager keyManager) async {
  final keyBytes = await keyManager.getKey(KeyType.backupKey);
  if (keyBytes == null) return null;
  
  // Convert to hex string for SQLCipher PRAGMA key
  return keyBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}

/// Validates that encryption key is a proper 64-character hexadecimal string
/// This prevents SQL injection and ensures key quality
bool _isValidEncryptionKey(String key) {
  // Must be exactly 64 hex characters (256 bits / 32 bytes)
  return RegExp(r'^[0-9a-fA-F]{64}$').hasMatch(key);
}

/// Exception thrown when encryption key is missing
/// This is a critical security issue for financial data
class EncryptionKeyMissingException implements Exception {
  final String message;
  const EncryptionKeyMissingException(this.message);
  
  @override
  String toString() => 'EncryptionKeyMissingException: $message';
}

/// Exception thrown when encryption key format is invalid
class InvalidEncryptionKeyException implements Exception {
  final String message;
  const InvalidEncryptionKeyException(this.message);
  
  @override
  String toString() => 'InvalidEncryptionKeyException: $message';
}
