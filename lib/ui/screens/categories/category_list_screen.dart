import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../features/categories/providers/category_providers.dart';
import '../../../features/categories/providers/category_controller.dart';
import '../../../data/drift/app_database.dart'; 
import 'package:cashpilot/l10n/app_localizations.dart'; 

// Import reusable input widgets
import '../../widgets/input/category_icon_selector.dart';
import '../../widgets/input/category_color_selector.dart';
import '../../widgets/common/app_grade_icons.dart';
import '../../widgets/common/cp_app_icon.dart';
import 'category_merge_dialog.dart';

// =============================================================================
// ICON AUTO-SUGGESTION ENGINE (ML-Ready)
// =============================================================================

class IconSuggestionEngine {
  /// Keyword mappings for auto-suggesting icons based on category name
  /// Structure is ML-ready: can be replaced with trained model later
  static const Map<String, List<String>> _keywordToIcons = {
    // Food & Dining
    'food': ['restaurant', 'food', 'fastfood'],
    'grocery': ['cart', 'shopping_cart'],
    'groceries': ['cart', 'shopping_cart'],
    'restaurant': ['restaurant', 'food'],
    'coffee': ['coffee', 'cafe'],
    'cafe': ['coffee', 'cafe'],
    'dining': ['restaurant', 'food'],
    'lunch': ['restaurant', 'food'],
    'dinner': ['restaurant', 'food'],
    'breakfast': ['coffee', 'food'],
    
    // Transport
    'transport': ['car', 'directions_car', 'commute'],
    'car': ['car', 'directions_car'],
    'fuel': ['local_gas_station', 'car'],
    'gas': ['local_gas_station'],
    'uber': ['car', 'commute'],
    'taxi': ['car', 'commute'],
    'bus': ['commute', 'directions_bus'],
    'train': ['commute', 'train'],
    'flight': ['flight', 'airplane'],
    'travel': ['flight', 'luggage'],
    
    // Shopping
    'shopping': ['shopping_bag', 'cart'],
    'clothes': ['shopping_bag'],
    'fashion': ['shopping_bag'],
    'amazon': ['shopping_cart', 'cart'],
    'online': ['shopping_cart'],
    
    // Entertainment
    'entertainment': ['movie', 'games'],
    'movie': ['movie', 'theaters'],
    'movies': ['movie', 'theaters'],
    'netflix': ['movie', 'tv'],
    'spotify': ['music', 'headphones'],
    'music': ['music', 'headphones'],
    'games': ['games', 'sports_esports'],
    'gaming': ['games', 'sports_esports'],
    
    // Home & Bills
    'rent': ['home', 'house'],
    'home': ['home', 'house'],
    'house': ['home', 'house'],
    'electricity': ['bolt', 'lightbulb'],
    'utilities': ['bolt', 'water'],
    'water': ['water', 'water_drop'],
    'internet': ['wifi', 'router'],
    'phone': ['phone', 'smartphone'],
    'insurance': ['security', 'shield'],
    
    // Health & Fitness
    'health': ['health', 'medical'],
    'medical': ['health', 'medical'],
    'doctor': ['medical', 'health'],
    'pharmacy': ['medical'],
    'gym': ['fitness', 'sports'],
    'fitness': ['fitness', 'sports'],
    'sports': ['sports', 'fitness'],
    
    // Education
    'education': ['school', 'book'],
    'school': ['school', 'book'],
    'books': ['book'],
    'course': ['school', 'book'],
    'learning': ['school', 'book'],
    
    // Personal
    'personal': ['person', 'account'],
    'beauty': ['spa', 'face'],
    'haircut': ['content_cut'],
    'salon': ['spa', 'face'],
    
    // Finance
    'savings': ['savings', 'piggy_bank'],
    'investment': ['trending_up', 'chart'],
    'stocks': ['trending_up', 'chart'],
    'crypto': ['currency_bitcoin'],
    
    // Pets
    'pet': ['pets'],
    'pets': ['pets'],
    'dog': ['pets'],
    'cat': ['pets'],
    
    // Kids
    'kids': ['child', 'toys'],
    'children': ['child', 'toys'],
    'baby': ['child', 'toys'],
    
    // Gifts
    'gift': ['gift', 'card_giftcard'],
    'gifts': ['gift', 'card_giftcard'],
    'birthday': ['cake', 'gift'],
    'party': ['celebration', 'cake'],
  };

