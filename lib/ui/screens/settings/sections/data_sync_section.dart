import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/subscription.dart';
import '../../../../features/subscription/providers/subscription_providers.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../features/settings/screens/backup_restore_screen.dart';
import '../../../../features/banking/providers/bank_connectivity_provider.dart';

import '../../../widgets/settings/settings_group_card.dart';
import '../../../widgets/settings/settings_selection_button.dart';


class DataSyncSection extends ConsumerWidget {
  const DataSyncSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    
    final l10n = AppLocalizations.of(context)!;
    final isFree = ref.watch(isFreeProvider);
    final bankingEnabled = ref.watch(bankConnectivityEnabledProvider);

    return SettingsGroupCard(
      title: l10n.settingsTabDataSync.toUpperCase(),
      padding: const EdgeInsets.fromLTRB(12, 20, 12, 12),
      child: Column(
        children: [
          IntrinsicHeight(
            child: Row(
               children: [
                 SettingsSelectionButton(
                   label: l10n.settingsBankConnectivity,
                   icon: Icons.account_balance_outlined,
                   isSelected: bankingEnabled,
                   onTap: () => ref
                      .read(bankConnectivityEnabledProvider.notifier)
                      .toggle(!bankingEnabled),
                 ),
                 VerticalDivider(
                  width: 1, 
                  thickness: 1, 
                  color: Theme.of(context).dividerColor.withOpacity(0.1), 
                  indent: 6, 
                  endIndent: 6,
                ),
                if (bankingEnabled)
                  SettingsSelectionButton(
                     label: l10n.settingsManageConnections,
                     icon: Icons.link_rounded,
                     isSelected: false,
                     onTap: () => context.push(AppRoutes.bankAccounts),
                  )
                else
                   // Placeholder to keep grid aligned if we want, or just let first item expand
                   // If first item expands, it takes full width which might be nice to emphasize "Connect Bank"
                   // But for consistency let's fill with Backup if not enabled?
                   // "If OFF: Row(Bank Connect (OFF) | Backup)"
                   SettingsSelectionButton(
                     label: l10n.settingsBackupRestore,
                     icon: Icons.backup_rounded,
                     isSelected: false,
                     showLock: isFree,
                     onTap: () {
                        if (!isFree) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const BackupRestoreScreen(),
                            ),
                          );
                        } else {
                          context.push(AppRoutes.paywall);
                        }
                     },
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
                 if (bankingEnabled) ...[
                   // If enabled, Backup was pushed down
                   SettingsSelectionButton(
                     label: l10n.settingsBackupRestore,
                     icon: Icons.backup_rounded,
                     isSelected: false,
                     showLock: isFree,
                     onTap: () {
                        if (!isFree) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const BackupRestoreScreen(),
                            ),
                          );
                        } else {
                          context.push(AppRoutes.paywall);
                        }
                     },
                   ),
                   VerticalDivider(
                    width: 1, 
                    thickness: 1, 
                    color: Theme.of(context).dividerColor.withOpacity(0.1), 
                    indent: 6, 
                    endIndent: 6,
                   ),
                 ] else ...[
                   // If disabled, Backup is up top. What goes here?
                   // Export | Knowledge
                   // We need Export here
                 ],
                 
                 SettingsSelectionButton(
                   label: l10n.settingsExportData,
                   icon: Icons.ios_share_rounded,
                   isSelected: false,
                   showLock: isFree,
                   onTap: () {
                      final canExport = ref.read(
                        canUseFeatureProvider(
                          Feature.fullDataExport,
                        ),
                      );
                      if (canExport) {
                        context.push(AppRoutes.export);
                      } else {
                        context.push(AppRoutes.paywall);
                      }
                   },
                 ),
                 
                 if (!bankingEnabled) ...[
                   VerticalDivider(
                    width: 1, 
                    thickness: 1, 
                    color: Theme.of(context).dividerColor.withOpacity(0.1), 
                    indent: 6, 
                    endIndent: 6,
                   ),
                    SettingsSelectionButton(
                     label: l10n.settingsKnowledgeBase,
                     icon: Icons.school_rounded,
                     isSelected: false,
                     onTap: () => context.push(AppRoutes.knowledge),
                   ),
                 ]
               ],
             ),
          ),
          if (bankingEnabled) ...[
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
                     label: l10n.settingsKnowledgeBase,
                     icon: Icons.school_rounded,
                     isSelected: false,
                     onTap: () => context.push(AppRoutes.knowledge),
                   ),
                   // Empty spacer to maintain left alignment or fill width? 
                   // Fill width is fine.
                 ],
               ),
            ),
          ]
        ],
      ),
    );
  }
}
