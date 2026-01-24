/// Budget Service with Domain Validation - EXAMPLE ONLY
/// 
/// This is a DEMONSTRATION file showing how to integrate:
/// - Domain validators
/// - Error reporting  
/// - Structured logging
/// - Idempotency protection
///
/// NOTE: This example is simplified. The actual Budget table has many more fields.
/// See lib/data/drift/tables.dart for the complete Budget schema.
library;

import 'package:uuid/uuid.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';

import '../core/providers/app_providers.dart';
import '../data/drift/app_database.dart';
import '../domain/budget/budget_domain.dart';
import '../domain/subscription/subscription_domain.dart';
import '../core/services/error_reporter.dart';
import '../core/logging/logger.dart';
import '../core/sync/idempotency_tracker.dart';

/// Idempotency tracker provider
final idempotencyTrackerProvider = Provider<IdempotencyTracker>((ref) {
  return IdempotencyTracker(ref.read(sharedPreferencesProvider));
});

/// Budget service provider (EXAMPLE)
final budgetServiceExampleProvider = Provider<BudgetServiceExample>((ref) {
  return BudgetServiceExample(
    db: ref.read(databaseProvider),
    idempotency: ref.read(idempotencyTrackerProvider),
  );
});

/// Budget service with domain validation - EXAMPLE
/// 
/// This demonstrates the integration pattern.
/// The actual budget service would need all required Budget fields.
class BudgetServiceExample {
  final AppDatabase db;
  final IdempotencyTracker idempotency;
  final Logger _logger = Loggers.budget;

  BudgetServiceExample({
    required this.db,
    required this.idempotency,
  });

  /// Create a new budget with domain validation
  /// 
  /// Example showing validation pattern - actual implementation would need
  /// all Budget table fields (see tables.dart line 58-88)
  Future<String> createBudgetExample({
    required String title,
    required double totalLimitInCents,
    required String type,
    required DateTime startDate,
    required DateTime endDate,
    required String ownerId,
    required SubscriptionTier userTier,
  }) async {
    final key = IdempotencyKey.forEntity(
      'budget',
      ownerId,
      'create_${DateTime.now().millisecondsSinceEpoch}',
    );

    final budgetId = await idempotency.executeOnce<String>(
      key: key,
      operation: () async {
        try {
          _logger.info('Creating budget', context: {
            'title': title,
            'totalLimit': totalLimitInCents,
            'type': type,
            'ownerId': ownerId,
          });

          // DOMAIN VALIDATION: Check tier limits
          final currentBudgetCount = await db.budgets.count().getSingle();
          BudgetDomain.validateCreate(
            currentBudgetCount: currentBudgetCount,
            tier: userTier.name, // Get enum name as string
          );

          // DOMAIN VALIDATION: Validate input
          BudgetDomain.validateName(title);
          BudgetDomain.validateAmount(totalLimitInCents / 100); // Convert cents to dollars
          BudgetDomain.validatePeriod(type);
          BudgetDomain.validateDates(startDate: startDate, endDate: endDate);

          // Generate ID
          final budgetId = const Uuid().v4();

          // Create budget using Drift Companion
          // NOTE: Actual Budget table has 30+ fields - this is simplified
          final budget = BudgetsCompanion.insert(
            id: budgetId,
            ownerId: ownerId,
            title: title,
            type: type,
            startDate: startDate,
            endDate: endDate,
            totalLimit: Value(totalLimitInCents.toInt()),
            status: const Value('active'),
            syncState: const Value('dirty'), // Mark for sync
          );

          // Insert into database
          await db.into(db.budgets).insert(budget);

          _logger.info('Budget created successfully', context: {
            'budgetId': budgetId,
            'title': title,
          });

          // Breadcrumb for error tracking
          errorReporter.addBreadcrumb(
            'Budget created',
            category: 'budget',
            data: {'id': budgetId, 'title': title},
          );

          return budgetId;
        } catch (e, stack) {
          _logger.error('Budget creation failed',
              error: e,
              stackTrace: stack,
              context: {
                'title': title,
                'ownerId': ownerId,
              });

          // Report error to Crashlytics/Sentry
          await errorReporter.reportException(e, stackTrace: stack, context: {
            'operation': 'create_budget',
            'ownerId': ownerId,
            'budgetTitle': title,
          });

          rethrow;
        }
      },
      resultDeserializer: (json) => json['budgetId'] as String,
    );

    return budgetId; 
  }

  /// Update budget with validation
  Future<void> updateBudgetExample({
    required String budgetId,
    String? title,
    int? totalLimitInCents,
  }) async {
    try {
      _logger.info('Updating budget', context: {'budgetId': budgetId});

      // DOMAIN VALIDATION
      if (title != null) {
        BudgetDomain.validateName(title);
      }
      if (totalLimitInCents != null) {
        BudgetDomain.validateAmount(totalLimitInCents / 100);
      }

      // Build update companion
      final updates = BudgetsCompanion(
        id: Value(budgetId),
        title: title != null ? Value(title) : const Value.absent(),
        totalLimit: totalLimitInCents != null ? Value(totalLimitInCents) : const Value.absent(),
        updatedAt: Value(DateTime.now()),
        syncState: const Value('dirty'), // Mark as needing sync
      );

      // Update using Drift syntax
      await (db.update(db.budgets)..where((t) => t.id.equals(budgetId)))
          .write(updates);

      _logger.info('Budget updated', context: {'budgetId': budgetId});
    } catch (e, stack) {
      _logger.error('Budget update failed', error: e, stackTrace: stack);

      await errorReporter.reportException(e, stackTrace: stack, context: {
        'operation': 'update_budget',
        'budgetId': budgetId,
      });

      rethrow;
    }
  }

  /// Delete budget (soft delete)
  Future<void> deleteBudgetExample(String budgetId) async {
    try {
      _logger.info('Deleting budget', context: {'budgetId': budgetId});

      // Soft delete by setting isDeleted flag
      await (db.update(db.budgets)..where((t) => t.id.equals(budgetId)))
          .write(const BudgetsCompanion(
        isDeleted: Value(true),
        syncState: Value('dirty'),
      ));

      _logger.info('Budget deleted', context: {'budgetId': budgetId});

      errorReporter.addBreadcrumb('Budget deleted',
          category: 'budget', data: {'id': budgetId});
    } catch (e, stack) {
      _logger.error('Budget deletion failed', error: e, stackTrace: stack);

      await errorReporter.reportException(e, stackTrace: stack, context: {
        'operation': 'delete_budget',
        'budgetId': budgetId,
      });

      rethrow;
    }
  }
}
