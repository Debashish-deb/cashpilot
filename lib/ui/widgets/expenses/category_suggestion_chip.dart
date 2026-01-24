/// Category Suggestion Chip Widget
/// Shows ML-powered category suggestions with confidence scores
library;

import 'package:flutter/material.dart';
import 'package:cashpilot/l10n/app_localizations.dart';
import '../../../features/expenses/models/prediction_result.dart';

class CategorySuggestionChip extends StatelessWidget {
  final PredictionResult prediction;
  final VoidCallback onApply;
  final VoidCallback onDismiss;
  final bool isAutoApplied;
  final AppLocalizations l10n;

  const CategorySuggestionChip({
    super.key,
    required this.prediction,
    required this.onApply,
    required this.onDismiss,
    required this.l10n,
    this.isAutoApplied = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final confidence = prediction.confidence;
    
    // Determine color based on confidence
    final Color chipColor;
    final Color textColor;
    if (confidence >= 85) {
      chipColor = Colors.green.withValues();
      textColor = Colors.green.shade700;
    } else if (confidence >= 70) {
      chipColor = Colors.blue.withValues();
      textColor = Colors.blue.shade700;
    } else {
      chipColor = Colors.orange.withValues();
      textColor = Colors.orange.shade700;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: textColor.withValues(),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: textColor.withValues(),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.lightbulb_outline,
              size: 18,
              color: textColor,
            ),
          ),
          const SizedBox(width: 12),
          
          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      isAutoApplied ? l10n.categoryAutoLabeled : l10n.categorySuggested,
                      style: TextStyle(
                        fontSize: 11,
                        color: textColor.withValues(),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Confidence badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: textColor.withValues(),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$confidence%',
                        style: TextStyle(
                          fontSize: 10,
                          color: textColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  prediction.category,
                  style: TextStyle(
                    fontSize: 15,
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          
          // Actions
          if (!isAutoApplied) ...[
            TextButton(
              onPressed: onDismiss,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                AppLocalizations.of(context)!.categoryDismiss,
                style: TextStyle(
                  fontSize: 12,
                  color: textColor.withValues(),
                ),
              ),
            ),
            const SizedBox(width: 4),
            ElevatedButton(
              onPressed: onApply,
              style: ElevatedButton.styleFrom(
                backgroundColor: textColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                elevation: 0,
              ),
              child: Text(
                AppLocalizations.of(context)!.categoryApply,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ] else ...[
            TextButton(
              onPressed: onDismiss,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                AppLocalizations.of(context)!.categoryUndo,
                style: TextStyle(
                  fontSize: 12,
                  color: textColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
