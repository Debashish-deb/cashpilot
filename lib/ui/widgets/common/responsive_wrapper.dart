/// Responsive Wrapper
/// Reusable widget that provides adaptive layout for different screen sizes
library;

import 'package:flutter/material.dart';

/// Responsive wrapper that adapts content based on screen size
/// 
/// Usage:
/// ```dart
/// ResponsiveWrapper(
///   builder: (context, screenSize) {
///     return Column(
///       children: [
///         SizedBox(height: screenSize.verticalSpacing),
///         // Your content
///       ],
///     );
///   },
/// )
/// ```
class ResponsiveWrapper extends StatelessWidget {
  final Widget Function(BuildContext context, ResponsiveScreenSize screenSize) builder;
  final bool enableScroll;
  final EdgeInsets? customPadding;

  const ResponsiveWrapper({
    super.key,
    required this.builder,
    this.enableScroll = true,
    this.customPadding,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenSize = ResponsiveScreenSize(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
        );

        final content = Padding(
          padding: customPadding ?? screenSize.defaultPadding,
          child: builder(context, screenSize),
        );

        if (enableScroll) {
          return SingleChildScrollView(
            child: content,
          );
        }

        return content;
      },
    );
  }
}

/// Screen size helper with adaptive values
class ResponsiveScreenSize {
  final double width;
  final double height;

  ResponsiveScreenSize({
    required this.width,
    required this.height,
  });

  /// Breakpoints
  // Ignore height for small screen check as modern phones are tall but narrow
  bool get isSmallScreen => width < 360;
  bool get isLargeScreen => width >= 600;
  bool get isMediumScreen => !isSmallScreen && !isLargeScreen;

  /// Adaptive padding
  EdgeInsets get defaultPadding => EdgeInsets.symmetric(
        // Standard phone gets 16 (was 24), Large gets 32
        horizontal: isLargeScreen ? 32 : 16,
        // Standard phone gets 16 (was 20), Large gets 24
        vertical: isLargeScreen ? 20 : (isSmallScreen ? 12 : 16),
      );

  /// Adaptive spacing
  // Standard phone gets 16 (was 24)
  double get verticalSpacing => isLargeScreen ? 24 : (isSmallScreen ? 12 : 16);
  double get horizontalSpacing => isLargeScreen ? 20 : 12;
  double get cardSpacing => isLargeScreen ? 20 : 12;

  /// Adaptive sizes
  double get iconSize => isLargeScreen ? 28 : (isSmallScreen ? 20 : 24);
  double get buttonHeight => isLargeScreen ? 56 : (isSmallScreen ? 44 : 48);
  double get appBarHeight => isLargeScreen ? 72 : (isSmallScreen ? 56 : 60);

  /// Adaptive font scale
  // Ensure standard phones stay at 1.0 to avoid scaling artifacts
  double get fontScale => isLargeScreen ? 1.2 : (isSmallScreen ? 0.9 : 1.0);
}
