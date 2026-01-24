import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'error_taxonomy.dart';

/// Error Handler - Applies UI behavior based on error category
/// 
/// This handler:
/// 1. Classifies the error
/// 2. Gets the UI behavior
/// 3. Shows appropriate feedback (banner, dialog)
/// 4. Handles retry logic
/// 5. Navigates if needed
class ErrorHandler {
  final Ref ref;
  
  ErrorHandler(this.ref);
  
  /// Handle an error with appropriate UI feedback
  /// 
  /// Returns true if the error was handled, false if it should propagate
  Future<bool> handle(
    BuildContext context,
    Exception error, {
    VoidCallback? onRetry,
    String? customMessage,
  }) async {
    final category = ErrorTaxonomy.classify(error);
    final behavior = ErrorUIBehavior.forCategory(category);
    final policy = ErrorTaxonomy.getRetryPolicy(category);
    
    // Show banner if needed
    if (behavior.showBanner && context.mounted) {
      _showErrorBanner(
        context,
        category: category,
        behavior: behavior,
        customMessage: customMessage,
        onRetry: behavior.showRetry ? onRetry : null,
      );
    }
    
    // Handle navigation if needed
    if (behavior.navigateTo != null && context.mounted) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (context.mounted) {
        Navigator.of(context).pushNamed(behavior.navigateTo!);
      }
    }
    
    // Handle logout if needed
    if (behavior.forceLogout) {
      // Typically would call authService.signOut()
      // This is left as a hook for the caller
    }
    
    return true;
  }
  
  /// Show error banner with material design
  void _showErrorBanner(
    BuildContext context, {
    required ErrorCategory category,
    required ErrorUIBehavior behavior,
    String? customMessage,
    VoidCallback? onRetry,
  }) {
    final message = customMessage ?? _getDefaultMessage(category);
    final color = _getCategoryColor(category);
    final icon = _getCategoryIcon(category);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: behavior.blocking 
          ? const Duration(seconds: 10)
          : const Duration(seconds: 4),
        action: onRetry != null
          ? SnackBarAction(
              label: 'RETRY',
              textColor: Colors.white,
              onPressed: onRetry,
            )
          : null,
      ),
    );
  }
  
  /// Get default message for error category
  String _getDefaultMessage(ErrorCategory category) {
    return switch (category) {
      ErrorCategory.network => 'No internet connection. Please check your network.',
      ErrorCategory.authentication => 'Session expired. Please log in again.',
      ErrorCategory.validation => 'Invalid input. Please check your data.',
      ErrorCategory.database => 'Database error. Please try again.',
      ErrorCategory.conflict => 'Data conflict detected. Review changes.',
      ErrorCategory.unknown => 'Something went wrong. Please try again.',
    };
  }
  
  /// Get color for error category
  Color _getCategoryColor(ErrorCategory category) {
    return switch (category) {
      ErrorCategory.network => Colors.orange,
      ErrorCategory.authentication => Colors.red,
      ErrorCategory.validation => Colors.amber.shade700,
      ErrorCategory.database => Colors.red.shade700,
      ErrorCategory.conflict => Colors.purple,
      ErrorCategory.unknown => Colors.grey.shade700,
    };
  }
  
  /// Get icon for error category
  IconData _getCategoryIcon(ErrorCategory category) {
    return switch (category) {
      ErrorCategory.network => Icons.wifi_off,
      ErrorCategory.authentication => Icons.lock_outline,
      ErrorCategory.validation => Icons.warning_amber,
      ErrorCategory.database => Icons.storage,
      ErrorCategory.conflict => Icons.sync_problem,
      ErrorCategory.unknown => Icons.error_outline,
    };
  }
}

/// Error handler provider
final errorHandlerProvider = Provider<ErrorHandler>((ref) {
  return ErrorHandler(ref);
});

/// Connectivity status for network errors
enum ConnectivityStatus {
  online,
  offline,
  checking,
}

/// Connectivity provider (to be wired to connectivity_plus)
final connectivityStatusProvider = StateProvider<ConnectivityStatus>((ref) {
  return ConnectivityStatus.online;
});

/// Helper extension for easy error handling
extension ErrorHandlingExtension<T> on AsyncValue<T> {
  /// Handle error with UI feedback
  void handleError(BuildContext context, Ref ref, {VoidCallback? onRetry}) {
    if (hasError && error is Exception) {
      ref.read(errorHandlerProvider).handle(
        context,
        error as Exception,
        onRetry: onRetry,
      );
    }
  }
}
