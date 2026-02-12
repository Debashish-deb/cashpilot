
import '../../repositories/net_worth/net_worth_repository.dart';
import '../use_case.dart';

class CalculateNetWorthUseCase implements UseCase<int, String> {
  final NetWorthRepository _repository;

  CalculateNetWorthUseCase(this._repository);

  @override
  Future<int> execute(String userId) async {
    return _repository.getNetWorth(userId);
  }
}
