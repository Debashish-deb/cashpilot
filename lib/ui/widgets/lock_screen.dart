/// Displays when app is locked and requires biometric authentication
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/tokens.g.dart';
import '../../core/theme/app_typography.dart';
import '../../core/providers/app_providers.dart';
import '../../core/managers/auth_manager.dart';
import '../../services/biometric_service.dart';
import '../../services/auth_service.dart';

class LockScreen extends ConsumerStatefulWidget {
  final Widget child;

  const LockScreen({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen>
    with WidgetsBindingObserver {
  bool _isAuthenticating = false;
  String? _errorMessage;
  bool _hasCheckedInitial = false;
  DateTime? _lastAuthAttempt;
  int _failedAttempts = 0;

  /// Track when we last successfully unlocked to prevent immediate re-lock
  /// when biometric dialog closes and triggers app resume
  DateTime? _lastSuccessfulUnlock;

  // ---------------------------------------------------------------------------
  // LIFECYCLE
  // ---------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasCheckedInitial) {
        _hasCheckedInitial = true;
        _checkInitialLockState();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    final appLockEnabled = ref.read(appLockEnabledProvider);
    final biometricEnabled = ref.read(biometricEnabledProvider);
    final timeout = ref.read(autoLockTimeoutProvider);

    if (!appLockEnabled || !biometricEnabled) return;

    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      // Don't record pause if we just unlocked (biometric dialog triggers pause/resume)
      if (_lastSuccessfulUnlock != null &&
          DateTime.now().difference(_lastSuccessfulUnlock!).inSeconds < 5) {
        return;
      }
      
      // Proactive Locking: If timeout is 0, lock immediately when leaving the app.
      // This prevents the "app visible for 1 frame" flicker on resume.
      if (timeout == 0) {
        ref.read(sessionUnlockedProvider.notifier).state = false;
      }
      
      // Only update timestamp when fully paused
      if (state == AppLifecycleState.paused) {
        ref.read(appPausedTimestampProvider.notifier).state = DateTime.now();
      }
      return;
    }

    if (state == AppLifecycleState.resumed) {
      // GRACE PERIOD: Don't auto-lock if user just successfully unlocked
      if (_lastSuccessfulUnlock != null &&
          DateTime.now().difference(_lastSuccessfulUnlock!).inSeconds < 5) {
        return;
      }

      final pausedAt = ref.read(appPausedTimestampProvider);
      final isUnlocked = ref.read(sessionUnlockedProvider);

      if (timeout == -1) return; // never auto-lock

      final shouldLock = !isUnlocked && (pausedAt == null ||
          timeout == 0 ||
          DateTime.now().difference(pausedAt).inSeconds >= timeout);

      if (shouldLock) {
        debugPrint('[LockScreen] Locking app on resume (timeout reached)');
        // Ensure state is false before we show the UI
        if (isUnlocked) {
          ref.read(sessionUnlockedProvider.notifier).state = false;
        }
        _errorMessage = null;
        _failedAttempts = 0;
        _attemptUnlock();
      }
    }
  }

  // ---------------------------------------------------------------------------
  // LOCK LOGIC
  // ---------------------------------------------------------------------------

  void _checkInitialLockState() {
    final appLockEnabled = ref.read(appLockEnabledProvider);
    final biometricEnabled = ref.read(biometricEnabledProvider);
    final isUnlocked = ref.read(sessionUnlockedProvider);

    // If already unlocked, don't change state
    if (isUnlocked) return;

    // Only show lock screen if BOTH app lock AND biometric are enabled
    if (appLockEnabled && biometricEnabled) {
      // App is locked, attempt to unlock with biometrics
      _attemptUnlock();
    } else {
      // Either app lock or biometric is disabled, keep session unlocked
      ref.read(sessionUnlockedProvider.notifier).state = true;
    }
  }

  Future<void> _attemptUnlock() async {
    if (_isAuthenticating) return;

    // Throttle repeated failures (banking-grade UX)
    if (_lastAuthAttempt != null &&
        DateTime.now().difference(_lastAuthAttempt!).inSeconds < 2) {
      return;
    }

    _lastAuthAttempt = DateTime.now();

    setState(() {
      _isAuthenticating = true;
      _errorMessage = null;
    });

    debugPrint('[LockScreen] Attempting biometric auth...');

    final result = await biometricService.authenticate(
      reason: 'Unlock CashPilot to access your financial data',
      biometricOnly: false,
    );

    debugPrint('[LockScreen] Biometric result: $result');

    if (!mounted) {
      debugPrint('[LockScreen] Widget not mounted after auth');
      return;
    }

    setState(() => _isAuthenticating = false);

    if (result == BiometricResult.success) {
      debugPrint('[LockScreen] SUCCESS - Setting sessionUnlockedProvider to TRUE');
      _lastSuccessfulUnlock = DateTime.now(); // Start grace period
      _failedAttempts = 0;
      ref.read(sessionUnlockedProvider.notifier).state = true;
      debugPrint('[LockScreen] sessionUnlockedProvider is now: ${ref.read(sessionUnlockedProvider)}');
    } else if (result != BiometricResult.cancelled) {
      debugPrint('[LockScreen] FAILED - result: $result');
      _failedAttempts++;
      setState(() {
        _errorMessage = biometricService.getErrorMessage(result);
      });
    } else {
      debugPrint('[LockScreen] CANCELLED by user');
    }
  }

  /// Navigate to authentication page as fallback when biometric isn't working
  Future<void> _usePasswordFallback() async {
    debugPrint('[LockScreen] User chose password fallback - logging out');
    
    try {
      // Sign out using authService directly
      await authService.signOut();
    } catch (e) {
      debugPrint('[LockScreen] Sign out warning: $e');
    }
    
    // Clear current user
    await ref.read(currentUserIdProvider.notifier).clearUserId();
    
    // Unlock session temporarily to allow navigation
    ref.read(sessionUnlockedProvider.notifier).state = true;
    
    // Auth state change listener will automatically redirect to login
    // No need to manually navigate - this avoids GoRouter context errors
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final appLockEnabled = ref.watch(appLockEnabledProvider);
    final biometricEnabled = ref.watch(biometricEnabledProvider);
    final isUnlocked = ref.watch(sessionUnlockedProvider);

    debugPrint('[LockScreen] BUILD: appLock=$appLockEnabled, biometric=$biometricEnabled, unlocked=$isUnlocked');

    if (!appLockEnabled || !biometricEnabled || isUnlocked) {
      debugPrint('[LockScreen] BUILD: Showing CHILD (unlocked or lock disabled)');
      return widget.child;
    }

    debugPrint('[LockScreen] BUILD: Showing LOCK SCREEN');
    return _buildLockScreen(context);
  }

  Widget _buildLockScreen(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Semantics(
          label: 'App locked. Authentication required.',
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLockIcon(theme),
                    const SizedBox(height: 40),
                    _buildTitle(theme),
                    const SizedBox(height: 12),
                    _buildSubtitle(theme),
                    const SizedBox(height: 48),
                    if (_errorMessage != null) ...[
                      _buildError(theme),
                      const SizedBox(height: 24),
                    ],
                    _buildUnlockButton(theme),
                    const SizedBox(height: 16),
                    _buildFallbackButton(theme),
                    const SizedBox(height: 24),
                    _buildHint(theme),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLockIcon(ThemeData theme) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: theme.primaryColor,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.lock_outline_rounded,
        size: 56,
        color: Colors.white,
      ),
    );
  }

