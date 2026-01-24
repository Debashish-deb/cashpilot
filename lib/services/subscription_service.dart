/// Subscription Service
/// Manages user subscription state, trials, and feature access
/// 
/// Aligned with payment plan: docs/payment plan.md
/// Tiers: Free, Pro, Pro Plus
library;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/subscription.dart';
import '../core/utils/logger.dart';
import 'auth_service.dart';
import 'stripe_service.dart';

/// Subscription service - Singleton
class SubscriptionService {
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  // Current subscription state (cached)
  SubscriptionTier _currentTier = SubscriptionTier.free;
  SubscriptionStatus _currentStatus = SubscriptionStatus.active;
  DateTime? _trialStartedAt;
  DateTime? _trialExpiresAt;
  DateTime? _subscriptionExpiresAt;
  int _ocrScansUsed = 0;
  DateTime? _ocrScansResetAt;
  
  // Family membership tracking
  bool _isMemberOfProPlusFamily = false;
  String? _familyOwnerId;

  // Getters
  SubscriptionTier get currentTier => _currentTier;
  SubscriptionStatus get currentStatus => _currentStatus;
  DateTime? get trialExpiresAt => _trialExpiresAt;
  DateTime? get subscriptionExpiresAt => _subscriptionExpiresAt;
  int get ocrScansUsed => _ocrScansUsed;
  
  bool get isMemberOfProPlusFamily => _isMemberOfProPlusFamily;
  String? get familyOwnerId => _familyOwnerId;
  
  int get ocrScansRemaining {
    final limit = SubscriptionManager.ocrScansPerMonth(_currentTier);
    if (limit == -1) return -1; // Unlimited
    if (limit == 0) return 0;   // No OCR access
    final remaining = limit - _ocrScansUsed;
    return remaining < 0 ? 0 : remaining;
  }

  bool get isFree => _currentTier == SubscriptionTier.free;
  bool get isPro => _currentTier == SubscriptionTier.pro;
  bool get isProPlus => _currentTier == SubscriptionTier.proPlus;
  bool get isPaid => _currentTier != SubscriptionTier.free;
  bool get isInGracePeriod => _currentStatus == SubscriptionStatus.gracePeriod;
  
  /// Check if user has any form of cloud access
  /// - Pro/Pro Plus: Full cloud access
  /// - Free member of Pro Plus family: Limited cloud access (family data only)
  bool get hasCloudAccess => isPaid || _isMemberOfProPlusFamily;

  // Initialization guard (prevent duplicate initializations)
  bool _initialized = false;

  /// Initialize subscription state
  Future<void> initialize() async {
    // Guard against duplicate initialization
    if (_initialized) {
      logger.info('Subscription service already initialized - skipping', category: LogCategory.subscription);
      return;
    }
    
    _initialized = true;
    
    try {
      logger.info('Initializing subscription service', category: LogCategory.subscription);
      
      // Load from local storage with retry
      await _loadFromStorageWithRetry();
      
      // Check for expirations and sync with remote
      await checkExpirations();
      await sync();
      
      // Sync with payment provider (Stripe)
      await _syncWithPaymentProvider();
      
      logger.info(
        'Subscription service initialized successfully',
        category: LogCategory.subscription,
        metadata: {
          'tier': _currentTier.value,
          'status': _currentStatus.value,
          'is_family_member': _isMemberOfProPlusFamily,
        },
      );
    } catch (e, stackTrace) {
      logger.error(
        'Failed to initialize subscription service',
        category: LogCategory.subscription,
        error: e,
        stackTrace: stackTrace,
      );
      // Graceful degradation: Continue with free tier
      _currentTier = SubscriptionTier.free;
      _currentStatus = SubscriptionStatus.active;
    }
  }

