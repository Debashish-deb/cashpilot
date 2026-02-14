import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../features/auth/providers/auth_provider.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../services/auth_service.dart';
import '../../../widgets/settings/settings_group_card.dart';
import '../../../widgets/settings/settings_selection_button.dart';

class DangerZoneSection extends ConsumerWidget {
  const DangerZoneSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return SettingsGroupCard(
      title: 'Danger Zone', // Fallback as specific danger group key is missing
      child: Column(
        children: [
          Row(
            children: [
              SettingsSelectionButton(
                label: l10n.settingsResetApp,
                icon: Icons.delete_sweep_rounded,
                isSelected: false,
                onTap: () => _showConfirmWipe(context, ref),
              ),
              const VerticalDivider(width: 1),
              SettingsSelectionButton(
                label: l10n.settingsDeleteAccount,
                icon: Icons.person_remove_rounded,
                isSelected: false,
                onTap: () => _showConfirmDeleteAccount(context, ref),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showConfirmWipe(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.settingsResetApp),
        content: const Text(
          'This will permanently delete all your financial data from this device and the cloud. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Wipe Everything'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final db = ref.read(databaseProvider);
      await db.markAllUserDataDeleted();
      await authService.signOut();
    }
  }

  Future<void> _showConfirmDeleteAccount(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    
    // Step 1: Broad confirmation
    final confirmed1 = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.settingsDeleteAccount),
        content: const Text(
          'Are you absolutely sure? This will delete your profile, subscription, and all data forever.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );

    if (confirmed1 != true) return;

    // Step 2: Final confirmation (safety check)
    if (!context.mounted) return;
    final confirmed2 = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Final Confirmation'),
        content: const Text(
          'Type "DELETE" to confirm account destruction.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.commonCancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );

    if (confirmed2 == true) {
      final db = ref.read(databaseProvider);
      await authService.deleteAccount(
        onPreDelete: () => db.markAllUserDataDeleted(),
      );
    }
  }
}
