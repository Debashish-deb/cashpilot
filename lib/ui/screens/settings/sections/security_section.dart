import 'package:cashpilot/features/settings/viewmodels/security_view_model.dart' show SecurityViewState, securityViewModelProvider;
import 'package:cashpilot/ui/widgets/settings/settings_selection_button.dart' show SettingsSelectionButton;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


import '../../../../l10n/app_localizations.dart';
import '../../../widgets/settings/settings_group_card.dart';
import '../../../widgets/settings/settings_selection_button.dart';


class SecuritySection extends ConsumerWidget {
  const SecuritySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final securityState = ref.watch(securityViewModelProvider);

    return SettingsGroupCard(
      title: "PRIVACY", // Localize later
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      child: securityState.when(
        data: (state) => _buildContent(context, ref, state, l10n),
        loading: () => const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (err, _) => Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            l10n.commonErrorMessage(err.toString()),
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    SecurityViewState state,
    AppLocalizations l10n,
  ) {
    return IntrinsicHeight(
      child: Row(
        children: [
          // Biometric Toggle
          SettingsSelectionButton(
            label: "Privacy", 
            icon: Icons.fingerprint_rounded,
            isSelected: state.biometricEnabled,
            onTap: state.isBiometricHardwareAvailable
                ? () => ref
                    .read(securityViewModelProvider.notifier)
                    .toggleBiometric(!state.biometricEnabled)
                : () {},
            showLock: !state.isBiometricHardwareAvailable,
          ),
          
          VerticalDivider(
            width: 1, 
            thickness: 1, 
            color: Theme.of(context).dividerColor.withOpacity(0.1), 
            indent: 6, 
            endIndent: 6,
          ),

          // App Lock
          SettingsSelectionButton(
            label: l10n.settingsAppLock,
            icon: Icons.lock_outline_rounded,
            isSelected: state.appLockEnabled,
            onTap: () => ref
                .read(securityViewModelProvider.notifier)
                .toggleAppLock(!state.appLockEnabled),
          ),
        ],
      ),
    );
  }
}
