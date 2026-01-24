/// Encryption Service
/// Provides AES-256 encryption for sensitive data
library;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Encryption service for protecting sensitive financial data
class EncryptionService {
  static final EncryptionService _instance = EncryptionService._internal();
  factory EncryptionService() => _instance;
  EncryptionService._internal();

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  static const String _keyStorageKey = 'encryption_key';
  static const String _ivStorageKey = 'encryption_iv';
  
  encrypt.Key? _key;
  encrypt.IV? _iv;
  encrypt.Encrypter? _encrypter;
  bool _initialized = false;

  /// Initialize the encryption service
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Try to load existing key
      String? storedKey = await _secureStorage.read(key: _keyStorageKey);
      String? storedIv = await _secureStorage.read(key: _ivStorageKey);

      if (storedKey != null && storedIv != null) {
        // Use existing key
        _key = encrypt.Key.fromBase64(storedKey);
        _iv = encrypt.IV.fromBase64(storedIv);
      } else {
        // Generate new key
        _key = encrypt.Key.fromSecureRandom(32); // AES-256
        _iv = encrypt.IV.fromSecureRandom(16);
        
        // Store keys securely
        await _secureStorage.write(key: _keyStorageKey, value: _key!.base64);
        await _secureStorage.write(key: _ivStorageKey, value: _iv!.base64);
      }

      _encrypter = encrypt.Encrypter(encrypt.AES(_key!, mode: encrypt.AESMode.cbc));
      _initialized = true;
      debugPrint('[EncryptionService] Initialized');
    } catch (e) {
      debugPrint('[EncryptionService] Failed to initialize encryption: $e');
      rethrow;
    }
  }

  /// Encrypt a string with a random IV
  /// Format: IV(base64):Ciphertext(base64)
  String encryptString(String plainText) {
    _checkInitialized();
    if (plainText.isEmpty) return plainText;
    
    try {
      final iv = encrypt.IV.fromSecureRandom(16);
      final encrypted = _encrypter!.encrypt(plainText, iv: iv);
      return '${iv.base64}:${encrypted.base64}';
    } catch (e) {
      debugPrint('Encryption error: $e');
      return plainText; 
    }
  }

  /// Decrypt a string (supports legacy and new format)
  String decryptString(String encryptedText) {
    _checkInitialized();
    if (encryptedText.isEmpty) return encryptedText;
    
    try {
      // Check if it's new format with IV
      if (encryptedText.contains(':')) {
        final parts = encryptedText.split(':');
        if (parts.length == 2) {
          final iv = encrypt.IV.fromBase64(parts[0]);
          final encrypted = encrypt.Encrypted.fromBase64(parts[1]);
          return _encrypter!.decrypt(encrypted, iv: iv);
        }
      }
      
      // Fallback: Try legacy decryption (static IV)
      // Note: This is for backward compatibility during migration
      final encrypted = encrypt.Encrypted.fromBase64(encryptedText);
      return _encrypter!.decrypt(encrypted, iv: _iv);
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

  /// Check if a string appears to be encrypted (base64 format)
  bool isEncrypted(String value) {
    try {
      base64Decode(value);
      return value.length > 20; // Encrypted data is typically longer
    } catch (e) {
      return false;
    }
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

  /// Clear all stored encryption keys (use with caution!)
  Future<void> resetEncryption() async {
    await _secureStorage.deleteAll();
    _key = null;
    _iv = null;
    _encrypter = null;
    _initialized = false;
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
