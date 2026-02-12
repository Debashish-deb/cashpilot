
library;

import 'package:cashpilot/l10n/app_localizations.dart' show AppLocalizations;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/theme/accent_colors.dart';
import '../../widgets/navigation/curved_bottom_bar.dart';

class MainShell extends ConsumerStatefulWidget {
  final Widget child;
  final String currentPath;

  const MainShell({
    super.key,
    required this.child,
    required this.currentPath,
  });

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  DateTime? _lastBackPressTime;

  @override
  Widget build(BuildContext context) {
    final currentIndex = _calculateSelectedIndex(context);
    final l10n = AppLocalizations.of(context)!;

    // Using PopScope for modern Flutter back handling
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        
        // If we are NOT on home tab, back button should go to Home first?
        // User didn't specify, but standard Android is: Back -> Home -> Exit.
        // User said "twice will close the app".
        // Let's implement: If not on Home, go Home. If on Home, double-back to exit.
        
        if (currentIndex != 0) {
           context.go(AppRoutes.home);
           return;
        }

        final now = DateTime.now();
        if (_lastBackPressTime == null || 
            now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
          _lastBackPressTime = now;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.closeAppDoubleTap ?? 'Tap back again to exit'),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Theme.of(context).colorScheme.inverseSurface,
            ),
          );
        } else {
          // Exit the app
          SystemNavigator.pop();
        }
      },
      child: GestureDetector(
        // "Sideways swap will take to next possible tab"
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity == null) return;
          
          if (details.primaryVelocity! > 300) {
             // Swiping Right -> Go Previous
             if (currentIndex > 0) {
               _onItemTapped(context, currentIndex - 1);
             }
          } else if (details.primaryVelocity! < -300) {
            // Swiping Left -> Go Next
            if (currentIndex < 3) {
              _onItemTapped(context, currentIndex + 1);
            }
          }
        },
        child: Scaffold(
          body: widget.child,
          extendBody: false,
          bottomNavigationBar: _AppleGradeBottomNav(
            currentIndex: currentIndex,
            onItemTapped: (index) => _onItemTapped(context, index),
          ),
          floatingActionButton: _buildFAB(context, ref, currentIndex),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        ),
      ),
    );
  }

  // =======================================================================
  // FLOATING ACTION BUTTON
  // =======================================================================

  Widget _buildFAB(BuildContext context, WidgetRef ref, int currentIndex) {
    final theme = Theme.of(context);
    final primaryColor = ref.watch(accentConfigProvider).primary;
    final isDark = theme.brightness == Brightness.dark;

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 300),
      tween: Tween(begin: 0.95, end: 1.0),
      curve: Curves.easeOutBack,
      builder: (context, scale, _) {
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  primaryColor,
                  primaryColor.withValues(alpha: 0.85),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withValues(alpha: isDark ? 0.5 : 0.35),
                  blurRadius: 20,
                  spreadRadius: 2,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () {
                  HapticFeedback.mediumImpact();
                  if (currentIndex == 1) {
                    context.push(AppRoutes.budgetCreate);
                  } else {
                    context.push(AppRoutes.addExpense);
                  }
                },
                child: Center(
                  child: Icon(
                    currentIndex == 1
                        ? Icons.post_add_rounded
                        : Icons.add_rounded,
                    size: 32,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // =======================================================================
  // NAVIGATION
  // =======================================================================

  int _calculateSelectedIndex(BuildContext context) {
    if (widget.currentPath.startsWith('/budgets')) return 1;
    if (widget.currentPath.startsWith('/reports')) return 2;
    if (widget.currentPath.startsWith('/settings')) return 3;
    return 0;
  }

  void _onItemTapped(BuildContext context, int index) {
    HapticFeedback.selectionClick();
    switch (index) {
      case 0:
        context.go(AppRoutes.home);
        break;
      case 1:
        context.go(AppRoutes.budgets);
        break;
      case 2:
        context.go(AppRoutes.reports);
        break;
      case 3:
        context.go(AppRoutes.settings);
        break;
    }
  }
}

// =======================================================================
// APPLE-GRADE BOTTOM NAVIGATION - Notched with Accent Colors
// =======================================================================

class _AppleGradeBottomNav extends ConsumerWidget {
  final int currentIndex;
  final ValueChanged<int> onItemTapped;

  const _AppleGradeBottomNav({
    required this.currentIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accentColor = ref.watch(accentConfigProvider).primary;

    return SmoothCurvedBottomBar(
      backgroundColor: theme.scaffoldBackgroundColor,
      borderColor: accentColor.withValues(alpha: 0.3),
      height: 70,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Expanded(
            child: _AppleNavItem(
              icon: Icons.home_rounded,
              label: l10n.navigationHome,
              isSelected: currentIndex == 0,
              onTap: () => onItemTapped(0),
              accentColor: accentColor,
            ),
          ),
          Expanded(
            child: _AppleNavItem(
              icon: Icons.account_balance_wallet_rounded,
              label: l10n.navigationBudgets,
              isSelected: currentIndex == 1,
              onTap: () => onItemTapped(1),
              accentColor: accentColor,
            ),
          ),
          const SizedBox(width: 56), // Space for FAB
          Expanded(
            child: _AppleNavItem(
              icon: Icons.bar_chart_rounded,
              label: l10n.navigationReports,
              isSelected: currentIndex == 2,
              onTap: () => onItemTapped(2),
              accentColor: accentColor,
            ),
          ),
          Expanded(
            child: _AppleNavItem(
              icon: Icons.settings_rounded,
              label: l10n.navigationSettings,
              isSelected: currentIndex == 3,
              onTap: () => onItemTapped(3),
              accentColor: accentColor,
            ),
          ),
        ],
      ),
    );
  }
}

// =======================================================================
// APPLE NAV ITEM - SF Symbols Style with Accent Colors
// =======================================================================

class _AppleNavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color accentColor;

  const _AppleNavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.accentColor,
  });

  @override
  State<_AppleNavItem> createState() => _AppleNavItemState();
}

class _AppleNavItemState extends State<_AppleNavItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );

    // Spring-like bounce on tap
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.88).chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.88, end: 1.0).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 70,
      ),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    _controller.forward(from: 0);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final activeColor = widget.accentColor; // Use accent color
    final inactiveColor = isDark
        ? Colors.white.withValues(alpha: 0.55)
        : Colors.black.withValues(alpha: 0.45);

    return GestureDetector(
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: widget.isSelected
                    ? widget.accentColor.withValues(alpha: isDark ? 0.2 : 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedScale(
                    scale: widget.isSelected ? 1.0 : 0.95,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutBack,
                    child: Icon(
                      widget.icon,
                      size: widget.isSelected ? 28 : 26,
                      color: widget.isSelected ? activeColor : inactiveColor,
                      weight: widget.isSelected ? 600 : 400,
                    ),
                  ),
                  const SizedBox(height: 2),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      fontSize: widget.isSelected ? 11 : 10,
                      fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: widget.isSelected ? activeColor : inactiveColor,
                      letterSpacing: -0.2,
                    ),
                    child: Text(
                      widget.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
