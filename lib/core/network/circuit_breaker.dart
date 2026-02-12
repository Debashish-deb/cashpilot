import 'dart:async';

enum CircuitState { closed, open, halfOpen }

/// Circuit Breaker to prevent repeated calls to a failing service.
class CircuitBreaker {
  final int failureThreshold;
  final Duration resetTimeout;
  
  CircuitState _state = CircuitState.closed;
  int _failureCount = 0;
  DateTime? _lastFailureTime;
  
  CircuitBreaker({
    this.failureThreshold = 5,
    this.resetTimeout = const Duration(seconds: 30),
  });

  CircuitState get state {
    if (_state == CircuitState.open) {
      if (DateTime.now().difference(_lastFailureTime!) > resetTimeout) {
        _state = CircuitState.halfOpen;
      }
    }
    return _state;
  }

  /// Execute a function protected by the circuit breaker.
  Future<T> run<T>(Future<T> Function() action) async {
    if (state == CircuitState.open) {
      throw CircuitBreakerOpenException('Circuit is OPEN. Fail immediately.');
    }

    try {
      final result = await action();
      _onSuccess();
      return result;
    } catch (e) {
      _onFailure(e);
      rethrow;
    }
  }

  void _onSuccess() {
    if (_state == CircuitState.halfOpen) {
      _state = CircuitState.closed;
      _failureCount = 0;
    } else if (_state == CircuitState.closed) {
      _failureCount = 0;
    }
  }

  void _onFailure(Object error) {
    if (_state == CircuitState.closed) {
      _failureCount++;
      if (_failureCount >= failureThreshold) {
        _state = CircuitState.open;
        _lastFailureTime = DateTime.now();
      }
    } else if (_state == CircuitState.halfOpen) {
      _state = CircuitState.open;
      _lastFailureTime = DateTime.now();
    }
  }
}

class CircuitBreakerOpenException implements Exception {
  final String message;
  CircuitBreakerOpenException(this.message);
  @override
  String toString() => 'CircuitBreakerOpenException: $message';
}
