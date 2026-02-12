import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/subscription.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/providers/user_mode_provider.dart';
import '../../../../features/subscription/providers/subscription_providers.dart';
import '../../../../l10n/app_localizations.dart';

import '../../../widgets/settings/settings_group_card.dart';
import '../../../widgets/settings/settings_selection_button.dart';
import '../../../widgets/settings/accent_color_picker.dart';
import '../../../widgets/settings/glass_selection_dialog.dart';


class PreferencesSection extends ConsumerWidget {
  const PreferencesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    final themeMode = ref.watch(themeModeProvider);
    final language = ref.watch(languageProvider);
    final currency = ref.watch(currencyProvider);
    final isFree = ref.watch(isFreeProvider);
    final canUseThemes = ref.watch(canUseFeatureProvider(Feature.multiColorTheme));
    final userMode = ref.watch(userModeProvider);

    return Column(
      children: [
        // ------------------------------------------------------------------
        // THEME GROUP
        // ------------------------------------------------------------------
        SettingsGroupCard(
          title: l10n.settingsTheme.toUpperCase(),
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8), // Compact padding
          child: IntrinsicHeight(
            child: Row(
              children: [
                SettingsSelectionButton(
                  label: l10n.themeLight,
                  icon: Icons.wb_sunny_outlined,
                  isSelected: themeMode == AppThemeMode.light,
                  onTap: () => ref
                      .read(themeModeProvider.notifier)
                      .setTheme(AppThemeMode.light),
                ),
                VerticalDivider(
                  width: 1, 
                  thickness: 1, 
                  color: Theme.of(context).dividerColor.withOpacity(0.1), 
                  indent: 6, 
                  endIndent: 6,
                ),
                SettingsSelectionButton(
                  label: l10n.themeDark,
                  icon: Icons.nightlight_round,
                  isSelected: themeMode == AppThemeMode.dark,
                  onTap: () => ref
                      .read(themeModeProvider.notifier)
                      .setTheme(AppThemeMode.dark),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12), // Compact spacing

        // ------------------------------------------------------------------
        // LANGUAGE GROUP
        // ------------------------------------------------------------------
        SettingsGroupCard(
          title: l10n.settingsLanguage.toUpperCase(),
           padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: IntrinsicHeight(
            child: Row(
              children: [
                SettingsSelectionButton(
                  label: "English",
                  icon: Icons.language,
                  isSelected: language == AppLanguage.english,
                  onTap: () => ref
                      .read(languageProvider.notifier)
                      .setLanguage(AppLanguage.english),
                ),
                VerticalDivider(
                  width: 1, 
                  thickness: 1, 
                  color: Theme.of(context).dividerColor.withOpacity(0.1), 
                  indent: 6, 
                  endIndent: 6,
                ),
                SettingsSelectionButton(
                  label: "বাংলা",
                  icon: Icons.translate,
                  isSelected: language == AppLanguage.bengali,
                  onTap: () => ref
                      .read(languageProvider.notifier)
                      .setLanguage(AppLanguage.bengali),
                ),
                VerticalDivider(
                  width: 1, 
                  thickness: 1, 
                  color: Theme.of(context).dividerColor.withOpacity(0.1), 
                  indent: 6, 
                  endIndent: 6,
                ),
                SettingsSelectionButton(
                  label: "Suomi",
                  icon: Icons.language_rounded,
                  isSelected: language == AppLanguage.finnish,
                  onTap: () => ref
                      .read(languageProvider.notifier)
                      .setLanguage(AppLanguage.finnish),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12), // Compact spacing

        // ------------------------------------------------------------------
        // GENERAL
        // ------------------------------------------------------------------
        SettingsGroupCard(
          title: "GENERAL", 
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          child: Column(
            children: [
              IntrinsicHeight(
                child: Row(
                  children: [
                    SettingsSelectionButton(
                       label: currency,
                       icon: Icons.attach_money_rounded,
                       isSelected: true, // Always "active" to show primary color
                       onTap: () => _showCurrencyDialog(context, ref, currency, l10n),
                    ),
                    VerticalDivider(
                      width: 1, 
                      thickness: 1, 
                      color: Theme.of(context).dividerColor.withOpacity(0.1), 
                      indent: 6, 
                      endIndent: 6,
                    ),
                    SettingsSelectionButton(
                       label: l10n.reportsCategories,
                       icon: Icons.category_rounded,
                       isSelected: false, 
                       onTap: () => context.push(AppRoutes.categories),
                    ),
                  ],
                ),
              ),
              Divider(
                height: 12, 
                thickness: 1, 
                color: Theme.of(context).dividerColor.withOpacity(0.1), 
                indent: 16, 
                endIndent: 16,
              ),
              IntrinsicHeight(
                child: Row(
                  children: [
                    SettingsSelectionButton(
                       label: l10n.settingsAccentColor,
                       icon: Icons.color_lens_rounded,
                       isSelected: false,
                       onTap: () {
                          if (canUseThemes) {
                            showAccentColorSheet(context);
                          } else {
                            _showThemeUpgradeDialog(context, l10n);
                          }
                       },
                       showLock: !canUseThemes && isFree,
                    ),
                    VerticalDivider(
                      width: 1, 
                      thickness: 1, 
                      color: Theme.of(context).dividerColor.withOpacity(0.1), 
                      indent: 6, 
                      endIndent: 6,
                    ),
                    SettingsSelectionButton(
                       label: l10n.settingsExperienceMode,
                       icon: userMode == UserMode.expert
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                       isSelected: userMode == UserMode.expert,
                       onTap: () => ref.read(userModeProvider.notifier).toggleMode(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }



  Future<void> _showCurrencyDialog(
    BuildContext context,
    WidgetRef ref,
    String currentCurrency,
    AppLocalizations l10n,
  ) async {
    const currencies = [
      'USD',
      'EUR',
      'GBP',
      'JPY',
      'INR',
      'AUD',
      'CAD',
      'SGD',
      'CHF',
      'CNY',
      'BDT',
    ];

    await showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (context) => GlassSelectionDialog<String>(
        title: l10n.settingsCurrency,
        currentValue: currentCurrency,
        options: currencies
            .map(
              (curr) => GlassDialogOption(
                label: curr,
                value: curr,
              ),
            )
            .toList(),
        onSelected: (value) {
          ref.read(currencyProvider.notifier).setCurrency(value);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showThemeUpgradeDialog(
    BuildContext context,
    AppLocalizations l10n,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.color_lens, color: AppColors.gold),
            const SizedBox(width: 12),
            Expanded(child: Text(l10n.settingsUnlockThemes)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.settingsUpgradeProThemes),
            const SizedBox(height: 12),
            _buildThemeFeature(l10n.settingsFeatureAccent),
            _buildThemeFeature(l10n.settingsFeaturePrimary),
            _buildThemeFeature(l10n.settingsFeatureDarkSync),
            _buildThemeFeature(l10n.settingsFeatureGradient),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.settingsMaybeLater),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(context);
              context.push(AppRoutes.paywall);
            },
            icon: const Icon(Icons.star, size: 18),
            label: Text(l10n.commonUpgrade),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeFeature(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle,
              size: 16, color: AppColors.gold),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
