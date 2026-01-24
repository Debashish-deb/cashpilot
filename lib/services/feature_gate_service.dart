/// Feature Gate Service
/// Controls access to Pro features based on subscription tier
/// 
/// Aligned with payment plan: docs/payment plan.md
/// Tiers: free, pro, pro_plus
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/auth_service.dart';
import '../services/subscription_service.dart';
import '../core/providers/app_providers.dart';
import '../core/constants/subscription.dart';

/// Feature gating service for Pro features
class FeatureGateService {
  final Ref ref;
  
  FeatureGateService(this.ref);

  /// Get the current subscription tier (from auth service or subscription service)
  /// Made public for external use (e.g., receipt scanning)
  Future<SubscriptionTier> getCurrentTier() async {
    // Try to get from auth service first (server-side truth)
    final tierString = await authService.getSubscriptionTier();
    return SubscriptionTier.fromString(tierString);
  }

  /// Check if user can use OCR scanning
  /// Free: No OCR
  /// Pro: Limited (20/month)
  /// Pro Plus: Unlimited
  Future<OCRAccess> canUseOCR() async {
    final tier = await getCurrentTier();
    
    if (tier == SubscriptionTier.proPlus) {
      return OCRAccess.unlimited;
    } else if (tier == SubscriptionTier.pro) {
      // Pro gets 20 scans/month (per payment plan)
      final usage = await _getOCRUsage();
      return usage < 20 ? OCRAccess.allowed : OCRAccess.limitReached;
    } else {
      // Free tier gets NO OCR (per payment plan)
      return OCRAccess.notAvailable;
    }
  }

  /// Check if user can use cloud sync
  /// Free: No (unless family member of Pro Plus)
  /// Pro/Pro Plus: Yes
  Future<bool> canUseCloudSync() async {
    final tier = await getCurrentTier();
    
    if (tier != SubscriptionTier.free) {
      return true;
    }
    
    // Check if free user is member of Pro Plus family
    return subscriptionService.isMemberOfProPlusFamily;
  }

  /// Check if user can create/manage family budgets
  /// Only Pro Plus
  Future<bool> canUseFamilyBudgets() async {
    final tier = await getCurrentTier();
    return tier == SubscriptionTier.proPlus;
  }

  /// Check if user can use bank connectivity
  /// Only Pro Plus
  Future<bool> canUseBankConnectivity() async {
    final tier = await getCurrentTier();
    return tier == SubscriptionTier.proPlus;
  }

  /// Check if user can use real-time currency conversion
  /// Pro and Pro Plus
  Future<bool> canUseRealTimeCurrency() async {
    final tier = await getCurrentTier();
    return tier != SubscriptionTier.free;
  }

  /// Check if user can use multi-color themes
  /// Pro and Pro Plus (Free: single color only)
  Future<bool> canUseMultiColorThemes() async {
    final tier = await getCurrentTier();
    return tier != SubscriptionTier.free;
  }

  /// Check if user has full expert mode access
  /// Free: Limited expert mode
  /// Pro/Pro Plus: Full
  Future<bool> hasFullExpertMode() async {
    final tier = await getCurrentTier();
    return tier != SubscriptionTier.free;
  }

  /// Check if user can use AI insights
  /// Free: Limited/Basic
  /// Pro/Pro Plus: Full
  Future<AIInsightLevel> getAIInsightLevel() async {
    final tier = await getCurrentTier();
    
    if (tier == SubscriptionTier.proPlus) {
      return AIInsightLevel.advanced;
    } else if (tier == SubscriptionTier.pro) {
      return AIInsightLevel.full;
    } else {
      return AIInsightLevel.limited;
    }
  }

  /// Get export data limit (months)
  /// Free: 3 months max
  /// Pro/Pro Plus: Unlimited
  Future<int> getExportMonthsLimit() async {
    final tier = await getCurrentTier();
    return SubscriptionManager.exportDataMonthsLimit(tier);
  }

  /// Get OCR usage count for current month
  Future<int> _getOCRUsage() async {
    if (!authService.isAuthenticated) {
      // For guest users, check local storage
      final db = ref.read(databaseProvider);
      final user = await (db.select(db.users)..limit(1)).getSingleOrNull();
      return user?.ocrUsageCount ?? 0;
    }

    try {
      final userId = authService.currentUser!.id;
      final response = await authService.client
          .from('profiles')
          .select('ocr_usage_count, ocr_usage_reset_at')
          .eq('id', userId)
          .single();

      final resetAt = DateTime.tryParse(response['ocr_usage_reset_at'] ?? '') ?? DateTime.now();
      final now = DateTime.now();

      // Reset if it's a new month
      if (now.difference(resetAt).inDays > 30) {
        await authService.client
            .from('profiles')
            .update({
              'ocr_usage_count': 0,
              'ocr_usage_reset_at': now.toIso8601String(),
            })
            .eq('id', userId);
        return 0;
      }

      return response['ocr_usage_count'] ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// Increment OCR usage count
  Future<void> incrementOCRUsage() async {
    if (!authService.isAuthenticated) return;

    try {
      final userId = authService.currentUser!.id;
      await authService.client.rpc('increment_ocr_usage', params: {'user_id': userId});
    } catch (e) {
      // Silent fail - don't block OCR
    }
  }

  /// Get remaining OCR scans for current tier
  Future<int> getRemainingOCRScans() async {
    final tier = await getCurrentTier();
    final limit = SubscriptionManager.ocrScansPerMonth(tier);
    
    if (limit == -1) {
      return 999; // "Unlimited" - represented as high number
    }
    
    if (limit == 0) {
      return 0; // No access
    }

    final usage = await _getOCRUsage();
    return (limit - usage).clamp(0, limit);
  }

  /// Get message explaining why a feature is locked
  String getLockedFeatureMessage(Feature feature) {
    return subscriptionService.getUpgradeMessage(feature);
  }
}

/// OCR access levels
enum OCRAccess {
  unlimited,     // Pro Plus
  allowed,       // Pro (within limit)
  limitReached,  // Pro (limit hit)
  notAvailable,  // Free tier
}

/// AI insight levels
enum AIInsightLevel {
  advanced,  // Pro Plus - Full AI with family insights
  full,      // Pro - Full AI insights
  limited,   // Free - Basic insights only
}

/// Feature gate service provider
final featureGateProvider = Provider<FeatureGateService>((ref) {
  return FeatureGateService(ref);
});
