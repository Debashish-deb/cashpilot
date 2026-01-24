import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../features/settings/viewmodels/security_view_model.dart';
import '../../../../l10n/app_localizations.dart';
import '../settings_tiles.dart';

class SecuritySection extends ConsumerWidget {
  const SecuritySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final securityState = ref.watch(securityViewModelProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(
            l10n.settingsSecurity,
            style: AppTypography.titleSmall.copyWith(
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        securityState.when(
          data: (state) => _buildContent(context, ref, state, l10n),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, SecurityViewState state, AppLocalizations l10n) {
    return Card(
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
            icon: Icons.fingerprint,
            title: state.biometricTypeDescription,
            subtitle: state.biometricEnabled ? 'Enabled' : 'Disabled',
            trailing: state.isLoading 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : Switch(
                  value: state.biometricEnabled,
                  onChanged: state.isBiometricHardwareAvailable 
                    ? (value) async {
                        final result = await ref.read(securityViewModelProvider.notifier).toggleBiometric(value);
                        if (!result.isSuccess && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(result.message ?? l10n.commonError)),
                          );
                        }
                      }
                    : null,
                ),
          ),
          const Divider(height: 1, indent: 56),
          SettingsTile(
            icon: Icons.lock_outline,
            title: l10n.settingsAppLock,
            subtitle: state.appLockEnabled ? 'Lock on app exit' : 'Never lock',
            trailing: Switch(
              value: state.appLockEnabled,
              onChanged: (value) async {
                final result = await ref.read(securityViewModelProvider.notifier).toggleAppLock(value);
                if (!result.isSuccess && context.mounted) {
                   ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(result.message ?? l10n.commonError)),
                  );
                }
              },
            ),
          ),
          if (state.appLockEnabled) ...[
            const Divider(height: 1, indent: 56),
            SettingsTile(
              icon: Icons.timer_outlined,
              title: 'Auto-lock timeout',
              subtitle: '${state.autoLockTimeoutSeconds} seconds',
              onTap: () => _showTimeoutPicker(context, ref, state.autoLockTimeoutSeconds),
            ),
          ],
        ],
      ),
    );
  }

  void _showTimeoutPicker(BuildContext context, WidgetRef ref, int current) {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Auto-lock timeout'),
        children: [15, 30, 60, 120, 300].map((s) {
          return RadioListTile<int>(
            title: Text('$s seconds'),
            value: s,
            groupValue: current,
            onChanged: (val) {
              if (val != null) {
                ref.read(securityViewModelProvider.notifier).setAutoLockTimeout(val);
                Navigator.pop(context);
              }
            },
          );
        }).toList(),
      ),
    );
  }
}