  Widget _buildTitle(ThemeData theme) {
    return Text(
      'CashPilot Locked',
      style: AppTypography.headlineMedium.copyWith(
        color: theme.colorScheme.onSurface,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildSubtitle(ThemeData theme) {
    return Text(
      'Authenticate to access your financial data',
      textAlign: TextAlign.center,
      style: AppTypography.bodyMedium.copyWith(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
      ),
    );
  }

  Widget _buildError(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTokens.semanticDanger.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTokens.semanticDanger.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: AppTokens.semanticDanger, size: 20),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              _errorMessage!,
              style: AppTypography.bodySmall.copyWith(
                color: AppTokens.semanticDanger,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnlockButton(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isAuthenticating ? null : _attemptUnlock,
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        icon: _isAuthenticating
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.fingerprint),
        label: Text(
          _isAuthenticating ? 'Authenticating…' : 'Unlock with Biometrics',
          style: AppTypography.labelLarge.copyWith(color: Colors.white),
        ),
      ),
    );
  }

  /// Fallback button to use email/password when biometric isn't working
  Widget _buildFallbackButton(ThemeData theme) {
    // Only show after failed attempts or if there's an error
    final showFallback = _failedAttempts >= 1 || _errorMessage != null;
    
    return AnimatedOpacity(
      opacity: showFallback ? 1.0 : 0.5,
      duration: const Duration(milliseconds: 300),
      child: TextButton.icon(
        onPressed: _usePasswordFallback,
        icon: Icon(
          Icons.email_outlined,
          size: 18,
          color: theme.colorScheme.primary,
        ),
        label: Text(
          'Use Email/Password Instead',
          style: AppTypography.labelMedium.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildHint(ThemeData theme) {
    final hintText = _failedAttempts >= 2
        ? 'Having trouble? Try using your email and password'
        : 'Your data is protected with biometric security';
    
    return Text(
      hintText,
      textAlign: TextAlign.center,
      style: AppTypography.bodySmall.copyWith(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
      ),
    );
  }
}

