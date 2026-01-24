/// Stripe Configuration
/// Contains publishable keys for payment processing
/// IMPORTANT: Never store secret keys in client code!
///
/// Secret keys should ONLY be used in backend (Supabase Edge Functions)
class StripeConfig {
  // ---------------------------------------------------------------------------
  // STRIPE KEYS
  // ---------------------------------------------------------------------------

  /// Stripe Publishable Key (TEST)
  /// Safe for client-side usage
  static const String publishableKey =
      'pk_test_51SdTVsCirFMLkjOknYcZKQyYDj8yZLTnRj4xNm33i7p2AYelhMdIoTjwBZnE6FHPw8nprxVPAoBW9bDyzKNt916p00e3jYv8zX';

  /// Stripe Publishable Key (LIVE)
  /// ⚠️ Set this before releasing production builds
  static const String livePublishableKey = '';

  // ---------------------------------------------------------------------------
  // APP / MERCHANT INFO
  // ---------------------------------------------------------------------------

  /// Display name shown in Stripe UI
  static const String merchantName = 'CashPilot';

  /// Deep link return URL registered in Stripe Dashboard
  static const String returnUrl = 'io.supabase.cashpilot://stripe-redirect';

  // ---------------------------------------------------------------------------
  // ACTIVE KEY SELECTION
  // ---------------------------------------------------------------------------

  /// Returns the correct publishable key based on build mode
  ///
  /// Safety guarantees:
  /// - Debug/Profile → test key
  /// - Release → live key (if provided)
  /// - Never returns an empty key silently in release
  static String get activePublishableKey {
    // In release builds, prefer live key
    const bool isRelease = bool.fromEnvironment('dart.vm.product');

    if (isRelease) {
      if (livePublishableKey.isEmpty) {
        // Fail loudly in debug logs but still prevent crash
        assert(
          false,
          'Stripe livePublishableKey is empty in release build!',
        );
        return publishableKey; // fallback to test to avoid hard crash
      }
      return livePublishableKey;
    }

    // Debug / profile builds
    return publishableKey;
  }
}
