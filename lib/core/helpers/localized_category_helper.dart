import 'package:flutter/widgets.dart';
import '../../l10n/app_localizations.dart';
import '../constants/default_categories.dart';

/// Helper class to resolve localized category names
class LocalizedCategoryHelper {
  /// localized category name using DefaultCategories lookup
  static String getLocalizedName(BuildContext context, String categoryName, {String? iconName}) {
    // 1. If we have iconName, try to find a matching default category
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
    
    // 2. Fallback: try to match by name (case insensitive) if it looks like a standard one
    try {
      final match = industrialCategories.firstWhere(
        (c) => c.localizationKey.toLowerCase().replaceAll('cat', '') == categoryName.toLowerCase() ||
               c.localizationKey == categoryName,
      );
      return match.getLocalizedName(context);
    } catch (e) {
      // No match by name
    }

    // 4. CHECK FOR UNCATEGORIZED EXPLICITLY
    if (categoryName.toLowerCase() == 'uncategorized') {
      return AppLocalizations.of(context)!.catUncategorized;
    }

    // 5. Return original name
    return categoryName;
  }
}
