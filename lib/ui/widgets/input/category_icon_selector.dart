import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../common/app_grade_icons.dart';

class CategoryIconSelector extends StatelessWidget {
  final String? selectedIconName;
  final Color accentColor;
  final ValueChanged<String> onIconSelected;

  /// Optional: category name for auto-suggestion
  final String? categoryName;

  const CategoryIconSelector({
    super.key,
    required this.selectedIconName,
    required this.accentColor,
    required this.onIconSelected,
    this.categoryName,
  });

  @override
  Widget build(BuildContext context) {
    final suggestedIcon = _suggestIcon(categoryName);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (suggestedIcon != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'Suggested',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: accentColor.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                  ),
            ),
          ),

        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 6,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
          ),
          itemCount: AppGradeIcons.pickerIcons.length,
          itemBuilder: (_, i) {
            final entry = AppGradeIcons.pickerIcons[i].entries.first;
            final name = entry.key;
            final icon = entry.value;

            final isSelected = name == selectedIconName;
            final isSuggested = name == suggestedIcon && !isSelected;

            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                onIconSelected(name);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                decoration: BoxDecoration(
                  color: isSelected
                      ? accentColor.withValues(alpha: 0.18)
                      : Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? accentColor
                        : isSuggested
                            ? accentColor.withValues(alpha: 0.4)
                            : Colors.transparent,
                    width: isSelected ? 2 : 1.2,
                  ),
                  boxShadow: (isSelected || isSuggested)
                      ? [
                          BoxShadow(
                            color: accentColor.withValues(alpha: 
                                isSelected ? 0.45 : 0.25),
                            blurRadius: isSelected ? 10 : 6,
                            offset: const Offset(0, 4),
                          )
                        ]
                      : null,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      icon,
                      size: 22,
                      color: isSelected
                          ? accentColor
                          : Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6),
                    ),

                    if (isSuggested && !isSelected)
                      Positioned(
                        bottom: 6,
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: accentColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // INTELLIGENCE: ICON AUTO-SUGGESTION
  // ---------------------------------------------------------------------------

  String? _suggestIcon(String? name) {
    if (name == null || name.trim().isEmpty) return null;

    final n = name.toLowerCase();

    const Map<String, List<String>> rules = {
      'cart': ['shop', 'grocery', 'market', 'buy'],
      'food': ['food', 'restaurant', 'meal', 'lunch', 'dinner'],
      'coffee': ['coffee', 'cafe'],
      'transport': ['transport', 'bus', 'car', 'fuel', 'uber', 'taxi'],
      'home': ['home', 'rent', 'house'],
      'utilities': ['electric', 'water', 'gas', 'bill'],
      'health': ['health', 'doctor', 'medical', 'pharmacy'],
      'fitness': ['gym', 'fitness', 'workout'],
      'subscriptions': ['netflix', 'spotify', 'subscription'],
      'travel': ['travel', 'flight', 'hotel'],
      'savings': ['save', 'savings', 'deposit'],
      'family': ['family', 'kids', 'child'],
      'work': ['work', 'office', 'job'],
      'entertainment': ['movie', 'cinema', 'fun'],
    };

    for (final entry in rules.entries) {
      if (entry.value.any(n.contains)) {
        return entry.key;
      }
    }

    return null;
  }
}