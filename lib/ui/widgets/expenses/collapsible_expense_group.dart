import 'package:flutter/material.dart';
import 'package:cashpilot/core/theme/app_typography.dart';
import 'package:cashpilot/core/theme/tokens.g.dart';
import '../common/cp_app_icon.dart';
import '../common/glass_card.dart';

class CollapsibleExpenseGroup extends StatefulWidget {
  final String title;
  final String? iconName;
  final Color color;
  final double totalAmount;
  final String currency;
  final List<Widget> children;
  final bool initiallyExpanded;
  final VoidCallback? onEdit;

  const CollapsibleExpenseGroup({
    super.key,
    required this.title,
    this.iconName,
    this.color = AppTokens.brandPrimary,
    required this.totalAmount,
    required this.currency,
    required this.children,
    this.initiallyExpanded = false,
    this.onEdit,
  });

  @override
  State<CollapsibleExpenseGroup> createState() => _CollapsibleExpenseGroupState();
}

class _CollapsibleExpenseGroupState extends State<CollapsibleExpenseGroup> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: GlassCard(
            padding: const EdgeInsets.all(12),
            borderRadius: 16,
            child: Row(
              children: [
                CPAppIcon(
                  icon: _resolveIcon(widget.iconName),
                  color: widget.color,
                  size: 40,
                  iconSize: 20,
                  useGradient: false,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${widget.children.length} items',
                        style: AppTypography.labelSmall.copyWith(
                          color: Theme.of(context).hintColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${_getCurrencySymbol(widget.currency)}${widget.totalAmount.toStringAsFixed(2)}',
                      style: AppTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    if (widget.onEdit != null)
                      GestureDetector(
                        onTap: widget.onEdit,
                        child: Icon(
                          Icons.edit_outlined,
                          size: 16,
                          color: Theme.of(context).primaryColor.withValues(alpha: 0.6),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 8),
                Icon(
                  _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: Theme.of(context).hintColor,
                ),
              ],
            ),
          ),
        ),
        if (_isExpanded)
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 4, bottom: 8),
            child: Column(
              children: widget.children,
            ),
          ),
      ],
    );
  }

  IconData _resolveIcon(String? name) {
    // Placeholder - in real app would use CategoryIconMapper
    return Icons.category;
  }

  String _getCurrencySymbol(String code) {
    switch (code) {
      case 'EUR': return '€';
      case 'USD': return '\$';
      case 'GBP': return '£';
      case 'BDT': return '৳';
      default: return code;
    }
  }
}
