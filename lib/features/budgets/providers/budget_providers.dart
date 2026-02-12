/// CashPilot Budget Providers
/// Riverpod providers for budget state management
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'dart:ui' show Color;

import '../../../data/drift/app_database.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/logging/logger.dart';
import '../../../core/services/error_reporter.dart';
import '../../../domain/budget/budget_domain.dart';
import '../../../services/sync_engine.dart';
import '../../../services/auth_service.dart';
import '../../../services/subscription_service.dart';
import '../../../core/errors/error_taxonomy.dart';
import '../models/budget_state.dart';

const _uuid = Uuid();

// ============================================================
// BUDGET LIST PROVIDERS
// ============================================================

/// Stream of all budgets for current user
final budgetsStreamProvider = StreamProvider<List<Budget>>((ref) {
  final db = ref.watch(databaseProvider);
  final userId = ref.watch(currentUserIdProvider);
  
  if (userId == null) {
    return Stream.value([]);
  }
  
  final userEmail = authService.currentUser?.email ?? '';
  return db.watchAccessibleBudgets(userId, userEmail);
});

// ============================================================
// BUDGET SEARCH AND FILTER PROVIDERS
// ============================================================

/// Search query for filtering budgets
final budgetSearchProvider = StateProvider<String>((ref) => '');

/// Recent searches history
final recentSearchesProvider = StateProvider<List<String>>((ref) => []);

/// Filtered budgets based on search query
final filteredBudgetsProvider = Provider<AsyncValue<List<Budget>>>((ref) {
  final budgetsAsync = ref.watch(budgetsStreamProvider);
  final searchQuery = ref.watch(budgetSearchProvider).toLowerCase().trim();
  
  return budgetsAsync.when(
    data: (budgets) {
      if (searchQuery.isEmpty) {
        return AsyncValue.data(budgets);
      }
      
      final filtered = budgets.where((budget) {
        return budget.title.toLowerCase().contains(searchQuery) ||
               budget.type.toLowerCase().contains(searchQuery) ||
               (budget.notes?.toLowerCase().contains(searchQuery) ?? false);
      }).toList();
      
      return AsyncValue.data(filtered);
    },
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
  );
});

/// Sort options for budgets
enum BudgetSortOption {
  dateNewest,
  dateOldest,
  nameAZ,
  nameZA,
  amountHighest,
  amountLowest,
}

/// Current sort option provider
final budgetSortProvider = StateProvider<BudgetSortOption>((ref) => BudgetSortOption.dateNewest);

/// Filter by type (all, active, completed, family)
final budgetTypeFilterProvider = StateProvider<String>((ref) => 'all');

// ============================================================
// VIEW MODE PROVIDERS (NEW - for scalability)
// ============================================================

/// View modes for budget list display
enum BudgetViewMode {
  timeline,  // Group by year-month
  category,  // Group by budget type
  status,    // Group by active/upcoming/past (current default)
}

/// Current view mode
final budgetViewModeProvider = StateProvider<BudgetViewMode>(
  (ref) => BudgetViewMode.status, // Start with familiar view
);

/// Year filter (null = all years)
final budgetYearFilterProvider = StateProvider<int?>((ref) => null);

/// Show archived budgets
final showArchivedBudgetsProvider = StateProvider<bool>((ref) => false);

