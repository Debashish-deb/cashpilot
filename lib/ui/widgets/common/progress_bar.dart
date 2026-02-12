 /// Budget Progress Bar Widget
/// Apple-grade progress indicators for budget spending
library;
import 'package:flutter/material.dart';

import '../../../core/theme/tokens.g.dart';

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
    final progressColor = color ?? getProgressColorToken(progress);
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
                  color: progressColor,
                  borderRadius: BorderRadius.circular(height / 2),
                  boxShadow: null,
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
                  color: AppTokens.semanticDanger,
                  shape: BoxShape.circle,
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
    final progressColor = color ?? getProgressColorToken(progress);
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
              color: progressColor,
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
    final progressColor = getProgressColorToken(progress);
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

Color getProgressColorToken(double percentage) {
  if (percentage < 0.65) return AppTokens.semanticSuccess;
  if (percentage < 0.85) return AppTokens.semanticCaution;
  if (percentage < 1.0) return AppTokens.semanticWarning;
  return AppTokens.semanticDanger;
}
