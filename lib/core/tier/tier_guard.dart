import 'package:flutter/foundation.dart';

/// Tier Enforcement Guard
/// Enforces free/pro/pro+ limits at DAO and service level
/// This fixes the tier enforcement gap from review
class TierGuard {
  /// Tier limits configuration
  static const Map<String, TierLimits> tierLimits = {
    'free': TierLimits(
      maxBudgets: 1, // Contract: 1
      maxSharedBudgets: 0,
      maxMembersPerBudget: 1, // Self only
      maxExpenses: 500, // Contract: 500
      maxOcrScansPerMonth: 0, // Contract: 0
      maxCategoriesPerBudget: 20,
      canUseRecurring: false,
      canUseSavingsGoals: false,
      canUseAnalytics: false,
      canUseRealtime: false,
    ),

    'pro': TierLimits(
      maxBudgets: 10, // Contract: 10
      maxSharedBudgets: 3,
      maxMembersPerBudget: 3,
      maxExpenses: -1, // Unlimited
      maxOcrScansPerMonth: 10, // Contract: 10/mo
      maxCategoriesPerBudget: 50,
      canUseRecurring: true,
      canUseSavingsGoals: true,
      canUseAnalytics: true,
      canUseRealtime: false,
    ),
    'pro_plus': TierLimits(
      maxBudgets: -1, // Unlimited
      maxSharedBudgets: -1,
      maxMembersPerBudget: 6,
      maxExpenses: -1, // Unlimited
      maxOcrScansPerMonth: -1,
      maxCategoriesPerBudget: -1,
      canUseRecurring: true,
      canUseSavingsGoals: true,
      canUseAnalytics: true,
      canUseRealtime: true,
    ),
  };
  
  /// Get tier limits for user
  static TierLimits getLimits(String tier) {
    var normalized = tier.toLowerCase().replaceAll(' ', '').replaceAll('_', '');
    
    // Map to internal keys
    if (normalized == 'proplus') normalized = 'pro_plus';
    
    return tierLimits[normalized] ?? tierLimits['free']!;
  }
  
  /// Check if user can create budget
  static Future<TierValidationResult> canCreateBudget({
    required String tier,
    required int currentBudgetCount,
  }) async {
    final limits = getLimits(tier);
    
    if (limits.maxBudgets == -1) {
      return TierValidationResult.allowed();
    }
    
    if (currentBudgetCount >= limits.maxBudgets) {
      return TierValidationResult.denied(
        reason: 'Budget limit reached (${limits.maxBudgets})',
        limit: limits.maxBudgets,
        current: currentBudgetCount,
        requiredTier: 'pro',
      );
    }
    
    return TierValidationResult.allowed();
  }

  /// Check if user can create expense
  static Future<TierValidationResult> canCreateExpense({
    required String tier,
    required int currentExpenseCount,
  }) async {
    final limits = getLimits(tier);
    
    if (limits.maxExpenses == -1) {
      return TierValidationResult.allowed();
    }
    
    if (currentExpenseCount >= limits.maxExpenses) {
      return TierValidationResult.denied(
        reason: 'Expense limit reached (${limits.maxExpenses})',
        limit: limits.maxExpenses,
        current: currentExpenseCount,
        requiredTier: 'pro',
      );
    }
    
    return TierValidationResult.allowed();
  }
  
  /// Check if user can share budget
  static Future<TierValidationResult> canShareBudget({
    required String tier,
    required int currentSharedCount,
  }) async {
    final limits = getLimits(tier);
    
    if (limits.maxSharedBudgets == -1) {
      return TierValidationResult.allowed();
    }
    
    if (limits.maxSharedBudgets == 0) {
      return TierValidationResult.denied(
        reason: 'Shared budgets not available',
        limit: 0,
        current: currentSharedCount,
        requiredTier: 'pro',
      );
    }
    
    if (currentSharedCount >= limits.maxSharedBudgets) {
      return TierValidationResult.denied(
        reason: 'Shared budget limit reached',
        limit: limits.maxSharedBudgets,
        current: currentSharedCount,
        requiredTier: 'pro_plus',
      );
    }
    
    return TierValidationResult.allowed();
  }
  
