import 'package:flutter/material.dart';
import 'package:cashpilot/core/theme/tokens.g.dart';

/// Industrial-Grade Card Primitive
/// 
/// Replaces ad-hoc Containers and "Glass" effects with a stable,
/// token-backed surface. Defaults to "Solid" style for maximum readability.
enum AppCardVariant {
  /// Standard solid background (White / Dark Grey)
  solid,
  
  /// Subtle outline, transparent background
  outlined,
  
  /// Elevated with soft shadow
  elevated,
  
  /// (Optional) Glass effect for special hero sections only
  glass,
}

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final AppCardVariant variant;
  final Color? customColor;
  final double? width;
  final double? height;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.variant = AppCardVariant.solid,
    this.customColor,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Resolve variant styles
    Color backgroundColor;
    Border? border;
    List<BoxShadow>? shadows;
    
    switch (variant) {
      case AppCardVariant.solid:
        backgroundColor = customColor ?? (isDark 
            ? AppTokens.themeDarkSurfaceVariant 
            : AppTokens.neutralWhite);
        border = Border.all(
          color: isDark ? AppTokens.themeDarkBorder : AppTokens.themeLightBorder,
          width: 1,
        );
        break;
        
      case AppCardVariant.outlined:
        backgroundColor = Colors.transparent;
        border = Border.all(
          color: isDark ? AppTokens.neutralGrey700 : AppTokens.neutralGrey300,
          width: 1,
        );
        break;
        
      case AppCardVariant.elevated:
        backgroundColor = customColor ?? (isDark 
            ? AppTokens.neutralGrey800 
            : AppTokens.neutralWhite);
        shadows = [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: AppTokens.radiusLg,
            offset: const Offset(0, 4),
          ),
        ];
        break;
        
      case AppCardVariant.glass:
        // Restricted usage
        backgroundColor = (isDark ? Colors.black : Colors.white).withOpacity(0.1);
        border = Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        );
        break;
    }

    final content = Container(
      width: width,
      height: height,
      padding: padding ?? const EdgeInsets.all(AppTokens.spaceLg),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppTokens.radiusLg),
        border: border,
        boxShadow: shadows,
      ),
      child: child,
    );

    if (margin != null) {
      return Padding(padding: margin!, child: _wrapTap(content));
    }
    
    return _wrapTap(content);
  }

  Widget _wrapTap(Widget content) {
    if (onTap == null) return content;
    
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: content,
    );
  }
}
