/// Compact Title + Amount Card Widget
/// Combines title and amount in one ultra-compact card
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CompactTitleAmountCard extends StatelessWidget {
  final TextEditingController titleController;
  final TextEditingController amountController;
  final String currencySymbol;
  final String? titleHint;
  final String? amountHint;
  final String? Function(String?)? titleValidator;
  final String? Function(String?)? amountValidator;
  final Function(String)? onAmountChanged;

  const CompactTitleAmountCard({
    super.key,
    required this.titleController,
    required this.amountController,
    required this.currencySymbol,
    this.titleHint,
    this.amountHint,
    this.titleValidator,
    this.amountValidator,
    this.onAmountChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title field
          TextFormField(
            controller: titleController,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: titleHint ?? 'Expense description',
              hintStyle: TextStyle(
                color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.3),
                fontWeight: FontWeight.w600,
              ),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
            validator: titleValidator,
          ),
          const SizedBox(height: 12),
          // Amount - large display
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                currencySymbol,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: TextFormField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary,
                  ),
                  decoration: InputDecoration(
                    hintText: amountHint ?? '0.00',
                    hintStyle: TextStyle(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                  ],
                  validator: amountValidator,
                  onChanged: onAmountChanged,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
