import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/app_localizations.dart';
import '../settings_tiles.dart';

class AboutSection extends StatelessWidget {
  const AboutSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(
            l10n.settingsAbout,
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
                icon: Icons.info_outline,
                title: l10n.settingsVersion,
                subtitle: '1.0.0 (1)', // Ideally fetched asynchronously, logic can be added later
                trailing: const SizedBox(), // No arrow
                onTap: () async {
                  final info = await PackageInfo.fromPlatform();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${info.appName} v${info.version} (${info.buildNumber})')),
                    );
                  }
                },
              ),
              const Divider(height: 1, indent: 56),
              SettingsTile(
                icon: Icons.description_outlined,
                title: l10n.settingsTerms,
                onTap: () => context.push(AppRoutes.termsOfService),
              ),
              const Divider(height: 1, indent: 56),
              SettingsTile(
                icon: Icons.privacy_tip_outlined,
                title: l10n.settingsPrivacy,
                onTap: () => context.push(AppRoutes.privacyPolicy),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