  /// Suggest icon based on category name (fuzzy matching)
  static String? suggestIcon(String categoryName) {
    if (categoryName.isEmpty) return null;
    
    final lowerName = categoryName.toLowerCase().trim();
    
    // Direct match
    if (_keywordToIcons.containsKey(lowerName)) {
      return _keywordToIcons[lowerName]!.first;
    }
    
    // Partial match (word contains keyword)
    for (final entry in _keywordToIcons.entries) {
      if (lowerName.contains(entry.key) || entry.key.contains(lowerName)) {
        return entry.value.first;
      }
    }
    
    // No match - return null (use default)
    return null;
  }

  /// Get confidence score for suggestion (0.0 - 1.0)
  /// Ready for ML model integration
  static double getConfidence(String categoryName, String iconName) {
    final suggestion = suggestIcon(categoryName);
    if (suggestion == iconName) return 1.0;
    if (suggestion != null) return 0.5;
    return 0.0;
  }
}

// =============================================================================
// CATEGORY LIST SCREEN
// =============================================================================

class CategoryListScreen extends ConsumerWidget {
  const CategoryListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupedCategoriesAsync = ref.watch(groupedCategoriesProvider);

    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.commonCategories),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              HapticFeedback.lightImpact();
              _showEditor(context, ref, null);
            },
          ),
        ],
      ),
      body: groupedCategoriesAsync.when(
        data: (grouped) {
          if (grouped.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Icon(Icons.category_outlined, size: 64, color: Theme.of(context).disabledColor),
                   const SizedBox(height: 16),
                   Text(l10n.categoryNoCategories, style: AppTypography.titleMedium.copyWith(color: Theme.of(context).disabledColor)),
                   const SizedBox(height: 24),
                   FilledButton.icon(
                     onPressed: () {
                       HapticFeedback.lightImpact();
                       _showEditor(context, ref, null);
                     },
                     icon: const Icon(Icons.add),
                     label: Text(l10n.categoryAdd),
                   ),
                ],
              ),
            );
          }
          
          final parents = grouped.keys.toList();
          return LayoutBuilder(
            builder: (context, constraints) {
              final horizontalPadding = constraints.maxWidth < 360 ? 12.0 : 16.0;
              return ListView.builder(
                itemCount: parents.length,
                padding: EdgeInsets.all(horizontalPadding),
                physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              final parent = parents[index];
              final children = grouped[parent] ?? [];
              
              return _CategoryGroupCard(
                parent: parent,
                children: children,
                onEditParent: () => _showEditor(context, ref, parent),
                onAddChild: () => _showEditor(context, ref, null, parentId: parent.id),
                onEditChild: (child) => _showEditor(context, ref, child),
                onDeleteCategory: (cat) => _deleteWithUndo(context, ref, cat),
              );
            },
          );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, stack) => Center(child: Text('Error: $e')),
      ),
    );
  }

  void _showEditor(BuildContext context, WidgetRef ref, Category? category, {String? parentId}) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CategoryEditorSheet(
        existingCategory: category, 
        parentId: parentId,
      ),
    );
  }

  void _deleteWithUndo(BuildContext context, WidgetRef ref, Category category) {
    HapticFeedback.mediumImpact();
    
    // Store for undo
    final deletedCategory = category;
    
    // Delete immediately
    ref.read(categoryControllerProvider).deleteCategory(category.id);
    ref.invalidate(groupedCategoriesProvider);
    
    // Show iOS-style undo snackbar
    ScaffoldMessenger.of(context).clearSnackBars();
    AppSnackBar.showUndo(
      context,
      message: AppLocalizations.of(context)!.categoryDeleted(deletedCategory.name),
      onUndo: () {
        HapticFeedback.lightImpact();
        // Restore category
        ref.read(categoryControllerProvider).createCategory(
          name: deletedCategory.name,
          type: deletedCategory.type,
          iconName: deletedCategory.iconName,
          colorHex: deletedCategory.colorHex,
          parentId: deletedCategory.parentId,
        );
        ref.invalidate(groupedCategoriesProvider);
      },
    );
  }
}

// =============================================================================
// CATEGORY GROUP CARD (with Swipe-to-Delete)
// =============================================================================