/// Grouped budgets by current view mode
final groupedBudgetsProvider = Provider<AsyncValue<Map<String, List<Budget>>>>((ref) {
  final sortedAsync = ref.watch(sortedBudgetsProvider);
  final viewMode = ref.watch(budgetViewModeProvider);
  final yearFilter = ref.watch(budgetYearFilterProvider);
  final showArchived = ref.watch(showArchivedBudgetsProvider);
  
  return sortedAsync.when(
    data: (budgets) {
      // Filter by year if specified
      List<Budget> filtered = budgets;
      if (yearFilter != null) {
        filtered = budgets.where((b) => 
          b.startDate.year == yearFilter
        ).toList();
      }
      
      // Filter archived
      if (!showArchived) {
        filtered = filtered.where((b) => 
          b.status != 'archived'
        ).toList();
      }
      
      // Group by view mode
      final grouped = <String, List<Budget>>{};
      
      switch (viewMode) {
        case BudgetViewMode.timeline:
          // Group by year-month (e.g., "2025-12", "2025-11")
          for (final budget in filtered) {
            final key = '${budget.startDate.year}-${budget.startDate.month.toString().padLeft(2, '0')}';
            grouped.putIfAbsent(key, () => []).add(budget);
          }
          break;
          
        case BudgetViewMode.category:
          // Group by type (monthly, weekly, event, etc.)
          for (final budget in filtered) {
            final key = budget.type;
            grouped.putIfAbsent(key, () => []).add(budget);
          }
          break;
          
        case BudgetViewMode.status:
          // Group by active/upcoming/past
          final now = DateTime.now();
          for (final budget in filtered) {
            String key;
            if (budget.startDate.isAfter(now)) {
              key = 'upcoming';
            } else if (budget.endDate.isBefore(now)) {
              key = 'past';
            } else {
              key = 'active';
            }
            grouped.putIfAbsent(key, () => []).add(budget);
          }
          break;
      }
      
      // Sort keys (newest first for timeline, alphabetical for others)
      final sortedGroups = <String, List<Budget>>{};
      final sortedKeys = grouped.keys.toList();
      
      if (viewMode == BudgetViewMode.timeline) {
        sortedKeys.sort((a, b) => b.compareTo(a)); // Descending
      } else {
        sortedKeys.sort(); // Ascending
      }
      
      for (final key in sortedKeys) {
        sortedGroups[key] = grouped[key]!;
      }
      
      return AsyncValue.data(sortedGroups);
    },
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
  );
});

/// Sorted and filtered budgets provider
final sortedBudgetsProvider = Provider<AsyncValue<List<Budget>>>((ref) {
  final filteredAsync = ref.watch(filteredBudgetsProvider);
  final sortOption = ref.watch(budgetSortProvider);
  final typeFilter = ref.watch(budgetTypeFilterProvider);
  
  return filteredAsync.when(
    data: (budgets) {
      // Apply type filter
      final now = DateTime.now();
      List<Budget> filtered = budgets;
      
      switch (typeFilter) {
        case 'active':
          filtered = budgets.where((b) => 
            b.startDate.isBefore(now) && b.endDate.isAfter(now)
          ).toList();
          break;
        case 'completed':
          filtered = budgets.where((b) => b.endDate.isBefore(now)).toList();
          break;
        case 'upcoming':
          filtered = budgets.where((b) => b.startDate.isAfter(now)).toList();
          break;
        case 'family':
          filtered = budgets.where((b) => b.isShared).toList();
          break;
        default:
          // 'all' - keep all
          break;
      }
      
      // Apply sorting
      switch (sortOption) {
        case BudgetSortOption.dateNewest:
          filtered.sort((a, b) => b.startDate.compareTo(a.startDate));
          break;
        case BudgetSortOption.dateOldest:
          filtered.sort((a, b) => a.startDate.compareTo(b.startDate));
          break;
        case BudgetSortOption.nameAZ:
          filtered.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
          break;
        case BudgetSortOption.nameZA:
          filtered.sort((a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase()));
          break;
        case BudgetSortOption.amountHighest:
          filtered.sort((a, b) => (b.totalLimit ?? 0).compareTo(a.totalLimit ?? 0));
          break;
        case BudgetSortOption.amountLowest:
          filtered.sort((a, b) => (a.totalLimit ?? 0).compareTo(b.totalLimit ?? 0));
          break;
      }
      
      return AsyncValue.data(filtered);
    },
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
  );
});

/// Budget health color based on spending percentage
Color getBudgetHealthColor(double spentPercentage) {
  if (spentPercentage >= 100) {
    return const Color(0xFFEF4444); // Red - Over budget
  } else if (spentPercentage >= 80) {
    return const Color(0xFFF59E0B); // Yellow/Orange - Near limit
  } else if (spentPercentage >= 50) {
    return const Color(0xFF3B82F6); // Blue - Moderate
  } else {
    return const Color(0xFF10B981); // Green - Healthy
  }
}

/// Get health status label
String getBudgetHealthLabel(double spentPercentage) {
  if (spentPercentage >= 100) {
    return 'Over Budget';
  } else if (spentPercentage >= 80) {
    return 'Near Limit';
  } else if (spentPercentage >= 50) {
    return 'Moderate';
  } else {
    return 'Healthy';
  }
}

