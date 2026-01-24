import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/app_localizations.dart';
import '../settings_tiles.dart';

class DangerZoneSection extends ConsumerWidget {
  const DangerZoneSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(
            'Danger Zone',
            style: AppTypography.titleSmall.copyWith(
              color: AppColors.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Card(
          elevation: 0,
          color: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: AppColors.error.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            children: [
              SettingsTile(
                icon: Icons.delete_forever_outlined,
                title: 'Delete Account',
                subtitle: 'Permanently delete your data',
                iconColor: AppColors.error,
                onTap: () {
                  // Show delete confirmation dialog
                  // For now, this is a placeholder for the logic in the main controller
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Delete Account functionality pending migration')),
                  );
                },
              ),
              const Divider(height: 1, indent: 56),
              SettingsTile(
                icon: Icons.restart_alt_rounded,
                title: 'Reset App',
                subtitle: 'Clear local data and cache',
                iconColor: AppColors.error,
                onTap: () {
                  // Show reset confirmation
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Reset App functionality pending migration')),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