class _CategoryGroupCard extends ConsumerWidget {
  final Category parent;
  final List<Category> children;
  final VoidCallback onEditParent;
  final VoidCallback onAddChild;
  final Function(Category) onEditChild;
  final Function(Category) onDeleteCategory;

  const _CategoryGroupCard({
    required this.parent,
    required this.children,
    required this.onEditParent,
    required this.onAddChild,
    required this.onEditChild,
    required this.onDeleteCategory,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final parentColor = _parseColor(parent.colorHex);
    final spendingStatsAsync = ref.watch(categorySpendingStatsProvider);

    return Dismissible(
      key: Key('category_${parent.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        HapticFeedback.mediumImpact();
        return await showDialog<bool>(
          context: context,
          builder: (c) => Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.delete_forever_rounded,
                      color: AppColors.danger,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context)!.categoryDeleteTitle,
                    style: AppTypography.titleLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context)!.categoryDeleteMsg(parent.name),
                      style: AppTypography.bodyMedium.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(c, false),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(AppLocalizations.of(context)!.commonCancel),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () => Navigator.pop(c, true),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.danger,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(AppLocalizations.of(context)!.commonDelete),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ) ?? false;
      },
      onDismissed: (_) => onDeleteCategory(parent),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppColors.danger,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.white, size: 28),
      ),
      child: Card(
        elevation: 0,
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: const EdgeInsets.only(bottom: 16),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: _AppleIconPreview(
              icon: AppGradeIcons.getIcon(parent.iconName),
              color: parentColor,
              size: 48,
            ),
            title: Text(
              parent.name,
              style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w600),
            ),
            subtitle: spendingStatsAsync.when(
              data: (stats) {
                final parentStats = stats[parent.id];
                final spent = parentStats?.totalSpent ?? 0.0;
                
                // Also sum up children spending for the group total
                double groupTotal = spent;
                for (final child in children) {
                   groupTotal += stats[child.id]?.totalSpent ?? 0.0;
                }
                
                if (groupTotal == 0) {
                   return children.isNotEmpty 
                      ? Text(AppLocalizations.of(context)!.categorySubCount(children.length), style: AppTypography.bodySmall) 
                      : null;
                }
                
                return Row(
                  children: [
                    Icon(Icons.payments_outlined, size: 14, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 4),
                    Text(
                      AppLocalizations.of(context)!.categorySpentMonth('₹${groupTotal.toStringAsFixed(0)}'),
                      style: AppTypography.bodySmall.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                );
              },
              loading: () => null,
              error: (_, __) => null,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_horiz_rounded, color: Colors.grey),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  onSelected: (value) {
                    if (value == 'edit') {
                      HapticFeedback.lightImpact();
                      onEditParent();
                    } else if (value == 'merge') {
                      HapticFeedback.lightImpact();
                      showMergeDialog(context, ref, parent);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          const Icon(Icons.edit_rounded, size: 20),
                          const SizedBox(width: 12),
                          Text(AppLocalizations.of(context)!.commonEdit),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'merge',
                      child: Row(
                        children: [
                          const Icon(Icons.merge_type_rounded, size: 20),
                          const SizedBox(width: 12),
                          Text(AppLocalizations.of(context)!.commonMerge),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                const Icon(Icons.expand_more_rounded),
              ],
            ),
            children: [
              ...children.map((child) {
                final childColor = _parseColor(child.colorHex);
                return Dismissible(
                  key: Key('subcategory_${child.id}'),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) => onDeleteCategory(child),
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 24),
                    color: AppColors.danger.withValues(alpha: 0.1),
                    child: Icon(Icons.delete_rounded, color: AppColors.danger, size: 20),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.only(left: 72, right: 16),
                    leading: child.iconName != null
                      ? CPAppIcon(
                          icon: AppGradeIcons.getIcon(child.iconName),
                          color: childColor,
                          size: 32,
                          useGradient: false,
                        )
                      : Icon(Icons.circle, size: 8, color: childColor.withValues(alpha: 0.5)),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(child.name, style: AppTypography.bodyMedium),
                        spendingStatsAsync.when(
                          data: (stats) {
                            final childStats = stats[child.id];
                            if (childStats == null || childStats.totalSpent == 0) return const SizedBox();
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '₹${childStats.totalSpent.toStringAsFixed(0)}',
                                style: AppTypography.labelSmall.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          },
                          loading: () => const SizedBox(),
                          error: (_, __) => const SizedBox(),
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit_rounded, size: 18),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        onEditChild(child);
                      },
                      splashRadius: 20,
                    ),
                    dense: true,
                  ),
                );
              }),
              Padding(
                padding: const EdgeInsets.fromLTRB(72, 8, 16, 16),
                child: OutlinedButton.icon(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    onAddChild();
                  },
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text(AppLocalizations.of(context)!.categoryAddSub),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 40),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return Colors.blue;
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return Colors.blue;
    }
  }
}