/// Budget statistics summary
final budgetStatisticsProvider = Provider<BudgetStatistics>((ref) {
  final budgetsAsync = ref.watch(budgetsStreamProvider);
  
  return budgetsAsync.when(
    data: (budgets) {
      final now = DateTime.now();
      final active = budgets.where((b) => 
        b.startDate.isBefore(now) && b.endDate.isAfter(now)
      ).length;
      final upcoming = budgets.where((b) => b.startDate.isAfter(now)).length;
      final completed = budgets.where((b) => b.endDate.isBefore(now)).length;
      final totalBudget = budgets.fold<int>(0, (sum, b) => sum + (b.totalLimit ?? 0));
      
      return BudgetStatistics(
        total: budgets.length,
        active: active,
        upcoming: upcoming,
        completed: completed,
        totalBudget: totalBudget,
      );
    },
    loading: () => BudgetStatistics.empty(),
    error: (_, __) => BudgetStatistics.empty(),
  );
});

/// Budget statistics data class
class BudgetStatistics {
  final int total;
  final int active;
  final int upcoming;
  final int completed;
  final int totalBudget;
  
  const BudgetStatistics({
    required this.total,
    required this.active,
    required this.upcoming,
    required this.completed,
    required this.totalBudget,
  });
  
  factory BudgetStatistics.empty() => const BudgetStatistics(
    total: 0,
    active: 0,
    upcoming: 0,
    completed: 0,
    totalBudget: 0,
  );
}

/// Stream of active budgets (within date range) - REACTIVE
final activeBudgetsProvider = Provider<AsyncValue<List<Budget>>>((ref) {
  final budgetsAsync = ref.watch(budgetsStreamProvider);
  
  return budgetsAsync.whenData((budgets) {
    final now = DateTime.now();
    return budgets.where((b) => 
      b.startDate.isBefore(now) && b.endDate.isAfter(now)
    ).toList();
  });
});

// ============================================================
// SINGLE BUDGET PROVIDERS
// ============================================================

/// Family of providers for watching individual budgets
final budgetByIdProvider = StreamProvider.family<Budget?, String>((ref, id) {
  final db = ref.watch(databaseProvider);
  return db.watchBudgetById(id);
});

/// Stream of total spent in a budget
final budgetTotalSpentProvider = StreamProvider.family<int, String>((ref, budgetId) {
  final db = ref.watch(databaseProvider);
  return db.watchTotalSpentInBudget(budgetId);
});

/// Stream of spending per semi-budget
final budgetSemiBudgetSpendingProvider = StreamProvider.family<Map<String, int>, String>((ref, budgetId) {
  final db = ref.watch(databaseProvider);
  return db.watchSemiBudgetSpending(budgetId);
});

/// Provider for budget with its semi-budgets - REACTIVE
final budgetWithSemiBudgetsProvider = Provider.family<AsyncValue<BudgetWithSemiBudgets?>, String>((ref, budgetId) {
  final budgetAsync = ref.watch(budgetByIdProvider(budgetId));
  final semiBudgetsAsync = ref.watch(semiBudgetsProvider(budgetId));
  final totalSpentAsync = ref.watch(budgetTotalSpentProvider(budgetId));
  final spendingMapAsync = ref.watch(budgetSemiBudgetSpendingProvider(budgetId));
  
  // Return loading if any valid stream is loading (and no previous data)
  if (budgetAsync.isLoading || semiBudgetsAsync.isLoading || 
      totalSpentAsync.isLoading || spendingMapAsync.isLoading) {
    if (!budgetAsync.hasValue && !semiBudgetsAsync.hasValue) {
       return const AsyncValue.loading();
    }
  }
  
  if (budgetAsync.hasError) return AsyncValue.error(budgetAsync.error!, budgetAsync.stackTrace!);
  
  final budget = budgetAsync.valueOrNull;
  if (budget == null) return const AsyncValue.data(null);
  
  final semiBudgets = semiBudgetsAsync.valueOrNull ?? [];
  final totalSpent = totalSpentAsync.valueOrNull ?? 0;
  final spendingMap = spendingMapAsync.valueOrNull ?? {};
  
  return AsyncValue.data(BudgetWithSemiBudgets(
    budget: budget,
    semiBudgets: semiBudgets,
    totalSpent: totalSpent,
    semiBudgetSpending: spendingMap,
  ));
});

/// Data class for budget with related data
class BudgetWithSemiBudgets {
  final Budget budget;
  final List<SemiBudget> semiBudgets;
  final int totalSpent;
  final Map<String, int> semiBudgetSpending;

