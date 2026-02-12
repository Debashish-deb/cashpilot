import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../widgets/settings/settings_group_card.dart';
import '../../../widgets/settings/settings_selection_button.dart';


class AboutSection extends StatelessWidget {
  const AboutSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 600 ? 3 : 2;
    final horizontalPadding = 16.0;
    final spacing = 20.0;
    final totalPadding = (horizontalPadding * 2) + (spacing * (crossAxisCount - 1));
    final tileWidth = (screenWidth - totalPadding) / crossAxisCount;
    final childAspectRatio = tileWidth / 74;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsGroupCard(
          title: l10n.settingsAbout.toUpperCase(),
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
          child: IntrinsicHeight(
            child: Row(
              children: [
                SettingsSelectionButton(
                  label: l10n.settingsTerms,
                  icon: Icons.description_rounded,
                  isSelected: false,
                  onTap: () => context.push(AppRoutes.termsOfService),
                ),
                VerticalDivider(
                  width: 1, 
                  thickness: 1, 
                  color: Theme.of(context).dividerColor.withOpacity(0.1), 
                  indent: 6, 
                  endIndent: 6,
                ),
                SettingsSelectionButton(
                  label: l10n.settingsPrivacy,
                  icon: Icons.privacy_tip_rounded,
                  isSelected: false,
                  onTap: () => context.push(AppRoutes.privacyPolicy),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Version Footer
        Center(
          child: FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox.shrink();
              final info = snapshot.data!;
              return Column(
                children: [
                   Text(
                    '${info.appName} v${info.version}',
                    style: AppTypography.labelMedium.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Build ${info.buildNumber}',
                     style: AppTypography.labelSmall.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
} // Ensuring class closes correctly if I missed Lines

