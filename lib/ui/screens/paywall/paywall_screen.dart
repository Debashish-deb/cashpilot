/// Paywall Screen
/// Premium subscription screen with Super Amoled Glassmorphism
/// 
/// Based on: docs/payment plan.md
/// Tiers: Free (current) → Pro or Pro Plus
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cashpilot/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../core/theme/tokens.g.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/subscription.dart';
import '../../../services/subscription_service.dart';

import '../../widgets/subscription/payment_method_selector.dart';
import '../../../features/subscription/providers/subscription_providers.dart';

class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  bool _isAnnual = true;
  SubscriptionTier _selectedTier = SubscriptionTier.pro;
  bool _isProcessing = false;
  bool _hasInitializedSelection = false;

  // Tier-specific tokens (migrated to AppTokens)
  static final List<Color> _proGradient = [AppTokens.brandSecondary, AppTokens.brandSecondary.withValues(alpha: 0.8)];
  static final List<Color> _proPlusGradient = [AppTokens.brandGold, AppTokens.brandGold.withValues(alpha: 0.8)];
  
  PaymentMethod _selectedPaymentMethod = PaymentMethod.stripe; // Default payment method

  @override
  Widget build(BuildContext context) {
    final currentTierAsync = ref.watch(currentTierProvider);
    final currentTier = currentTierAsync.value ?? SubscriptionTier.free;
    final l10n = AppLocalizations.of(context)!;

    // Smart default selection: If Free/Pro, select the next tier up by default
    if (!_hasInitializedSelection && currentTier != SubscriptionTier.free) {
      if (currentTier == SubscriptionTier.pro) {
        _selectedTier = SubscriptionTier.proPlus;
      }
      // If Pro+, keep whatever (maybe ProPlus)
      _hasInitializedSelection = true;
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Close button
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: Icon(Icons.close, size: 26, color: Theme.of(context).iconTheme.color),
                onPressed: () => context.pop(),
              ),
            ),
            
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final horizontalPadding = constraints.maxWidth < 360 ? 16.0 : 20.0;
                  return SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                    child: Column(
                      children: [
                        _buildHeader(currentTier, l10n),
                        const SizedBox(height: 28),
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: _buildBillingToggle(l10n),
                        ),
                        const SizedBox(height: 24),
                        _buildPlanCards(currentTier, l10n),
                        const SizedBox(height: 24),
                        // Payment Method Selector
                        PaymentMethodSelector(
                          selectedMethod: _selectedPaymentMethod,
                          onMethodSelected: (method) => setState(() => _selectedPaymentMethod = method),
                          showApplePay: Theme.of(context).platform == TargetPlatform.iOS,
                        ),
                        const SizedBox(height: 24),
                        _buildFeatureComparison(l10n),
                        const SizedBox(height: 28),
                        if (currentTier != SubscriptionTier.proPlus)
                          _buildCTAButton(currentTier, l10n),
                        const SizedBox(height: 16),
                        _buildSecondaryActions(l10n),
                        const SizedBox(height: 16),
                        _buildTerms(l10n),
                        const SizedBox(height: 32),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // HEADER
  // ================================================================
  Widget _buildHeader(SubscriptionTier currentTier, AppLocalizations l10n) {
    String title;
    String subtitle;
    IconData icon;
    List<Color> gradientColors;

    switch (currentTier) {
      case SubscriptionTier.proPlus:
        title = 'Pro Plus';
        subtitle = 'Everything Pro, plus more';
        icon = Icons.verified_rounded;
        gradientColors = _proPlusGradient;
        break;
      case SubscriptionTier.pro:
        title = 'Pro';
        subtitle = 'Unlock core power';
        icon = Icons.bolt_rounded;
        gradientColors = _proGradient;
        break;
      case SubscriptionTier.free:
      default:
        title = 'Upgrade';
        subtitle = 'Enhance your experience';
        icon = Icons.workspace_premium;
        gradientColors = [
           _proPlusGradient[0].withValues(alpha: 0.3),
           _proGradient[0].withValues(alpha: 0.3),
        ];
        break;
    }

    return Column(
      children: [
        // Glowing badge icon
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: gradientColors[0].withValues(alpha: 0.1),
            border: Border.all(color: gradientColors[0].withValues(alpha: 0.3)),
          ),
          child: Icon(
            icon,
            size: 48,
            color: gradientColors[0],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          title,
          style: AppTypography.displaySmall.copyWith(
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          subtitle,
          style: AppTypography.bodyLarge.copyWith(
            color: Colors.white60,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // ================================================================
  // BILLING TOGGLE - Glassmorphism
  // ================================================================
  Widget _buildBillingToggle(AppLocalizations l10n) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Plain container
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).dividerColor,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildToggleButton('Monthly', !_isAnnual, () => setState(() => _isAnnual = false)),
              ),
              Expanded(
                child: _buildToggleButton('Yearly', _isAnnual, () => setState(() => _isAnnual = true)),
              ),
            ],
          ),
        ),
        
        // Badge - Floating on top right
        Positioned(
          top: -8,
          right: 20,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 90),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppTokens.semanticSuccess,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '2 months free!',
              style: AppTypography.bodySmall.copyWith(
                color: Colors.white,
                fontSize: 7.5,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.2,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.visible,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildToggleButton(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(colors: _proGradient)
              : null,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: _proGradient[0].withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: AppTypography.labelLarge.copyWith(
            color: Colors.white,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  // ================================================================
  // PLAN CARDS - Super Amoled Glassmorphism, Identical Size
  // ================================================================
  Widget _buildPlanCards(SubscriptionTier currentTier, AppLocalizations l10n) {
    return IntrinsicHeight( // Makes both cards same height
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Pro Plan
          Expanded(
            child: _buildPlanCard(
              tier: SubscriptionTier.pro,
              currentTier: currentTier,
              gradient: LinearGradient(colors: _proGradient),
              icon: Icons.bolt_rounded, // Lightning for Pro
               features: [
                'Cloud Sync & Backup',
                'Multi-device Support',
                'Advanced Analytics',
                'Real-time Currency',
                '20 OCR Scans / Month',
                'Custom Colors & Icons',
              ],
              l10n: l10n,
            ),
          ),
          const SizedBox(width: 12),
          // Pro Plus Plan
          Expanded(
            child: _buildPlanCard(
              tier: SubscriptionTier.proPlus,
              currentTier: currentTier,
              gradient: LinearGradient(colors: _proPlusGradient),
              icon: Icons.rocket_launch_rounded, // Rocket for Pro Plus
               features: [
                'Everything in Pro, plus:',
                'Family Budgets',
                'Bank Account Connect',
                'Unlimited OCR Scans',
                'Invite Family Members',
                'Priority Support',
              ],
              l10n: l10n,
              recommended: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard({
    required SubscriptionTier tier,
    required SubscriptionTier currentTier,
    required LinearGradient gradient,
    required IconData icon,
    required List<String> features,
    required AppLocalizations l10n,
    bool recommended = false,
  }) {
    final isSelected = _selectedTier == tier;
    final isActivePlan = tier == currentTier;
    
    final price = tier == SubscriptionTier.pro
        ? (_isAnnual ? PlanPricing.proYearly : PlanPricing.proMonthly)
        : (_isAnnual ? PlanPricing.proPlusYearly : PlanPricing.proPlusMonthly);
    final period = _isAnnual ? '/year' : '/mo';

    return GestureDetector(
      onTap: () {
        // Allow selection even if active
        setState(() => _selectedTier = tier);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActivePlan 
                ? AppTokens.semanticSuccess // Green for active
                : (isSelected
                    ? gradient.colors[0]
                    : Theme.of(context).dividerColor),
            width: isActivePlan || isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Recommended or Active Badge
            if (isActivePlan)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: AppTokens.semanticSuccess,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle, size: 10, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      'Current Plan',
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              )
            else if (recommended)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: gradient.colors[0],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Best Value',
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            
            // Tier icon + name
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: gradient.colors[0].withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    tier.displayName,
                    style: AppTypography.titleMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                // Checkmark if active
                if (isActivePlan)
                  Icon(Icons.check_circle_rounded, color: const Color(0xFF10B981), size: 20),
              ],
            ),
            const SizedBox(height: 12),

            // Price
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  PlanPricing.formatPrice(price),
                  style: AppTypography.headlineSmall.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  period,
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white60,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            
            // Features
            ...features.map((feature) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    size: 14,
                    color: gradient.colors[0],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      feature,
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // FEATURE COMPARISON - Glassmorphism
  // ================================================================
  Widget _buildFeatureComparison(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.compare_arrows_rounded, color: Theme.of(context).iconTheme.color, size: 20),
              const SizedBox(width: 8),
              Text(
                'Compare Plans',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Header row
          _buildComparisonHeader(l10n),
          const SizedBox(height: 12),
          _buildComparisonRow('Cloud Sync', false, true, true),
          _buildComparisonRow('Multi-device', false, true, true),
          _buildComparisonRow('OCR Scanning', false, true, true),
          _buildComparisonRow('Family Budgets', false, false, true),
          _buildComparisonRow('Bank Connect', false, false, true),
          _buildComparisonRow('Unlimited OCR', false, false, true),
        ],
      ),
    );
  }

  Widget _buildComparisonHeader(AppLocalizations l10n) {
    return Row(
      children: [
        const Expanded(flex: 3, child: SizedBox()),
        Expanded(
          child: Text(
            'Free',
            style: AppTypography.labelSmall.copyWith(color: Colors.white54),
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          child: Text(
            'Pro',
            style: AppTypography.labelSmall.copyWith(color: _proGradient[0], fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          child: Text(
            'Pro+',
            style: AppTypography.labelSmall.copyWith(color: _proPlusGradient[0], fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildComparisonRow(String feature, dynamic free, dynamic pro, dynamic proPlus) {
    Widget buildCell(dynamic value, Color activeColor) {
      if (value is bool) {
        return Icon(
          value ? Icons.check_circle : Icons.remove_circle_outline,
          size: 16,
          color: value ? activeColor : Colors.white24,
        );
      } else {
        return Text(
          value.toString(),
          style: AppTypography.labelSmall.copyWith(color: Colors.white70),
          textAlign: TextAlign.center,
        );
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              feature,
              style: AppTypography.bodySmall.copyWith(color: Colors.white70),
            ),
          ),
          Expanded(child: Center(child: buildCell(free, Colors.white54))),
          Expanded(child: Center(child: buildCell(pro, _proGradient[0]))),
          Expanded(child: Center(child: buildCell(proPlus, _proPlusGradient[0]))),
        ],
      ),
    );
  }

  // ================================================================
  // CTA BUTTON - Vibrant Gradient
  // ================================================================
  Widget _buildCTAButton(SubscriptionTier currentTier, AppLocalizations l10n) {
    final isProPlus = _selectedTier == SubscriptionTier.proPlus;
    final gradient = isProPlus ? _proPlusGradient : _proGradient;
    
    // If selected == current, text should maybe say "Current Plan" or "Manage"
    // But user might want to switch billing cycle (Monthly <-> Annual)
    final isActive = _selectedTier == currentTier;

    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        color: gradient[0],
        borderRadius: BorderRadius.circular(16),
      ),
      child: ElevatedButton(
        onPressed: isActive ? null : (_isProcessing ? null : _handleSubscribe),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          disabledBackgroundColor: Colors.white12,
        ),
        child: _isProcessing
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isActive ? Icons.check_circle : (isProPlus ? Icons.rocket_launch_rounded : Icons.bolt_rounded),
                    color: Colors.white.withValues(alpha: isActive ? 0.5 : 1),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                   Text(
                    isActive 
                      ? 'Current Plan' 
                      : 'Get ${_selectedTier.displayName} ${_isAnnual ? "Yearly" : "Monthly"}',
                    style: AppTypography.labelLarge.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withValues(alpha: isActive ? 0.5 : 1),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ================================================================
  // SECONDARY ACTIONS
  // ================================================================
  Widget _buildSecondaryActions(AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextButton(
          onPressed: _handleRestorePurchases,
          child: Text(
            'Restore Purchases',
            style: AppTypography.labelMedium.copyWith(color: Colors.white54),
          ),
        ),
        Container(width: 1, height: 16, color: Colors.white24),
        TextButton(
          onPressed: _handleStartTrial,
          child: Text(
            'Start 7-Day Free Trial',
            style: AppTypography.labelMedium.copyWith(color: _proGradient[0]),
          ),
        ),
      ],
    );
  }

  // ================================================================
  // TERMS
  // ================================================================
  Widget _buildTerms(AppLocalizations l10n) {
    return Column(
      children: [
        Text(
          'Subscription auto-renews. Cancel anytime.',
          style: AppTypography.bodySmall.copyWith(color: Colors.white38),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.verified_user, size: 14, color: const Color(0xFF10B981)),
            const SizedBox(width: 4),
            Text(
              'Transparent pricing • No hidden fees',
              style: AppTypography.bodySmall.copyWith(color: Colors.white38),
            ),
          ],
        ),
      ],
    );
  }

  // ================================================================
  // HANDLERS
  // ================================================================
  void _handleSubscribe() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      bool success;
      if (_selectedTier == SubscriptionTier.pro) {
        success = await subscriptionService.upgradeToPro(yearly: _isAnnual);
      } else {
        success = await subscriptionService.upgradeToProPlus(yearly: _isAnnual);
      }


      if (success && mounted) {
        AppSnackBar.showSuccess(context, 'Subscription activated! Enjoy Pro features.');
        context.pop();
      } else if (mounted) {
        AppSnackBar.showError(context, 'Subscription failed. Please try again.');
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'Payment failed: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _handleRestorePurchases() async {
    try {
      AppSnackBar.showInfo(context, 'Restoring purchases...');
      await subscriptionService.restorePurchases();
      if (mounted) {
        AppSnackBar.showSuccess(context, 'Purchases restored!');
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'Error restoring purchases: $e');
      }
    }
  }

  void _handleStartTrial() async {
    final success = await subscriptionService.startTrial();
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.paywallTrialStarted),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.paywallTrialUnavailable),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    }
  }
}