  /// Load subscription state from local storage with retry logic
  Future<void> _loadFromStorageWithRetry({int maxRetries = 3}) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        await _loadFromStorage();
        return;
      } catch (e) {
        logger.warning(
          'Storage load attempt $attempt failed',
          category: LogCategory.subscription,
          error: e,
        );
        
        if (attempt == maxRetries) {
          rethrow;
        }
        
        // Exponential backoff
        await Future.delayed(Duration(milliseconds: 100 * attempt));
      }
    }
  }

  /// Load subscription state from local storage
  Future<void> _loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    
    _currentTier = SubscriptionTier.fromString(
      prefs.getString('subscription_tier') ?? 'free',
    );
    _currentStatus = SubscriptionStatus.fromString(
      prefs.getString('subscription_status') ?? 'active',
    );
    
    final trialStartMs = prefs.getInt('trial_started_at');
    _trialStartedAt = trialStartMs != null 
        ? DateTime.fromMillisecondsSinceEpoch(trialStartMs) 
        : null;
    
    final trialExpiresMs = prefs.getInt('trial_expires_at');
    _trialExpiresAt = trialExpiresMs != null 
        ? DateTime.fromMillisecondsSinceEpoch(trialExpiresMs) 
        : null;
    
    final subExpiresMs = prefs.getInt('subscription_expires_at');
    _subscriptionExpiresAt = subExpiresMs != null 
        ? DateTime.fromMillisecondsSinceEpoch(subExpiresMs) 
        : null;
    
    _ocrScansUsed = prefs.getInt('ocr_scans_used') ?? 0;
    
    final ocrResetMs = prefs.getInt('ocr_scans_reset_at');
    _ocrScansResetAt = ocrResetMs != null 
        ? DateTime.fromMillisecondsSinceEpoch(ocrResetMs) 
        : null;
    
    // Family membership
    _isMemberOfProPlusFamily = prefs.getBool('is_family_member') ?? false;
    _familyOwnerId = prefs.getString('family_owner_id');
  }

  /// Save subscription state to local storage
  Future<void> _saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setString('subscription_tier', _currentTier.value);
    await prefs.setString('subscription_status', _currentStatus.value);
    
    if (_trialStartedAt != null) {
      await prefs.setInt('trial_started_at', _trialStartedAt!.millisecondsSinceEpoch);
    }
    
    if (_trialExpiresAt != null) {
      await prefs.setInt('trial_expires_at', _trialExpiresAt!.millisecondsSinceEpoch);
    }
    
    if (_subscriptionExpiresAt != null) {
      await prefs.setInt('subscription_expires_at', _subscriptionExpiresAt!.millisecondsSinceEpoch);
    }
    
    await prefs.setInt('ocr_scans_used', _ocrScansUsed);
    
    if (_ocrScansResetAt != null) {
      await prefs.setInt('ocr_scans_reset_at', _ocrScansResetAt!.millisecondsSinceEpoch);
    }
    
    // Family membership
    await prefs.setBool('is_family_member', _isMemberOfProPlusFamily);
    if (_familyOwnerId != null) {
      await prefs.setString('family_owner_id', _familyOwnerId!);
    } else {
      await prefs.remove('family_owner_id');
    }
  }

  /// Reset subscription to free tier (for guest users or logout)
  Future<void> resetToFree() async {
    _currentTier = SubscriptionTier.free;
    _currentStatus = SubscriptionStatus.active;
    _trialStartedAt = null;
    _trialExpiresAt = null;
    _subscriptionExpiresAt = null;
    _ocrScansUsed = 0;
    _ocrScansResetAt = null;
    _isMemberOfProPlusFamily = false;
    _familyOwnerId = null;
    
    await _saveToStorage();
    logger.info('Subscription reset to free tier', category: LogCategory.subscription);
  }

  /// Start 14-day free trial (gives Pro features)
  Future<bool> startTrial() async {
    try {
      // Validation: Check if trial already started
      if (_trialStartedAt != null) {
        logger.warning(
          'Trial start rejected: already started',
          category: LogCategory.subscription,
          metadata: {'started_at': _trialStartedAt!.toIso8601String()},
        );
        return false;
      }
      
      // Validation: Check if user was previously on paid tier
      if (isPaid) {
        logger.warning(
          'Trial start rejected: user already has/had paid subscription',
          category: LogCategory.subscription,
          metadata: {'current_tier': _currentTier.value},
        );
        return false;
      }
      
      final now = DateTime.now();
      _trialStartedAt = now;
      _trialExpiresAt = now.add(const Duration(days: TrialConfig.trialDurationDays));
      _currentTier = SubscriptionTier.pro; // Trial gives Pro access
      _currentStatus = SubscriptionStatus.active;
      
      await _saveToStorage();
      
      logger.info(
        'Trial started successfully',
        category: LogCategory.subscription,
        metadata: {
          'expires_at': _trialExpiresAt!.toIso8601String(),
          'duration_days': TrialConfig.trialDurationDays,
        },
      );
      
      return true;
    } catch (e, stackTrace) {
      logger.error(
        'Failed to start trial',
        category: LogCategory.subscription,
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Check if trial/subscription has expired
  Future<void> checkExpirations() async {
    final now = DateTime.now();
    
    // Check trial expiration
    if (_trialExpiresAt != null && now.isAfter(_trialExpiresAt!)) {
      if (_currentStatus != SubscriptionStatus.expired) {
        debugPrint('[SubscriptionService] Trial expired, entering grace period');
        await _handleTrialExpired();
      }
    }
    
    // Check subscription expiration
    if (isPaid && _subscriptionExpiresAt != null) {
      if (now.isAfter(_subscriptionExpiresAt!)) {
        debugPrint('[SubscriptionService] Subscription expired');
        await _handleSubscriptionExpired();
      }
    }
    
    // Check grace period expiration
    if (_currentStatus == SubscriptionStatus.gracePeriod) {
      final graceEndDate = (_subscriptionExpiresAt ?? _trialExpiresAt)!.add(
        const Duration(days: TrialConfig.gracePeriodDays),
      );
      
      if (now.isAfter(graceEndDate)) {
        debugPrint('[SubscriptionService] Grace period expired, downgrading to free');
        await _downgradeToFree();
      }
    }
    
    // Reset OCR scans monthly
    if (_ocrScansResetAt != null && now.isAfter(_ocrScansResetAt!)) {
      _ocrScansUsed = 0;
      _ocrScansResetAt = DateTime(now.year, now.month + 1, 1);
      await _saveToStorage();
      debugPrint('[SubscriptionService] OCR scans reset');
    }
  }

  Future<void> _handleTrialExpired() async {
    _currentStatus = SubscriptionStatus.gracePeriod;
    _subscriptionExpiresAt = _trialExpiresAt;
    
    await _saveToStorage();
  }

  Future<void> _handleSubscriptionExpired() async {
    _currentStatus = SubscriptionStatus.gracePeriod;
    
    await _saveToStorage();
  }

  Future<void> _downgradeToFree() async {
    _currentTier = SubscriptionTier.free;
    _currentStatus = SubscriptionStatus.active;
    _subscriptionExpiresAt = null;
    
    await _saveToStorage();
    
    logger.info('Downgraded to free tier', category: LogCategory.subscription);
    // Note: Data archiving handled by business logic layer
  }

  /// Upgrade to Pro
  Future<bool> upgradeToPro({bool yearly = false}) async {
    debugPrint('[SubscriptionService] Upgrading to Pro (${yearly ? 'yearly' : 'monthly'})');
    
    // Process payment via Stripe
    final amount = yearly ? 3999 : 499; // €39.99 or €4.99 in cents
    final success = await stripeService.processSubscription(
      planId: yearly ? 'cashpilot_pro_yearly' : 'cashpilot_pro_monthly',
      amountInCents: amount,
    );
    
    if (!success) {
      logger.warning('Pro upgrade payment failed', category: LogCategory.subscription);
      return false;
    }
    
    _currentTier = SubscriptionTier.pro;
    _currentStatus = SubscriptionStatus.active;
    _subscriptionExpiresAt = yearly 
        ? DateTime.now().add(const Duration(days: 365))
        : DateTime.now().add(const Duration(days: 30));
    
    await _saveToStorage();
    
    logger.info('Upgraded to Pro! Expires: $_subscriptionExpiresAt', category: LogCategory.subscription);
    
    return true;
  }

  /// Upgrade to Pro Plus
  Future<bool> upgradeToProPlus({bool yearly = false}) async {
    debugPrint('[SubscriptionService] Upgrading to Pro Plus (${yearly ? 'yearly' : 'monthly'})');
    
    // Process payment via Stripe
    final amount = yearly ? 7999 : 999; // €79.99 or €9.99 in cents
    final success = await stripeService.processSubscription(
      planId: yearly ? 'cashpilot_proplus_yearly' : 'cashpilot_proplus_monthly',
      amountInCents: amount,
    );
    
    if (!success) {
      logger.warning('Pro Plus upgrade payment failed', category: LogCategory.subscription);
      return false;
    }
    
    _currentTier = SubscriptionTier.proPlus;
    _currentStatus = SubscriptionStatus.active;
    _subscriptionExpiresAt = yearly 
        ? DateTime.now().add(const Duration(days: 365))
        : DateTime.now().add(const Duration(days: 30));
    
    await _saveToStorage();
    
    logger.info('Upgraded to Pro Plus! Expires: $_subscriptionExpiresAt', category: LogCategory.subscription);
    
    return true;
  }

  /// Join a Pro Plus family budget (for Free users)
  Future<bool> joinProPlusFamily(String ownerId) async {
    if (!isFree) {
      // Only free users need family cloud access boost
      return true;
    }
    
    _isMemberOfProPlusFamily = true;
    _familyOwnerId = ownerId;
    await _saveToStorage();
    
    debugPrint('[SubscriptionService] Joined Pro Plus family, limited cloud access granted');
    return true;
  }

  /// Leave a Pro Plus family budget
  Future<void> leaveFamilyBudget() async {
    if (_isMemberOfProPlusFamily) {
      _isMemberOfProPlusFamily = false;
      _familyOwnerId = null;
      await _saveToStorage();
      
      debugPrint('[SubscriptionService] Left Pro Plus family, cloud access revoked');
    }
  }

  /// Use an OCR scan (server-side validation)
  /// This now calls Supabase RPC to prevent client-side bypass
  Future<bool> useOCRScan() async {
    try {
      // Call server-side validation function
      final response = await authService.client.rpc('use_ocr_scan');
      
      if (response == null) {
        logger.error(
          'OCR scan RPC returned null',
          category: LogCategory.feature,
        );
        return false;
      }

      final data = response as Map<String, dynamic>;
      final success = data['success'] as bool? ?? false;

      if (!success) {
        final error = data['error'] as String? ?? 'Unknown error';
        logger.warning(
          'OCR scan rejected by server: $error',
          category: LogCategory.feature,
          metadata: data,
        );
        return false;
      }

      // Update local cache from server response
      if (data['used'] != null) {
        _ocrScansUsed = data['used'] as int;
      }
      if (data['reset_at'] != null) {
        _ocrScansResetAt = DateTime.parse(data['reset_at'] as String);
      }
      
      await _saveToStorage();

      logger.debug(
        'OCR scan used successfully (server-validated)',
        category: LogCategory.feature,
        metadata: {
          'used': data['used'],
          'limit': data['limit'],
          'remaining': data['remaining'],
          'tier': data['tier'],
        },
      );

      return true;
    } catch (e, stackTrace) {
      logger.error(
        'Failed to use OCR scan',
        category: LogCategory.feature,
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Check if user can use a feature
  bool canUseFeature(Feature feature) {
    // Special case: Family budget temporary cloud sync for free users
    if (feature == Feature.cloudSync && isFree && _isMemberOfProPlusFamily) {
      return true; // Limited cloud sync for family data only
    }
    
    return SubscriptionManager.canUseFeature(_currentTier, feature);
  }

  /// Restore purchases (for app reinstall)
  Future<void> restorePurchases() async {
    logger.info('Restoring purchases...', category: LogCategory.subscription);
    
    // Sync with Stripe and Auth service
    await _syncWithPaymentProvider();
    await sync();
    
    logger.info('Purchases restored', category: LogCategory.subscription);
  }

  /// Cancel subscription
  Future<void> cancelSubscription() async {
    debugPrint('[SubscriptionService] Canceling subscription');
    
    _currentStatus = SubscriptionStatus.canceled;
    
    await _saveToStorage();
    
    // Subscription will remain active until expiration date
  }

  /// Get tier-specific message for a blocked feature
  String getUpgradeMessage(Feature feature) {
    final featureName = SubscriptionManager.getFeatureName(feature);
    
    if (SubscriptionManager.canUseFeature(SubscriptionTier.pro, feature)) {
      return 'Upgrade to Pro to unlock $featureName';
    } else {
      return 'Upgrade to Pro Plus to unlock $featureName';
    }
  }

  /// Get the minimum required tier for a feature
  SubscriptionTier getRequiredTier(Feature feature) {
    if (SubscriptionManager.canUseFeature(SubscriptionTier.free, feature)) {
      return SubscriptionTier.free;
    } else if (SubscriptionManager.canUseFeature(SubscriptionTier.pro, feature)) {
      return SubscriptionTier.pro;
    } else {
      return SubscriptionTier.proPlus;
    }
  }
  /// Sync with remote (AuthService/Supabase)
  Future<void> sync() async {
    await _syncWithAuthService();
  }

  Future<void> _syncWithAuthService() async {
    if (authService.isAuthenticated) {
      try {
        final tierStr = await authService.getSubscriptionTier();
        final newTier = SubscriptionTier.fromString(tierStr);
        if (_currentTier != newTier) {
           _currentTier = newTier;
           if (newTier != SubscriptionTier.free) {
             _currentStatus = SubscriptionStatus.active;
           }
           await _saveToStorage();
           logger.info('Synced subscription tier from Auth: $newTier', category: LogCategory.subscription);
        }
      } catch (e) {
         logger.warning('Failed to sync subscription from Auth', category: LogCategory.subscription, error: e);
      }
    }
  }
  
  /// Sync with Stripe payment provider
  Future<void> _syncWithPaymentProvider() async {
    try {
      // Initialize Stripe if not already done
      await stripeService.initialize();
      
      // Note: In production, you would query Stripe API for active subscriptions
      // For now, we rely on local state and Auth service sync
      
      if (kDebugMode) {
        debugPrint('[Subscription] Stripe available: ${stripeService.isAvailable}');
      }
    } catch (e) {
      logger.warning(
        'Failed to sync with payment provider',
        category: LogCategory.subscription,
        error: e,
      );
    }
  }
}

/// Global instance for easy access
final subscriptionService = SubscriptionService();
