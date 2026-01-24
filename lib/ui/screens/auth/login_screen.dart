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

  late final AnimationController _buttonController;
  late final Animation<double> _buttonScale;

  @override
  void initState() {
    super.initState();

    _buttonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.96,
      upperBound: 1.0,
      value: 1.0,
    );

    _buttonScale = CurvedAnimation(
      parent: _buttonController,
      curve: Curves.easeOut,
    );

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
    _buttonController.dispose();
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
          _buildBackground(context),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Determine screen size category
                final height = constraints.maxHeight;
                final isSmallScreen = height < 700;
                final isShortScreen = height < 600;

                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: height - 60, // Account for vertical padding
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Dynamic top spacing
                          SizedBox(height: isShortScreen ? 24 : 48),

                          _buildHeader(isSmallScreen),

                          // Flexible spacer instead of fixed height
                          if (isShortScreen) 
                            const SizedBox(height: 24)
                          else 
                            const Spacer(flex: 2),

                          // 🧊 GLASS CARD CONTAINER
                          _buildGlassCard(
                            child: _buildForm(authState, l10n, isSmallScreen),
                          ),

                          // Flexible spacer
                          if (isShortScreen)
                            const SizedBox(height: 20)
                          else
                            const Spacer(flex: 1),

                          _buildDivider(),

                          SizedBox(height: isSmallScreen ? 20 : 28),

                          _buildSocialButtons(),

                          if (_biometricAvailable) ...[
                            SizedBox(height: isSmallScreen ? 16 : 20),
                            _buildBiometricButton(),
                          ],

                          // Flexible spacer
                          if (isShortScreen)
                            const SizedBox(height: 24)
                          else
                            const Spacer(flex: 2),

                          _buildToggle(),
                          
                          const SizedBox(height: 16),

                          _buildSkipButton(),

                          const SizedBox(height: 24),

                          _buildLegalFooter(context),
                          
                          const SizedBox(height: 32),
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

  Widget _buildHeader([bool isSmallScreen = false]) {
    final double iconSize = isSmallScreen ? 32 : 44;
    final double containerSize = isSmallScreen ? 64 : 88;
    final double spacing = isSmallScreen ? 16 : 28;
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
            borderRadius: BorderRadius.circular(isSmallScreen ? 18 : 24),
            boxShadow: [
              BoxShadow(
                blurRadius: isSmallScreen ? 16 : 22,
                offset: Offset(0, isSmallScreen ? 6 : 10),
                color: Colors.black.withValues(alpha: 0.12),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(isSmallScreen ? 18 : 24),
            child: Image.asset(
              'assets/images/logo_CP.png',
              width: iconSize,
              height: iconSize,
              fit: BoxFit.contain,
            ),
          ),
        ),
        SizedBox(height: spacing),
        Text(
          _isLogin ? l10n.authWelcome : l10n.authCreateAccount,
          style: (isSmallScreen 
              ? AppTypography.headlineMedium 
              : AppTypography.displaySmall).copyWith(
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  // ─────────────────────────────────────────
  // Form
  // ─────────────────────────────────────────

  Widget _buildForm(AuthState authState, AppLocalizations l10n, [bool isSmallScreen = false]) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          _buildEmailField(),
          SizedBox(height: isSmallScreen ? 12 : 18),
          _buildPasswordField(),
          SizedBox(height: isSmallScreen ? 18 : 26),

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
    return ScaleTransition(
      scale: _buttonScale,
      child: GestureDetector(
        onTapDown: (_) => _buttonController.reverse(),
        onTapUp: (_) => _buttonController.forward(),
        onTapCancel: () => _buttonController.forward(),
        child: CPButton(
          label: _isLogin ? l10n.authSignIn : l10n.authCreateAccount,
          loading: loading,
          expanded: true,
          onTap: _handleSubmit,
        ),
      ),
    );
  }

  // ─────────────────────────────────────────
  // 🔐 Biometric Button
  // ─────────────────────────────────────────

  Widget _buildBiometricButton() {
    final l10n = AppLocalizations.of(context)!;
    return CPOutlinedButton(
      label: l10n.authSignInBiometrics,
      icon: Icons.fingerprint,
      onTap: _handleBiometricAuth,
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

  Widget _buildSocialButtons() {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: CPOutlinedButton(
            label: l10n.authGoogle,
            icon: Icons.g_mobiledata,
            onTap: _handleGoogleSignIn,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: CPOutlinedButton(
            label: l10n.authApple,
            icon: Icons.apple,
            onTap: _handleAppleSignIn,
          ),
        ),
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
        // Store session as JSON
        await _secureStorage.write(
          key: 'biometric_session',
          value: jsonEncode(session.toJson()),
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
            // Restore session
            final sessionData = jsonDecode(sessionJson) as Map<String, dynamic>;
            await Supabase.instance.client.auth.recoverSession(jsonEncode(sessionData));
            
            if (mounted) context.go(AppRoutes.home);
          } catch (e) {
            // Session expired or invalid
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
