
import 'dart:ui'; // Added for BackdropFilter
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cashpilot/features/subscription/providers/subscription_providers.dart';
import 'package:cashpilot/core/constants/subscription.dart';
import 'package:cashpilot/core/constants/app_routes.dart';
import 'package:cashpilot/core/theme/app_colors.dart';
import 'package:cashpilot/core/theme/app_typography.dart';
import 'package:cashpilot/l10n/app_localizations.dart';
// Assuming this exists or generic icon

class SubscriptionManagementScreen extends ConsumerWidget {
  const SubscriptionManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tierAsync = ref.watch(currentTierProvider);
    final trialDaysRemaining = ref.watch(trialRemainingDaysProvider);
    final ocrRemaining = ref.watch(ocrScansRemainingProvider);
    final ocrLimit = ref.watch(ocrScansLimitProvider);
    final expiresAt = ref.watch(subscriptionExpiresAtProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Subscription'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: theme.colorScheme.surface.withValues(alpha: 0.5)),
          ),
        ),
      ),
      body: tierAsync.when(
        data: (tier) => Stack(
          children: [
             // Background Gradient Mesh
             Positioned(
                top: -100,
                right: -100,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        _getTierGradient(tier)[0].withValues(alpha: 0.15),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
             ),
             
             ListView(
              padding: const EdgeInsets.fromLTRB(20, 110, 20, 20),
              children: [
                // Current Plan Card (Premium Look)
                _PlanStatusCard(
                  tier: tier,
                  expiresAt: expiresAt,
                  trialDaysRemaining: trialDaysRemaining,
                ),
                
                const SizedBox(height: 24),
                
                // Usage Stats (Dashboard Style)
                if (tier != SubscriptionTier.free) ...[
                  Text(
                    'Your Usage',
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _UsageCard(
                    title: 'OCR Scans',
                    used: ocrLimit == -1 ? 0 : (ocrLimit - ocrRemaining),
                    limit: ocrLimit,
                    icon: Icons.document_scanner_rounded,
                  ),
                  const SizedBox(height: 32),
                ],
                
                // Actions Header
                Text(
                  'Manage Subscription',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Upgrades
                if (tier == SubscriptionTier.free) ...[
                  _UpgradeBanner(
                    title: 'Upgrade to Pro',
                    subtitle: 'Cloud sync, analytics & scanning',
                    gradient: const [Color(0xFF6366F1), Color(0xFF4F46E5)],
                    icon: Icons.bolt_rounded,
                    onTap: () => context.push(AppRoutes.paywall),
                  ),
                  const SizedBox(height: 12),
                  _UpgradeBanner(
                    title: 'Get Pro +',
                    subtitle: 'Family budgets & unlimited power',
                    gradient: const [Color(0xFFF59E0B), Color(0xFFD97706)],
                    icon: Icons.rocket_launch_rounded,
                    onTap: () => context.push(AppRoutes.paywall),
                  ),
                ] else if (tier == SubscriptionTier.pro) ...[
                  _UpgradeBanner(
                    title: 'Upgrade to Pro +',
                    subtitle: 'Unlock family sharing & bank connect',
                    gradient: const [Color(0xFFF59E0B), Color(0xFFD97706)],
                    icon: Icons.rocket_launch_rounded,
                    onTap: () => context.push(AppRoutes.paywall),
                  ),
                ],
                
                const SizedBox(height: 12),
                
                // Utilities
                _UtilityAction(
                  label: 'Restore Purchases',
                  icon: Icons.restore_rounded,
                  onTap: () async {
                    final service = ref.read(subscriptionServiceProvider);
                    await service.restorePurchases();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Purchase restored successfully')),
                      );
                    }
                  },
                ),
                
                if (tier != SubscriptionTier.free) ...[
                  _UtilityAction(
                    label: 'Cancel Subscription',
                    icon: Icons.cancel_outlined,
                    isDestructive: true,
                    onTap: () => _showCancelDialog(context, ref),
                  ),
                ],
                
                const SizedBox(height: 32),
                
                // Feature comparison
                _FeatureComparisonSection(currentTier: tier),
                const SizedBox(height: 40),
              ],
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }

  void _showCancelDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Subscription'),
        content: const Text(
          'You will retain access until the end of your billing period.\n\nAre you sure you want to cancel?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep Plan'),
          ),
          FilledButton(
            onPressed: () async {
              final service = ref.read(subscriptionServiceProvider);
              await service.cancelSubscription();
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Subscription cancelled')),
                );
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Cancel Subscription'),
          ),
        ],
      ),
    );
  }

  List<Color> _getTierGradient(SubscriptionTier tier) => switch (tier) {
    SubscriptionTier.free => [Colors.grey.shade400, Colors.grey.shade600],
    SubscriptionTier.pro => [const Color(0xFF6366F1), const Color(0xFF4F46E5)],
    SubscriptionTier.proPlus => [const Color(0xFFF59E0B), const Color(0xFFD97706)],
  };
}

