/// Budget Domain - Business Rules and Invariants
/// Enforces budget-related business logic at the domain layer
library;

import '../../../core/errors/app_error.dart';

/// Subscription tier limits for budgets
class BudgetLimits {
  static const int freeBudgetLimit = 1;
  static const int proBudgetLimit = 10;
  static const int proPlusBudgetLimit = 999; // Effectively unlimited
  
  static const int freeCategoryLimit = 5;
  static const int proCategoryLimit = 15;
  static const int proPlusCategoryLimit = 999;
}

/// Budget domain logic and invariant enforcement
class BudgetDomain {
  /// Validate budget creation based on tier limits
  /// 
  /// Throws AppError if limit exceeded
  static void validateCreate({
    required int currentBudgetCount,
    required String tier,
  }) {
    final maxBudgets = _getMaxBudgets(tier);
    
    if (currentBudgetCount >= maxBudgets) {
      throw AppError(
        code: AppErrorCode.subscriptionLimitReached,
        message: tier == 'free'
            ? 'Free plan allows only 1 budget. Upgrade to Pro for 10 budgets.'
            : 'You\'ve reached the limit of $maxBudgets budgets for your ${tier.toUpperCase()} plan.',
        severity: AppErrorSeverity.actionRequired,
      );
    }
  }
  
  /// Validate budget name
  static void validateName(String name) {
    if (name.trim().isEmpty) {
      throw AppError.validation(
        message: 'Budget name cannot be empty',
      );
    }
    
    if (name.length > 100) {
      throw AppError.validation(
        message: 'Budget name cannot exceed 100 characters',
      );
    }
  }
  
  /// Validate budget amount
  static void validateAmount(double amount) {
    if (amount <= 0) {
      throw AppError.validation(
        message: 'Budget amount must be greater than zero',
      );
    }
    
    if (amount > 999999999) {
      throw AppError.validation(
        message: 'Budget amount is too large',
      );
    }
  }
  
  /// Validate category count for tier
  static void validateCategoryCount({
    required int categoryCount,
    required String tier,
  }) {
    final maxCategories = _getMaxCategories(tier);
    
    if (categoryCount > maxCategories) {
      throw AppError(
        code: AppErrorCode.subscriptionLimitReached,
        message: tier == 'free'
            ? 'Free plan allows only $maxCategories categories per budget. Upgrade to Pro for more.'
            : 'Your ${tier.toUpperCase()} plan allows $maxCategories categories per budget.',
        severity: AppErrorSeverity.actionRequired,
      );
    }
  }
  
  /// Validate budget period
  static void validatePeriod(String period) {
    const validPeriods = ['daily', 'weekly', 'monthly', 'yearly'];
    
    if (!validPeriods.contains(period.toLowerCase())) {
      throw AppError.validation(
        message: 'Budget period must be one of: ${validPeriods.join(", ")}',
      );
    }
  }
  
  /// Validate budget dates
  static void validateDates({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    if (endDate.isBefore(startDate)) {
      throw AppError.validation(
        message: 'Budget end date must be after start date',
      );
    }
    
    final duration = endDate.difference(startDate);
    if (duration.inDays > 1095) { // 3 years
      throw AppError.validation(
        message: 'Budget period cannot exceed 3 years',
      );
    }
  }
  
  /// Get maximum budgets for tier
  static int _getMaxBudgets(String tier) {
    return switch (tier.toLowerCase()) {
      'free' => BudgetLimits.freeBudgetLimit,
      'pro' => BudgetLimits.proBudgetLimit,
      'pro_plus' => BudgetLimits.proPlusBudgetLimit,
      _ => BudgetLimits.freeBudgetLimit,
    };
  }
  
  /// Get maximum categories for tier
  static int _getMaxCategories(String tier) {
    return switch (tier.toLowerCase()) {
      'free' => BudgetLimits.freeCategoryLimit,
      'pro' => BudgetLimits.proCategoryLimit,
      'pro_plus' => BudgetLimits.proPlusCategoryLimit,
      _ => BudgetLimits.freeCategoryLimit,
    };
  }
  
  /// Check if user can create another budget
  static bool canCreateBudget({
    required int currentCount,
    required String tier,
  }) {
    return currentCount < _getMaxBudgets(tier);
  }
  
  /// Get remaining budget slots
  static int getRemainingSlots({
    required int currentCount,
    required String tier,
  }) {
    final max = _getMaxBudgets(tier);
    return (max - currentCount).clamp(0, max);
  }
}
