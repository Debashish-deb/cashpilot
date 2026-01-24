/// Budget Progress Bar Widget
/// Apple-grade progress indicators for budget spending
library;
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class BudgetProgressBar extends StatelessWidget {
  final double progress;
  final double height;
  final Color? backgroundColor;
  final Color? color;
  final bool showOverflow;
  final bool animate;

  const BudgetProgressBar({
    super.key,
    required this.progress,
    this.height = 8,
    this.backgroundColor,
    this.color,
    this.showOverflow = true,
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
    final progressColor = color ?? AppColors.getProgressColor(progress);
    final clampedProgress = progress.clamp(0.0, 1.0);
    final isOverBudget = progress > 1.0;

    return Semantics(
      label: 'Budget usage ${(clampedProgress * 100).round()} percent',
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          // ------------------------------------------------------------------
          // BACKGROUND TRACK (Apple soft material)
          // ------------------------------------------------------------------
          Container(
            width: double.infinity,
            height: height,
            decoration: BoxDecoration(
              color: backgroundColor ??
                  Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(height / 2),
            ),
          ),

          // ------------------------------------------------------------------
          // PROGRESS BAR
          // ------------------------------------------------------------------
          AnimatedContainer(
            duration: animate
                ? const Duration(milliseconds: 420)
                : Duration.zero,
            curve: Curves.easeOutCubic,
            height: height,
            width: double.infinity,
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: clampedProgress,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      progressColor.withValues(alpha: 0.95),
                      progressColor.withValues(alpha: 0.85),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(height / 2),
                  boxShadow: clampedProgress > 0.05
                      ? [
                          BoxShadow(
                            color:
                                progressColor.withValues(alpha: 0.25), // Apple soft
                            blurRadius: height * 0.9,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
              ),
            ),
          ),

          // ------------------------------------------------------------------
          // OVERFLOW INDICATOR
          // ------------------------------------------------------------------
          if (showOverflow && isOverBudget)
            Positioned(
              right: -2,
              child: Container(
                width: height + 4,
                height: height + 4,
                decoration: BoxDecoration(
                  color: AppColors.danger,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.danger.withValues(alpha: 0.35),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.priority_high_rounded,
                  size: height * 0.75,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================================================
// MINI PROGRESS BAR (List items / compact rows)
// ============================================================================

class MiniProgressBar extends StatelessWidget {
  final double progress;
  final Color? color;

  const MiniProgressBar({
    super.key,
    required this.progress,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final progressColor = color ?? AppColors.getProgressColor(progress);
    final clampedProgress = progress.clamp(0.0, 1.0);

    return Semantics(
      label: 'Usage ${(clampedProgress * 100).round()} percent',
      child: Container(
        height: 4,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(2),
        ),
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: clampedProgress,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  progressColor,
                  progressColor.withValues(alpha: 0.85),
                ],
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// CIRCULAR BUDGET PROGRESS (Dashboards / Analytics)
// ============================================================================

class CircularBudgetProgress extends StatelessWidget {
  final double progress;
  final double size;
  final double strokeWidth;
  final Widget? child;

  const CircularBudgetProgress({
    super.key,
    required this.progress,
    this.size = 100,
    this.strokeWidth = 8,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final progressColor = AppColors.getProgressColor(progress);
    final clampedProgress = progress.clamp(0.0, 1.0);

    return Semantics(
      label: 'Budget progress ${(clampedProgress * 100).round()} percent',
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Background ring
            CircularProgressIndicator(
              value: 1.0,
              strokeWidth: strokeWidth,
              color:
                  Theme.of(context).colorScheme.surfaceContainerHighest,
            ),

            // Foreground animated ring
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: clampedProgress),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return CircularProgressIndicator(
                  value: value,
                  strokeWidth: strokeWidth,
                  color: progressColor,
                  strokeCap: StrokeCap.round,
                );
              },
            ),

            if (child != null) child!,
          ],
        ),
      ),
    );
  }
}