  BudgetWithSemiBudgets({
    required this.budget,
    required this.semiBudgets,
    required this.totalSpent,
    required this.semiBudgetSpending,
  });

  double get spentPercentage {
    if (budget.totalLimit == null || budget.totalLimit == 0) return 0;
    return totalSpent / budget.totalLimit!;
  }

  int get remaining {
    if (budget.totalLimit == null) return 0;
    return budget.totalLimit! - totalSpent;
  }

  /// Groups semi-budgets by parent ID.
  /// Key: Parent SemiBudget, Value: List of child SemiBudgets
  Map<SemiBudget, List<SemiBudget>> get groupedSemiBudgets {
    final roots = semiBudgets.where((s) => s.parentCategoryId == null).toList();
    final Map<SemiBudget, List<SemiBudget>> grouped = {};
    
    for (final root in roots) {
      grouped[root] = semiBudgets.where((s) => s.parentCategoryId == root.id).toList();
    }
    
    return grouped;
  }

  /// Gets total spent for a category including all its subcategories
  int getAggregatedSpending(String categoryId) {
    int total = semiBudgetSpending[categoryId] ?? 0;
    
    // Find children
    final children = semiBudgets.where((s) => s.parentCategoryId == categoryId);
    for (final child in children) {
      total += semiBudgetSpending[child.id] ?? 0;
    }
    
    return total;
  }

  /// Gets total limit for a category including all its subcategories
  int getAggregatedLimit(String categoryId) {
    final parent = semiBudgets.firstWhere((s) => s.id == categoryId);
    int total = parent.limitAmount;
    
    // In some systems, subcategory limits might be "parts" of the parent limit
    // or additional. Usually they are parts. 
    // If the user set a parent limit of 1000 and sub limits totaling 800, 
    // the parent limit is the source of truth.
    // If parent limit is 0, we sum sub limits.
    
    if (total == 0) {
      final children = semiBudgets.where((s) => s.parentCategoryId == categoryId);
      for (final child in children) {
        total += child.limitAmount;
      }
    }
    
    return total;
  }
}

// ============================================================
// SEMI-BUDGET PROVIDERS
// ============================================================

/// Stream of semi-budgets for a specific budget
final semiBudgetsProvider = StreamProvider.family<List<SemiBudget>, String>((ref, budgetId) {
  final db = ref.watch(databaseProvider);
  return db.watchSemiBudgetsByBudgetId(budgetId);
});

// ============================================================
// BUDGET CONTROLLER
// ============================================================

// ============================================================
// BUDGET CONTROLLER
// ============================================================

/// Controller for budget mutations
final budgetControllerProvider = StateNotifierProvider<BudgetController, BudgetState>((ref) {
  return BudgetController(ref);
});

class BudgetController extends StateNotifier<BudgetState> {
  final Ref _ref;
  final Logger _logger = Loggers.budget;
  
  BudgetController(this._ref) : super(const BudgetState());
  
  AppDatabase get _db => _ref.read(databaseProvider);
  String? get _userId => _ref.read(currentUserIdProvider);
  
  // Phase 1: Outbox service for offline-safe writes
  // OutboxService usage removed in favor of DataBatchSync (Drift/DB)