class _PlanStatusCard extends StatelessWidget {
  final SubscriptionTier tier;
  final DateTime? expiresAt;
  final int trialDaysRemaining;

  const _PlanStatusCard({
    required this.tier,
    required this.expiresAt,
    required this.trialDaysRemaining,
  });

  @override
  Widget build(BuildContext context) {
    final gradient = _getTierGradient(tier);
    final isTrialActive = trialDaysRemaining > 0 && tier != SubscriptionTier.free;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [gradient[0].withValues(alpha: 0.1), gradient[1].withValues(alpha: 0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: gradient[0].withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: gradient[0].withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
             Row(
               children: [
                 Container(
                   padding: const EdgeInsets.all(12),
                   decoration: BoxDecoration(
                     color: gradient[0].withValues(alpha: 0.2),
                     shape: BoxShape.circle,
                   ),
                   child: Icon(
                     _getTierIcon(tier),
                     color: gradient[0],
                     size: 32,
                   ),
                 ),
                 const SizedBox(width: 16),
                 Expanded(
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Flexible(
                         child: Text(
                           tier.displayName,
                           style: AppTypography.headlineSmall.copyWith(
                             fontWeight: FontWeight.w800,
                             color: gradient[0], // Use primary gradient color for text
                           ),
                           maxLines: 1,
                           overflow: TextOverflow.ellipsis,
                         ),
                       ),
                       if (isTrialActive)
                        Text(
                          '$trialDaysRemaining days trial remaining',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.warning,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                       else if (expiresAt != null)
                        Text(
                          'Renews ${DateFormat('MMM d, y', AppLocalizations.of(context)!.localeName).format(expiresAt!)}',
                          style: AppTypography.bodySmall,
                        )
                       else 
                        Text(
                          'Basic access',
                          style: AppTypography.bodySmall,
                        ),
                     ],
                   ),
                 ),
               ],
             ),
             const SizedBox(height: 20),
             // Current Features Pills
             Wrap(
               spacing: 8,
               runSpacing: 8,
               children: _getBenefits(tier).take(3).map((b) => Container(
                 padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                 decoration: BoxDecoration(
                   color: Theme.of(context).colorScheme.surface,
                   borderRadius: BorderRadius.circular(20),
                   border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
                 ),
                 child: Row(
                   mainAxisSize: MainAxisSize.min,
                   children: [
                     Icon(Icons.check_circle_rounded, size: 14, color: AppColors.success),
                     const SizedBox(width: 4),
                     Text(b, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
                   ],
                 ),
               )).toList(),
             ),
          ],
        ),
      ),
    );
  }

  IconData _getTierIcon(SubscriptionTier tier) => switch (tier) {
    SubscriptionTier.free => Icons.person_outline_rounded,
    SubscriptionTier.pro => Icons.bolt_rounded,
    SubscriptionTier.proPlus => Icons.verified_rounded,
  };

  List<String> _getBenefits(SubscriptionTier tier) {
     // Reusing logic but cleaner
     if (tier == SubscriptionTier.free) return ['Basic Tracking', 'Manual Entry'];
     if (tier == SubscriptionTier.pro) return ['Cloud Sync', 'Analytics', '20 OCR Scans'];
     return ['Family Budgets', 'Bank Connect', 'Unlimited OCR', 'Priority Support'];
  }
  
  List<Color> _getTierGradient(SubscriptionTier tier) => switch (tier) {
    SubscriptionTier.free => [Colors.grey.shade400, Colors.grey.shade600],
    SubscriptionTier.pro => [const Color(0xFF6366F1), const Color(0xFF4F46E5)],
    SubscriptionTier.proPlus => [const Color(0xFFF59E0B), const Color(0xFFD97706)],
  };
}

