/// CashPilot Color Palette — Cross-Platform Unified Edition
/// Accurate for both Apple HIG + Material Design 3
library;

import 'package:flutter/material.dart';

class AppColors {
  // ============================================================
  // BRAND COLORS — platform-neutral but premium
  // ============================================================

  /// Financial-grade green (not overly Apple or Android)
  static const Color primaryGreen = Color(0xFF1F9E63);
  static const Color primaryGreenLight = Color(0xFF48C98C);
  static const Color primaryGreenDark = Color(0xFF0C7A4A);

  /// Universal accent blue (between iOS Blue & Material Blue)
  static const Color accent = Color(0xFF2DA8E8);      // midpoint tone
  static const Color accentLight = Color(0xFF6BCBFF);
  static const Color accentDark = Color(0xFF0A78C2);

  /// Purple (Apple tint + Material tone merge)
  static const Color accentPurple = Color(0xFFB05AF2);

  /// Banking Gold (premium regardless of platform)
  static const Color primaryGold = Color(0xFFC7A46A);
  static const Color accentGold = Color(0xFFE2C77B);

  /// Indigo Palette (New Brand Colors)
  static const Color indigo600 = Color(0xFF4F46E5);
  static const Color indigo400 = Color(0xFF818CF8);

  // ============================================================
  // LIGHT MODE — Balanced for iOS + Android
  // ============================================================

  /// Backgrounds (matches both systems)
  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFF4F4F6);
  static const Color lightSurfaceVariant = Color(0xFFE6E6EA);

  static const Color lightCardBackground = Color(0xFFFFFFFF);

  /// Text colors (industry-neutral, readable)
  static const Color lightTextPrimary = Color(0xFF000000);
  static const Color lightTextSecondary = Color(0xFF5A5A5F);
  static const Color lightTextTertiary = Color(0xFF8C8C91);

  static const Color lightTextOnPrimary = Color(0xFFFFFFFF);

  /// Dividers & Borders (perfect middle between iOS & Material)
  static const Color lightDivider = Color(0xFFD0D0D5);
  static const Color lightBorder = Color(0xFFBEBEC2);

  // ============================================================
  // DARK MODE — Universal Android + iOS darkness
  // ============================================================

  /// Solid Grey Dark Mode (User provided reference)
  static const Color darkBackground = Color(0xFF3C3C3C);
  static const Color darkSurface = Color(0xFF3C3C3C);
  static const Color darkSurfaceVariant = Color(0xFF4A4A4A);
  static const Color darkCardBackground = Color(0xFF4A4A4A);

  /// Text hierarchy (Apple + Android compatible)
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFCECED4);
  static const Color darkTextTertiary = Color(0xFF8E8E93);

  static const Color darkTextOnPrimary = Color(0xFFFFFFFF);

  /// Separators (tuned for OLED contrast)
  static const Color darkDivider = Color(0xFF1C1C1F);
  static const Color darkBorder = Color(0xFF262629);

  // ============================================================
  // SEMANTIC COLORS — Cross-Platform standard tones
  // ============================================================

  /// Green (Success)
  /// Matches iOS systemGreen + Material green500 midpoint
  static const Color success = Color(0xFF32C75A);
  static const Color successLight = Color(0xFFE6F7EB);
  static const Color successDark = Color(0xFF1F8A41);

  /// Warning (Orange)
  static const Color warning = Color(0xFFF6A100);
  static const Color warningLight = Color(0xFFFFF3DE);
  static const Color warningDark = Color(0xFFC77B00);

  /// Danger (Red)
  static const Color danger = Color(0xFFE33D38);
  static const Color error = danger;
  static const Color dangerLight = Color(0xFFFFE6E5);
  static const Color dangerDark = Color(0xFFB22A26);

  /// Info (Blue)
  static const Color info = Color(0xFF248BFF);
  static const Color infoLight = Color(0xFFE3F0FF);

  /// Premium gold
  static const Color gold = Color(0xFFC6A46D);
  static const Color goldLight = Color(0xFFF3E7C9);

  // ============================================================
  // PROGRESS COLORS — Unified interpretation
  // ============================================================

  static Color getProgressColor(double percentage) {
    if (percentage < 0.65) return success;
    if (percentage < 0.85) return caution;
    if (percentage < 1.0) return warning;
    return danger;
  }

  static const Color caution = Color(0xFFFFCC00);
  static const Color cautionLight = Color(0xFFFFF8D6);

  // ============================================================
  // GRADIENTS — Both platforms accept these
  // ============================================================

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF58D69C), Color(0xFF1F9E63)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient premiumGradient = LinearGradient(
    colors: [Color(0xFFCDB5FF), Color(0xFF8C63FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient sunsetGradient = LinearGradient(
    colors: [Color(0xFFFFB98A), Color(0xFFF96C4A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient oceanGradient = LinearGradient(
    colors: [Color(0xFF73D2FF), Color(0xFF1A8FFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient magmaGradient = sunsetGradient;

  static const LinearGradient tealGradient = LinearGradient(
    colors: [Color(0xFF4FD1C5), Color(0xFF285E61)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient emeraldGradient = LinearGradient(
    colors: [Color(0xFF6EE7B7), Color(0xFF065F46)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient indigoGradient = LinearGradient(
    colors: [Color(0xFF818CF8), Color(0xFF312E81)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ============================================================
  // PROFILE GLASS COLORS — Tuned for both Android & iOS
  // ============================================================

  static const int _glassAlpha = 26; // Perfect midpoint translucency

  static const Color greenGlass =
      Color.fromARGB(_glassAlpha, 38, 146, 91);

  static const Color electricBlueGlass =
      Color.fromARGB(_glassAlpha, 45, 168, 232);

  static const Color prismaticAuroraGlass =
      Color.fromARGB(_glassAlpha, 176, 90, 242);

  static const Color sunsetOrangeGlass =
      Color.fromARGB(_glassAlpha, 255, 149, 0);

  static const Color graphiteGlass =
      Color.fromARGB(_glassAlpha, 44, 44, 46);

  static const Map<String, Color> profileColors = {
    'default': greenGlass,
    'electric_blue': electricBlueGlass,
    'prismatic_aurora': prismaticAuroraGlass,
    'sunset_orange': sunsetOrangeGlass,
    'deep_shade': graphiteGlass,
  };

  // ============================================================
  // PROFILE GRADIENTS — platform neutral
  // ============================================================

  static const LinearGradient greenGradient = LinearGradient(
    colors: [Color(0xFFA2F3C7), Color(0xFF1F9E63)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient electricBlueGradient = LinearGradient(
    colors: [Color(0xFFA9DFFF), Color(0xFF1A8FFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient prismaticAuroraGradient = LinearGradient(
    colors: [Color(0xFFE1B8FF), Color(0xFFB05AF2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient sunsetOrangeGradient = LinearGradient(
    colors: [Color(0xFFFFD4AD), Color(0xFFF6A100)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient graphiteGradient = LinearGradient(
    colors: [Color(0xFF9A9AA2), Color(0xFF2A2A2D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Map<String, LinearGradient> profileGradients = {
    'default': greenGradient,
    'electric_blue': electricBlueGradient,
    'prismatic_aurora': prismaticAuroraGradient,
    'sunset_orange': sunsetOrangeGradient,
    'deep_shade': graphiteGradient,
  };

  // ============================================================
  // MISC / UTILITY
  // ============================================================
  
  /// Generic medium grey, often used for inactive states
  static const Color neutral60 = Color(0xFF8C8C91);
}
