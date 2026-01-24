import 'package:flutter/material.dart';
import '../../../core/theme/app_typography.dart';

/// Reusable collapsible section widget for grouped lists
class CollapsibleSection<T> extends StatefulWidget {
  final String title;
  final int count;
  final List<T> items;
  final Widget Function(T) itemBuilder;
  final bool initiallyExpanded;
  final Color? accentColor;
  final IconData? icon;

  const CollapsibleSection({
    super.key,
    required this.title,
    required this.count,
    required this.items,
    required this.itemBuilder,
    this.initiallyExpanded = true,
    this.accentColor,
    this.icon,
  });

  @override
  State<CollapsibleSection<T>> createState() => _CollapsibleSectionState<T>();
}

class _CollapsibleSectionState<T> extends State<CollapsibleSection<T>>
    with SingleTickerProviderStateMixin {
  late bool _isExpanded;
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 0.5,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    
    if (_isExpanded) {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accentColor = widget.accentColor ?? theme.primaryColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Material(
          color: isDark
              ? theme.colorScheme.surfaceContainerHighest
              : theme.colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: _toggleExpanded,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // Expand/collapse icon
                  RotationTransition(
                    turns: _rotationAnimation,
                    child: Icon(
                      Icons.arrow_drop_down_rounded,
                      color: accentColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 8),
                  
                  // Optional icon
                  if (widget.icon != null) ...[
                    Icon(widget.icon, color: accentColor, size: 20),
                    const SizedBox(width: 8),
                  ],
                  
                  // Title
                  Expanded(
                    child: Text(
                      widget.title,
                      style: AppTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  
                  // Count badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: accentColor.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      '${widget.count}',
                      style: AppTypography.labelSmall.copyWith(
                        color: accentColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        
        // Content
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              children: widget.items.map(widget.itemBuilder).toList(),
            ),
          ),
          crossFadeState: _isExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }
}
