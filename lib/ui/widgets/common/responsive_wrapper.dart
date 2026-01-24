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
  bool get isSmallScreen => height < 600 || width < 360;
  bool get isLargeScreen => width > 600;
  bool get isMediumScreen => !isSmallScreen && !isLargeScreen;

  /// Adaptive padding
  EdgeInsets get defaultPadding => EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 16 : (isLargeScreen ? 32 : 24),
        vertical: isSmallScreen ? 12 : 20,
      );

  /// Adaptive spacing
  double get verticalSpacing => isSmallScreen ? 12 : 24;
  double get horizontalSpacing => isSmallScreen ? 12 : 16;
  double get cardSpacing => isSmallScreen ? 12 : (isLargeScreen ? 20 : 16);

  /// Adaptive sizes
  double get iconSize => isSmallScreen ? 20 : (isLargeScreen ? 28 : 24);
  double get buttonHeight => isSmallScreen ? 44 : 48;
  double get appBarHeight => isSmallScreen ? 56 : 64;

  /// Adaptive font scale
  double get fontScale => isSmallScreen ? 0.9 : (isLargeScreen ? 1.1 : 1.0);
}
