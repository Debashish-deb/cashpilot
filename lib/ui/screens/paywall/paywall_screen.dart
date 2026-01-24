/// Paywall Screen
/// Premium subscription screen with Super Amoled Glassmorphism
/// 
/// Based on: docs/payment plan.md
/// Tiers: Free (current) → Pro or Pro Plus
library;

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/app_snackbar.dart';

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

  // Tier-specific colors
  static const _proGradient = [Color(0xFF6366F1), Color(0xFF4F46E5)]; // Indigo
  static const _proPlusGradient = [Color(0xFFF59E0B), Color(0xFFD97706)]; // Amber/Gold
  
  PaymentMethod _selectedPaymentMethod = PaymentMethod.stripe; // Default payment method

  @override
  Widget build(BuildContext context) {
    final currentTierAsync = ref.watch(currentTierProvider);
    final currentTier = currentTierAsync.value ?? SubscriptionTier.free;

    // Smart default selection: If Free/Pro, select the next tier up by default
    if (!_hasInitializedSelection && currentTier != SubscriptionTier.free) {
      if (currentTier == SubscriptionTier.pro) {
        _selectedTier = SubscriptionTier.proPlus;
      }
      // If Pro+, keep whatever (maybe ProPlus)
      _hasInitializedSelection = true;
    }

    return Scaffold(
      backgroundColor: Colors.black, // Pure Amoled black
      body: Stack(
        children: [
          // Ambient glow background
          Positioned(
            top: -100,
            left: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _proGradient[0].withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 200,
            right: -100,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _proPlusGradient[0].withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          
          // Main content
          SafeArea(
            child: Column(
              children: [
                // Close button
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: const Icon(Icons.close, size: 26, color: Colors.white70),
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
                        _buildHeader(currentTier),
                        const SizedBox(height: 28),
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: _buildBillingToggle(),
                      ),
                        const SizedBox(height: 24),
                        _buildPlanCards(currentTier),
                        const SizedBox(height: 24),
                        // Payment Method Selector
                        PaymentMethodSelector(
                          selectedMethod: _selectedPaymentMethod,
                          onMethodSelected: (method) => setState(() => _selectedPaymentMethod = method),
                          showApplePay: Theme.of(context).platform == TargetPlatform.iOS,
                        ),
                        const SizedBox(height: 24),
                        _buildFeatureComparison(),
                        const SizedBox(height: 28),
                        if (currentTier != SubscriptionTier.proPlus) // Hide CTA if maxed out? Or change text?
                          _buildCTAButton(currentTier),
                        const SizedBox(height: 16),
                        _buildSecondaryActions(),
                        const SizedBox(height: 16),
                        _buildTerms(),
                        const SizedBox(height: 32),
                      ],
                    )
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // HEADER
  // ================================================================
  Widget _buildHeader(SubscriptionTier currentTier) {
    String title;
    String subtitle;
    IconData icon;
    List<Color> gradientColors;

    switch (currentTier) {
      case SubscriptionTier.proPlus:
        title = 'You are a Pro+ User! 🚀';
        subtitle = 'You have unlocked the ultimate financial experience.\nEnjoy unlimited access to every feature.';
        icon = Icons.verified_rounded;
        gradientColors = _proPlusGradient;
        break;
      case SubscriptionTier.pro:
        title = 'You are a Pro User! ⚡';
        subtitle = 'Maximize your financial power with Pro Plus.\nUnlock family budgets, bank connect, and unlimited OCR.';
        icon = Icons.bolt_rounded;
        gradientColors = _proGradient;
        break;
      case SubscriptionTier.free:
      default:
        title = 'Upgrade Your Experience';
        subtitle = 'Smart budgeting for individuals,\nprofessionals, and families';
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
            gradient: LinearGradient(
              colors: gradientColors.length == 2 
                  ? [gradientColors[0].withValues(alpha: 0.3), gradientColors[1].withValues(alpha: 0.3)]
                  : gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: gradientColors[0].withValues(alpha: 0.4),
                blurRadius: 40,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Icon(
            icon,
            size: 48,
            color: Colors.white,
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
  Widget _buildBillingToggle() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Glass container
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildToggleButton('Monthly', !_isAnnual, () => setState(() => _isAnnual = false)),
                  ),
                  Expanded(
                    child: _buildToggleButton('Annual', _isAnnual, () => setState(() => _isAnnual = true)),
                  ),
                ],
              ),
            ),
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
              gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]),
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10B981).withValues(alpha: 0.5),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              '2 MONTHS FREE',
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
              ? const LinearGradient(colors: _proGradient)
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
  Widget _buildPlanCards(SubscriptionTier currentTier) {
    return IntrinsicHeight( // Makes both cards same height
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Pro Plan
          Expanded(
            child: _buildPlanCard(
              tier: SubscriptionTier.pro,
              currentTier: currentTier,
              gradient: _proGradient,
              icon: Icons.bolt_rounded, // Lightning for Pro
              features: const [
                'Cloud sync',
                'Multi-device',
                'Advanced analytics',
                'Real-time currency',
                '20 OCR scans/mo',
                'Color themes',
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Pro Plus Plan
          Expanded(
            child: _buildPlanCard(
              tier: SubscriptionTier.proPlus,
              currentTier: currentTier,
              gradient: _proPlusGradient,
              icon: Icons.rocket_launch_rounded, // Rocket for Pro Plus
              features: const [
                'Everything in Pro',
                'Family budgets',
                'Bank connect',
                'Unlimited OCR',
                'Invite free users',
                'Priority support',
              ],
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
    required List<Color> gradient,
    required IconData icon,
    required List<String> features,
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
        // Allow selection even if active, so they can see "Manage" or similar if we implemented it
        // Or to switch between Pro/Pro+
        setState(() => _selectedTier = tier);
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  gradient[0].withValues(alpha: isSelected ? 0.35 : 0.18),
                  gradient[1].withValues(alpha: isSelected ? 0.2 : 0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isActivePlan 
                    ? const Color(0xFF10B981) // Green for active
                    : (isSelected
                        ? gradient[0]
                        : Colors.white.withValues(alpha: 0.15)),
                width: isActivePlan || isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: gradient[0].withValues(alpha: 0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : null,
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
                      color: const Color(0xFF10B981),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withValues(alpha: 0.5),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle, size: 10, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          'CURRENT PLAN',
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
                      gradient: LinearGradient(colors: gradient),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: gradient[0].withValues(alpha: 0.5),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Text(
                      'BEST VALUE',
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
                        color: gradient[0].withValues(alpha: 0.3),
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
                        color: gradient[0],
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
        ),
      ),
    );
  }

  // ================================================================
  // FEATURE COMPARISON - Glassmorphism
  // ================================================================
  Widget _buildFeatureComparison() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.compare_arrows_rounded, color: Colors.white70, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Compare Plans',
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Header row
              _buildComparisonHeader(),
              const SizedBox(height: 12),
              _buildComparisonRow('Cloud Sync', false, true, true),
              _buildComparisonRow('Multi-Device', false, true, true),
              _buildComparisonRow('OCR Scanning', false, true, true),
              _buildComparisonRow('Family Budgets', false, false, true),
              _buildComparisonRow('Bank Connect', false, false, true),
              _buildComparisonRow('Unlimited OCR', false, false, true),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildComparisonHeader() {
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
  Widget _buildCTAButton(SubscriptionTier currentTier) {
    final isProPlus = _selectedTier == SubscriptionTier.proPlus;
    final gradient = isProPlus ? _proPlusGradient : _proGradient;
    
    // If selected == current, text should maybe say "Current Plan" or "Manage"
    // But user might want to switch billing cycle (Monthly <-> Annual)
    final isActive = _selectedTier == currentTier;

    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradient),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradient[0].withValues(alpha: 0.5),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
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
  Widget _buildSecondaryActions() {
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
            'Start Free Trial',
            style: AppTypography.labelMedium.copyWith(color: _proGradient[0]),
          ),
        ),
      ],
    );
  }

  // ================================================================
  // TERMS
  // ================================================================
  Widget _buildTerms() {
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
          const SnackBar(
            content: Text('14-day free trial started! 🎉'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Trial already used or unavailable'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    }
  }
}
