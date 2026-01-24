/// Default expense categories with icons and colors
/// Production-grade category system
library;

import 'dart:math';
import 'package:flutter/material.dart';

class CategoryDefaults {
  static const List<DefaultCategory> categories = [
    DefaultCategory(
      name: 'Groceries',
      nameKey: 'category_groceries',
      group: CategoryGroup.needs,
      icon: Icons.local_grocery_store_outlined,
      iosIcon: 'cart',
      color: Color(0xFF2E7D32),
      accentColor: Color(0xFF81C784),
    ),
    DefaultCategory(
      name: 'Transport',
      nameKey: 'category_transport',
      group: CategoryGroup.needs,
      icon: Icons.directions_transit_outlined,
      iosIcon: 'car',
      color: Color(0xFF1565C0),
      accentColor: Color(0xFF90CAF9),
    ),
    DefaultCategory(
      name: 'Eating Out',
      nameKey: 'category_eating_out',
      group: CategoryGroup.wants,
      icon: Icons.restaurant_menu_outlined,
      iosIcon: 'fork.knife',
      color: Color(0xFFEF6C00),
      accentColor: Color(0xFFFFCC80),
    ),
    DefaultCategory(
      name: 'Entertainment',
      nameKey: 'category_entertainment',
      group: CategoryGroup.wants,
      icon: Icons.theaters_outlined,
      iosIcon: 'play.rectangle',
      color: Color(0xFF6A1B9A),
      accentColor: Color(0xFFCE93D8),
    ),
    DefaultCategory(
      name: 'Shopping',
      nameKey: 'category_shopping',
      group: CategoryGroup.wants,
      icon: Icons.shopping_bag_outlined,
      iosIcon: 'bag',
      color: Color(0xFFC2185B),
      accentColor: Color(0xFFF48FB1),
    ),
    DefaultCategory(
      name: 'Healthcare',
      nameKey: 'category_healthcare',
      group: CategoryGroup.needs,
      icon: Icons.medical_services_outlined,
      iosIcon: 'cross.case',
      color: Color(0xFFD32F2F),
      accentColor: Color(0xFFEF9A9A),
    ),
    DefaultCategory(
      name: 'Utilities',
      nameKey: 'category_utilities',
      group: CategoryGroup.needs,
      icon: Icons.power_outlined,
      iosIcon: 'bolt',
      color: Color(0xFFF9A825),
      accentColor: Color(0xFFFFF59D),
    ),
    DefaultCategory(
      name: 'Subscriptions',
      nameKey: 'category_subscriptions',
      group: CategoryGroup.wants,
      icon: Icons.autorenew_outlined,
      iosIcon: 'repeat',
      color: Color(0xFF00838F),
      accentColor: Color(0xFF80DEEA),
    ),
    DefaultCategory(
      name: 'Savings',
      nameKey: 'category_savings',
      group: CategoryGroup.needs,
      icon: Icons.account_balance_wallet_outlined,
      iosIcon: 'wallet.pass',
      color: Color(0xFF1E9E63),
      accentColor: Color(0xFF66E2B4),
    ),
    DefaultCategory(
      name: 'Other',
      nameKey: 'category_other',
      group: CategoryGroup.other,
      icon: Icons.more_horiz_rounded,
      iosIcon: 'ellipsis',
      color: Color(0xFF9E9E9E),
      accentColor: Color(0xFFBDBDBD),
    ),
  ];

  // ---------------------------------------------------------------------------
  // EXISTING API (unchanged)
  // ---------------------------------------------------------------------------

  static DefaultCategory getCategoryByName(String name) {
    return categories.firstWhere(
      (c) => c.name.toLowerCase() == name.toLowerCase(),
      orElse: () => categories.last,
    );
  }

  static Color getColorForCategory(String name, {Brightness? brightness}) {
    return getCategoryByName(name).resolveColor(brightness);
  }

  static IconData getIconForCategory(String name) {
    return getCategoryByName(name).icon;
  }

  // ---------------------------------------------------------------------------
  // NEW CAPABILITIES
  // ---------------------------------------------------------------------------

  /// For gradient backgrounds
  static List<Color> getGradient(String name, {Brightness? brightness}) {
    final c = getCategoryByName(name);
    return [
      c.resolveColor(brightness),
      c.resolveAccentColor(brightness),
    ];
  }

  /// Chart-safe deterministic color
  static Color getChartColor(String name, {Brightness? brightness}) {
    final base = getCategoryByName(name).resolveColor(brightness);
    return _desaturate(base, 0.15);
  }

  /// Group filtering
  static List<DefaultCategory> byGroup(CategoryGroup group) {
    return categories.where((c) => c.group == group).toList();
  }

  /// Needs vs Wants split
  static List<DefaultCategory> get needs =>
      byGroup(CategoryGroup.needs);

  static List<DefaultCategory> get wants =>
      byGroup(CategoryGroup.wants);

  // ---------------------------------------------------------------------------
  // INTERNAL HELPERS
  // ---------------------------------------------------------------------------

  static Color _desaturate(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withSaturation(max(0, hsl.saturation - amount))
        .toColor();
  }
}

// =============================================================================
// MODELS
// =============================================================================

class DefaultCategory {
  final String name;
  final String nameKey;
  final CategoryGroup group;

  /// Android / Material icon
  final IconData icon;

  /// iOS SF Symbol name (for Cupertino)
  final String iosIcon;

  /// Primary color
  final Color color;

  /// Secondary accent color (for gradients)
  final Color accentColor;

  const DefaultCategory({
    required this.name,
    required this.nameKey,
    required this.group,
    required this.icon,
    required this.iosIcon,
    required this.color,
    required this.accentColor,
  });

  /// Light/Dark adaptive primary color
  Color resolveColor(Brightness? brightness) {
    if (brightness == Brightness.dark) {
      return _adjustForDark(color);
    }
    return color;
  }

  /// Light/Dark adaptive accent color
  Color resolveAccentColor(Brightness? brightness) {
    if (brightness == Brightness.dark) {
      return _adjustForDark(accentColor);
    }
    return accentColor;
  }

  Color _adjustForDark(Color c) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withLightness(min(0.75, hsl.lightness + 0.15)).toColor();
  }
}

// =============================================================================
// ENUMS
// =============================================================================

enum CategoryGroup {
  needs,
  wants,
  other,
}
