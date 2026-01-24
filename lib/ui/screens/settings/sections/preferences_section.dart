import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/subscription.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/accent_colors.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/providers/user_mode_provider.dart';
import '../../../../features/subscription/providers/subscription_providers.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../widgets/settings/accent_color_picker.dart';
import '../../../widgets/common/enhanced_widgets.dart';
import '../settings_tiles.dart';

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(
            l10n.settingsPreferences,
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
                icon: Icons.palette_outlined,
                title: l10n.settingsTheme,
                subtitle: _getThemeLabel(themeMode, l10n),
                onTap: () => _showThemeDialog(context, ref, themeMode, l10n),
              ),
              const Divider(height: 1, indent: 56),
              SettingsTile(
                icon: Icons.language_outlined,
                title: l10n.settingsLanguage,
                subtitle: language.displayName,
                onTap: () => _showLanguageDialog(context, ref, language, l10n),
              ),
              const Divider(height: 1, indent: 56),
              SettingsTile(
                icon: Icons.attach_money_outlined,
                title: l10n.settingsCurrency,
                subtitle: currency,
                onTap: () => _showCurrencyDialog(context, ref, currency, l10n),
              ),
              const Divider(height: 1, indent: 56),
              SettingsTile(
                icon: Icons.category_outlined,
                title: l10n.reportsCategories,
                subtitle: 'Manage expense categories',
                onTap: () => context.push(AppRoutes.categories),
              ),
              const Divider(height: 1, indent: 56),
              SettingsTile(
                icon: Icons.color_lens_outlined,
                title: 'Accent Color',
                subtitle: isFree 
                    ? 'Customize app colors'
                    : AccentColors.getConfig(ref.watch(accentColorProvider)).displayName,
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
                  if (canUseThemes) {
                    showAccentColorSheet(context);
                  } else {
                    _showThemeUpgradeDialog(context, l10n);
                  }
                },
              ),
              const Divider(height: 1, indent: 56),
              _buildExperienceModeToggle(context, ref, l10n),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExperienceModeToggle(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    final userMode = ref.watch(userModeProvider);
    final isExpert = userMode == UserMode.expert;
    
    return ListTile(
      leading: Container(
        width: 48,
        height: 48,
        alignment: Alignment.center,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isExpert 
                ? AppColors.primaryGold.withValues(alpha: 0.15)
                : Theme.of(context).primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            isExpert ? Icons.star_rounded : Icons.star_border_rounded, 
            color: isExpert ? AppColors.primaryGold : Theme.of(context).primaryColor, 
            size: 20,
          ),
        ),
      ),
      title: const Text('Experience Mode', style: AppTypography.titleSmall),
      subtitle: Text(
        isExpert ? 'Expert' : 'Simplified',
        style: AppTypography.bodySmall.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        ),
      ),
      trailing: Switch(
        value: isExpert,
        onChanged: (_) => ref.read(userModeProvider.notifier).toggleMode(),
        activeThumbColor: AppColors.primaryGold,
      ),
    );
  }

  String _getThemeLabel(AppThemeMode mode, AppLocalizations l10n) {
    switch (mode) {
      case AppThemeMode.light:
        return l10n.themeLight;
      case AppThemeMode.dark:
        return l10n.themeDark;
    }
  }

  Future<void> _showThemeDialog(
    BuildContext context, 
    WidgetRef ref, 
    AppThemeMode currentMode, 
    AppLocalizations l10n
  ) async {
    await showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(l10n.settingsTheme),
        children: AppThemeMode.values.map((mode) {
          return RadioListTile<AppThemeMode>(
            title: Text(_getThemeLabel(mode, l10n)),
            value: mode,
            groupValue: currentMode,
            onChanged: (value) {
              if (value != null) {
                ref.read(themeModeProvider.notifier).setTheme(value);
                Navigator.pop(context);
              }
            },
          );
        }).toList(),
      ),
    );
  }

  Future<void> _showLanguageDialog(
    BuildContext context, 
    WidgetRef ref, 
    AppLanguage currentLang, 
    AppLocalizations l10n
  ) async {
    await showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(l10n.settingsLanguage),
        children: AppLanguage.values.map((lang) {
          return RadioListTile<AppLanguage>(
            title: Text(lang.displayName),
            value: lang,
            groupValue: currentLang,
            onChanged: (value) {
              if (value != null) {
                ref.read(languageProvider.notifier).setLanguage(value);
                Navigator.pop(context);
              }
            },
          );
        }).toList(),
      ),
    );
  }

  Future<void> _showCurrencyDialog(
    BuildContext context, 
    WidgetRef ref, 
    String currentCurrency, 
    AppLocalizations l10n
  ) async {
    // This assumes simple currency selection for now. 
    // Ideally this should use a proper currency picker widget if the list is long.
    final currencies = ['USD', 'EUR', 'GBP', 'JPY', 'INR', 'AUD', 'CAD', 'SGD', 'CHF', 'CNY', 'BDT'];
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.settingsCurrency),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: currencies.length,
            itemBuilder: (context, index) {
              final currency = currencies[index];
              return RadioListTile<String>(
                title: Text(currency),
                value: currency,
                groupValue: currentCurrency,
                onChanged: (value) {
                  if (value != null) {
                    ref.read(currencyProvider.notifier).setCurrency(value);
                    Navigator.pop(context);
                  }
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _showThemeUpgradeDialog(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.color_lens, color: AppColors.gold),
            const SizedBox(width: 12),
            const Expanded(child: Text('Unlock Custom Themes')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Upgrade to Pro to check out these features:'),
            const SizedBox(height: 12),
            _buildThemeFeature('Accent Color Customization'),
            _buildThemeFeature('Premium Primary Colors'),
            _buildThemeFeature('Dark/Light Mode Sync'),
            _buildThemeFeature('Gradient UI Elements'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Maybe Later'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(context);
              context.push(AppRoutes.paywall);
            },
            icon: const Icon(Icons.star, size: 18),
            label: Text(l10n.commonUpgrade), // commonUpgrade exists? No, check.
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
          const Icon(Icons.check_circle, size: 16, color: AppColors.gold),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
