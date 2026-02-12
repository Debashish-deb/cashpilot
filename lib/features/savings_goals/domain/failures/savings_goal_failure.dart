// Standalone library
abstract class SavingsGoalFailure implements Exception {
  const SavingsGoalFailure();
}

class ConcurrencyFailure extends SavingsGoalFailure {}

class DatabaseFailure extends SavingsGoalFailure {
  final String? message;
  const DatabaseFailure([this.message]);
}

class SyncFailure extends SavingsGoalFailure {}

class ValidationFailure extends SavingsGoalFailure {
  final String message;
  const ValidationFailure(this.message);
  
  @override
  String toString() => 'ValidationFailure: $message';
}
