
import '../../entities/net_worth/asset.dart';
import '../../entities/net_worth/liability.dart';

abstract class NetWorthRepository {
  // Assets
  Stream<List<Asset>> watchAssets(String userId);
  Future<List<Asset>> getAssets(String userId);
  Future<void> addAsset(Asset asset);
  Future<void> updateAsset(Asset asset);
  Future<void> deleteAsset(String assetId);
  
  // Liabilities
  Stream<List<Liability>> watchLiabilities(String userId);
  Future<List<Liability>> getLiabilities(String userId);
  Future<void> addLiability(Liability liability);
  Future<void> updateLiability(Liability liability);
  Future<void> deleteLiability(String liabilityId);
  
  // Calculations
  Stream<int> watchNetWorth(String userId);
  Future<int> getNetWorth(String userId);
  
  // Valuation History (Graphing)
  Future<List<Map<String, dynamic>>> getValuationHistory({
    required String userId, 
    required DateTime start, 
    required DateTime end
  });

  Future<List<Map<String, dynamic>>> getNetWorthHistory(String userId, {int days});
}