class _UsageCard extends StatelessWidget {
  final String title;
  final int used;
  final int limit;
  final IconData icon;

  const _UsageCard({required this.title, required this.used, required this.limit, required this.icon});

  @override
  Widget build(BuildContext context) {
    final isUnlimited = limit == -1;
    final double progress = isUnlimited ? 0.0 : (used / limit).clamp(0.0, 1.0);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primaryGreen, size: 20),
              const SizedBox(width: 8),
              Flexible(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
              const Spacer(),
              if (isUnlimited)
                const Icon(Icons.all_inclusive_rounded, size: 20, color: AppColors.gold)
              else
                Flexible(child: Text('$used / $limit', style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis)),
            ],
          ),
          const SizedBox(height: 12),
          if (!isUnlimited)
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                color: progress > 0.9 ? AppColors.danger : AppColors.primaryGreen,
              ),
            ),
        ],
      ),
    );
  }
}

class _UpgradeBanner extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Color> gradient;
  final IconData icon;
  final VoidCallback onTap;

  const _UpgradeBanner({
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradient),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
             BoxShadow(
               color: gradient[0].withValues(alpha: 0.3),
               blurRadius: 12,
               offset: const Offset(0, 4),
             ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_rounded, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

class _UtilityAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isDestructive;

  const _UtilityAction({
    required this.label,
    required this.icon,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? AppColors.danger : Theme.of(context).colorScheme.onSurface;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                 label, 
                 style: TextStyle(
                   color: color,
                   fontWeight: FontWeight.w500,
                 ),
                 maxLines: 1,
                 overflow: TextOverflow.ellipsis,
              ),
            ),
            const Spacer(),
            Icon(Icons.chevron_right_rounded, color: color.withValues(alpha: 0.3), size: 20),
          ],
        ),
      ),
    );
  }
}

class _FeatureComparisonSection extends StatelessWidget {
  final SubscriptionTier currentTier;
  const _FeatureComparisonSection({required this.currentTier});

  @override
  Widget build(BuildContext context) {
     // Concise version for management screen
     return Container(
       padding: const EdgeInsets.all(20),
       decoration: BoxDecoration(
         color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
         borderRadius: BorderRadius.circular(24),
       ),
       child: Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
            const Text('Feature Comparison', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            // Minimal rows
            _row('Cloud Sync', false, true, true),
            _row('Analytics', 'Basic', 'Full', 'Full'),
            _row('OCR', '0', '20', '∞'),
            _row('Family', false, false, true),
            _row('Bank Connect', false, false, true),
         ],
       ),
     );
  }

  Widget _row(String label, dynamic free, dynamic pro, dynamic proPlus) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(label, style: const TextStyle(fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis)),
          Expanded(child: Center(child: _cell(free))),
          Expanded(child: Center(child: _cell(pro, color: const Color(0xFF6366F1)))),
          Expanded(child: Center(child: _cell(proPlus, color: const Color(0xFFF59E0B)))),
        ],
      ),
    );
  }

  Widget _cell(dynamic value, {Color? color}) {
    if (value is bool) {
      return Icon(
        value ? Icons.check_circle_rounded : Icons.remove,
        size: 16,
        color: value ? (color ?? Colors.green) : Colors.grey.withValues(alpha: 0.3),
      );
    }
    return Text(
      value.toString(),
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        color: color,
      ),
    );
  }
}
