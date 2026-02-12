import 'package:drift/drift.dart';
import '../../data/drift/app_database.dart';
import 'package:uuid/uuid.dart';

/// Manages User Consents for GDPR and Open Banking (Layer 3 Compliance).
class ConsentManager {
  final AppDatabase _db;
  
  ConsentManager(this._db);

  /// Records a new consent granted by the user.
  Future<void> grantConsent({
    required String userId,
    required String scope,
    Duration? validity,
    Map<String, dynamic>? evidence,
  }) async {
    final now = DateTime.now();
    await _db.into(_db.userConsents).insert(
      UserConsentsCompanion.insert(
        id: Uuid().v4(),
        userId: userId,
        scope: scope,
        grantedAt: Value(now),
        expiresAt: Value(validity != null ? now.add(validity) : null),
        status: const Value('active'),
      ),
    );
  }

  /// Checks if a valid consent exists for the given scope.
  Future<bool> hasValidConsent(String userId, String scope) async {
    final consent = await (_db.select(_db.userConsents)
          ..where((t) => 
            t.userId.equals(userId) & 
            t.scope.equals(scope) & 
            t.status.equals('active')))
        .getSingleOrNull();
    
    if (consent == null) return false;
    
    if (consent.expiresAt != null && DateTime.now().isAfter(consent.expiresAt!)) {
      // Auto-expire
      await revokeConsent(consent.id);
      return false;
    }
    
    return true;
  }

  /// Revokes an existing consent.
  Future<void> revokeConsent(String id) async {
    await (_db.update(_db.userConsents)..where((t) => t.id.equals(id)))
        .write(UserConsentsCompanion(status: const Value('revoked')));
  }
}
