
import '../../entities/net_worth/asset.dart';
import '../../repositories/net_worth/net_worth_repository.dart';
import '../use_case.dart';

class AddAssetUseCase implements UseCase<void, Asset> {
  final NetWorthRepository _repository;

  AddAssetUseCase(this._repository);

  @override
  Future<void> execute(Asset asset) async {
    return _repository.addAsset(asset);
  }
}
