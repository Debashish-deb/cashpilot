/// Subscription Domain - Business Rules and Invariants
/// Enforces subscription tier limits and feature access
library;

import '../../../core/errors/app_error.dart';

/// Subscription tier definitions
enum SubscriptionTier {
  free,
  pro,
  proPlus;
  
  static SubscriptionTier fromString(String tier) {
    return switch (tier.toLowerCase()) {
      'free' => SubscriptionTier.free,
      'pro' => SubscriptionTier.pro,
      'pro_plus' || 'proplus' => SubscriptionTier.proPlus,
      _ => SubscriptionTier.free,
    };
  }
  
  String toDisplayString() {
    return switch (this) {
      SubscriptionTier.free => 'Free',
      SubscriptionTier.pro => 'Pro',
      SubscriptionTier.proPlus => 'Pro Plus',
    };
  }
}

/// Tier limits and feature matrix
class TierLimits {
  final int maxBudgets;
  final int maxCategoriesPerBudget;
  final int maxFamilyMembers;
  final bool hasReceiptScanning;
  final bool hasBarcodeScanning;
  final bool hasMLAnalytics;
  final bool hasAdvancedReports;
  final bool hasBankIntegration;
  final bool hasPrioritySupport;
  
  const TierLimits({
    required this.maxBudgets,
    required this.maxCategoriesPerBudget,
    required this.maxFamilyMembers,
    this.hasReceiptScanning = false,
    this.hasBarcodeScanning = false,
    this.hasMLAnalytics = false,
    this.hasAdvancedReports = false,
    this.hasBankIntegration = false,
    this.hasPrioritySupport = false,
  });
  
  /// Get limits for subscription tier
  static TierLimits forTier(SubscriptionTier tier) {
    return switch (tier) {
      SubscriptionTier.free => const TierLimits(
        maxBudgets: 1,
        maxCategoriesPerBudget: 5,
        maxFamilyMembers: 0, // No family sharing
        hasReceiptScanning: true, // Basic feature
        hasBarcodeScanning: false,
        hasMLAnalytics: false,
        hasAdvancedReports: false,
        hasBankIntegration: false,
        hasPrioritySupport: false,
      ),
      SubscriptionTier.pro => const TierLimits(
        maxBudgets: 10,
        maxCategoriesPerBudget: 15,
        maxFamilyMembers: 3,
        hasReceiptScanning: true,
        hasBarcodeScanning: true,
        hasMLAnalytics: true,
        hasAdvancedReports: true,
        hasBankIntegration: false,
        hasPrioritySupport: false,
      ),
      SubscriptionTier.proPlus => const TierLimits(
        maxBudgets: 999, // Unlimited
        maxCategoriesPerBudget: 999, // Unlimited
        maxFamilyMembers: 999, // Unlimited
        hasReceiptScanning: true,
        hasBarcodeScanning: true,
        hasMLAnalytics: true,
        hasAdvancedReports: true,
        hasBankIntegration: true,
        hasPrioritySupport: true,
      ),
    };
  }
}

/// Subscription domain logic
class SubscriptionDomain {
  /// Check if tier has access to feature
  static bool hasFeatureAccess({
    required SubscriptionTier tier,
    required String feature,
  }) {
    final limits = TierLimits.forTier(tier);
    
    return switch (feature.toLowerCase()) {
      'receipt_scanning' => limits.hasReceiptScanning,
      'barcode_scanning' => limits.hasBarcodeScanning,
      'ml_analytics' => limits.hasMLAnalytics,
      'advanced_reports' => limits.hasAdvancedReports,
      'bank_integration' => limits.hasBankIntegration,
      'priority_support' => limits.hasPrioritySupport,
      'family_sharing' => limits.maxFamilyMembers > 0,
      _ => false,
    };
  }
  
  /// Validate feature access, throw error if denied
  static void requireFeature({
    required SubscriptionTier tier,
    required String feature,
  }) {
    if (!hasFeatureAccess(tier: tier, feature: feature)) {
      throw AppError.subscriptionRequired(
        message: _getUpgradeMessage(feature),
      );
    }
  }
  
  /// Get upgrade message for feature
  static String _getUpgradeMessage(String feature) {
    return switch (feature.toLowerCase()) {
      'barcode_scanning' => 'Barcode scanning requires a Pro subscription',
      'ml_analytics' => 'ML Analytics requires a Pro subscription',
      'advanced_reports' => 'Advanced reports require a Pro subscription',
      'bank_integration' => 'Bank integration requires a Pro Plus subscription',
      'family_sharing' => 'Family sharing requires a Pro subscription',
      'priority_support' => 'Priority support requires a Pro Plus subscription',
      _ => 'This feature requires a Pro subscription',
    };
  }
  
  /// Validate tier upgrade
  static void validateTierChange({
    required SubscriptionTier currentTier,
    required SubscriptionTier newTier,
  }) {
    // Can always downgrade or stay same
    if (newTier.index <= currentTier.index) {
      return;
    }
    
    // Validate upgrade path
    if (currentTier == SubscriptionTier.free && 
        newTier == SubscriptionTier.proPlus) {
      // Direct upgrade from Free to Pro Plus is allowed
      return;
    }
  }
  
  /// Get recommended tier for user needs
  static SubscriptionTier getRecommendedTier({
    required int budgetCount,
    required int familyMemberCount,
    required bool needsBankIntegration,
  }) {
    if (needsBankIntegration) {
      return SubscriptionTier.proPlus;
    }
    
    if (familyMemberCount > 3 || budgetCount > 10) {
      return SubscriptionTier.proPlus;
    }
    
    if (familyMemberCount > 0 || budgetCount > 1) {
      return SubscriptionTier.pro;
    }
    
    return SubscriptionTier.free;
  }
}