  /// Check if user can use OCR
  static Future<TierValidationResult> canUseOcr({
    required String tier,
    required int ocrUsageThisMonth,
  }) async {
    final limits = getLimits(tier);
    
    if (limits.maxOcrScansPerMonth == -1) {
      return TierValidationResult.allowed();
    }
    
    if (ocrUsageThisMonth >= limits.maxOcrScansPerMonth) {
      return TierValidationResult.denied(
        reason: 'OCR scan limit reached this month',
        limit: limits.maxOcrScansPerMonth,
        current: ocrUsageThisMonth,
        requiredTier: tier == 'free' ? 'pro' : 'pro_plus',
      );
    }
    
    return TierValidationResult.allowed();
  }
  
  /// Check if user can add category to budget
  static Future<TierValidationResult> canAddCategory({
    required String tier,
    required int currentCategoryCount,
  }) async {
    final limits = getLimits(tier);
    
    if (limits.maxCategoriesPerBudget == -1) {
      return TierValidationResult.allowed();
    }
    
    if (currentCategoryCount >= limits.maxCategoriesPerBudget) {
      return TierValidationResult.denied(
        reason: 'Category limit reached for this budget',
        limit: limits.maxCategoriesPerBudget,
        current: currentCategoryCount,
        requiredTier: tier == 'free' ? 'pro' : 'pro_plus',
      );
    }
    
    return TierValidationResult.allowed();
  }
  
  /// Check if user can add member to budget
  static Future<TierValidationResult> canAddMember({
    required String tier,
    required int currentMemberCount,
  }) async {
    final limits = getLimits(tier);
    
    if (limits.maxMembersPerBudget == -1) {
      return TierValidationResult.allowed();
    }
    
    // Note: currentMemberCount typically includes the owner
    if (currentMemberCount >= limits.maxMembersPerBudget) {
      return TierValidationResult.denied(
        reason: 'Budget member limit reached',
        limit: limits.maxMembersPerBudget,
        current: currentMemberCount,
        requiredTier: tier == 'free' ? 'pro' : 'pro_plus',
      );
    }
    
    return TierValidationResult.allowed();
  }
  
  /// Check if feature is available
  static bool canUseFeature(String tier, String feature) {
    final limits = getLimits(tier);
    
    switch (feature) {
      case 'recurring':
        return limits.canUseRecurring;
      case 'savings_goals':
        return limits.canUseSavingsGoals;
      case 'analytics':
        return limits.canUseAnalytics;
      case 'realtime':
        return limits.canUseRealtime;
      default:
        return false;
    }
  }
}

/// Tier limits configuration
class TierLimits {
  final int maxBudgets; // -1 = unlimited
  final int maxSharedBudgets;
  final int maxExpenses; // New: -1 = unlimited
  final int maxOcrScansPerMonth;
  final int maxCategoriesPerBudget;
  final bool canUseRecurring;
  final bool canUseSavingsGoals;
  final bool canUseAnalytics;
  final bool canUseRealtime;
  
  final int maxMembersPerBudget;
  
  const TierLimits({
    required this.maxBudgets,
    required this.maxSharedBudgets,
    required this.maxExpenses,
    required this.maxOcrScansPerMonth,
    required this.maxCategoriesPerBudget,
    required this.maxMembersPerBudget,
    required this.canUseRecurring,
    required this.canUseSavingsGoals,
    required this.canUseAnalytics,
    required this.canUseRealtime,
  });
}

/// Tier validation result
class TierValidationResult {
  final bool isAllowed;
  final String? reason;
  final int? limit;
  final int? current;
  final String? requiredTier;
  
  const TierValidationResult._({
    required this.isAllowed,
    this.reason,
    this.limit,
    this.current,
    this.requiredTier,
  });
  
  factory TierValidationResult.allowed() {
    return const TierValidationResult._(isAllowed: true);
  }
  
  factory TierValidationResult.denied({
    required String reason,
    required int limit,
    required int current,
    required String requiredTier,
  }) {
    debugPrint('[TierGuard] DENIED: $reason (limit: $limit, current: $current, need: $requiredTier)');
    return TierValidationResult._(
      isAllowed: false,
      reason: reason,
      limit: limit,
      current: current,
      requiredTier: requiredTier,
    );
  }
  
  String get userMessage => reason ?? 'Allowed';
  
  @override
  String toString() => isAllowed 
      ? 'Allowed' 
      : 'Denied: $reason (limit: $limit, current: $current, upgrade to: $requiredTier)';
}
