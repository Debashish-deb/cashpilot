/// CashPilot Typography System — Apple-Polished + Android-Optimized
/// Consistent, clear, premium typography across both platforms
library;

import 'package:flutter/material.dart';

class AppTypography {
  static const String fontFamily = 'Inter';

  // ============================================================
  // DISPLAY — Hero Text (Large Titles / Dashboard)
  // Apple uses tight spacing; Android gets balanced line height
  // ============================================================

  static const TextStyle displayLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 54,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.9, // balanced for Android + iOS
    height: 1.10,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 42,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.6,
    height: 1.12,
  );

  static const TextStyle displaySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.25,
    height: 1.16,
  );

  // ============================================================
  // HEADLINES — Section Headers
  // Clear, strong readability with Apple-inspired rhythm
  // ============================================================

  static const TextStyle headlineLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.25,
    height: 1.24,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.15,
    height: 1.26,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.05,
    height: 1.28,
  );

  // ============================================================
  // TITLES — for cards + settings rows
  // Matches Apple’s compact title style but behaves consistently on Android
  // ============================================================

  static const TextStyle titleLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.02,
    height: 1.34,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.02,
    height: 1.38,
  );

  static const TextStyle titleSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.05,
    height: 1.38,
  );

  // ============================================================
  // LABELS — Buttons, Chips, TabBar
  // Apple-like clarity, Android-friendly spacing
  // ============================================================

  static const TextStyle labelLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.15,
    height: 1.38,
  );

  static const TextStyle labelMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12.5,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.25,
    height: 1.34,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.35,
    height: 1.32,
  );

  // ============================================================
  // BODY — long text readability
  // Apple’s main body is 17pt, Inter matches this well
  // ============================================================

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 17,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.56,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.05,
    height: 1.50,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.08,
    height: 1.46,
  );

  // ============================================================
  // MONEY — Banking-grade numerical typography
  // Perfect alignment for budgets, totals, charts
  // ============================================================

  static const TextStyle moneyLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 46,
    fontWeight: FontWeight.w700,
    letterSpacing: -1.1,
    height: 1.06,
    fontFeatures: [
      FontFeature.tabularFigures(),
      FontFeature.liningFigures(),
    ],
  );

  static const TextStyle moneyMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 30,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.55,
    height: 1.10,
    fontFeatures: [
      FontFeature.tabularFigures(),
      FontFeature.liningFigures(),
    ],
  );

  static const TextStyle moneySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.12,
    height: 1.15,
    fontFeatures: [
      FontFeature.tabularFigures(),
      FontFeature.liningFigures(),
    ],
  );

  // ============================================================
  // BENGALI NUMERALS — Enhanced Typography
  // Bengali digits (০-৯) need 15-20% larger size for proper rendering
  // Uses system fonts that support Bengali properly
  // ============================================================

  static const TextStyle bengaliMoneyLarge = TextStyle(
    fontSize: 52, // 15% larger than moneyLarge (46 → 52)
    fontWeight: FontWeight.w700,
    letterSpacing: -0.8,
    height: 1.08,
    fontFeatures: [
      FontFeature.tabularFigures(),
      FontFeature.liningFigures(),
    ],
  );

  static const TextStyle bengaliMoneyMedium = TextStyle(
    fontSize: 35, // 15% larger than moneyMedium (30 → 35)
    fontWeight: FontWeight.w700,
    letterSpacing: -0.4,
    height: 1.12,
    fontFeatures: [
      FontFeature.tabularFigures(),
      FontFeature.liningFigures(),
    ],
  );

  static const TextStyle bengaliMoneySmall = TextStyle(
    fontSize: 23, // 15% larger than moneySmall (20 → 23)
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.18,
    fontFeatures: [
      FontFeature.tabularFigures(),
      FontFeature.liningFigures(),
    ],
  );

  static const TextStyle bengaliNumber = TextStyle(
    fontSize: 17, // 15% larger than body
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.5,
    fontFeatures: [
      FontFeature.tabularFigures(),
    ],
  );

  // ============================================================
  // TEXT THEME — platform-synchronized mapping
  // ============================================================

  static TextTheme getTextTheme(Color textColor, Color secondaryTextColor) {
    return TextTheme(
      // Displays
      displayLarge: displayLarge.copyWith(color: textColor),
      displayMedium: displayMedium.copyWith(color: textColor),
      displaySmall: displaySmall.copyWith(color: textColor),

      // Headlines
      headlineLarge: headlineLarge.copyWith(color: textColor),
      headlineMedium: headlineMedium.copyWith(color: textColor),
      headlineSmall: headlineSmall.copyWith(color: textColor),

      // Titles
      titleLarge: titleLarge.copyWith(color: textColor),
      titleMedium: titleMedium.copyWith(color: textColor),
      titleSmall: titleSmall.copyWith(color: textColor),

      // Labels
      labelLarge: labelLarge.copyWith(color: textColor),
      labelMedium: labelMedium.copyWith(color: secondaryTextColor),
      labelSmall: labelSmall.copyWith(color: secondaryTextColor),

      // Body
      bodyLarge: bodyLarge.copyWith(color: textColor),
      bodyMedium: bodyMedium.copyWith(color: secondaryTextColor),
      bodySmall: bodySmall.copyWith(color: secondaryTextColor),
    );
  }
}
