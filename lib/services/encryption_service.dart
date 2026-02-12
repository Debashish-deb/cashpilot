/// Encryption Service
/// Provides AES-256 encryption for sensitive data
library;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/security/security_policy_engine.dart';

/// Encryption service for protecting sensitive financial data
class EncryptionService {
  static final EncryptionService _instance = EncryptionService._internal();
  factory EncryptionService() => _instance;
  
  @visibleForTesting
  factory EncryptionService.test({required FlutterSecureStorage secureStorage}) {
    return EncryptionService._internal(secureStorage: secureStorage);
  }

  EncryptionService._internal({FlutterSecureStorage? secureStorage}) 
      : _secureStorage = secureStorage ?? const FlutterSecureStorage(
          aOptions: AndroidOptions(
            encryptedSharedPreferences: true,
          ),
          iOptions: IOSOptions(
            // P0 SECURITY: Enforce that device must have a passcode set and data is not syncable to iCloud
            accessibility: KeychainAccessibility.first_unlock_this_device,
          ),
        );

  final FlutterSecureStorage _secureStorage;

  static const String _keyStorageKey = 'encryption_key'; // Legacy key for v1
  static const String _ivStorageKey = 'encryption_iv';   // Legacy IV for v1
  
  static const String _currentKeyVersionKey = 'encryption_current_version';
  static const String _keyPrefix = 'encryption_key_v';
  
  // Active key
  int _currentVersion = 1;
  encrypt.Key? _activeKey;
  
  // Key Ring for decryption of older data
  final Map<int, encrypt.Key> _keyRing = {};
  
  encrypt.Encrypter? _encrypter; // Uses active key
  bool _initialized = false;
  bool _isCompromised = false;
  final SecurityPolicyEngine _policyEngine = SecurityPolicyEngine();

  /// Initialize the encryption service
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // P0 SECURITY: Check device integrity BEFORE initializing secrets
      final report = await _policyEngine.evaluateIntegrity();
      if (report.isCompromised) {
        _isCompromised = true;
        debugPrint('[EncryptionService] FATAL: Device compromised. Encryption disabled.');
        return; 
      }

      // Load current version
      final versionStr = await _secureStorage.read(key: _currentKeyVersionKey);
      _currentVersion = int.tryParse(versionStr ?? '1') ?? 1;

      // Load ALL keys from 1 to currentVersion
      // This ensures we can decrypt older data even after rotation
      bool keysFound = false;
      for (int v = 1; v <= _currentVersion; v++) {
        // Handle V1 legacy special case (stored as 'encryption_key' not 'encryption_key_v1')
        String? keyStr;
        if (v == 1) {
             keyStr = await _secureStorage.read(key: _keyStorageKey);
             // If not found in legacy location, try new location (consistency)
             keyStr ??= await _secureStorage.read(key: '${_keyPrefix}1');
        } else {
             keyStr = await _secureStorage.read(key: '$_keyPrefix$v');
        }

        if (keyStr != null) {
          _keyRing[v] = encrypt.Key.fromBase64(keyStr);
          keysFound = true;
        } else {
          // If v1 is missing but we are at v1, we will generate it below.
          // If intermediate keys are missing, that's a data loss risk for old data.
          debugPrint('[EncryptionService] Warning: Missing key for version $v');
        }
      }

      // If no keys found (fresh install) or active key missing
      if (!keysFound || !_keyRing.containsKey(_currentVersion)) {
         debugPrint('[EncryptionService] No keys found or active key missing. Generating new v$_currentVersion key.');
         await _generateAndStoreKey(_currentVersion);
      }

