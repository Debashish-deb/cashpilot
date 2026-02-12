import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cashpilot/l10n/app_localizations.dart';

import 'sections/danger_zone_section.dart';
import 'settings_tiles.dart';

import '../../../../services/sync_engine.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/user_mode_provider.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../features/settings/providers/app_settings_provider.dart';

class AdvancedSettingsScreen extends ConsumerWidget {
  const AdvancedSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsTabAdvanced),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: const [
          _SyncControlSection(),
          SizedBox(height: 32),
          DangerZoneSection(),
          SizedBox(height: 32),
        ],
      ),
    );
  }
}

// =============================================================================
// SYNC / SYSTEM CONTROL SECTION
// =============================================================================

class _SyncControlSection extends ConsumerWidget {
  const _SyncControlSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    final syncStatus = ref.watch(syncStatusProvider);
    final isSyncing = syncStatus.status == SyncStatus.syncing;

    final userMode = ref.watch(userModeProvider);
    final isExpert = userMode == UserMode.expert;

    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ------------------------------------------------------------------
          // SECTION TITLE
          // ------------------------------------------------------------------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              l10n.settingsSystemControl.toUpperCase(),
              style: AppTypography.titleSmall.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ------------------------------------------------------------------
          // CONTENT CONTAINER
          // ------------------------------------------------------------------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).dividerColor.withOpacity(0.15),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    // ----------------------------------------------------------
                    // CLOUD SYNC
                    // ----------------------------------------------------------
                    SettingsTile(
                      isFullWidth: true,
                      icon: Icons.cloud_sync_rounded,
                      title: l10n.settingsCloudSync,
                      extraContent: Switch(
                        value: ref.watch(cloudSyncEnabledProvider),
                        onChanged: (val) => ref
                            .read(cloudSyncEnabledProvider.notifier)
                            .state = val,
                      ),
                      onTap: () {
                        final current =
                            ref.read(cloudSyncEnabledProvider);
                        ref
                            .read(cloudSyncEnabledProvider.notifier)
                            .state = !current;
                      },
                    ),

                    const SizedBox(height: 12),

                    // ----------------------------------------------------------
                    // FORCE FULL SYNC
                    // ----------------------------------------------------------
                    SettingsTile(
                      isFullWidth: true,
                      icon: Icons.sync_rounded,
                      title: l10n.settingsForceSync,
                      trailing: isSyncing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh_rounded, size: 18),
                      onTap: isSyncing
                          ? null
                          : () async {
                              await ref
                                  .read(syncEngineProvider)
                                  .performSync();
                            },
                    ),

                    const SizedBox(height: 12),

                    // ----------------------------------------------------------
                    // PERFORMANCE MODE
                    // ----------------------------------------------------------
                    SettingsTile(
                      isFullWidth: true,
                      icon: Icons.speed_rounded,
                      title: l10n.settingsHighPerformanceMode,
                      extraContent: Switch(
                        value: ref
                            .watch(appSettingsProvider)
                            .performanceMode,
                        onChanged: (value) => ref
                            .read(appSettingsProvider.notifier)
                            .togglePerformanceMode(value),
                        activeThumbColor:
                            Theme.of(context).primaryColor,
                      ),
                      onTap: () {
                        final current = ref
                            .read(appSettingsProvider)
                            .performanceMode;
                        ref
                            .read(appSettingsProvider.notifier)
                            .togglePerformanceMode(!current);
                      },
                    ),

                    const SizedBox(height: 12),

                    // ----------------------------------------------------------
                    // EXPERIENCE MODE
                    // ----------------------------------------------------------
                    SettingsTile(
                      isFullWidth: true,
                      icon: isExpert
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      iconColor:
                          isExpert ? AppColors.primaryGold : null,
                      title: l10n.settingsExperienceMode,
                      extraContent: Switch(
                        value: isExpert,
                        onChanged: (_) => ref
                            .read(userModeProvider.notifier)
                            .toggleMode(),
                        activeThumbColor: AppColors.primaryGold,
                      ),
                      onTap: () =>
                          ref.read(userModeProvider.notifier).toggleMode(),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ------------------------------------------------------------------
          // ERROR STATE
          // ------------------------------------------------------------------
          if (syncStatus.status == SyncStatus.error &&
              syncStatus.message != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                l10n.commonErrorMessage(syncStatus.message!),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
