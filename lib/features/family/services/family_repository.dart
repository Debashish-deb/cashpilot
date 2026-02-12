import '../../../data/drift/app_database.dart';

class FamilyRepository {
  final AppDatabase _db;

  FamilyRepository(this._db);

  // --- Family Groups ---

  Future<List<FamilyGroup>> getFamilyGroups(String userId) {
    return (_db.select(_db.familyGroups)..where((t) => t.ownerId.equals(userId))).get();
  }

  Future<int> insertFamilyGroup(FamilyGroupsCompanion group) {
    return _db.into(_db.familyGroups).insert(group);
  }

  // --- Family Contacts ---

  Stream<List<FamilyContact>> watchFamilyContacts() {
    return (_db.select(_db.familyContacts)..where((t) => t.isDeleted.equals(false))).watch();
  }

  Future<int> insertFamilyContact(FamilyContactsCompanion contact) {
    return _db.into(_db.familyContacts).insert(contact);
  }

  Future<bool> updateFamilyContact(FamilyContactsCompanion contact) {
    return _db.update(_db.familyContacts).replace(contact);
  }

  // --- Family Relations ---

  Future<List<FamilyRelation>> getRelations() {
    return _db.select(_db.familyRelations).get();
  }

  Future<int> insertRelation(FamilyRelationsCompanion relation) {
    return _db.into(_db.familyRelations).insert(relation);
  }

  Future<int> deleteRelation(String id) {
    return (_db.delete(_db.familyRelations)..where((t) => t.id.equals(id))).go();
  }
}
