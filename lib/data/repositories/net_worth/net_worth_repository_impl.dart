
import '../../../domain/repositories/net_worth/net_worth_repository.dart';
import '../../../domain/entities/net_worth/asset.dart';
import '../../../domain/entities/net_worth/liability.dart';
import '../../drift/app_database.dart' as db;
import 'package:drift/drift.dart';

class NetWorthRepositoryImpl implements NetWorthRepository {
  final db.AppDatabase _db;

  NetWorthRepositoryImpl(this._db);

  // --- ASSETS ---

  @override
  Stream<List<Asset>> watchAssets(String userId) {
    return _db.watchAssets(userId).map((rows) => rows.map(_mapAsset).toList());
  }

  @override
  Future<List<Asset>> getAssets(String userId) async {
    final rows = await _db.getAssets(userId);
    return rows.map(_mapAsset).toList();
  }

  @override
  Future<void> addAsset(Asset asset) async {
    await _db.insertAsset(_mapAssetToCompanion(asset));
    await _db.recordNetWorthSnapshot(asset.userId);
  }

  @override
  Future<void> updateAsset(Asset asset) async {
    await _db.updateAsset(_mapAssetToCompanion(asset));
    await _db.recordNetWorthSnapshot(asset.userId);
  }

  @override
  Future<void> deleteAsset(String assetId) async {
    final asset = await _db.getAssetById(assetId);
    if (asset != null) {
      await _db.deleteAsset(assetId);
      await _db.recordNetWorthSnapshot(asset.userId);
    }
  }

  // --- LIABILITIES ---

  @override
  Stream<List<Liability>> watchLiabilities(String userId) {
    return _db.watchLiabilities(userId).map((rows) => rows.map(_mapLiability).toList());
  }

  @override
  Future<List<Liability>> getLiabilities(String userId) async {
    final rows = await _db.getLiabilities(userId);
    return rows.map(_mapLiability).toList();
  }

  @override
  Future<void> addLiability(Liability liability) async {
    await _db.insertLiability(_mapLiabilityToCompanion(liability));
    await _db.recordNetWorthSnapshot(liability.userId);
  }

  @override
  Future<void> updateLiability(Liability liability) async {
    await _db.updateLiability(_mapLiabilityToCompanion(liability));
    await _db.recordNetWorthSnapshot(liability.userId);
  }

  @override
  Future<void> deleteLiability(String liabilityId) async {
    final liability = await _db.getLiabilityById(liabilityId);
    if (liability != null) {
      await _db.deleteLiability(liabilityId);
      await _db.recordNetWorthSnapshot(liability.userId);
    }
  }

  // --- CALCULATIONS ---

  @override
  Stream<int> watchNetWorth(String userId) {
    return _db.watchAssets(userId).asyncMap((assets) async {
      final liabilities = await _db.getLiabilities(userId);
      return _calculateNetWorth(assets, liabilities);
    });
  }

  @override
  Future<int> getNetWorth(String userId) async {
    final assets = await _db.getAssets(userId);
    final liabilities = await _db.getLiabilities(userId);
    return _calculateNetWorth(assets, liabilities);
  }
  
  int _calculateNetWorth(List<db.Asset> assets, List<db.Liability> liabilities) {
    int totalAssets = 0;
    for (var a in assets) {
      totalAssets += a.currentValue;
    }
    
    int totalLiabilities = 0;
    for (var l in liabilities) {
      totalLiabilities += l.currentBalance;
    }
    
    return totalAssets - totalLiabilities;
  }

  // --- VALUATION ---

  @override
  Future<List<Map<String, dynamic>>> getValuationHistory({
    required String userId,
    required DateTime start,
    required DateTime end,
  }) async {
    final rows = await _db.getValuationHistory(
      entityId: userId, // Assuming user-level valuation if passed as userId
      start: start,
      end: end,
    );
    return rows.map((r) => {
      'date': r.date.toIso8601String(),
      'value': r.value / 100.0,
    }).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> getNetWorthHistory(String userId, {int days = 30}) async {
    final rows = await _db.getNetWorthHistory(userId, days: days);
    return rows.map((r) => {
      'date': r.date.toIso8601String(),
      'value': r.value, // Now directly in cents
    }).toList();
  }

  // --- MAPPERS ---

  Asset _mapAsset(db.Asset row) {
    return Asset(
      id: row.id,
      userId: row.userId,
      name: row.name,
      type: _mapAssetType(row.type),
      currentValue: row.currentValue,
      currency: row.currency,
      institutionName: row.InstitutionName,
      notes: row.notes,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      isDeleted: row.isDeleted,
      revision: row.revision,
    );
  }

  db.AssetsCompanion _mapAssetToCompanion(Asset asset) {
    return db.AssetsCompanion(
      id: Value(asset.id),
      userId: Value(asset.userId),
      name: Value(asset.name),
      type: Value(asset.type.name), // Enum to string
      currentValue: Value(asset.currentValue), // Already in cents
      currency: Value(asset.currency),
      InstitutionName: Value(asset.institutionName),
      notes: Value(asset.notes),
      createdAt: Value(asset.createdAt),
      updatedAt: Value(asset.updatedAt),
      isDeleted: Value(asset.isDeleted),
      revision: Value(asset.revision),
    );
  }
  
  AssetType _mapAssetType(String typeStr) {
    return AssetType.values.firstWhere(
      (e) => e.name == typeStr, 
      orElse: () => AssetType.other
    );
  }

  Liability _mapLiability(db.Liability row) {
    return Liability(
      id: row.id,
      userId: row.userId,
      name: row.name,
      type: _mapLiabilityType(row.type),
      currentBalance: row.currentBalance,
      currency: row.currency,
      interestRate: row.interestRate,
      dueDate: row.dueDate,
      minPayment: row.minPayment,
      notes: row.notes,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      isDeleted: row.isDeleted,
      revision: row.revision,
    );
  }

  db.LiabilitiesCompanion _mapLiabilityToCompanion(Liability liability) {
    return db.LiabilitiesCompanion(
      id: Value(liability.id),
      userId: Value(liability.userId),
      name: Value(liability.name),
      type: Value(liability.type.name), // Enum to string
      currentBalance: Value(liability.currentBalance), // Already in cents
      currency: Value(liability.currency),
      interestRate: Value(liability.interestRate),
      dueDate: Value(liability.dueDate),
      minPayment: Value(liability.minPayment),
      notes: Value(liability.notes),
      createdAt: Value(liability.createdAt),
      updatedAt: Value(liability.updatedAt),
      isDeleted: Value(liability.isDeleted),
      revision: Value(liability.revision),
    );
  }
  
  LiabilityType _mapLiabilityType(String typeStr) {
    return LiabilityType.values.firstWhere(
      (e) => e.name == typeStr, 
      orElse: () => LiabilityType.other
    );
  }
}