  Future<String> createBudget({
    required String title,
    required String type,
    required DateTime startDate,
    required DateTime endDate,
    required String currency,
    int? totalLimit,
    String? notes,
    String? tags,
    String status = 'active',
    bool isShared = false,
  }) async {
    if (_userId == null) {
      state = state.copyWith(lastOperation: AsyncValue.error(Exception('User not logged in'), StackTrace.current));
      throw Exception('User not logged in');
    }
    
    state = state.copyWith(isLoading: true, lastOperation: const AsyncValue.loading());
    _logger.info('Creating budget', context: {'title': title, 'type': type});
    
    try {
      // DOMAIN VALIDATION: Check tier limits
      final currentBudgetCount = await _db.budgets.count().getSingle();
      final userTier = subscriptionService.currentTier.name;
      BudgetDomain.validateCreate(
        currentBudgetCount: currentBudgetCount,
        tier: userTier,
      );
      
      // DOMAIN VALIDATION: Validate inputs
      BudgetDomain.validateName(title);
      if (totalLimit != null) {
        BudgetDomain.validateAmount(totalLimit.toDouble() / 100); // cents to dollars
      }
      BudgetDomain.validatePeriod(type);
      BudgetDomain.validateDates(startDate: startDate, endDate: endDate);
      
      final id = _uuid.v4();
      
      await _db.insertBudget(BudgetsCompanion(
        id: Value(id),
        ownerId: Value(_userId!),
        title: Value(title),
        type: Value(type),
        startDate: Value(startDate),
        endDate: Value(endDate),
        currency: Value(currency),
        totalLimit: Value(totalLimit),
        notes: Value(notes),
        tags: Value(tags),
        status: Value(status),
        isShared: Value(isShared),
        syncState: const Value('dirty'),
      ));
      
      // Sync handled by DataBatchSync (dirty flag set above)
      
      _logger.info('Budget created successfully', context: {'id': id, 'title': title});
      errorReporter.addBreadcrumb('Budget created', category: 'budget', data: {'id': id});
      
      state = state.copyWith(
        isLoading: false,
        lastOperation: const AsyncValue.data(null),
        lastSuccessId: id,
      );
      return id;
    } catch (e, stack) {
      _logger.error('Budget creation failed', error: e, stackTrace: stack, context: {'title': title});
      await errorReporter.reportException(e, stackTrace: stack, context: {
        'operation': 'create_budget',
        'title': title,
      });
      // Standardize error handling
      final category = ErrorTaxonomy.classify(e is Exception ? e : Exception(e.toString()));
      state = state.copyWith(
        isLoading: false,
        lastOperation: AsyncValue.error(e, stack),
      );
      rethrow;
    }
  }

  Future<void> updateBudget({
    required String id,
    String? title,
    String? type,
    DateTime? startDate,
    DateTime? endDate,
    String? currency,
    int? totalLimit,
    String? notes,
    String? tags,
    String? status,
    bool? isShared,
  }) async {
    state = state.copyWith(isLoading: true, lastOperation: const AsyncValue.loading());
    try {
      final existing = await _db.getBudgetById(id);
      if (existing == null) throw Exception('Budget not found');
      
      await _db.updateBudget(BudgetsCompanion(
        id: Value(id),
        ownerId: Value(existing.ownerId),
        title: Value(title ?? existing.title),
        type: Value(type ?? existing.type),
        startDate: Value(startDate ?? existing.startDate),
        endDate: Value(endDate ?? existing.endDate),
        currency: Value(currency ?? existing.currency),
        totalLimit: Value(totalLimit ?? existing.totalLimit),
        notes: Value(notes ?? existing.notes),
        tags: Value(tags ?? existing.tags),
        status: Value(status ?? existing.status),
        isShared: Value(isShared ?? existing.isShared),
        createdAt: Value(existing.createdAt),
        updatedAt: Value(DateTime.now()),
        revision: Value(existing.revision + 1),
        isDeleted: Value(existing.isDeleted),
        syncState: const Value('dirty'),
      ));

      // Sync handled by DataBatchSync (dirty flag)
      
      state = state.copyWith(
        isLoading: false, 
        lastOperation: const AsyncValue.data(null),
        lastSuccessId: id,
      );
    } catch (e, st) {
      state = state.copyWith(
        isLoading: false,
        lastOperation: AsyncValue.error(e, st),
      );
    }
  }

  Future<void> deleteBudget(String id) async {
    state = state.copyWith(isLoading: true, lastOperation: const AsyncValue.loading());
    try {
      await _db.deleteBudget(id);
      try {
        _ref.read(syncEngineProvider).syncBudget(id);
      } catch (e) {
        print('Sync trigger failed: $e');
      }
      state = state.copyWith(
        isLoading: false, 
        lastOperation: const AsyncValue.data(null),
      );
    } catch (e, st) {
      state = state.copyWith(
        isLoading: false,
        lastOperation: AsyncValue.error(e, st),
      );
    }
  }

