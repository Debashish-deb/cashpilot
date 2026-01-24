/// KeyManager - Secure Key Storage and Encryption
/// Implements AES-256 encryption with device-controlled keys
/// Per Developer Report Section 4.1
library;

import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Key types managed by KeyManager
enum KeyType {
  /// Master key - used to derive other keys
  masterKey,
  /// Data key - used to encrypt sync payloads
  dataKey,
  /// Backup key - used to encrypt backups
  backupKey,
}

/// Actions for key loss scenario
enum KeyLossAction {
  /// No action needed - keys are valid
  noAction,
  /// Keys were regenerated - encrypted data is lost
  regenerated,
  /// App should lock and prompt user for action
  locked,
}

/// Manages encryption keys with secure storage
/// Keys are stored in:
/// - iOS: Keychain
/// - Android: Keystore
class KeyManager {
  final FlutterSecureStorage _storage;
  
  // Storage keys
  static const _masterKeyKey = 'cashpilot_master_key';
  static const _dataKeyKey = 'cashpilot_data_key';
  static const _backupKeyKey = 'cashpilot_backup_key';
  static const _keyCreatedAtKey = 'cashpilot_key_created_at';
  
  // AES-256 requires 32 bytes
  static const _keyLength = 32;
  
  KeyManager() : _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      keyCipherAlgorithm: KeyCipherAlgorithm.RSA_ECB_OAEPwithSHA_256andMGF1Padding,
      storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  /// Initialize keys if not present
  Future<void> initialize() async {
    final masterKey = await _storage.read(key: _masterKeyKey);
    if (masterKey == null) {
      debugPrint('[KeyManager] No master key found, generating new keys...');
      await _generateAllKeys();
      debugPrint('[KeyManager] Keys generated and stored securely');
    } else {
      debugPrint('[KeyManager] Encryption keys loaded from secure storage');
    }
  }

  /// Generate all encryption keys
  Future<void> _generateAllKeys() async {
    final masterKey = _generateSecureKey(_keyLength);
    final dataKey = _generateSecureKey(_keyLength);
    final backupKey = _generateSecureKey(_keyLength);
    
    await _storage.write(key: _masterKeyKey, value: base64Encode(masterKey));
    await _storage.write(key: _dataKeyKey, value: base64Encode(dataKey));
    await _storage.write(key: _backupKeyKey, value: base64Encode(backupKey));
    await _storage.write(key: _keyCreatedAtKey, value: DateTime.now().toIso8601String());
  }

  /// Generate cryptographically secure random key
  Uint8List _generateSecureKey(int length) {
    final random = Random.secure();
    return Uint8List.fromList(List.generate(length, (_) => random.nextInt(256)));
  }

  /// Get a key by type
  Future<Uint8List?> getKey(KeyType type) async {
    final storageKey = switch (type) {
      KeyType.masterKey => _masterKeyKey,
      KeyType.dataKey => _dataKeyKey,
      KeyType.backupKey => _backupKeyKey,
    };
    
    final encoded = await _storage.read(key: storageKey);
    if (encoded == null) return null;
    
    return base64Decode(encoded);
  }

  /// Check if keys exist
  Future<bool> hasKeys() async {
    final masterKey = await _storage.read(key: _masterKeyKey);
    return masterKey != null;
  }

  /// Get key creation date
  Future<DateTime?> getKeyCreatedAt() async {
    final dateStr = await _storage.read(key: _keyCreatedAtKey);
    if (dateStr == null) return null;
    return DateTime.tryParse(dateStr);
  }

  /// Delete all keys (for account deletion)
  Future<void> deleteAllKeys() async {
    await _storage.delete(key: _masterKeyKey);
    await _storage.delete(key: _dataKeyKey);
    await _storage.delete(key: _backupKeyKey);
    await _storage.delete(key: _keyCreatedAtKey);
    debugPrint('[KeyManager] All encryption keys deleted');
  }
  
