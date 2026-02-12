import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../l10n/app_localizations.dart';

import '../../../../services/sync_engine.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../features/settings/providers/app_settings_provider.dart';
import '../../../widgets/settings/settings_group_card.dart';
import '../../../widgets/settings/settings_selection_button.dart';


class SyncSection extends ConsumerWidget {
  const SyncSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    final syncStatus = ref.watch(syncStatusProvider);
    final isSyncing = syncStatus.status == SyncStatus.syncing;
    
    final cloudSyncEnabled = ref.watch(cloudSyncEnabledProvider);
    final performanceMode = ref.watch(appSettingsProvider).performanceMode;

    return SettingsGroupCard(
      title: l10n.settingsSystemControl.toUpperCase(),
      padding: const EdgeInsets.fromLTRB(12, 20, 12, 12),
      child: Column(
        children: [
          IntrinsicHeight(
            child: Row(
              children: [
                SettingsSelectionButton(
                  label: l10n.settingsCloudSync,
                  icon: Icons.cloud_sync_rounded,
                  isSelected: cloudSyncEnabled,
                  onTap: () => ref
                      .read(cloudSyncEnabledProvider.notifier)
                      .setEnabled(!cloudSyncEnabled),
                ),
                VerticalDivider(
                  width: 1, 
                  thickness: 1, 
                  color: Theme.of(context).dividerColor.withOpacity(0.1), 
                  indent: 6, 
                  endIndent: 6,
                ),
                SettingsSelectionButton(
                  label: l10n.settingsHighPerformanceMode,
                  icon: Icons.speed_rounded,
                  isSelected: performanceMode,
                  onTap: () => ref
                      .read(appSettingsProvider.notifier)
                      .togglePerformanceMode(!performanceMode),
                ),
              ],
            ),
          ),
          Divider(
             height: 1,
             thickness: 1,
             color: Theme.of(context).dividerColor.withOpacity(0.1),
             indent: 16,
             endIndent: 16,
          ),
          IntrinsicHeight(
            child: Row(
               children: [
                 SettingsSelectionButton(
                  label: isSyncing ? "Syncing..." : l10n.settingsForceSync,
                  icon: isSyncing ? Icons.refresh_rounded : Icons.sync_rounded, // Animating this might be complex in this widget, simplifying
                  isSelected: false, // Action button
                  onTap: isSyncing
                      ? () {}
                      : () async {
                           await ref.read(syncEngineProvider).performSync();
                        },
                ),
                 // Add spacer or empty box to fill row if desired, or just let it take full width?
                 // SettingsSelectionButton is Expanded. So one button in a Row takes full width.
                 // That's actually okay for "Force Sync", giving it prominence as a big action bar.
               ],
            ),
          ),
        ],
      ),
    );
  }
}
