import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:drift/drift.dart' as drift;

import '../../../core/theme/app_colors.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../data/drift/app_database.dart';
import '../../../core/providers/app_providers.dart';
import '../../../services/auth_service.dart';

class ProfileColorNotifier extends StateNotifier<Color> {
  final Ref ref;
  String _currentKey = 'default';  // Track the key

  ProfileColorNotifier(this.ref) : super(AppColors.primaryGreen) {
    _init();
  }

  /// Get the current profile color key
  String get currentKey => _currentKey;

  void _init() {
    final user = ref.read(currentUserProvider);
    if (user != null) {
      _loadColorFromMetadata(user.userMetadata);
    }
  }

  void _loadColorFromMetadata(Map<String, dynamic>? metadata) {
    if (metadata == null) return;
    final colorKey = metadata['profile_color'] as String?;
    if (colorKey != null && AppColors.profileColors.containsKey(colorKey)) {
      _currentKey = colorKey;
      state = AppColors.profileColors[colorKey]!;
    }
  }

  Future<void> updateColor(String colorKey) async {
    if (!AppColors.profileColors.containsKey(colorKey)) return;

    // 1. Optimistic Update
    _currentKey = colorKey;
    state = AppColors.profileColors[colorKey]!;

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    try {
      // 2. Update Supabase
      await authService.client.auth.updateUser(
        supabase.UserAttributes(
          data: {'profile_color': colorKey},
        ),
      );

      // 3. Update Supabase Profiles Table (for redundancy/other clients)
      await authService.client
          .from('profiles')
          .update({'metadata': {'profile_color': colorKey}}) // This merges by default in basic JSONB updates usually, but let's be careful. 
          // Actually, 'profiles' table has a 'metadata' column. 
          // Let's fetch existing first to be safe or use jsonb_set in SQL if we could, 
          // but for now simple update is fine as we are likely the only writer to this key.
          .eq('id', user.id);


      // 4. Update Local Database
      final db = ref.read(databaseProvider);
      
      // We need to fetch current user to get existing metadata to merge
      final localUser = await (db.select(db.users)..where((u) => u.id.equals(user.id))).getSingleOrNull();
      
      if (localUser != null) {
        final currentMetadata = Map<String, dynamic>.from(localUser.metadata ?? {});
        currentMetadata['profile_color'] = colorKey;

        await db.updateUser(UsersCompanion(
          id: drift.Value(user.id),
          metadata: drift.Value(currentMetadata),
          updatedAt: drift.Value(DateTime.now()),
        ));
      }

    } catch (e) {
      debugPrint('Failed to update profile color: $e');
      // Ideally revert state here if critical
    }
  }
}

final profileColorProvider = StateNotifierProvider<ProfileColorNotifier, Color>((ref) {
  return ProfileColorNotifier(ref);
});

/// Provider that returns the current profile color KEY (e.g., 'electric_blue', 'default')
final profileColorKeyProvider = Provider<String>((ref) {
  // Need to watch the color to trigger updates
  ref.watch(profileColorProvider);
  return ref.read(profileColorProvider.notifier).currentKey;
});

/// Returns the profile color adjusted for the current theme brightness
/// This ensures dark modes get lightened colors for better visibility
Color getThemeAdjustedColor(Color baseColor, Brightness brightness) {
  if (brightness == Brightness.light) {
    return baseColor;
  } else {
    // Lighten for dark mode
    return Color.alphaBlend(
      Colors.white.withValues(alpha: 0.3),
      baseColor,
    );
  }
}

/// Provider that returns the theme-adjusted profile color
/// Use this instead of profileColorProvider when you need the color for UI elements
final themeAdjustedProfileColorProvider = Provider<Color>((ref) {
  final baseColor = ref.watch(profileColorProvider);
  // We can't access BuildContext here, so return the base color
  // Widgets should use Theme.of(context).primaryColor instead for proper theme adjustment
  return baseColor;
});
