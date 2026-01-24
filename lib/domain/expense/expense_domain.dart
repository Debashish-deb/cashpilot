/// Expense Domain - Business Rules and Invariants
/// Enforces expense-related business logic at the domain layer
library;

import '../../../core/errors/app_error.dart';

/// Expense domain logic and invariant enforcement
class ExpenseDomain {
  /// Validate expense creation
  /// 
  /// Throws AppError if validation fails
  static void validateCreate({
    required double amount,
    required String? budgetId,
    String? description,
  }) {
    validateAmount(amount);
    validateBudgetAssociation(budgetId);
    if (description != null) {
      validateDescription(description);
    }
  }
  
  /// Validate expense amount
  static void validateAmount(double amount) {
    if (amount <= 0) {
      throw AppError.validation(
        message: 'Expense amount must be greater than zero',
      );
    }
    
    if (amount > 999999999) {
      throw AppError.validation(
        message: 'Expense amount is too large',
      );
    }
  }
  
  /// Validate budget association
  /// 
  /// Note: Budgets are optional but recommended
  static void validateBudgetAssociation(String? budgetId) {
    // For now, budgets are optional
    // In strict mode, we could require budgets for all expenses
    // if (budgetId == null || budgetId.isEmpty) {
    //   throw AppError.validation(
    //     message: 'Expense must be associated with a budget',
    //   );
    // }
  }
  
  /// Validate expense description
  static void validateDescription(String description) {
    if (description.length > 500) {
      throw AppError.validation(
        message: 'Description cannot exceed 500 characters',
      );
    }
  }
  
  /// Validate expense category
  static void validateCategory(String? categoryId) {
    if (categoryId == null || categoryId.isEmpty) {
      throw AppError.validation(
        message: 'Expense must have a category',
      );
    }
  }
  
  /// Validate expense date
  static void validateDate(DateTime date) {
    final now = DateTime.now();
    final futureLimit = now.add(const Duration(days: 365));
    
    if (date.isAfter(futureLimit)) {
      throw AppError.validation(
        message: 'Expense date cannot be more than 1 year in the future',
      );
    }
    
    final pastLimit = now.subtract(const Duration(days: 3650)); // 10 years
    if (date.isBefore(pastLimit)) {
      throw AppError.validation(
        message: 'Expense date cannot be more than 10 years in the past',
      );
    }
  }
  
  /// Validate expense update
  static void validateUpdate({
    double? amount,
    String? description,
  }) {
    if (amount != null) {
      validateAmount(amount);
    }
    if (description != null) {
      validateDescription(description);
    }
  }
  
  /// Check if expense exceeds budget (warning only)
  /// Returns warning message if budget exceeded
  static String? checkBudgetExceeded({
    required double expenseAmount,
    required double budgetLimit,
    required double currentSpent,
  }) {
    final newTotal = currentSpent + expenseAmount;
    
    if (newTotal > budgetLimit) {
      final overage = newTotal - budgetLimit;
      return 'This expense will exceed your budget by \$${overage.toStringAsFixed(2)}';
    }
    
    final remaining = budgetLimit - newTotal;
    if (remaining < budgetLimit * 0.1) { // Less than 10% remaining
      return 'Only \$${remaining.toStringAsFixed(2)} remaining in budget';
    }
    
    return null;
  }
  
  /// Validate receipt attachment
  static void validateReceipt({
    required String? receiptUrl,
    int? receiptFileSize,
  }) {
    if (receiptUrl != null && receiptUrl.isNotEmpty) {
      if (!receiptUrl.startsWith('http://') && !receiptUrl.startsWith('https://')) {
        throw AppError.validation(
          message: 'Invalid receipt URL format',
        );
      }
    }
    
    if (receiptFileSize != null && receiptFileSize > 10 * 1024 * 1024) { // 10 MB
      throw AppError.validation(
        message: 'Receipt file size cannot exceed 10 MB',
      );
    }
  }
}
