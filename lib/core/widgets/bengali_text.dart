/// Bengali Typography Helper
/// Provides styled Text widgets for Bengali numerals with proper sizing
library;

import 'package:flutter/material.dart';
import '../theme/app_typography.dart';

/// Helper class for displaying Bengali numbers with proper typography
class BengaliText {
  // ------------------------------------------------------------
  // MONEY STYLES
  // ------------------------------------------------------------

  /// Display Bengali currency with large money style
  static Widget moneyLarge(
    String bengaliText, {
    Color? color,
    TextAlign? textAlign,
  }) {
    return _build(
      bengaliText,
      style: AppTypography.bengaliMoneyLarge,
      color: color,
      textAlign: textAlign,
    );
  }

  /// Display Bengali currency with medium money style
  static Widget moneyMedium(
    String bengaliText, {
    Color? color,
    TextAlign? textAlign,
  }) {
    return _build(
      bengaliText,
      style: AppTypography.bengaliMoneyMedium,
      color: color,
      textAlign: textAlign,
    );
  }

  /// Display Bengali currency with small money style
  static Widget moneySmall(
    String bengaliText, {
    Color? color,
    TextAlign? textAlign,
  }) {
    return _build(
      bengaliText,
      style: AppTypography.bengaliMoneySmall,
      color: color,
      textAlign: textAlign,
    );
  }

  // ------------------------------------------------------------
  // NUMBER STYLE
  // ------------------------------------------------------------

  /// Display Bengali number with standard style
  static Widget number(
    String bengaliText, {
    Color? color,
    TextAlign? textAlign,
  }) {
    return _build(
      bengaliText,
      style: AppTypography.bengaliNumber,
      color: color,
      textAlign: textAlign,
    );
  }

  // ------------------------------------------------------------
  // STYLE RESOLVER
  // ------------------------------------------------------------

  /// Get the appropriate money style based on context
  static TextStyle getMoneyStyle({
    bool large = false,
    bool small = false,
  }) {
    if (large) return AppTypography.bengaliMoneyLarge;
    if (small) return AppTypography.bengaliMoneySmall;
    return AppTypography.bengaliMoneyMedium;
  }

  // ------------------------------------------------------------
  // INTERNAL BUILDER (NON-BREAKING)
  // ------------------------------------------------------------

  static Widget _build(
    String text, {
    required TextStyle style,
    Color? color,
    TextAlign? textAlign,
  }) {
    return Text(
      text,
      style: style.copyWith(color: color),
      textAlign: textAlign,
      textScaleFactor: WidgetsBinding.instance.platformDispatcher.textScaleFactor,
      maxLines: 1,
      overflow: TextOverflow.visible,
    );
  }
}
