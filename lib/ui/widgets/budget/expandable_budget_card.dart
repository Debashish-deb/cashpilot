import 'package:cashpilot/core/constants/default_categories.dart' show CategoryIconMapper;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/tokens.g.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/drift/app_database.dart';
import '../../../core/providers/app_providers.dart';

/// Phase 4: Expandable Hierarchical Budget Card
/// 
/// Shows Category -> Total
///           SubCategory -> Breakdown
class ExpandableBudgetCard extends ConsumerStatefulWidget {
  final SemiBudget category;
  final double spent;
  final double limit;
  final String currency;
  final double progress;
  
  const ExpandableBudgetCard({
    super.key,
    required this.category,
    required this.spent,
    required this.limit,
    required this.currency,
    required this.progress,
  });

  @override
  ConsumerState<ExpandableBudgetCard> createState() => _ExpandableBudgetCardState();
}

class _ExpandableBudgetCardState extends ConsumerState<ExpandableBudgetCard> with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  late Animation<double> _roateAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _expandAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _roateAnimation = Tween<double>(begin: 0, end: 0.5).animate(_controller);
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // 1. Fetch SubCategories logic would go here or be passed in
    // For MVP, we query them on expansion or load.
    // Let's assume we fetch them simply via a specialized provider or future builder for now.
    final subCatsAsync = ref.watch(_subCategoriesProvider(widget.category.id));
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      children: [
        // Main Category Row
        InkWell(
          onTap: _toggle,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: isDark ? Colors.white10 : Colors.grey.shade200),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    // Icon
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: HexColor(widget.category.colorHex ?? '#2196F3').withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        CategoryIconMapper.resolve(widget.category.iconName ?? 'category'),
                        color: HexColor(widget.category.colorHex ?? '#2196F3'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Title & Progress
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.category.name,
                            style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: widget.progress.clamp(0.0, 1.0),
                            backgroundColor: isDark ? Colors.white10 : Colors.grey.shade100,
                            color: _getProgressColor(widget.progress),
                            minHeight: 6,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Amount & Chevron
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${(widget.spent / 100).toStringAsFixed(0)} / ${(widget.limit / 100).toStringAsFixed(0)}',
                          style: AppTypography.bodyMedium,
                        ),
                        RotationTransition(
                          turns: _roateAnimation,
                          child: const Icon(Icons.expand_more, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        
        // Expanded SubCategories
        SizeTransition(
          sizeFactor: _expandAnimation,
          child: subCatsAsync.when(
            data: (subCats) {
              if (subCats.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(left: 24, right: 16, top: 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
                  ),
                  child: Column(
                    children: subCats.map((sub) => _buildSubCategoryRow(sub, context)).toList(),
                  ),
                ),
              );
            },
            loading: () => const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
            error: (_,__) => const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }

  Widget _buildSubCategoryRow(SubCategory sub, BuildContext context) {
    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      title: Text(sub.name, style: AppTypography.bodyMedium),
      trailing: Text(
        '${sub.usageCount} uses', // Using usage count as proxy for health for now
        style: AppTypography.labelSmall.copyWith(color: Colors.grey),
      ),
      leading: const Icon(Icons.subdirectory_arrow_right, size: 16, color: Colors.grey),
    );
  }

  Color _getProgressColor(double progress) {
    if (progress >= 1.0) return AppTokens.semanticDanger;
    if (progress >= 0.8) return AppTokens.semanticWarning;
    return AppTokens.semanticSuccess;
  }
}

// Helper to fetch subcategories
final _subCategoriesProvider = FutureProvider.family<List<SubCategory>, String>((ref, categoryId) async {
  final db = ref.read(databaseProvider);
  return (db.select(db.subCategories)..where((t) => t.categoryId.equals(categoryId))).get();
});

class HexColor extends Color {
  static int _getColorFromHex(String hexColor) {
    hexColor = hexColor.toUpperCase().replaceAll("#", "");
    if (hexColor.length == 6) {
      hexColor = "FF$hexColor";
    }
    return int.parse(hexColor, radix: 16);
  }

  HexColor(final String hexColor) : super(_getColorFromHex(hexColor));
}