  Future<String> createSemiBudget({
    required String budgetId,
    required String name,
    required int limitAmount,
    int priority = 3,
    String? iconName,
    String? colorHex,
    String? parentCategoryId,
    String? masterCategoryId, // Links to Categories table for proper expense filtering
  }) async {
    state = state.copyWith(isLoading: true, lastOperation: const AsyncValue.loading());
    try {
      final id = _uuid.v4();
      final isSubcategory = parentCategoryId != null;
      
      await _db.insertSemiBudget(SemiBudgetsCompanion(
        id: Value(id),
        budgetId: Value(budgetId),
        name: Value(name),
        limitAmount: Value(limitAmount),
        priority: Value(priority),
        iconName: Value(iconName),
        colorHex: Value(colorHex),
        parentCategoryId: Value(parentCategoryId),
        isSubcategory: Value(isSubcategory),
        masterCategoryId: Value(masterCategoryId),
        syncState: const Value('dirty'), 
      ));
      
      // Sync handled by DataBatchSync
      
      state = state.copyWith(
        isLoading: false,
        lastOperation: const AsyncValue.data(null),
      );
      return id;
    } catch (e, st) {
      state = state.copyWith(
        isLoading: false,
        lastOperation: AsyncValue.error(e, st),
      );
      rethrow;
    }
  }

  Future<void> updateSemiBudget({
    required String id,
    String? name,
    int? limitAmount,
    int? priority,
    String? iconName,
    String? colorHex,
    String? parentCategoryId,
    String? masterCategoryId,
  }) async {
    state = state.copyWith(isLoading: true, lastOperation: const AsyncValue.loading());
    try {
      final existing = await _db.getSemiBudgetById(id);
      if (existing == null) throw Exception('Semi-budget not found');
      
      final isSubcategory = parentCategoryId != null;

      await _db.updateSemiBudget(SemiBudgetsCompanion(
        id: Value(id),
        budgetId: Value(existing.budgetId),
        name: Value(name ?? existing.name),
        limitAmount: Value(limitAmount ?? existing.limitAmount),
        priority: Value(priority ?? existing.priority),
        iconName: Value(iconName ?? existing.iconName),
        colorHex: Value(colorHex ?? existing.colorHex),
        parentCategoryId: Value(parentCategoryId), // Allow setting/unsetting
        isSubcategory: Value(isSubcategory),
        masterCategoryId: Value(masterCategoryId ?? existing.masterCategoryId),
        createdAt: Value(existing.createdAt),
        updatedAt: Value(DateTime.now()),
        revision: Value(existing.revision + 1),
        isDeleted: Value(existing.isDeleted),
      ));

      // Sync handled by DataBatchSync (dirty flag)
      
      state = state.copyWith(isLoading: false, lastOperation: const AsyncValue.data(null));
    } catch (e, st) {
      state = state.copyWith(isLoading: false, lastOperation: AsyncValue.error(e, st));
    }
  }

  /// Delete a semi-budget (soft delete)
  Future<void> deleteSemiBudget(String id) async {
    state = state.copyWith(isLoading: true, lastOperation: const AsyncValue.loading());
    try {
      final existing = await _db.getSemiBudgetById(id);
      if (existing == null) throw Exception('Semi-budget not found');
      
      await _db.updateSemiBudget(SemiBudgetsCompanion(
        id: Value(id),
        isDeleted: const Value(true),
        updatedAt: Value(DateTime.now()),
        syncState: const Value('dirty'),
        revision: Value(existing.revision + 1), 
      ));
      
      // Sync handled by DataBatchSync (dirty flag)
      
      state = state.copyWith(isLoading: false, lastOperation: const AsyncValue.data(null));
    } catch (e, st) {
      state = state.copyWith(isLoading: false, lastOperation: AsyncValue.error(e, st));
    }
  }
}

// ============================================================
// FAMILY BUDGET MEMBERS PROVIDERS
// ============================================================

/// Stream of members for a specific budget
final budgetMembersProvider = StreamProvider.family<List<BudgetMember>, String>((ref, budgetId) {
  final db = ref.watch(databaseProvider);
  return db.watchBudgetMembers(budgetId);
});

/// Check if current user is owner of a budget
final isBudgetOwnerProvider = Provider.family<bool, Budget>((ref, budget) {
  final userId = ref.watch(currentUserIdProvider);
  return userId != null && budget.ownerId == userId;
});

/// All budgets with their member counts (for family screen grouped view)
final budgetsWithMemberCountsProvider = FutureProvider<List<({Budget budget, int memberCount})>>((ref) async {
  final budgetsAsync = ref.watch(budgetsStreamProvider);
  final db = ref.watch(databaseProvider);
  
  return budgetsAsync.when(
    data: (budgets) async {
      final results = <({Budget budget, int memberCount})>[];
      for (final budget in budgets) {
        final members = await db.getBudgetMembers(budget.id);
        results.add((budget: budget, memberCount: members.length));
      }
      return results;
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

