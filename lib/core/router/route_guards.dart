import 'package:flutter/foundation.dart';
import '../constants/app_routes.dart';
import '../constants/subscription.dart';

class RouteGuards {
  /// Main redirect function used by GoRouter
  static String? redirect(String? location, {
    required bool onboardingComplete,
    required String? currentUserId,
    required SubscriptionTier tier,
  }) {
    location ??= '/';
    
    final isOnboardingRoute = location == AppRoutes.onboarding;
    final isPublicRoute = location == AppRoutes.login || 
                         location == AppRoutes.register ||
                         location == AppRoutes.userAgreement ||
                         location == AppRoutes.privacyPolicy ||
                         location == AppRoutes.termsOfService;
    final isLoggedIn = currentUserId != null;

    debugPrint('🔀 RouteGuard: location=$location, user=$isLoggedIn, onboarding=$onboardingComplete, tier=${tier.value}');

    // 1. Force Onboarding
    if (!onboardingComplete) {
      if (!isOnboardingRoute) return AppRoutes.onboarding;
      return null;
    }

    // 2. Already Onboarded
    if (onboardingComplete && isOnboardingRoute) {
      return isLoggedIn ? AppRoutes.home : AppRoutes.login;
    }

    // 3. Authenticated User on Public Pages (except legal which they can revisit)
    final isAuthOnlyRoute = location == AppRoutes.login || location == AppRoutes.register;
    if (isLoggedIn && isAuthOnlyRoute) return AppRoutes.home;

    // 4. Unauthenticated User on Protected Pages
    if (!isLoggedIn && !isPublicRoute) return AppRoutes.login;

    // 5. Feature Gating (New)
    if (isLoggedIn) {
      final requiredTier = _getRequiredTierForRoute(location);
      if (requiredTier != SubscriptionTier.free && _isTierLower(tier, requiredTier)) {
        debugPrint('🚫 RouteGuard: feature gated. Route=$location requires ${requiredTier.value}. User has ${tier.value}');
        return '${AppRoutes.paywall}?from=${Uri.encodeComponent(location)}';
      }
    }

    return null; // No redirect needed
  }

  /// Helper to check if a user can access a route based on their tier
  static bool canAccessRoute(String route, SubscriptionTier tier) {
    final required = _getRequiredTierForRoute(route);
    if (required == SubscriptionTier.free) return true;
    return !_isTierLower(tier, required);
  }

  static SubscriptionTier _getRequiredTierForRoute(String route) {
    // Pro Features
    if (route.startsWith(AppRoutes.scanReceipt) || 
        route.startsWith(AppRoutes.scanBarcode) ||
        route == AppRoutes.recurringExpenses) {
      return SubscriptionTier.pro;
    }

    // Pro Plus Features
    if (route.startsWith(AppRoutes.familySettings) ||
        route.startsWith(AppRoutes.pendingInvites) ||
        route.startsWith(AppRoutes.contactPicker) ||
        route.startsWith('/banking')) {
      return SubscriptionTier.proPlus;
    }

    return SubscriptionTier.free;
  }

  static bool _isTierLower(SubscriptionTier current, SubscriptionTier required) {
    if (current == required) return false;
    if (required == SubscriptionTier.proPlus) return true; // current must be lower if not equal
    if (required == SubscriptionTier.pro) return current == SubscriptionTier.free;
    return false;
  }
}
