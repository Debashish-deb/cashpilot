/// Onboarding Screen
/// First-time user experience with welcome & setup entry
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/providers/app_providers.dart';
import 'package:cashpilot/l10n/app_localizations.dart';
import '../../widgets/common/cp_buttons.dart';
import '../../widgets/common/responsive_wrapper.dart';

/// Apple-style spacing system (SF Grid)
class SFSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double hero = 48;
}

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenSize = ResponsiveScreenSize(width: constraints.maxWidth, height: constraints.maxHeight);
          final iconSize = screenSize.isSmallScreen ? 120.0 : 144.0;
          final iconInnerSize = screenSize.isSmallScreen ? 60.0 : 72.0;
          
          return SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenSize.isSmallScreen ? SFSpacing.md : SFSpacing.xl,
                      vertical: SFSpacing.lg,
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: SFSpacing.xl),
                        
                        /// HERO ICON (Apple-grade depth)
                        Container(
                          width: iconSize,
                          height: iconSize,
                          decoration: BoxDecoration(
                            color: theme.primaryColor,
                            borderRadius: BorderRadius.circular(40),
                          ),
                          child: Icon(
                            Icons.account_balance_wallet_rounded,
                            size: iconInnerSize,
                            color: Colors.white,
                          ),
                        ),

                        const SizedBox(height: SFSpacing.hero),

                        /// TITLE
                        Text(
                          l10n.onboardingWelcomeTitle ?? 'Welcome to CashPilot',
                          style: AppTypography.displaySmall.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.6,
                            color: theme.colorScheme.onSurface,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: SFSpacing.md),

                        /// VALUE PROPOSITION
                        Text(
                          l10n.onboardingWelcomeSubtitle ??
                              'Take full control of your money with secure, intelligent budgeting and expense tracking—designed to be fast, private, and effortless.',
                          style: AppTypography.bodyLarge.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
                            height: 1.55,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: SFSpacing.xxl),
                        const Spacer(),

                        /// PRIMARY CTA
                        CPButton(
                          label: l10n.commonGetStarted ?? 'Get Started',
                          expanded: true,
                          onTap: () async {
                            await ref
                                .read(onboardingCompleteProvider.notifier)
                                .setComplete(true);

                            if (context.mounted) {
                              context.go(AppRoutes.login);
                            }
                          },
                        ),

                        const SizedBox(height: SFSpacing.lg),

                        /// TRUST FOOTER (Apple-style subtle copy)
                        Text(
                          l10n.onboardingPrivacyNote ??
                              'Your data stays private. No ads. No selling data.',
                          style: AppTypography.labelSmall.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                            letterSpacing: 0.2,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: SFSpacing.sm),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
