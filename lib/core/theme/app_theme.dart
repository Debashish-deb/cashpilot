/// CashPilot Theme Configuration — 2025 Hybrid Adaptive Edition
/// Platform-accurate (iOS + Android), M3 compliant, dynamic surface system.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_typography.dart';

class AppTheme {
  // ========================================================================
  // HELPERS — detect glass colors, detect platform, handle dynamic opacity
  // ========================================================================

  static bool _isGlass(Color c) => c.alpha < 50;

  static Color _solidify(Color base, {double opacity = 0.92}) {
    return base.withValues(alpha: opacity);
  }

  static Color _iosBoost(Color c) {
    // Apple boosts color vibrancy in dark mode
    return Color.alphaBlend(
      Colors.white.withValues(alpha: 0.32),
      c,
    );
  }

  // ========================================================================
  // LIGHT THEME — iOS surface hierarchy + Android safe M3 roles
  // ========================================================================

  static ThemeData lightTheme(Color basePrimaryColor) {
    final glass = _isGlass(basePrimaryColor);
    final primary = glass
        ? Color.fromARGB(235, basePrimaryColor.red, basePrimaryColor.green, basePrimaryColor.blue)
        : _solidify(basePrimaryColor);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      // =======================
      // COLOR SCHEME (M3 + Apple)
      // =======================
      colorScheme: ColorScheme.light(
        primary: primary,
        onPrimary: Colors.white,
        secondary: AppColors.accent,
        onSecondary: Colors.white,

        // New M3 surface roles — *very important for layering*
        surface: AppColors.lightSurface,
        surfaceContainerLowest: AppColors.lightBackground,
        surfaceContainerLow: AppColors.lightSurface,
        surfaceContainer: AppColors.lightSurfaceVariant,
        surfaceContainerHigh: AppColors.lightSurfaceVariant,
        surfaceContainerHighest: AppColors.lightSurfaceVariant,

        onSurface: AppColors.lightTextPrimary,
        surfaceTint: basePrimaryColor,

        error: AppColors.danger,
        onError: Colors.white,
      ),

      scaffoldBackgroundColor: AppColors.lightBackground,

      // =======================
      // TYPOGRAPHY
      // =======================
      textTheme: AppTypography.getTextTheme(
        AppColors.lightTextPrimary,
        AppColors.lightTextSecondary,
      ),

      // =======================
      // APP BAR (iOS style)
      // =======================
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.lightSurface,
        elevation: 0,
        centerTitle: true,
        shadowColor: Colors.transparent,
        foregroundColor: AppColors.lightTextPrimary,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarBrightness: Brightness.light,
          statusBarIconBrightness: Brightness.dark,
        ),
      ),

      // =======================
      // NAVIGATION BAR
      // =======================
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.lightSurface,
        elevation: 4,
        selectedItemColor: primary,
        unselectedItemColor: AppColors.lightTextTertiary,
        selectedLabelStyle: AppTypography.labelSmall.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: AppTypography.labelSmall,
      ),

      // =======================
      // CARD STYLE
      // =======================
      cardTheme: CardThemeData(
        color: AppColors.lightCardBackground,
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.lightBorder),
        ),
      ),

      // =======================
      // BUTTONS
      // =======================
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: AppTypography.labelLarge,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: BorderSide(color: primary, width: 1.4),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: AppTypography.labelLarge,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          textStyle: AppTypography.labelLarge,
        ),
      ),

      // =======================
      // INPUT FIELDS
      // =======================
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightSurfaceVariant,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: AppTypography.bodyMedium.copyWith(color: AppColors.lightTextSecondary),
        hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.lightTextTertiary),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primary, width: 2),
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.lightDivider,
        thickness: 1,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: AppColors.lightSurfaceVariant,
        selectedColor: primary.withValues(alpha: 0.23),
        labelStyle: AppTypography.labelMedium,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primary,
      ),

      // Platform transitions
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
        },
      ),
    );
  }

  // ========================================================================
  // DARK THEME — Apple-depth + AMOLED efficiency + M3 surface roles
  // ========================================================================

  static ThemeData darkTheme(Color basePrimaryColor) {
    final glass = _isGlass(basePrimaryColor);

    final primary = glass
        ? _iosBoost(basePrimaryColor)
        : _iosBoost(basePrimaryColor.withValues(alpha: 0.92));

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primary,

      // ================
      // COLOR SCHEME
      // ================
      colorScheme: ColorScheme.dark(
        primary: primary,
        onPrimary: Colors.black,

        secondary: AppColors.accent,
        onSecondary: Colors.black,

        surface: AppColors.darkSurface,
        surfaceContainerLowest: AppColors.darkBackground,
        surfaceContainerLow: AppColors.darkSurface,
        surfaceContainer: AppColors.darkSurfaceVariant,
        surfaceContainerHigh: AppColors.darkSurfaceVariant,
        surfaceContainerHighest: AppColors.darkSurfaceVariant,

        onSurface: AppColors.darkTextPrimary,
        error: AppColors.danger,
        onError: Colors.white,
      ),

      scaffoldBackgroundColor: AppColors.darkBackground,

      // =======================
      // TYPOGRAPHY
      // =======================
      textTheme: AppTypography.getTextTheme(
        AppColors.darkTextPrimary,
        AppColors.darkTextSecondary,
      ),

      // =======================
      // APP BAR
      // =======================
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkSurface,
        elevation: 0,
        centerTitle: true,
        foregroundColor: AppColors.darkTextPrimary,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarBrightness: Brightness.dark,
          statusBarIconBrightness: Brightness.light,
        ),
      ),

      // =======================
      // NAV BAR
      // =======================
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        selectedItemColor: primary,
        unselectedItemColor: AppColors.darkTextTertiary,
        elevation: 8,
        selectedLabelStyle: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.w600),
      ),

      // =======================
      // CARD
      // =======================
      cardTheme: CardThemeData(
        color: AppColors.darkCardBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.darkBorder),
        ),
      ),

      // =======================
      // BUTTONS
      // =======================
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.black,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: BorderSide(color: primary, width: 1.4),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),

      // =======================
      // INPUTS
      // =======================
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurfaceVariant,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: AppTypography.bodyMedium.copyWith(color: AppColors.darkTextSecondary),
        hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.darkTextTertiary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primary, width: 2),
        ),
      ),

      dividerTheme: const DividerThemeData(
        thickness: 1,
        color: AppColors.darkDivider,
      ),

      // =======================
      // POPUPS / DIALOGS / SHEETS (AMOLED)
      // =======================
      popupMenuTheme: PopupMenuThemeData(
        color: const Color(0xFF1A1A1A),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: const Color(0xFF121212),
        modalBackgroundColor: const Color(0xFF121212),
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        dragHandleColor: Colors.white.withValues(alpha: 0.3),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(color: primary),

      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
