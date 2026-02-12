/// CashPilot Theme Configuration — 2025 Hybrid Adaptive Edition
/// Platform-accurate (iOS + Android), M3 compliant, token-driven.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_typography.dart';
import 'tokens.g.dart';

class AppTheme {
  // ========================================================================
  // HELPERS
  // ========================================================================

  static bool _isGlass(Color c) => c.alpha < 50;

  static Color _solidify(Color base, {double opacity = 0.92}) {
    return base.withOpacity(opacity);
  }

  static Color _iosBoost(Color c) {
    return Color.alphaBlend(
      Colors.white.withOpacity(0.32),
      c,
    );
  }

  // ========================================================================
  // LIGHT THEME
  // ========================================================================

  static ThemeData lightTheme(Color basePrimaryColor) {
    final glass = _isGlass(basePrimaryColor);
    final primary = glass
        ? basePrimaryColor.withOpacity(0.92)
        : _solidify(basePrimaryColor);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      colorScheme: ColorScheme.light(
        primary: primary,
        onPrimary: AppTokens.neutralWhite,
        secondary: AppTokens.brandSecondary,
        onSecondary: AppTokens.neutralWhite,

        surface: AppTokens.themeLightSurface,
        surfaceContainerLowest: AppTokens.themeLightBackground,
        surfaceContainerLow: AppTokens.themeLightSurface,
        surfaceContainer: AppTokens.themeLightSurfaceVariant,
        surfaceContainerHigh: AppTokens.themeLightSurfaceVariant,
        surfaceContainerHighest: AppTokens.themeLightSurfaceVariant,

        onSurface: AppTokens.themeLightTextPrimary,
        surfaceTint: primary,

        error: AppTokens.semanticDanger,
        onError: AppTokens.neutralWhite,
      ),

      scaffoldBackgroundColor: AppTokens.themeLightBackground,

      textTheme: AppTypography.getTextTheme(
        AppTokens.themeLightTextPrimary,
        AppTokens.themeLightTextSecondary,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: AppTokens.themeLightSurface,
        elevation: 0,
        centerTitle: true,
        foregroundColor: AppTokens.themeLightTextPrimary,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarBrightness: Brightness.light,
          statusBarIconBrightness: Brightness.dark,
        ),
      ),
    );
  }

  // ========================================================================
  // DARK THEME — DARK GREY (NOT BLACK)
  // ========================================================================

  static ThemeData darkTheme(Color basePrimaryColor) {
    final primary = _iosBoost(
      basePrimaryColor.withOpacity(0.92),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      colorScheme: ColorScheme.dark(
        primary: primary,
        onPrimary: AppTokens.themeDarkTextOnPrimary,

        secondary: AppTokens.brandSecondary,
        onSecondary: AppTokens.themeDarkTextPrimary,

        // 🔑 DARK GREY SYSTEM
        surface: AppTokens.themeDarkSurface,
        surfaceContainerLowest: AppTokens.themeDarkBackground,
        surfaceContainerLow: AppTokens.themeDarkSurface,
        surfaceContainer: AppTokens.themeDarkSurfaceVariant,
        surfaceContainerHigh: AppTokens.themeDarkSurfaceElevated,
        surfaceContainerHighest: AppTokens.themeDarkSurfaceElevated,

        onSurface: AppTokens.themeDarkTextPrimary,

        error: AppTokens.semanticDanger,
        onError: AppTokens.neutralWhite,
      ),

      scaffoldBackgroundColor: AppTokens.themeDarkBackground,

      textTheme: AppTypography.getTextTheme(
        AppTokens.themeDarkTextPrimary,
        AppTokens.themeDarkTextSecondary,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: AppTokens.themeDarkTextPrimary,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarBrightness: Brightness.dark,
          statusBarIconBrightness: Brightness.light,
        ),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppTokens.themeDarkSurface,
        selectedItemColor: primary,
        unselectedItemColor: AppTokens.themeDarkTextSecondary,
        elevation: 0,
        selectedLabelStyle: AppTypography.labelSmall.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),

      cardTheme: CardThemeData(
        color: AppTokens.themeDarkSurfaceVariant,
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusLg),
          side: BorderSide(
            color: AppTokens.themeDarkBorder.withOpacity(0.6),
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppTokens.themeDarkSurfaceVariant,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppTokens.spaceLg,
          vertical: AppTokens.spaceLg,
        ),
        labelStyle: AppTypography.bodyMedium.copyWith(
          color: AppTokens.themeDarkTextSecondary,
        ),
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: AppTokens.themeDarkTextSecondary,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          borderSide: BorderSide(color: primary, width: 2),
        ),
      ),

      dividerTheme: DividerThemeData(
        thickness: 0.5,
        color: AppTokens.themeDarkBorder,
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primary,
      ),

      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
        },
      ),
    );
  }
}
