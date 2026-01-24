import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CategoryColorSelector extends StatelessWidget {
  final Color? selectedColor;
  final ValueChanged<Color> onColorSelected;

  const CategoryColorSelector({
    super.key,
    required this.selectedColor,
    required this.onColorSelected,
  });

  static final List<Color> defaultColors = [
    const Color(0xFF1E9E63), // Green
    const Color(0xFF4A90E2), // Blue
    const Color(0xFFF5A623), // Orange
    const Color(0xFFE94E77), // Pink
    const Color(0xFF9B59B6), // Purple
    const Color(0xFF00BCD4), // Cyan
    const Color(0xFF607D8B), // Blue Grey
    const Color(0xFFFF5252), // Red
    const Color(0xFF3F51B5), // Indigo
    const Color(0xFF009688), // Teal
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: defaultColors.map((color) {
        final selected = selectedColor == color;

        return _ColorDot(
          color: color,
          selected: selected,
          onTap: () {
            // Platform-correct feedback
            if (Platform.isIOS) {
              HapticFeedback.selectionClick();
            } else {
              HapticFeedback.lightImpact();
            }
            onColorSelected(color);
          },
        );
      }).toList(),
    );
  }
}

// ===================================================================
// PRIVATE — APPLE + ANDROID GRADE COLOR DOT
// ===================================================================

class _ColorDot extends StatefulWidget {
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _ColorDot({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_ColorDot> createState() => _ColorDotState();
}

class _ColorDotState extends State<_ColorDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 160),
      lowerBound: 0.96,
      upperBound: 1.0,
    )..value = 1.0;

    _scale = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAndroid = Platform.isAndroid;

    final content = ScaleTransition(
      scale: _scale,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color,
          boxShadow: [
            // Platform-tuned depth
            BoxShadow(
              color: widget.color.withValues(alpha: isAndroid ? 0.45 : 0.35),
              blurRadius: widget.selected ? 10 : 6,
              offset: const Offset(0, 4),
            ),
            // iOS-style soft highlight
            if (!isAndroid)
              BoxShadow(
                color: Colors.white.withValues(alpha: 
                  isDark ? 0.08 : 0.18,
                ),
                blurRadius: 1,
                offset: const Offset(-1, -1),
              ),
          ],
          border: widget.selected
              ? Border.all(
                  color: Colors.white,
                  width: 3,
                )
              : null,
        ),
        child: widget.selected
            ? const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 22,
              )
            : null,
      ),
    );

    // Android → ripple
    // iOS → gesture only
    return Material(
      type: MaterialType.transparency,
      child: isAndroid
          ? InkResponse(
              onTap: widget.onTap,
              radius: 28,
              containedInkWell: true,
              splashColor: widget.color.withValues(alpha: 0.25),
              highlightColor: Colors.transparent,
              onTapDown: (_) => _controller.reverse(),
              onTapCancel: () => _controller.forward(),
              onTapUp: (_) => _controller.forward(),
              child: content,
            )
          : GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (_) => _controller.reverse(),
              onTapCancel: () => _controller.forward(),
              onTapUp: (_) {
                _controller.forward();
                widget.onTap();
              },
              child: content,
            ),
    );
  }
}
