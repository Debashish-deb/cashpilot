/// Custom Page Transitions for Industrial-Grade Routing
/// Fast, smooth transitions optimized for performance
library;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Fast fade transition - minimal animation for speed
class FastFadePage<T> extends CustomTransitionPage<T> {
  FastFadePage({
    required super.child,
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
    super.maintainState = true,
    super.fullscreenDialog = false,
  }) : super(
          transitionDuration: const Duration(milliseconds: 150),
          reverseTransitionDuration: const Duration(milliseconds: 120),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOut,
              ),
              child: child,
            );
          },
        );
}

/// Slide up transition for modal-like screens
class SlideUpPage<T> extends CustomTransitionPage<T> {
  SlideUpPage({
    required super.child,
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
    super.maintainState = true,
    super.fullscreenDialog = true,
  }) : super(
          transitionDuration: const Duration(milliseconds: 250),
          reverseTransitionDuration: const Duration(milliseconds: 200),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curve = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.1),
                end: Offset.zero,
              ).animate(curve),
              child: FadeTransition(
                opacity: curve,
                child: child,
              ),
            );
          },
        );
}

/// Slide in from right transition for drill-down navigation
class SlideInPage<T> extends CustomTransitionPage<T> {
  SlideInPage({
    required super.child,
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
    super.maintainState = true,
    super.fullscreenDialog = false,
  }) : super(
          transitionDuration: const Duration(milliseconds: 200),
          reverseTransitionDuration: const Duration(milliseconds: 180),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curve = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.25, 0),
                end: Offset.zero,
              ).animate(curve),
              child: FadeTransition(
                opacity: Tween<double>(begin: 0.5, end: 1.0).animate(curve),
                child: child,
              ),
            );
          },
        );
}

/// Scale transition for special screens (paywall, etc.)
class ScalePage<T> extends CustomTransitionPage<T> {
  ScalePage({
    required super.child,
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
    super.maintainState = true,
    super.fullscreenDialog = true,
  }) : super(
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 250),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curve = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutBack,
              reverseCurve: Curves.easeIn,
            );
            return ScaleTransition(
              scale: Tween<double>(begin: 0.9, end: 1.0).animate(curve),
              child: FadeTransition(
                opacity: curve,
                child: child,
              ),
            );
          },
        );
}

/// Helper extension for easy access to page types
extension GoRouterPageBuilder on GoRoute {
  /// Create a fast fade page builder
  static Page<dynamic> fadePage({
    required Widget child,
    LocalKey? key,
    String? name,
  }) {
    return FastFadePage(
      key: key,
      name: name,
      child: child,
    );
  }

  /// Create a slide up page builder
  static Page<dynamic> slideUpPage({
    required Widget child,
    LocalKey? key,
    String? name,
  }) {
    return SlideUpPage(
      key: key,
      name: name,
      child: child,
    );
  }

  /// Create a slide in page builder
  static Page<dynamic> slideInPage({
    required Widget child,
    LocalKey? key,
    String? name,
  }) {
    return SlideInPage(
      key: key,
      name: name,
      child: child,
    );
  }

  /// Create a scale page builder
  static Page<dynamic> scalePage({
    required Widget child,
    LocalKey? key,
    String? name,
  }) {
    return ScalePage(
      key: key,
      name: name,
      child: child,
    );
  }
}