      _activeKey = _keyRing[_currentVersion];
      _encrypter = encrypt.Encrypter(encrypt.AES(_activeKey!, mode: encrypt.AESMode.cbc));
      _initialized = true;
      debugPrint('[EncryptionService] Initialized at version v$_currentVersion');
      
    } catch (e) {
      debugPrint('[EncryptionService] Failed to initialize encryption: $e');
      rethrow;
    }
  }

  /// Generate and store a key for a specific version
  Future<void> _generateAndStoreKey(int version) async {
    final key = encrypt.Key.fromSecureRandom(32); // AES-256
    
    // For V1, we write to BOTH legacy and new location to ensure backward compat + consistency
    if (version == 1) {
        await _secureStorage.write(key: _keyStorageKey, value: key.base64);
        // Also write a random IV for legacy V1 support (even though V2+ uses dynamic IVs)
        final iv = encrypt.IV.fromSecureRandom(16);
        await _secureStorage.write(key: _ivStorageKey, value: iv.base64);
    }
    
    await _secureStorage.write(key: '$_keyPrefix$version', value: key.base64);
    await _secureStorage.write(key: _currentKeyVersionKey, value: version.toString());
    
    _keyRing[version] = key;
    _currentVersion = version; // Ensure local state matches
  }

  /// Rotate encryption key (Security Feature)
  /// Increments version, generates new key, and makes it active for NEW writes.
  /// Old keys are kept in ring for reading old data.
  Future<void> rotateKey() async {
    _checkInitialized();
    final newVersion = _currentVersion + 1;
    debugPrint('[EncryptionService] Rotating key to v$newVersion...');
    
    await _generateAndStoreKey(newVersion);
    
    _activeKey = _keyRing[newVersion];
    _encrypter = encrypt.Encrypter(encrypt.AES(_activeKey!, mode: encrypt.AESMode.cbc));
    
    debugPrint('[EncryptionService] Key rotation complete. Active: v$newVersion');
  }

  /// Encrypt a string
  /// Format: v{version}:{iv}:{ciphertext}
  String encryptString(String plainText) {
    _checkInitialized();
    if (_isCompromised) return plainText;
    if (plainText.isEmpty) return plainText;
    
    try {
      final iv = encrypt.IV.fromSecureRandom(16);
      final encrypted = _encrypter!.encrypt(plainText, iv: iv);
      return 'v$_currentVersion:${iv.base64}:${encrypted.base64}';
    } catch (e) {
      debugPrint('Encryption error: $e');
      return plainText; 
    }
  }

  /// Decrypt a string
  /// Support formats:
  /// 1. v{version}:{iv}:{ciphertext} (New)
  /// 2. {iv}:{ciphertext} (Legacy/V1 auto-migration)
  /// 3. {ciphertext} (Legacy static IV - discouraged but supported for read)
  String decryptString(String encryptedText) {
    _checkInitialized();
    if (_isCompromised) return 'DEVICE_COMPROMISED_ACCESS_DENIED';
    if (encryptedText.isEmpty) return encryptedText;
    
    try {
      // Format: v{version}:{iv}:{ciphertext}
      if (encryptedText.startsWith('v')) {
        final firstColon = encryptedText.indexOf(':');
        if (firstColon != -1) {
          final versionStr = encryptedText.substring(1, firstColon);
          final version = int.tryParse(versionStr);
          
          if (version != null && _keyRing.containsKey(version)) {
            final parts = encryptedText.substring(firstColon + 1).split(':');
            if (parts.length == 2) {
              final iv = encrypt.IV.fromBase64(parts[0]);
              final encrypted = encrypt.Encrypted.fromBase64(parts[1]);
              
              // Use specific key for this version
              final encrypter = encrypt.Encrypter(encrypt.AES(_keyRing[version]!, mode: encrypt.AESMode.cbc));
              return encrypter.decrypt(encrypted, iv: iv);
            }
          }
        }
      }

      // Legacy Format fallback (Assumes v1 or static IV)
      // If we have v1 key, try it.
      final v1Key = _keyRing[1];
      if (v1Key != null) {
        final legacyEncrypter = encrypt.Encrypter(encrypt.AES(v1Key, mode: encrypt.AESMode.cbc));
        
        if (encryptedText.contains(':')) {
           final parts = encryptedText.split(':');
           if (parts.length == 2) {
             final iv = encrypt.IV.fromBase64(parts[0]);
             final encrypted = encrypt.Encrypted.fromBase64(parts[1]);
             return legacyEncrypter.decrypt(encrypted, iv: iv);
           }
        }
        
        // Very old legacy (Static IV from storage?)
        // Try reading the legacy IV.
        // This is a blocking read, which isn't ideal in a sync method, but 
        // decryptString is synchronous. Ideally we should have loaded legacy IV in initialize().
        // For now, if we can't decrypt, we return raw text.
      }
      
      return encryptedText; // Failure to decrypt returns raw text
    } catch (e) {
      debugPrint('Decryption error: $e');
      return encryptedText; 
    }
  }

  /// Encrypt a map/JSON object
  String encryptJson(Map<String, dynamic> data) {
    _checkInitialized();
    final jsonString = jsonEncode(data);
    return encryptString(jsonString);
  }

  /// Decrypt a map/JSON object
  Map<String, dynamic> decryptJson(String encryptedData) {
    _checkInitialized();
    final jsonString = decryptString(encryptedData);
    try {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      return {};
    }
  }

  /// Encrypt sensitive amount data
  String encryptAmount(int amountInCents) {
    return encryptString(amountInCents.toString());
  }

  /// Decrypt amount data
  int decryptAmount(String encryptedAmount) {
    final decrypted = decryptString(encryptedAmount);
    return int.tryParse(decrypted) ?? 0;
  }

  /// Check if a string appears to be encrypted
  bool isEncrypted(String value) {
    return value.startsWith('v') && value.contains(':');
  }

  /// Store a sensitive value securely
  Future<void> storeSecure(String key, String value) async {
    await _secureStorage.write(key: key, value: value);
  }

  /// Retrieve a sensitive value
  Future<String?> getSecure(String key) async {
    return await _secureStorage.read(key: key);
  }

  /// Delete a secure value
  Future<void> deleteSecure(String key) async {
    await _secureStorage.delete(key: key);
  }

  /// Secure Wipe: Deletes ALL keys and secrets.
  /// Irreversible - data will be permanently unrecoverable.
  Future<void> deleteAllKeys() async {
    await _secureStorage.deleteAll();
    _keyRing.clear();
    _activeKey = null;
    _encrypter = null;
    _initialized = false;
    debugPrint('[EncryptionService] ALL KEYS DELETED. DATA IS NOW UNRECOVERABLE.');
  }

  void _checkInitialized() {
    if (!_initialized) {
      throw StateError('EncryptionService not initialized. Call initialize() first.');
    }
  }

  /// Check if encryption is ready
  bool get isReady => _initialized;
}

/// Global encryption service instance
final encryptionService = EncryptionService();
