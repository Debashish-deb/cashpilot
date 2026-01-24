/// Data Manager
/// Centralized manager for data operations coordination
/// Acts as a facade for database and sync operations
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';
import '../../features/sync/sync_providers.dart';

// =============================================================================
// DATA MANAGER - Singleton Pattern
// =============================================================================

/// Centralized data operations manager
/// Coordinates database operations and sync triggers
class DataManager {
  static final DataManager _instance = DataManager._internal();
  factory DataManager() => _instance;
  DataManager._internal();

  // Robustness: prevent sync storms (rapid repeated triggers)
  DateTime? _lastSyncTriggeredAt;
  static const Duration _minSyncInterval = Duration(seconds: 2);

  // ==========================================================================
  // SYNC COORDINATION
  // ==========================================================================

  /// Trigger a sync after data modification
  void triggerSync(Ref ref) {
    try {
      final now = DateTime.now();

      // Throttle sync triggers to avoid storms
      if (_lastSyncTriggeredAt != null &&
          now.difference(_lastSyncTriggeredAt!) < _minSyncInterval) {
        debugPrint('DataManager: Sync trigger throttled');
        return;
      }

      _lastSyncTriggeredAt = now;

      ref.read(requestSyncProvider(SyncReason.dataChanged).future);
    } catch (e, stack) {
      debugPrint('DataManager: Sync trigger failed: $e');
      debugPrintStack(stackTrace: stack);
    }
  }

  /// Force a full sync
  Future<void> forceFullSync(Ref ref) async {
    try {
      await ref.read(requestSyncProvider(SyncReason.forceFull).future);
      _lastSyncTriggeredAt = DateTime.now();
      debugPrint('DataManager: Full sync completed');
    } catch (e, stack) {
      debugPrint('DataManager: Full sync failed: $e');
      debugPrintStack(stackTrace: stack);
    }
  }

  // ==========================================================================
  // DATA VALIDATION
  // ==========================================================================

  /// Validate expense data before saving
  ValidationResult validateExpense({
    required String title,
    required double amount,
    required String categoryId,
  }) {
    final errors = <String>[];

    final trimmedTitle = title.trim();

    if (trimmedTitle.isEmpty) {
      errors.add('Title is required');
    }
    if (trimmedTitle.length > 200) {
      errors.add('Title is too long');
    }
    if (!amount.isFinite) {
      errors.add('Amount is invalid');
    } else if (amount <= 0) {
      errors.add('Amount must be greater than zero');
    } else if (amount > 999999999) {
      errors.add('Amount is too large');
    }
    if (categoryId.trim().isEmpty) {
      errors.add('Category is required');
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
    );
  }

  /// Validate budget data before saving
  ValidationResult validateBudget({
    required String title,
    required double limit,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final errors = <String>[];

    final trimmedTitle = title.trim();

    if (trimmedTitle.isEmpty) {
      errors.add('Title is required');
    }
    if (trimmedTitle.length > 100) {
      errors.add('Title is too long');
    }
    if (!limit.isFinite) {
      errors.add('Limit is invalid');
    } else if (limit <= 0) {
      errors.add('Limit must be greater than zero');
    } else if (limit > 999999999) {
      errors.add('Limit is too large');
    }
    if (endDate.isBefore(startDate)) {
      errors.add('End date must be after start date');
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
    );
  }

  // ==========================================================================
  // DATA UTILITIES
  // ==========================================================================

  /// Get current user ID or throw if not logged in
  String requireUserId(Ref ref) {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null || userId.isEmpty) {
      throw DataManagerException('User not authenticated');
    }
    return userId;
  }

  /// Check if user is authenticated
  bool isAuthenticated(Ref ref) {
    final userId = ref.read(currentUserIdProvider);
    return userId != null && userId.isNotEmpty;
  }

  // ==========================================================================
  // DATA CLEANUP
  // ==========================================================================

  /// Clean up old data (for maintenance)
  Future<void> cleanupOldData(Ref ref, {int keepDays = 365}) async {
    try {
      if (keepDays <= 0) {
        debugPrint('DataManager: Invalid keepDays value');
        return;
      }

      // Placeholder for future implementation
      debugPrint(
        'DataManager: Cleanup requested (keeping $keepDays days of data)',
      );
    } catch (e, stack) {
      debugPrint('DataManager: Cleanup failed: $e');
      debugPrintStack(stackTrace: stack);
    }
  }
}

// =============================================================================
// DATA MODELS
// =============================================================================

class ValidationResult {
  final bool isValid;
  final List<String> errors;

  ValidationResult({
    required this.isValid,
    required this.errors,
  });

  String get errorMessage => errors.join(', ');
}

class DataManagerException implements Exception {
  final String message;
  DataManagerException(this.message);

  @override
  String toString() => 'DataManagerException: $message';
}

// =============================================================================
// PROVIDERS
// =============================================================================

/// Data manager provider
final dataManagerProvider = Provider<DataManager>((ref) {
  return DataManager();
});

/// Global data manager instance
final dataManager = DataManager();
