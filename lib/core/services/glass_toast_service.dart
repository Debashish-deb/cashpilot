import 'dart:async';
import 'package:flutter/material.dart';
import '../../ui/widgets/common/glass_toast.dart';

/// Service to show premium "Glass" toasts.
/// Uses Overlay to display toasts on top of everything.
class GlassToastService {
  static final GlassToastService _instance = GlassToastService._internal();
  factory GlassToastService() => _instance;
  GlassToastService._internal();

  OverlayEntry? _overlayEntry;
  Timer? _dismissTimer;
  Timer? _animationTimer;

  /// Global Navigator Key (Must be assigned to MaterialApp.router)
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  void show(String message, {
    String? title,
    GlassToastType type = GlassToastType.info,
    Duration duration = const Duration(seconds: 3),
    BuildContext? context, // Optional: if null, uses navigatorKey
  }) {
    _removeToast();

    final targetContext = context ?? navigatorKey.currentContext;
    if (targetContext == null) {
      debugPrint('[GlassToast] Cannot show toast: No context available.');
      return; // Can't show without context
    }

    final overlay = Overlay.of(targetContext);
   
    _overlayEntry = OverlayEntry(
      builder: (context) => _ToastAnimator(
        child: GlassToast(message: message, title: title, type: type),
        onDismiss: () => _removeToast(),
      ),
    );

    overlay.insert(_overlayEntry!);

    _dismissTimer = Timer(duration, () {
      _removeToast();
    });
  }

  void _removeToast() {
    _dismissTimer?.cancel();
    _animationTimer?.cancel(); // If we had one for exit animation
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}

class _ToastAnimator extends StatefulWidget {
  final Widget child;
  final VoidCallback onDismiss;

  const _ToastAnimator({required this.child, required this.onDismiss});

  @override
  State<_ToastAnimator> createState() => _ToastAnimatorState();
}

class _ToastAnimatorState extends State<_ToastAnimator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
      reverseDuration: const Duration(milliseconds: 300),
    );

    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _offset = Tween<Offset>(
      begin: const Offset(0.0, -0.5), // Slide down from top
      end: const Offset(0.0, 0.15),   // Settle slightly below top safe area
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 20,
      right: 20,
      child: SlideTransition(
        position: _offset,
        child: FadeTransition(
          opacity: _opacity,
          child: widget.child,
        ),
      ),
    );
  }
}