// =============================================================================
// APPLE-GRADE ICON PREVIEW (Depth + Reflection)
// =============================================================================

class _AppleIconPreview extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;

  const _AppleIconPreview({
    required this.icon,
    required this.color,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.9), color],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size * 0.22),
        boxShadow: [
          // Depth shadow
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: size * 0.3,
            offset: Offset(0, size * 0.15),
          ),
          // Inner glow
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.2),
            blurRadius: 2,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Reflection layer
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: size * 0.4,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(size * 0.22)),
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.3),
                    Colors.white.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          // Icon
          Center(
            child: Icon(
              icon,
              size: size * 0.5,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// CATEGORY EDITOR SHEET (with Intelligence & iOS Vibrancy)
// =============================================================================

class CategoryEditorSheet extends ConsumerStatefulWidget {
  final Category? existingCategory;
  final String? parentId;

  const CategoryEditorSheet({super.key, this.existingCategory, this.parentId});

  @override
  ConsumerState<CategoryEditorSheet> createState() => _CategoryEditorSheetState();
}

class _CategoryEditorSheetState extends ConsumerState<CategoryEditorSheet>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  
  String? _selectedIconName;
  Color? _selectedColor;
  bool _isLoading = false;
  String? _suggestedIconName;
  
  late AnimationController _springController;
  late Animation<double> _springAnimation;

  @override
  void initState() {
    super.initState();
    
    // Spring animation for icon preview
    _springController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _springAnimation = CurvedAnimation(
      parent: _springController,
      curve: Curves.elasticOut,
    );
    
    if (widget.existingCategory != null) {
      _nameController.text = widget.existingCategory!.name;
      _selectedIconName = widget.existingCategory!.iconName;
      if (widget.existingCategory!.colorHex != null) {
        try {
          _selectedColor = Color(int.parse(widget.existingCategory!.colorHex!.replaceFirst('#', '0xFF')));
        } catch (_) {}
      }
    } else {
       // Smart defaults
       _selectedIconName = 'cart';
       _selectedColor = const Color(0xFF4A90E2);
    }
    
    // Listen for name changes to suggest icons
    _nameController.addListener(_onNameChanged);
    
    // Trigger spring animation
    _springController.forward();
  }

  @override
  void dispose() {
    _nameController.removeListener(_onNameChanged);
    _nameController.dispose();
    _springController.dispose();
    super.dispose();
  }

  void _onNameChanged() {
    final suggested = IconSuggestionEngine.suggestIcon(_nameController.text);
    if (suggested != _suggestedIconName) {
      setState(() {
        _suggestedIconName = suggested;
      });
      // Bounce animation when suggestion changes
      if (suggested != null) {
        _springController.reset();
        _springController.forward();
        HapticFeedback.selectionClick();
      }
    }
  }

  void _applySuggestion() {
    if (_suggestedIconName != null) {
      setState(() {
        _selectedIconName = _suggestedIconName;
      });
      _springController.reset();
      _springController.forward();
      HapticFeedback.lightImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingCategory != null;
    final accent = _selectedColor ?? Theme.of(context).primaryColor;
    final theme = Theme.of(context);

    return GestureDetector(
      onVerticalDragEnd: (details) {
        // Swipe-to-dismiss
        if (details.primaryVelocity != null && details.primaryVelocity! > 500) {
          HapticFeedback.lightImpact();
          Navigator.pop(context);
        }
      },
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor.withValues(alpha: 0.95),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 30,
                  offset: const Offset(0, -10),
                ),
              ],
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              left: 20,
              right: 20,
              top: 12,
            ),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Handle Bar
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: theme.dividerColor.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    Text(
                      isEditing ? 'Edit Category' : 'New Category',
                      style: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    
                    // Apple-Grade Icon Preview with Spring Animation
                    Center(
                      child: ScaleTransition(
                        scale: _springAnimation,
                        child: _AppleIconPreview(
                          icon: AppGradeIcons.getIcon(_selectedIconName),
                          color: accent,
                          size: 96,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Name Field with Suggestion Hint
                    TextFormField(
                      controller: _nameController,
                      style: AppTypography.bodyLarge,
                      decoration: InputDecoration(
                        labelText: 'Name',
                        hintText: 'e.g., Groceries, Coffee, Transport',
                        prefixIcon: const Icon(Icons.label_rounded),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        floatingLabelBehavior: FloatingLabelBehavior.never,
                      ),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    
                    // Inline Icon Suggestion
                    if (_suggestedIconName != null && _suggestedIconName != _selectedIconName) ...[
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: _applySuggestion,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: accent.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.auto_awesome, size: 18, color: accent),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Suggested icon: $_suggestedIconName',
                                  style: AppTypography.bodySmall.copyWith(color: accent),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: accent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Apply',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 32),
                    Text('Icon', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 16),
                    CategoryIconSelector(
                      selectedIconName: _selectedIconName,
                      accentColor: accent,
                      onIconSelected: (val) {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedIconName = val);
                        _springController.reset();
                        _springController.forward();
                      },
                    ),
                    
                    const SizedBox(height: 32),
                    Text('Color', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 16),
                    CategoryColorSelector(
                      selectedColor: _selectedColor,
                      onColorSelected: (val) {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedColor = val);
                      },
                    ),

                    const SizedBox(height: 40),
                    
                    // Action Buttons
                    Row(
                      children: [
                         if (isEditing) ...[
                           Expanded(
                              child: TextButton(
                                onPressed: () => _confirmDelete(context, widget.existingCategory!),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                                child: const Text('Delete'),
                              ),
                           ),
                           const SizedBox(width: 16),
                         ],
                         
                         Expanded(
                           flex: 2,
                           child: FilledButton(
                             onPressed: _isLoading ? null : _save,
                             style: FilledButton.styleFrom(
                               backgroundColor: accent,
                               foregroundColor: Colors.white,
                               padding: const EdgeInsets.symmetric(vertical: 16),
                               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                               elevation: 0,
                             ),
                             child: _isLoading 
                               ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                               : Text(isEditing ? 'Save Changes' : 'Create Category', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                           ),
                         ),
                      ],
                    ),
                    
                    // Cancel button if not editing
                    if (!isEditing) ...[
                       const SizedBox(height: 16),
                       TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('Cancel', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
                       ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Category cat) {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category?'),
        content: Text('Are you sure you want to delete "${cat.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(categoryControllerProvider).deleteCategory(cat.id);
                if (mounted) Navigator.pop(context);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);
    
    try {
      // 1. Validation: Check for duplicate/similar names
      final allCategories = await ref.read(allCategoriesProvider.future);
      final newNameNormalized = _nameController.text.trim().toLowerCase();
      
      final duplicate = allCategories.any((c) {
        // Skip comparing to self if editing
        if (widget.existingCategory != null && c.id == widget.existingCategory!.id) {
          return false;
        }
        return c.name.trim().toLowerCase() == newNameNormalized;
      });
      
      if (duplicate) {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(
               content: Text('Category "${_nameController.text}" already exists'),
               backgroundColor: AppColors.warning,
               behavior: SnackBarBehavior.floating,
             ),
           );
           setState(() => _isLoading = false);
        }
        return;
      }
      
      final controller = ref.read(categoryControllerProvider);
      final colorHex = '#${(_selectedColor ?? Colors.blue).toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';
      
      if (widget.existingCategory != null) {
        await controller.updateCategory(
          id: widget.existingCategory!.id,
          name: _nameController.text,
          iconName: _selectedIconName,
          colorHex: colorHex,
        );
      } else {
        await controller.createCategory(
          name: _nameController.text,
          type: 'expense',
          iconName: _selectedIconName,
          colorHex: colorHex,
          parentId: widget.parentId,
        );
      }
      
      ref.invalidate(groupedCategoriesProvider);
      
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'Error: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
