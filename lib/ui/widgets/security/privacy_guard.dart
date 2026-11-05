import 'dart:ui';
import 'package:flutter/material.dart';

/// PrivacyGuard
/// Blurs and masks app content when app is backgrounded,
/// inactive, or visible in the task switcher.
///
/// Banking / password-manager grade protection.
class PrivacyGuard extends StatefulWidget {
  final Widget child;
  final bool enabled;

  const PrivacyGuard({
    super.key,
    required this.child,
    this.enabled = true,
  });

  @override
  State<PrivacyGuard> createState() => _PrivacyGuardState();
}

class _PrivacyGuardState extends State<PrivacyGuard>
    with WidgetsBindingObserver {
  bool _shouldBlur = false;
  AppLifecycleState? _lastState;

  // ---------------------------------------------------------------------------
  // LIFECYCLE
  // ---------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!widget.enabled) return;

    // Avoid unnecessary rebuilds
    if (_lastState == state) return;
    _lastState = state;

    final shouldBlur = _shouldBlurForState(state);

    if (shouldBlur != _shouldBlur && mounted) {
      setState(() {
        _shouldBlur = shouldBlur;
      });
    }
  }

  bool _shouldBlurForState(AppLifecycleState state) {
    // When the app is inactive, paused, hidden, or detached, blur the content.
    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        return true;
      case AppLifecycleState.resumed:
        return false;
    }
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,

        // Security overlay: Instant 0ms cover when backgrounding to prevent OS recent-apps snapshot leakage,
        // smooth fade-out on resume
        IgnorePointer(
          ignoring: !_shouldBlur,
          child: AnimatedOpacity(
            opacity: _shouldBlur ? 1.0 : 0.0,
            duration: _shouldBlur ? Duration.zero : const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            child: _buildBlurOverlay(context),
          ),
        ),
      ],
    );
  }

  Widget _buildBlurOverlay(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BackdropFilter(
      filter: ImageFilter.blur(
        sigmaX: 18,
        sigmaY: 18,
      ),
      child: Container(
        // High opacity background to prevent OCR or screenshot threshold leakage
        color: isDark ? const Color(0xE6121212) : const Color(0xE6F8F9FA),
        alignment: Alignment.center,
        child: Semantics(
          label: 'Content hidden for privacy',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.lock_rounded,
                size: 64,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              const SizedBox(height: 12),
              Text(
                'Content hidden',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
