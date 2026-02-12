import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../features/knowledge/presentation/providers/knowledge_providers.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../widgets/common/glass_card.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';

class HomeInsightsCarousel extends ConsumerStatefulWidget {
  const HomeInsightsCarousel({super.key});

  @override
  ConsumerState<HomeInsightsCarousel> createState() => _HomeInsightsCarouselState();
}

class _HomeInsightsCarouselState extends ConsumerState<HomeInsightsCarousel> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 8), (timer) {
      if (!mounted) return;
      
      // If we have data for the tip, we have 2 pages. Otherwise just 1.
      final tipAsync = ref.read(dailyTipProvider);
      final hasTip = tipAsync.hasValue && tipAsync.value != null;
      final pageCount = hasTip ? 2 : 1;
      
      if (pageCount > 1) {
        int nextPage = (_currentPage + 1) % pageCount;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final tipAsync = ref.watch(dailyTipProvider);
    final l10n = AppLocalizations.of(context)!;
    
    final hasTip = tipAsync.hasValue && tipAsync.value != null;
    final pageCount = hasTip ? 2 : 1;

    return Column(
      children: [
        SizedBox(
          height: 96, // Reduced by 20% from 120
          child: PageView(
            controller: _pageController,
            onPageChanged: (page) => setState(() => _currentPage = page),
            children: [
              // SLIDE 1: Welcome / Encouragement
              _buildWelcomeSlide(context, l10n),
              
              // SLIDE 2: Daily Tip (if available)
              if (hasTip) _buildTipSlide(context, ref, tipAsync.value!, l10n),
            ],
          ),
        ),
        if (pageCount > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              pageCount,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 4,
                width: _currentPage == index ? 12 : 4,
                decoration: BoxDecoration(
                  color: _currentPage == index 
                      ? AppTokens.brandPrimary 
                      : Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildWelcomeSlide(BuildContext context, AppLocalizations l10n) {
    return GlassCard(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      borderRadius: 20,
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTokens.brandPrimary.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.thumb_up_rounded, color: AppTokens.brandPrimary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "You're doing great!",
                  style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  "You've logged expenses consistently. Keep it up!",
                  style: AppTypography.bodySmall.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipSlide(BuildContext context, WidgetRef ref, dynamic tip, AppLocalizations l10n) {
    return GlassCard(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      borderRadius: 20,
      color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.2),
      onTap: tip.actionRoute.isNotEmpty ? () => context.push(tip.actionRoute) : null,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(LucideIcons.lightbulb, color: Theme.of(context).colorScheme.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        tip.title,
                        style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (tip.actionRoute.isNotEmpty)
                      Icon(Icons.arrow_forward_ios, size: 12, color: Theme.of(context).colorScheme.primary),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  tip.content,
                  style: AppTypography.bodySmall.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
