// Login Screen
// Store-ready authentication screen with:
// - Glass card container
// - Biometric login polish
// - Button micro-animations
// - App Store screenshot safe layout
//
// Structure, providers, and routes preserved.

import 'dart:ui';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cashpilot/l10n/app_localizations.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/utils/validators.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../widgets/common/cp_buttons.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final _localAuth = LocalAuthentication();
  final _secureStorage = const FlutterSecureStorage();

  bool _obscurePassword = true;
  bool _isLogin = true;
  bool _biometricAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
  }

  Future<void> _checkBiometricAvailability() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final supported = await _localAuth.isDeviceSupported();
      if (mounted) {
        setState(() => _biometricAvailable = canCheck && supported);
      }
    } catch (_) {
      _biometricAvailable = false;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Stack(
        children: [
          // _buildBackground(context), // Removed per user request
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Dynamic scaling
                final height = constraints.maxHeight;
                // Proportions (Compact)
                final double topSpacer = height * 0.03; // Reduced
                final double logoSize = (height * 0.08).clamp(40.0, 60.0); // Much smaller (~20% of previous max)
                final double gapAfterLogo = height * 0.02;
                final double gapBeforeForm = height * 0.02;
                final double gapAfterForm = height * 0.02;
                
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: 400, // Safe max width for tablets
                        minHeight: height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom, 
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(height: topSpacer + 20),

                          _buildHeader(logoSize),

                          SizedBox(height: gapBeforeForm + 10),

                          // 🧊 GLASS CARD CONTAINER
                          _buildGlassCard(
                            child: _buildForm(authState, l10n),
                          ),

                          SizedBox(height: gapAfterForm + 10),

                          _buildDivider(),

                          const SizedBox(height: 16),
                          
                          // Compact Social Row
                          _buildCompactSocialRow(),

                          const SizedBox(height: 32),

                          _buildToggle(),
                          
                          const SizedBox(height: 16),

                          _buildSkipButton(),

                          const SizedBox(height: 32),

                          _buildLegalFooter(context),
                          
                          SizedBox(height: height * 0.05 + 20),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────
  // Background (Store-ready gradient)
  // ─────────────────────────────────────────

  Widget _buildBackground(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.16),
            theme.colorScheme.surface,
            theme.colorScheme.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(color: Colors.white.withValues(alpha: 0.02)),
      ),
    );
  }

  // ─────────────────────────────────────────
  // Header (Screenshot-friendly)
  // ─────────────────────────────────────────

  Widget _buildHeader(double logoSize) {
    final double containerSize = logoSize * 2.0; 
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        Container(
          width: containerSize,
          height: containerSize,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).primaryColor.withValues(alpha: 0.85),
              ],
            ),
            borderRadius: BorderRadius.circular(containerSize * 0.27),
            boxShadow: [
              BoxShadow(
                blurRadius: containerSize * 0.25,
                offset: Offset(0, containerSize * 0.1),
                color: Colors.black.withValues(alpha: 0.12),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(containerSize * 0.27),
            child: Image.asset(
              'assets/images/logo_CP.png',
              width: logoSize,
              height: logoSize,
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          _isLogin ? l10n.authWelcome : l10n.authCreateAccount,
          style: AppTypography.headlineMedium.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          _isLogin
              ? l10n.authTaglineLogin
              : l10n.authTaglineSignup,
          style: AppTypography.bodyLarge.copyWith(
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          l10n.authFeatures,
          style: AppTypography.labelSmall.copyWith(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.7),
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // ─────────────────────────────────────────
  // Glass Card
  // ─────────────────────────────────────────

  Widget _buildGlassCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
        ),
      ),
      child: child,
    );
  }

  // ─────────────────────────────────────────
  // Form
  // ─────────────────────────────────────────

  Widget _buildForm(AuthState authState, AppLocalizations l10n) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          _buildEmailField(),
          const SizedBox(height: 16),
          _buildPasswordField(),
          const SizedBox(height: 24),

          if (authState.errorMessage != null)
            _buildErrorMessage(authState.errorMessage!),

          _buildAnimatedSubmitButton(authState.isLoading),
          
          const SizedBox(height: 12),
          Text(
            l10n.authDataEncrypted,
            textAlign: TextAlign.center,
            style: AppTypography.labelSmall.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailField() {
    final l10n = AppLocalizations.of(context)!;
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      decoration: _inputDecoration(
        label: l10n.authEmailLabel,
        icon: Icons.email_outlined,
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return l10n.authEmailRequired;
        return Validators.isValidEmail(v) ? null : l10n.authEmailInvalid;
      },
    );
  }

  Widget _buildPasswordField() {
    final l10n = AppLocalizations.of(context)!;
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      decoration: _inputDecoration(
        label: l10n.authPasswordLabel,
        icon: Icons.lock_outline,
        suffix: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
          ),
          onPressed: () =>
              setState(() => _obscurePassword = !_obscurePassword),
        ),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return l10n.authPasswordRequired;
        if (_isLogin) {
          // Login: just check minimum length
          return v.length < 6 ? l10n.authPasswordLength : null;
        } else {
          // Signup: check strength
          return Validators.getPasswordStrengthMessage(v).isEmpty 
              ? null 
              : Validators.getPasswordStrengthMessage(v);
        }
      },
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      suffixIcon: suffix,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }

  Widget _buildErrorMessage(String message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        message,
        style: AppTypography.bodySmall.copyWith(color: AppColors.danger),
      ),
    );
  }

  // ─────────────────────────────────────────
  // 🎬 Animated Submit Button
  // ─────────────────────────────────────────

  Widget _buildAnimatedSubmitButton(bool loading) {
    final l10n = AppLocalizations.of(context)!;
    return CPButton(
      label: _isLogin ? l10n.authSignIn : l10n.authCreateAccount,
      loading: loading,
      expanded: true,
      onTap: _handleSubmit,
    );
  }

  // ─────────────────────────────────────────
  // 🔐 Biometric Button
  // ─────────────────────────────────────────

  // ─────────────────────────────────────────
  // 🤏 Compact Social Row
  // ─────────────────────────────────────────

  Widget _buildCompactSocialRow() {
    final l10n = AppLocalizations.of(context)!;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Google
        _buildSocialIconBtn(
          icon: Icons.g_mobiledata, 
          onTap: _handleGoogleSignIn,
        ),
        
        const SizedBox(width: 16),
        
        // Apple
        _buildSocialIconBtn(
          icon: Icons.apple, 
          onTap: _handleAppleSignIn,
        ),

        if (_biometricAvailable) ...[
           const SizedBox(width: 16),
           _buildSocialIconBtn(
             icon: Icons.fingerprint,
             onTap: _handleBiometricAuth,
             isBiometric: true,
           ),
        ],
      ],
    );
  }

  Widget _buildSocialIconBtn({
    required IconData icon, 
    required VoidCallback onTap,
    bool isBiometric = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isBiometric 
                ? Theme.of(context).primaryColor.withOpacity(0.5)
                : Theme.of(context).dividerColor,
          ),
        ),
        child: Icon(
          icon,
          size: 24,
          color: isBiometric 
              ? Theme.of(context).primaryColor 
              : Theme.of(context).iconTheme.color,
        ),
      ),
    );
  }

  // ─────────────────────────────────────────
  // Social / Footer
  // ─────────────────────────────────────────

  Widget _buildDivider() {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            l10n.authOr,
            style: AppTypography.bodySmall,
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }



  Widget _buildToggle() {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _isLogin ? l10n.authNoAccount : l10n.authHaveAccount,
        ),
        CPTextButton(
          label: _isLogin ? l10n.authSignUp : l10n.authSignIn,
          onTap: () => setState(() => _isLogin = !_isLogin),
        ),
      ],
    );
  }

  Widget _buildSkipButton() {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: CPTextButton(
        label: l10n.authGuest,
        onTap: _handleSkip,
      ),
    );
  }

  Widget _buildLegalFooter(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        Text(
          l10n.authAgree,
          style: AppTypography.bodySmall,
        ),
        GestureDetector(
          onTap: () => context.push(AppRoutes.userAgreement),
          child: Text(
            l10n.authPolicy,
            style: AppTypography.bodySmall.copyWith(
              decoration: TextDecoration.underline,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────
  // Session Storage Helper
  // ─────────────────────────────────────────

  /// Store Supabase session for biometric authentication
  /// Works for all auth methods: email/password, Google, Apple
  Future<void> _storeAuthSession() async {
    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        // Store session with metadata for expiry validation
        final sessionMap = session.toJson();
        final storedAt = DateTime.now();
        
        await _secureStorage.write(
          key: 'biometric_session',
          value: jsonEncode({
            ...sessionMap,
            'stored_at': storedAt.toIso8601String(),
            // Ensure we have a clear expiry, default to 7 days if not provided by Supabase
            'expires_at_validated': ((session.expiresAt as DateTime?) ?? storedAt.add(const Duration(days: 7))).toIso8601String(),
          }),
        );
        
        // Store user email for display (if available)
        final email = session.user.email;
        if (email != null) {
          await _secureStorage.write(
            key: 'biometric_email',
            value: email,
          );
        }
      }
    } catch (e) {
      // Silent fail - biometric will just not work until next login
    }
  }

  // ─────────────────────────────────────────
  // Actions
  // ─────────────────────────────────────────

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    final success = _isLogin
        ? await ref.read(authProvider.notifier).signInWithEmail(
              email: email,
              password: password,
            )
        : await ref.read(authProvider.notifier).signUpWithEmail(
              email: email,
              password: password,
            );

    if (success) {
      // Store session for biometric login (works for all auth methods)
      await _storeAuthSession();
      if (mounted) context.go(AppRoutes.home);
    }
  }

  Future<void> _handleBiometricAuth() async {
    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: AppLocalizations.of(context)!.authBiometricReason,
        options: const AuthenticationOptions(biometricOnly: true),
      );

      if (authenticated && mounted) {
        // Retrieve stored session
        final sessionJson = await _secureStorage.read(key: 'biometric_session');
        
        if (sessionJson != null) {
          try {
            final sessionData = jsonDecode(sessionJson) as Map<String, dynamic>;
            
            // SECURITY: Validate session age and expiry
            final expiresAtStr = sessionData['expires_at_validated'] as String?;
            final storedAtStr = sessionData['stored_at'] as String?;
            
            bool isExpired = true;
            if (expiresAtStr != null && storedAtStr != null) {
              final expiresAt = DateTime.parse(expiresAtStr);
              final storedAt = DateTime.parse(storedAtStr);
              final now = DateTime.now();
              
              // Only allow biometric recovery if:
              // 1. Current time is before the validated expiry
              // 2. The session was stored less than 30 days ago (sanity fallback)
              isExpired = now.isAfter(expiresAt) || now.difference(storedAt).inDays > 30;
            }

            if (isExpired) {
              throw Exception('Session expired');
            }

            // Restore session
            await Supabase.instance.client.auth.recoverSession(jsonEncode(sessionData));
            
            if (mounted) context.go(AppRoutes.home);
          } catch (e) {
            // Session expired or invalid - clear it to force fresh login
            await _secureStorage.delete(key: 'biometric_session');
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppLocalizations.of(context)!.authSessionExpired),
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          }
        } else {
          // No stored session
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context)!.authBiometricLogin),
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      }
    } on PlatformException {
      // silently fail
    }
  }

  Future<void> _handleGoogleSignIn() async {
    final success = await ref.read(authProvider.notifier).signInWithGoogle();
    if (success) {
      await _storeAuthSession();
    }
  }

  Future<void> _handleAppleSignIn() async {
    final success = await ref.read(authProvider.notifier).signInWithApple();
    if (success) {
      await _storeAuthSession();
    }
  }

  Future<void> _handleSkip() async {
    final success =
        await ref.read(authProvider.notifier).continueAsGuest();
    if (mounted && success) context.go(AppRoutes.home);
  }
}
