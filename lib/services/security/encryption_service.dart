/// Encryption Service
/// Provides E2E encryption for sync payloads and sensitive data
/// Per Developer Report Section 4.2-4.3
library;

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'key_manager.dart';

/// Service for encrypting/decrypting data before sync
class EncryptionService {
  final KeyManager _keyManager;
  bool _initialized = false;

  EncryptionService(this._keyManager);

  /// Initialize encryption (must be called at app start)
  Future<void> initialize() async {
    if (_initialized) return;
    await _keyManager.initialize();
    _initialized = true;
    debugPrint('[EncryptionService] Initialized with E2E encryption');
  }

  /// Check if encryption is ready
  bool get isReady => _initialized;

  /// Encrypt a sync payload before sending to cloud
  /// This ensures "encrypted on device before cloud sync"
  Future<EncryptedPayload> encryptSyncPayload(Map<String, dynamic> payload) async {
    if (!_initialized) {
      throw StateError('EncryptionService not initialized');
    }

    final jsonStr = jsonEncode(payload);
    final encrypted = await _keyManager.encryptData(jsonStr, keyType: KeyType.dataKey);
    final keyHash = await _keyManager.getMasterKeyHash();

    return EncryptedPayload(
      version: 1,
      algorithm: 'AES-256-GCM',
      keyHash: keyHash,
      data: encrypted,
      encryptedAt: DateTime.now(),
    );
  }

  /// Decrypt a received sync payload
  Future<Map<String, dynamic>> decryptSyncPayload(EncryptedPayload payload) async {
    if (!_initialized) {
      throw StateError('EncryptionService not initialized');
    }

    // Verify key hash matches
    final keyHash = await _keyManager.getMasterKeyHash();
    if (payload.keyHash != keyHash) {
      throw StateError('Key mismatch - data encrypted with different key');
    }

    return _keyManager.decryptJson(payload.data, keyType: KeyType.dataKey);
  }

  /// Encrypt sensitive fields in an entity (e.g., bank account numbers)
  Future<Map<String, dynamic>> encryptSensitiveFields(
    Map<String, dynamic> entity,
    List<String> sensitiveFields,
  ) async {
    final result = Map<String, dynamic>.from(entity);
    
    for (final field in sensitiveFields) {
      if (result.containsKey(field) && result[field] != null) {
        final value = result[field].toString();
        result[field] = await _keyManager.encryptData(value, keyType: KeyType.dataKey);
        result['${field}_encrypted'] = true;
      }
    }
    
    return result;
  }

  /// Decrypt sensitive fields in an entity
  Future<Map<String, dynamic>> decryptSensitiveFields(
    Map<String, dynamic> entity,
    List<String> sensitiveFields,
  ) async {
    final result = Map<String, dynamic>.from(entity);
    
    for (final field in sensitiveFields) {
      if (result['${field}_encrypted'] == true && result[field] != null) {
        result[field] = await _keyManager.decryptData(
          result[field] as String,
          keyType: KeyType.dataKey,
        );
        result.remove('${field}_encrypted');
      }
    }
    
    return result;
  }

  /// Encrypt bank credentials (highest security)
  Future<String> encryptBankCredentials(Map<String, dynamic> credentials) async {
    if (!_initialized) {
      throw StateError('EncryptionService not initialized');
    }
    
    // Use master key for bank credentials (most sensitive)
    return _keyManager.encryptJson(credentials, keyType: KeyType.masterKey);
  }

  /// Decrypt bank credentials
  Future<Map<String, dynamic>> decryptBankCredentials(String encrypted) async {
    if (!_initialized) {
      throw StateError('EncryptionService not initialized');
    }
    
    return _keyManager.decryptJson(encrypted, keyType: KeyType.masterKey);
  }

  /// Get encryption status for display in settings
  Future<EncryptionStatus> getStatus() async {
    final hasKeys = await _keyManager.hasKeys();
    final createdAt = await _keyManager.getKeyCreatedAt();
    final keyHash = hasKeys ? await _keyManager.getMasterKeyHash() : null;

    return EncryptionStatus(
      isEnabled: hasKeys,
      algorithm: 'AES-256-GCM',
      keyCreatedAt: createdAt,
      keyFingerprint: keyHash,
    );
  }

  /// Delete all encryption keys (for account deletion)
  Future<void> deleteKeys() async {
    await _keyManager.deleteAllKeys();
    _initialized = false;
    debugPrint('[EncryptionService] All keys deleted');
  }
}

/// Encrypted payload wrapper for sync
class EncryptedPayload {
  final int version;
  final String algorithm;
  final String keyHash;
  final String data;
  final DateTime encryptedAt;

  EncryptedPayload({
    required this.version,
    required this.algorithm,
    required this.keyHash,
    required this.data,
    required this.encryptedAt,
  });

  Map<String, dynamic> toJson() => {
    'version': version,
    'algorithm': algorithm,
    'keyHash': keyHash,
    'data': data,
    'encryptedAt': encryptedAt.toIso8601String(),
  };

  factory EncryptedPayload.fromJson(Map<String, dynamic> json) => EncryptedPayload(
    version: json['version'] as int,
    algorithm: json['algorithm'] as String,
    keyHash: json['keyHash'] as String,
    data: json['data'] as String,
    encryptedAt: DateTime.parse(json['encryptedAt'] as String),
  );
}

/// Encryption status for display
class EncryptionStatus {
  final bool isEnabled;
  final String algorithm;
  final DateTime? keyCreatedAt;
  final String? keyFingerprint;

  EncryptionStatus({
    required this.isEnabled,
    required this.algorithm,
    this.keyCreatedAt,
    this.keyFingerprint,
  });
}

// Providers
final encryptionServiceProvider = Provider<EncryptionService>((ref) {
  final keyManager = ref.watch(keyManagerProvider);
  return EncryptionService(keyManager);
});

final encryptionStatusProvider = FutureProvider<EncryptionStatus>((ref) async {
  final service = ref.watch(encryptionServiceProvider);
  await service.initialize();
  return service.getStatus();
});
