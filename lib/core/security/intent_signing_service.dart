import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

/// Cryptographical Intent Signing Service
/// 
/// Provides a mechanism to sign "Intents" for high-value operations.
/// This ensures that an operation was requested by the authentic app 
/// on the authentic device with high integrity.
class IntentSigningService {
  static final IntentSigningService _instance = IntentSigningService._internal();
  factory IntentSigningService() => _instance;
  IntentSigningService._internal();

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  static const String _signingKeyName = 'intent_signing_secret';
  String? _cachedSecret;

  /// Sign an operation intent
  Future<SignedIntent> signIntent(String operation, Map<String, dynamic> payload) async {
    final secret = await _getOrGenerateSecret();
    final intentId = const Uuid().v4();
    final timestamp = DateTime.now().toIso8601String();
    
    // Create payload signature
    final payloadString = jsonEncode(payload);
    final payloadHash = sha256.convert(utf8.encode(payloadString)).toString();
    
    final messageToSign = '$intentId|$operation|$timestamp|$payloadHash';
    final hmac = Hmac(sha256, utf8.encode(secret));
    final signature = hmac.convert(utf8.encode(messageToSign)).toString();

    return SignedIntent(
      id: intentId,
      operation: operation,
      timestamp: timestamp,
      payloadHash: payloadHash,
      signature: signature,
    );
  }

  /// Verify a signed intent
  Future<bool> verifyIntent(SignedIntent intent, String operation, Map<String, dynamic> actualPayload) async {
    final secret = await _getOrGenerateSecret();
    
    // 1. Verify Operation Match
    if (intent.operation != operation) return false;
    
    // 2. Verify Payload Integrity
    final payloadString = jsonEncode(actualPayload);
    final actualHash = sha256.convert(utf8.encode(payloadString)).toString();
    if (intent.payloadHash != actualHash) return false;
    
    // 3. Verify Signature
    final messageToSign = '${intent.id}|${intent.operation}|${intent.timestamp}|${intent.payloadHash}';
    final hmac = Hmac(sha256, utf8.encode(secret));
    final expectedSignature = hmac.convert(utf8.encode(messageToSign)).toString();
    
    if (intent.signature != expectedSignature) return false;
    
    // 4. Verify Freshness (e.g., within 5 minutes)
    final intentTime = DateTime.tryParse(intent.timestamp);
    if (intentTime == null) return false;
    if (DateTime.now().difference(intentTime).inMinutes > 5) return false;

    return true;
  }

  Future<String> _getOrGenerateSecret() async {
    if (_cachedSecret != null) return _cachedSecret!;
    
    String? secret = await _secureStorage.read(key: _signingKeyName);
    if (secret == null) {
      secret = const Uuid().v4(); // In production, this would be a high-entropy key
      await _secureStorage.write(key: _signingKeyName, value: secret);
    }
    
    _cachedSecret = secret;
    return secret;
  }
}

/// Represents a cryptographically signed operation intent
class SignedIntent {
  final String id;
  final String operation;
  final String timestamp;
  final String payloadHash;
  final String signature;

  const SignedIntent({
    required this.id,
    required this.operation,
    required this.timestamp,
    required this.payloadHash,
    required this.signature,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'operation': operation,
    'timestamp': timestamp,
    'payloadHash': payloadHash,
    'signature': signature,
  };
}
