import 'package:flutter/widgets.dart';
import '../../l10n/app_localizations.dart';
import '../constants/default_categories.dart';

/// Helper class to resolve localized category names
class LocalizedCategoryHelper {
  /// localized category name using DefaultCategories lookup
  static String getLocalizedName(BuildContext context, String categoryName, {String? iconName}) {
    // 1. Try to match by name first (more precise)
    try {
      final match = industrialCategories.firstWhere(
        (c) {
          final cleanKey = c.localizationKey.toLowerCase().replaceAll('cat', '').replaceAll(' ', '');
          final cleanName = categoryName.toLowerCase().replaceAll(' ', '');
          return cleanKey == cleanName || c.localizationKey == categoryName || c.localizationKey.toLowerCase() == 'cat$cleanName';
        },
      );
      return match.getLocalizedName(context);
    } catch (e) {
      // No match by name
    }

    // 2. If no name match, try iconName
    if (iconName != null) {
      try {
        final match = industrialCategories.firstWhere(
          (c) => c.iconName == iconName,
        );
        return match.getLocalizedName(context);
      } catch (e) {
        // No match by icon
      }
    }

    // 4. CHECK FOR UNCATEGORIZED EXPLICITLY
    if (categoryName.toLowerCase() == 'uncategorized') {
      return AppLocalizations.of(context)?.catUncategorized ?? 'Uncategorized';
    }

    // 5. Return original name
    return categoryName;
  }

  /// Resolves a hierarchical category name (e.g., "Housing > Rent")
  static String getLocalizedHierarchy(BuildContext context, String? categoryId, String? subCategoryId) {
    if (categoryId == null && subCategoryId == null) {
      return AppLocalizations.of(context)?.catUncategorized ?? 'Uncategorized';
    }

    final l10n = AppLocalizations.of(context);
    
    String? masterName;
    if (categoryId != null) {
      try {
        // Find master category
        final master = industrialCategories.firstWhere(
          (c) => c.localizationKey.toLowerCase() == categoryId.toLowerCase(),
          orElse: () => industrialCategories.firstWhere((c) => c.localizationKey == categoryId, 
          orElse: () => throw Exception('Not found')),
        );
        masterName = master.getLocalizedName(context);
      } catch (e) {
        // Fallback if categoryId is unrecognized but present
        masterName = categoryId;
      }
    }

    if (subCategoryId != null) {
      try {
        // Try to find subcategory directly (it might be a master category key shifted to sub)
        final sub = industrialCategories.firstWhere(
          (c) => c.localizationKey.toLowerCase() == subCategoryId.toLowerCase() || 
                 c.localizationKey.toLowerCase() == 'cat${subCategoryId.toLowerCase()}',
          orElse: () => industrialCategories.firstWhere((c) => c.localizationKey == subCategoryId,
          orElse: () => throw Exception('Not found')),
        );
        final subName = sub.getLocalizedName(context);
        return masterName != null ? '$masterName > $subName' : subName;
      } catch (_) {
        // If subcategory not found in industrialCategories, maybe it's custom
        final cleanSub = subCategoryId.replaceAll('cat', '');
        final displaySub = cleanSub.substring(0, 1).toUpperCase() + cleanSub.substring(1).toLowerCase();
        return masterName != null ? '$masterName > $displaySub' : displaySub;
      }
    }

    return masterName ?? l10n?.catUncategorized ?? 'Uncategorized';
  }
}
