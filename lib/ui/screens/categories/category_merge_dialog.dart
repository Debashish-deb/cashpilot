import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cashpilot/features/categories/providers/category_providers.dart';
import 'package:cashpilot/features/categories/providers/category_controller.dart';
import 'package:cashpilot/ui/widgets/common/app_grade_icons.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../data/drift/app_database.dart';
import 'package:cashpilot/l10n/app_localizations.dart';

// =============================================================================
// CATEGORY MERGE DIALOG
// =============================================================================

Future<void> showMergeDialog(BuildContext context, WidgetRef ref, Category sourceCategory) async {
  // 1. Fetch potential targets (all other categories)
  final allCategories = await ref.read(allCategoriesProvider.future);
  final targets = allCategories.where((c) => c.id != sourceCategory.id).toList();

  if (targets.isEmpty) {
    if (context.mounted) {
      AppSnackBar.showError(context, AppLocalizations.of(context)!.categoryNoMergeTargets);
    }
    return;
  }
  
  // Sort by name
  targets.sort((a, b) => a.name.compareTo(b.name));

  Category? selectedTarget;
  
  if (!context.mounted) return;

  // 2. Show selection dialog
  await showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        final l10n = AppLocalizations.of(context)!;
        return AlertDialog(
          title: Text(l10n.categoryMergeTitle(sourceCategory.name)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                Text(
                l10n.categoryMergeMsg,
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<Category>(
                decoration: InputDecoration(
                  labelText: l10n.categoryMergeIntoLabel,
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                isExpanded: true,
                items: targets.map((c) => DropdownMenuItem(
                  value: c,
                  child: Row(
                    children: [
                      Icon(AppGradeIcons.getIcon(c.iconName), size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(child: Text(c.name, overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                )).toList(),
                onChanged: (val) => setState(() => selectedTarget = val),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.commonCancel),
            ),
            FilledButton(
              onPressed: selectedTarget == null ? null : () async {
                HapticFeedback.mediumImpact();
                Navigator.pop(context); // Close dialog
                
                // Show loading/processing
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.categoryMerging),
                    duration: const Duration(seconds: 1),
                  ),
                );
                
                try {
                  await ref.read(categoryControllerProvider).mergeCategories(
                    sourceCategory.id,
                    selectedTarget!.id,
                  );
                  ref.invalidate(groupedCategoriesProvider);
                  ref.invalidate(categorySpendingStatsProvider); // Update stats too
                  
                  if (context.mounted) {
                    AppSnackBar.showSuccess(context, l10n.categoryMerged(selectedTarget!.name));
                  }
                } catch (e) {
                  if (context.mounted) {
                    AppSnackBar.showError(context, l10n.categoryMergeFailed(e.toString()));
                  }
                }
              },
              child: Text(l10n.commonMerge),
            ),
          ],
        );
      },
    ),
  );
}
