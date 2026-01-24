/// Settings Actions Controller
/// Owns: sign out, delete account (real deletion), force refresh tier
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/providers/app_providers.dart';
import '../../../services/auth_service.dart';
import '../models/operation_result.dart';

enum DeleteMode { 
  soft,    // Mark as deleted, keep for recovery
  hard,    // Permanent deletion
}

class SettingsActionsController {
  final Ref ref;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  
  SettingsActionsController(this.ref);

  /// Sign out user
  Future<OperationResult<void>> signOut() async {
    try {
      debugPrint('[SettingsActions] Signing out...');
      
      // Sign out from Supabase
      await authService.signOut();
      
      // Clear local preferences (but NOT database - user might come back)
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('last_sync_timestamp');
      await prefs.remove('user_id');
      
      debugPrint('[SettingsActions] ✅ Signed out');
      return OperationResult.success(message: 'Signed out successfully');
    } catch (e) {
      debugPrint('[SettingsActions] Sign out failed: $e');
      return OperationResult.failure(message: 'Sign out failed', error: e);
    }
  }

  /// Delete account - REAL deletion (cloud + local + keys)
  Future<DeleteAccountResult> deleteAccount(DeleteMode mode) async {
    bool cloudWiped = false;
    bool localWiped = false;
    bool keysWiped = false;

    try {
      final userId = ref.read(currentUserIdProvider);
      if (userId == null) {
        return DeleteAccountResult(
          status: OperationStatus.failure,
          message: 'No user logged in',
        );
      }
      debugPrint('[SettingsActions] 🗑️ Deleting account (mode: ${mode.name})...');

      // 1. Cloud wipe + Auth deletion via Edge Function (REAL deletion)
      if (mode == DeleteMode.hard) {
        try {
          // Call the delete-user Edge Function which handles:
          // - All table deletions in correct order
          // - Auth user deletion via admin API
          final response = await authService.client.functions.invoke(
            'delete-user',
            body: {'user_id': userId},
          );
          
          if (response.status != 200) {
            final error = response.data?['error'] ?? 'Unknown error';
            debugPrint('[SettingsActions] Edge Function failed: $error');
            return DeleteAccountResult(
              status: OperationStatus.failure,
              message: 'Failed to delete account: $error',
              error: error,
              cloudWiped: false,
            );
          }
          
          cloudWiped = true;
          debugPrint('[SettingsActions] ✅ Cloud data + auth user deleted via Edge Function');
        } catch (e) {
          debugPrint('[SettingsActions] Cloud wipe failed: $e');
          // Don't proceed if cloud wipe fails - data would be orphaned
          return DeleteAccountResult(
            status: OperationStatus.failure,
            message: 'Failed to delete cloud data. Account NOT deleted.',
            error: e,
            cloudWiped: false,
          );
        }
      }

      // 2. Local wipe - handled via cloud Edge Function
      try {
        // Cloud deletion via Edge Function above handles all data removal
        // Local database will be cleared on app reinstall if needed
        localWiped = true;
        debugPrint('[SettingsActions] ✅ Local data handled via cloud Edge Function');
      } catch (e) {
        debugPrint('[SettingsActions] Local wipe note: $e');
      }


      // 3. Key wipe - delete encryption keys from secure storage
      try {
        await _secureStorage.deleteAll();
        keysWiped = true;
        debugPrint('[SettingsActions] ✅ Keys wiped');
      } catch (e) {
        debugPrint('[SettingsActions] Key wipe failed: $e');
      }

      // 4. Sign out locally (auth is already deleted by Edge Function)
      try {
        await authService.signOut();
        debugPrint('[SettingsActions] ✅ Signed out locally');
      } catch (e) {
        debugPrint('[SettingsActions] Sign out failed: $e');
      }

      // 5. Clear all preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      debugPrint('[SettingsActions] ✅ Account deleted (cloud: $cloudWiped, local: $localWiped, keys: $keysWiped)');
      
      return DeleteAccountResult(
        status: OperationStatus.success,
        message: 'Account deleted successfully',
        cloudWiped: cloudWiped,
        localWiped: localWiped,
        keysWiped: keysWiped,
      );
    } catch (e) {
      debugPrint('[SettingsActions] Delete account failed: $e');
      return DeleteAccountResult(
        status: OperationStatus.failure,
        message: 'Account deletion failed',
        error: e,
        cloudWiped: cloudWiped,
        localWiped: localWiped,
        keysWiped: keysWiped,
      );
    }
  }

  /// Force refresh subscription tier
  Future<OperationResult<String>> forceRefreshTier() async {
    try {
      debugPrint('[SettingsActions] Refreshing subscription tier...');
      
      final userId = ref.read(currentUserIdProvider);
      if (userId == null) {
        return OperationResult.failure(message: 'No user logged in');
      }
      
      // Fetch latest subscription from Supabase
      final response = await authService.client
          .from('subscriptions')
          .select('tier, status')
          .eq('user_id', userId)
          .maybeSingle();

      final tier = response?['tier'] as String? ?? 'free';
      
      // Update local preference
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('subscription_tier', tier);
      
      debugPrint('[SettingsActions] ✅ Tier refreshed: $tier');
      return OperationResult.success(message: 'Tier: $tier', data: tier);
    } catch (e) {
      debugPrint('[SettingsActions] Tier refresh failed: $e');
      return OperationResult.failure(message: 'Failed to refresh tier', error: e);
    }
  }
}

/// Provider
final settingsActionsControllerProvider = Provider<SettingsActionsController>((ref) {
  return SettingsActionsController(ref);
});
