/// Base UseCase interface
/// 
/// All use cases follow this pattern for consistency
abstract class UseCase<Type, Params> {
  Future<Type> execute(Params params);
}

/// For use cases that don't need parameters
class NoParams {
  const NoParams();
}

/// Result wrapper for use cases
sealed class UseCaseResult<T> {
  const UseCaseResult();
}

class Success<T> extends UseCaseResult<T> {
  final T data;
  const Success(this.data);
}

class Failure<T> extends UseCaseResult<T> {
  final String message;
  final Exception? exception;
  const Failure(this.message, {this.exception});
}
