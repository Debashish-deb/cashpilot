import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Secure implementation of LocalStorage for Supabase Auth
/// Uses FlutterSecureStorage to encrypt session tokens
class SecureLocalStorage extends LocalStorage {
  final FlutterSecureStorage _storage;

  const SecureLocalStorage()
      : _storage = const FlutterSecureStorage(
          aOptions: AndroidOptions(
            encryptedSharedPreferences: true,
          ),
          iOptions: IOSOptions(
            accessibility: KeychainAccessibility.first_unlock,
          ),
        );

  @override
  Future<void> initialize() async {
    // Explicitly return Future.value to avoid early access races.
    return Future.value();
  }

  @override
  Future<bool> hasAccessToken() async {
    try {
      return await _storage.containsKey(key: supabasePersistSessionKey);
    } catch (_) {
      return false;
    }
  }

  @override
  Future<String?> accessToken() async {
    try {
      return await _storage.read(key: supabasePersistSessionKey);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> persistSession(String persistSessionString) async {
    try {
      await _storage.write(
        key: supabasePersistSessionKey,
        value: persistSessionString,
      );
    } catch (_) {
      // silent fallback — do NOT crash auth
    }
  }

  @override
  Future<void> removePersistedSession() async {
    try {
      await _storage.delete(key: supabasePersistSessionKey);
    } catch (_) {
      // silent fallback — prevents app crashes on logout
    }
  }
}
