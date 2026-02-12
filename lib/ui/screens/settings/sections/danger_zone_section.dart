import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../widgets/settings/settings_group_card.dart';
import '../../../widgets/settings/settings_selection_button.dart';

class DangerZoneSection extends ConsumerWidget {
  const DangerZoneSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return SettingsGroupCard(
      title: l10n.settingsDangerZone.toUpperCase(),
      padding: const EdgeInsets.fromLTRB(12, 20, 12, 12),
      child: IntrinsicHeight(
        child: Row(
          children: [
            SettingsSelectionButton(
              label: l10n.settingsDeleteAccount,
              icon: Icons.delete_forever_rounded,
              isSelected: false,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.settingsDeleteAccountPending),
                    backgroundColor: AppColors.error,
                  ),
                );
              },
            ),
             VerticalDivider(
                width: 1, 
                thickness: 1, 
                color: Theme.of(context).dividerColor.withOpacity(0.1), 
                indent: 6, 
                endIndent: 6,
              ),
            SettingsSelectionButton(
              label: l10n.settingsResetApp,
              icon: Icons.restart_alt_rounded,
              isSelected: false,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.settingsResetAppPending),
                    backgroundColor: AppColors.error,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
