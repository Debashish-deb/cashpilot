import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/constants/subscription.dart';
import '../../../../features/subscription/providers/subscription_providers.dart';
import '../../../../l10n/app_localizations.dart';
import '../settings_tiles.dart';
import '../../../widgets/common/enhanced_widgets.dart';

class DataSyncSection extends ConsumerWidget {
  const DataSyncSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final syncEnabled = ref.watch(cloudSyncEnabledProvider);
    final canUseCloudSync = ref.watch(canUseFeatureProvider(Feature.cloudSync));
    final isFree = ref.watch(isFreeProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(
            l10n.settingsData, // Use settingsData instead of settingsDataSync
            style: AppTypography.titleSmall.copyWith(
              color: Theme.of(context).primaryColor,
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
              color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
            ),
          ),
          child: Column(
            children: [
              SettingsTile(
                icon: Icons.cloud_sync_outlined,
                title: l10n.settingsCloudSync,
                subtitle: syncEnabled ? 'On' : 'Off', // Hardcode On/Off
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isFree) const FeatureBadge(),
                    Switch(
                      value: syncEnabled,
                      onChanged: (value) {
                        if (value && !canUseCloudSync) {
                          context.push(AppRoutes.paywall);
                        } else {
                          ref.read(cloudSyncEnabledProvider.notifier).state = value;
                        }
                      },
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, indent: 56),
              SettingsTile(
                icon: Icons.backup_outlined,
                title: l10n.settingsBackup, // Use settingsBackup
                subtitle: 'Import, export, and manage data', // Hardcoded
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isFree) const FeatureBadge(),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                    ),
                  ],
                ),
                onTap: () {
                  if (!isFree) {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const _PlaceholderBackupScreen()),
                    );
                  } else {
                    context.push(AppRoutes.paywall);
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Temporary placeholder until we verify where RestoreScreen is imported from
class _PlaceholderBackupScreen extends StatelessWidget {
  const _PlaceholderBackupScreen();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Backup & Restore')),
      body: const Center(child: Text('Backup Restore functionality migrated to Advanced Tab')),
    );
  }
}
