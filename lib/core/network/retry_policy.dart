import 'dart:math';

/// Retry Policy with Exponential Backoff and Jitter.
class RetryPolicy {
  final int maxRetries;
  final Duration initialDelay;
  final Duration maxDelay;
  final double jitterFactor;

  RetryPolicy({
    this.maxRetries = 3,
    this.initialDelay = const Duration(seconds: 1),
    this.maxDelay = const Duration(seconds: 10),
    this.jitterFactor = 0.2,
  });

  /// Execute a function with retries.
  Future<T> execute<T>(Future<T> Function() action) async {
    int attempts = 0;
    while (true) {
      try {
        attempts++;
        return await action();
      } catch (e) {
        if (attempts > maxRetries) {
          rethrow;
        }
        
        // Calculate delay with exponential backoff
        double delayMs = initialDelay.inMilliseconds * pow(2, attempts - 1).toDouble();
        
        // Cap at max delay
        delayMs = min(delayMs, maxDelay.inMilliseconds.toDouble());
        
        // Add Jitter (Prevent Thundering Herd)
        // random variance between -jitterFactor and +jitterFactor
        final random = Random();
        final jitter = 1 + (random.nextDouble() * 2 - 1) * jitterFactor; 
        final finalDelay = (delayMs * jitter).toInt();

        await Future.delayed(Duration(milliseconds: finalDelay));
      }
    }
  }
}
