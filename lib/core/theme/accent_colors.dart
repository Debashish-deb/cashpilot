/// Accent Color Provider — Cross-Platform Premium Edition
/// Apple-polished + Material-accurate accent colors
library;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/app_providers.dart';

// =============================================================================
// ACCENT COLOR OPTIONS (unchanged enum)
// =============================================================================

enum AccentColorOption {
  emerald,   // Green - Finance default
  ocean,     // Blue - Universal trust
  coral,     // Red - Bold energy
  amber,     // Orange - Warm optimism
  violet,    // Purple - Premium modern
  slate,     // Gray - Professional timeless
}

// =============================================================================
// PREMIUM FINTECH ACCENT COLORS
// Tuned for: iOS Apple HIG + Android M3 + Finance UI
// =============================================================================

class AccentColorConfig {
  final String name;
  final String displayName;
  final Color primary;
  final Color light;
  final Color dark;
  final Color onPrimary;

  const AccentColorConfig({
    required this.name,
    required this.displayName,
    required this.primary,
    required this.light,
    required this.dark,
    required this.onPrimary,
  });

  // ===== SMART TEXT COLORS =====
  
  /// Text color for use on primary background (same as onPrimary)
  Color get textOnPrimary => onPrimary;
  
  /// Muted text color for subtitles on primary background
  Color get textOnPrimaryMuted => onPrimary.withValues(alpha: 0.7);
  
  /// Very subtle text for tertiary content
  Color get textOnPrimarySubtle => onPrimary.withValues(alpha: 0.5);
  
  /// Icon color on primary background
  Color get iconOnPrimary => onPrimary.withValues(alpha: 0.9);
  
  /// Border color for elements on primary background
  Color get borderOnPrimary => onPrimary.withValues(alpha: 0.2);
  
  /// Background overlay for chips/badges on primary
  Color get chipBackgroundOnPrimary => onPrimary.withValues(alpha: 0.2);
  
  /// Determine if the primary color is "light" (needs dark text)
  bool get isLightAccent => primary.computeLuminance() > 0.5;
  
  /// Get contrast color dynamically computed from luminance
  static Color computeContrastColor(Color background) {
    return background.computeLuminance() > 0.5 
        ? Colors.black 
        : Colors.white;
  }
  
  /// Get muted contrast color
  static Color computeMutedContrastColor(Color background) {
    final base = computeContrastColor(background);
    return base.withValues(alpha: 0.7);
  }

  LinearGradient get gradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [light, primary],
      );

  LinearGradient get subtleGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          primary.withValues(alpha: 0.08),
          primary.withValues(alpha: 0.03),
        ],
      );
}

// =============================================================================
// CROSS-PLATFORM PREMIUM COLOR PRESETS
// =============================================================================

class AccentColors {
  static const Map<AccentColorOption, AccentColorConfig> presets = {
    // ===== GREEN (Primary finance color)
    AccentColorOption.emerald: AccentColorConfig(
      name: 'emerald',
      displayName: 'Emerald',
      primary: Color(0xFF1F9E63),
      light: Color(0xFF48C98C),
      dark: Color(0xFF0C7A4A),
      onPrimary: Colors.white,
    ),

    // ===== BLUE (Universal, trusted)
    AccentColorOption.ocean: AccentColorConfig(
      name: 'ocean',
      displayName: 'Ocean',
      primary: Color(0xFF2E8FEF),
      light: Color(0xFF6AB4FF),
      dark: Color(0xFF0C64C7),
      onPrimary: Colors.white,
    ),

    // ===== RED (Muted — not neon)
    AccentColorOption.coral: AccentColorConfig(
      name: 'coral',
      displayName: 'Coral',
      primary: Color(0xFFE35A4A),
      light: Color(0xFFF38A7B),
      dark: Color(0xFFB2382F),
      onPrimary: Colors.white,
    ),

    // ===== ORANGE (Warm, not cartoonish)
    AccentColorOption.amber: AccentColorConfig(
      name: 'amber',
      displayName: 'Amber',
      primary: Color(0xFFF5A623),
      light: Color(0xFFFFC766),
      dark: Color(0xFFCC7B12),
      onPrimary: Colors.black,
    ),

    // ===== INDIGO (Apple-ish, premium)
    AccentColorOption.violet: AccentColorConfig(
      name: 'violet',
      displayName: 'Violet',
      primary: Color(0xFF5C6CFF),
      light: Color(0xFFA4ADFF),
      dark: Color(0xFF3644D1),
      onPrimary: Colors.white,
    ),

    // ===== SLATE (Professional, monochrome)
    AccentColorOption.slate: AccentColorConfig(
      name: 'slate',
      displayName: 'Slate',
      primary: Color(0xFF4A4F57),
      light: Color(0xFF767B84),
      dark: Color(0xFF2E3237),
      onPrimary: Colors.white,
    ),
  };

  static AccentColorConfig getConfig(AccentColorOption option) {
    return presets[option]!;
  }

  static AccentColorConfig getConfigByName(String name) {
    final option = AccentColorOption.values.firstWhere(
      (o) => o.name == name,
      orElse: () => AccentColorOption.emerald,
    );
    return getConfig(option);
  }

  static List<AccentColorConfig> get allOptions =>
      AccentColorOption.values.map((o) => getConfig(o)).toList();
}

// =============================================================================
// PROVIDERS (unchanged logic)
// =============================================================================



class AccentColorNotifier extends StateNotifier<AccentColorOption> {
  final SharedPreferences _prefs;
  static const _key = 'accent_color';

  AccentColorNotifier(this._prefs) : super(_loadInitial(_prefs));

  static AccentColorOption _loadInitial(SharedPreferences prefs) {
    final saved = prefs.getString(_key);
    if (saved == null) return AccentColorOption.emerald;

    // Migration map for deprecated colors
    const migrationMap = {
      'lavender': 'violet',   // Similar purple → brighter violet
      'rose': 'coral',        // Similar warm → coral
      'teal': 'ocean',        // Similar cool blue → ocean
      'mint': 'ocean',        // Similar cyan → ocean
      'midnight': 'ocean',    // Same blue family → ocean
    };

    // Check if color was removed and migrate
    final migratedName = migrationMap[saved] ?? saved;

    return AccentColorOption.values.firstWhere(
      (o) => o.name == migratedName,
      orElse: () => AccentColorOption.emerald,
    );
  }

  Future<void> setAccentColor(AccentColorOption option) async {
    if (state == option) return;
    state = option;
    await _prefs.setString(_key, option.name);
  }

  /// Manual refresh from SharedPreferences
  void refreshFromPrefs() {
    final option = _loadInitial(_prefs);
    if (state != option) {
      state = option;
    }
  }

  AccentColorConfig get currentConfig => AccentColors.getConfig(state);

}

final accentColorProvider =
    StateNotifierProvider<AccentColorNotifier, AccentColorOption>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return AccentColorNotifier(prefs);
});

final accentConfigProvider = Provider<AccentColorConfig>((ref) {
  final option = ref.watch(accentColorProvider);
  return AccentColors.getConfig(option);
});

// =============================================================================
// UI EXTENSIONS
// =============================================================================

extension AccentColorExtension on WidgetRef {
  Color get accentPrimary => watch(accentConfigProvider).primary;
  Color get accentLight => watch(accentConfigProvider).light;
  Color get accentDark => watch(accentConfigProvider).dark;
  LinearGradient get accentGradient => watch(accentConfigProvider).gradient;
}