  /// Handle key loss scenario
  /// 
  /// Called when keys are detected as missing/corrupted.
  /// Returns the action that should be taken by the caller.
  /// 
  /// Options:
  /// - KeyLossAction.regenerate: Keys regenerated (data will be lost)
  /// - KeyLossAction.locked: App should lock and prompt user
  Future<KeyLossAction> handleKeyLoss({
    required bool allowRegeneration,
  }) async {
    final hasExistingKeys = await hasKeys();
    
    if (hasExistingKeys) {
      // Keys exist but might be corrupted - verify
      final isValid = await verifyKeys();
      if (isValid) {
        return KeyLossAction.noAction;
      }
    }
    
    debugPrint('[KeyManager] ⚠️ Key loss detected');
    
    if (allowRegeneration) {
      // Delete any partial keys and regenerate
      await deleteAllKeys();
      await _generateAllKeys();
      debugPrint('[KeyManager] Keys regenerated (any encrypted local data is now inaccessible)');
      return KeyLossAction.regenerated;
    } else {
      debugPrint('[KeyManager] Keys missing - app should lock');
      return KeyLossAction.locked;
    }
  }
  
  /// Verify that keys are valid and can be used
  Future<bool> verifyKeys() async {
    try {
      final masterKey = await getKey(KeyType.masterKey);
      final dataKey = await getKey(KeyType.dataKey);
      
      if (masterKey == null || dataKey == null) return false;
      if (masterKey.length != _keyLength) return false;
      if (dataKey.length != _keyLength) return false;
      
      // Try a round-trip encryption to verify keys work
      const testData = 'key_verification_test';
      final encrypted = await encryptData(testData);
      final decrypted = await decryptData(encrypted);
      
      return decrypted == testData;
    } catch (e) {
      debugPrint('[KeyManager] Key verification failed: $e');
      return false;
    }
  }

  /// Encrypt data with AES-256-GCM
  Future<String> encryptData(String plaintext, {KeyType keyType = KeyType.dataKey}) async {
    final keyBytes = await getKey(keyType);
    if (keyBytes == null) {
      throw StateError('Encryption key not found. Call initialize() first.');
    }
    
    final key = encrypt.Key(keyBytes);
    final iv = encrypt.IV.fromSecureRandom(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.gcm));
    
    final encrypted = encrypter.encrypt(plaintext, iv: iv);
    
    // Return IV + encrypted data as base64
    final combined = Uint8List(iv.bytes.length + encrypted.bytes.length);
    combined.setAll(0, iv.bytes);
    combined.setAll(iv.bytes.length, encrypted.bytes);
    
    return base64Encode(combined);
  }

  /// Decrypt data with AES-256-GCM
  Future<String> decryptData(String ciphertext, {KeyType keyType = KeyType.dataKey}) async {
    final keyBytes = await getKey(keyType);
    if (keyBytes == null) {
      throw StateError('Encryption key not found. Call initialize() first.');
    }
    
    final combined = base64Decode(ciphertext);
    
    // Extract IV (first 16 bytes) and encrypted data
    final iv = encrypt.IV(Uint8List.fromList(combined.sublist(0, 16)));
    final encryptedBytes = Uint8List.fromList(combined.sublist(16));
    
    final key = encrypt.Key(keyBytes);
    final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.gcm));
    
    return encrypter.decrypt(encrypt.Encrypted(encryptedBytes), iv: iv);
  }

  /// Encrypt a JSON object
  Future<String> encryptJson(Map<String, dynamic> data, {KeyType keyType = KeyType.dataKey}) async {
    return encryptData(jsonEncode(data), keyType: keyType);
  }

  /// Decrypt to JSON object
  Future<Map<String, dynamic>> decryptJson(String ciphertext, {KeyType keyType = KeyType.dataKey}) async {
    final plaintext = await decryptData(ciphertext, keyType: keyType);
    return jsonDecode(plaintext) as Map<String, dynamic>;
  }

  /// Generate a hash of the master key for verification (without exposing the key)
  Future<String> getMasterKeyHash() async {
    final masterKey = await getKey(KeyType.masterKey);
    if (masterKey == null) return '';
    return sha256.convert(masterKey).toString().substring(0, 16);
  }
}

// Provider
final keyManagerProvider = Provider<KeyManager>((ref) {
  return KeyManager();
});
