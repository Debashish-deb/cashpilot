/// Error Taxonomy for CashPilot
/// 
/// Categorizes errors and defines retry strategies
library;

enum ErrorCategory {
  /// Network errors (retry with backoff)
  network,
  
  /// Authentication errors (require re-login)
  authentication,
  
  /// Validation errors (user input issue, no retry)
  validation,
  
  /// Database errors (critical, may need recovery)
  database,
  
  /// Sync conflicts (special handling)
  conflict,
  
  /// Unknown/unexpected errors
  unknown,
}

/// UI behavior for each error category
/// Defines how errors should be presented to users
class ErrorUIBehavior {
  /// Should show a banner/toast to user?
  final bool showBanner;
  
  /// Banner message key (for localization)
  final String? bannerMessageKey;
  
  /// Should block UI interaction?
  final bool blocking;
  
  /// Should show retry button?
  final bool showRetry;
  
  /// Should navigate to specific route?
  final String? navigateTo;
  
  /// Should log out user?
  final bool forceLogout;
  
  const ErrorUIBehavior({
    this.showBanner = true,
    this.bannerMessageKey,
    this.blocking = false,
    this.showRetry = false,
    this.navigateTo,
    this.forceLogout = false,
  });
  
  /// Get UI behavior for error category
  static ErrorUIBehavior forCategory(ErrorCategory category) {
    return switch (category) {
      ErrorCategory.network => const ErrorUIBehavior(
        showBanner: true,
        bannerMessageKey: 'error_no_connection',
        showRetry: true,
        blocking: false,
      ),
      ErrorCategory.authentication => const ErrorUIBehavior(
        showBanner: true,
        bannerMessageKey: 'error_session_expired',
        blocking: true,
        forceLogout: true,
        navigateTo: '/login',
      ),
      ErrorCategory.validation => const ErrorUIBehavior(
        showBanner: true,
        bannerMessageKey: 'error_invalid_input',
        blocking: false,
        showRetry: false,
      ),
      ErrorCategory.database => const ErrorUIBehavior(
        showBanner: true,
        bannerMessageKey: 'error_database',
        blocking: true,
        showRetry: true,
      ),
      ErrorCategory.conflict => const ErrorUIBehavior(
        showBanner: true,
        bannerMessageKey: 'error_sync_conflict',
        blocking: false,
        showRetry: false,
        navigateTo: '/sync/conflicts',
      ),
      ErrorCategory.unknown => const ErrorUIBehavior(
        showBanner: true,
        bannerMessageKey: 'error_unknown',
        showRetry: true,
      ),
    };
  }
}

/// Retry policy for each error category
class RetryPolicy {
  final bool shouldRetry;
  final Duration initialDelay;
  final int maxAttempts;
  final double backoffMultiplier;

  const RetryPolicy({
    required this.shouldRetry,
    required this.initialDelay,
    required this.maxAttempts,
    this.backoffMultiplier = 2.0,
  });

  /// No retry policy
  static const none = RetryPolicy(
    shouldRetry: false,
    initialDelay: Duration.zero,
    maxAttempts: 0,
  );

  /// Standard retry with exponential backoff
  static const standard = RetryPolicy(
    shouldRetry: true,
    initialDelay: Duration(seconds: 1),
    maxAttempts: 3,
    backoffMultiplier: 2.0,
  );

  /// Aggressive retry for critical operations
  static const aggressive = RetryPolicy(
    shouldRetry: true,
    initialDelay: Duration(milliseconds: 500),
    maxAttempts: 5,
    backoffMultiplier: 1.5,
  );
}

/// Error classification and retry strategy
class ErrorTaxonomy {
  /// Classify an error into a category
  static ErrorCategory classify(Exception error) {
    final message = error.toString().toLowerCase();

    if (message.contains('network') || 
        message.contains('connection') ||
        message.contains('timeout') ||
        message.contains('socket')) {
      return ErrorCategory.network;
    }

    if (message.contains('auth') || 
        message.contains('unauthorized') ||
        message.contains('forbidden') ||
        message.contains('token')) {
      return ErrorCategory.authentication;
    }

    if (message.contains('validation') ||
        message.contains('invalid') ||
        message.contains('required')) {
      return ErrorCategory.validation;
    }

    if (message.contains('database') ||
        message.contains('sql') ||
        message.contains('drift')) {
      return ErrorCategory.database;
    }

    if (message.contains('conflict') ||
        message.contains('version')) {
      return ErrorCategory.conflict;
    }

    return ErrorCategory.unknown;
  }

  /// Get retry policy for error category
  static RetryPolicy getRetryPolicy(ErrorCategory category) {
    return switch (category) {
      ErrorCategory.network => RetryPolicy.standard,
      ErrorCategory.authentication => RetryPolicy.none,
      ErrorCategory.validation => RetryPolicy.none,
      ErrorCategory.database => RetryPolicy.aggressive,
      ErrorCategory.conflict => RetryPolicy.standard,
      ErrorCategory.unknown => RetryPolicy.standard,
    };
  }

  /// Execute with retry logic
  static Future<T> executeWithRetry<T>({
    required Future<T> Function() operation,
    required ErrorCategory category,
  }) async {
    final policy = getRetryPolicy(category);
    
    if (!policy.shouldRetry) {
      return await operation();
    }

    int attempts = 0;
    Duration delay = policy.initialDelay;

    while (true) {
      try {
        return await operation();
      } catch (e) {
        attempts++;
        
        if (attempts >= policy.maxAttempts) {
          rethrow;
        }

        // Wait with backoff
        await Future.delayed(delay);
        delay *= policy.backoffMultiplier;
      }
    }
  }
}
