/// Subscription Providers
/// Riverpod providers for subscription state management
/// 
/// Aligned with payment plan: docs/payment plan.md
/// Tiers: Free, Pro, Pro Plus
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/subscription_service.dart';
import '../../../core/constants/subscription.dart';

/// Subscription service provider
final subscriptionServiceProvider = Provider<SubscriptionService>((ref) {
  return subscriptionService;
});

/// Current tier provider (stream)
/// Polling + Sync implementation ensures real-time updates from Supabase
final currentTierProvider = StreamProvider<SubscriptionTier>((ref) async* {
  final service = ref.watch(subscriptionServiceProvider);
  
  // Emit current tier immediately
  yield service.currentTier;
  
  // Check for changes periodically (every 10 seconds)
  // This loop ensures the app stays in sync with remote db
  while (true) {
    await Future.delayed(const Duration(seconds: 10));
    // Trigger sync with Auth/Remote
    await service.sync();
    await service.checkExpirations();
    yield service.currentTier;
  }
});

/// Current status provider
final subscriptionStatusProvider = Provider<SubscriptionStatus>((ref) {
  // Watch tier to trigger updates
  ref.watch(currentTierProvider);
  return ref.watch(subscriptionServiceProvider).currentStatus;
});

/// Is Free tier provider
final isFreeProvider = Provider<bool>((ref) {
  final tierAsync = ref.watch(currentTierProvider);
  // Default to free if loading or null
  final tier = tierAsync.value ?? SubscriptionTier.free;
  return tier == SubscriptionTier.free;
});

/// Is Pro tier provider
final isProProvider = Provider<bool>((ref) {
  final tierAsync = ref.watch(currentTierProvider);
  final tier = tierAsync.value ?? SubscriptionTier.free;
  return tier == SubscriptionTier.pro;
});

/// Is Pro Plus tier provider
final isProPlusProvider = Provider<bool>((ref) {
  final tierAsync = ref.watch(currentTierProvider);
  final tier = tierAsync.value ?? SubscriptionTier.free;
  return tier == SubscriptionTier.proPlus;
});

/// Is Paid (Pro or Pro Plus) provider
final isPaidProvider = Provider<bool>((ref) {
  final tierAsync = ref.watch(currentTierProvider);
  final tier = tierAsync.value ?? SubscriptionTier.free;
  return tier != SubscriptionTier.free;
});

/// Has cloud access (paid OR free member of Pro Plus family)
final hasCloudAccessProvider = Provider<bool>((ref) {
  ref.watch(currentTierProvider); // Signal dependency
  return ref.watch(subscriptionServiceProvider).hasCloudAccess;
});

/// Is member of Pro Plus family (for Free users with limited cloud access)
final isFamilyMemberProvider = Provider<bool>((ref) {
  ref.watch(currentTierProvider); // Signal dependency
  return ref.watch(subscriptionServiceProvider).isMemberOfProPlusFamily;
});

/// Trial remaining days provider
final trialRemainingDaysProvider = Provider<int>((ref) {
  ref.watch(currentTierProvider); // Signal dependency
  final service = ref.watch(subscriptionServiceProvider);
  final expiresAt = service.trialExpiresAt;
  
  if (expiresAt == null) return 0;
  
  final now = DateTime.now();
  final remaining = expiresAt.difference(now).inDays;
  
  return remaining < 0 ? 0 : remaining;
});

/// OCR scans remaining provider
/// -1 = unlimited, 0 = limit reached
final ocrScansRemainingProvider = Provider<int>((ref) {
  ref.watch(currentTierProvider); // Signal dependency
  return ref.watch(subscriptionServiceProvider).ocrScansRemaining;
});

/// OCR scans used this month
final ocrScansUsedProvider = Provider<int>((ref) {
  ref.watch(currentTierProvider); // Signal dependency
  return ref.watch(subscriptionServiceProvider).ocrScansUsed;
});

/// Can use feature provider (parameterized)
final canUseFeatureProvider = Provider.family<bool, Feature>((ref, feature) {
  ref.watch(currentTierProvider); // Signal dependency
  return ref.watch(subscriptionServiceProvider).canUseFeature(feature);
});

/// Required tier for feature provider
final requiredTierProvider = Provider.family<SubscriptionTier, Feature>((ref, feature) {
  return ref.watch(subscriptionServiceProvider).getRequiredTier(feature);
});

/// Subscription expires at provider
final subscriptionExpiresAtProvider = Provider<DateTime?>((ref) {
  ref.watch(currentTierProvider); // Signal dependency
  return ref.watch(subscriptionServiceProvider).subscriptionExpiresAt;
});

/// OCR scans limit provider
final ocrScansLimitProvider = Provider<int>((ref) {
  final tier = ref.watch(currentTierProvider).value ?? SubscriptionTier.free;
  return SubscriptionManager.ocrScansPerMonth(tier);
});
