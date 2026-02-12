/// Category Form Screen
/// Add or edit a budget category (semi-budget)
/// Enhanced with Intelligence & Apple-grade UX
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../features/budgets/providers/budget_providers.dart';
import '../../../features/categories/providers/category_providers.dart';
import '../../../data/drift/app_database.dart'; 
import '../../widgets/input/category_icon_selector.dart';
import '../../widgets/input/category_color_selector.dart';
import '../../widgets/common/app_grade_icons.dart';

// Import the shared IconSuggestionEngine
import 'category_list_screen.dart' show IconSuggestionEngine;
import 'package:cashpilot/l10n/app_localizations.dart';

class CategoryFormScreen extends ConsumerStatefulWidget {
  final String budgetId;
  final String? categoryId;

  const CategoryFormScreen({
    super.key,
    required this.budgetId,
    this.categoryId,
  });

  @override
  ConsumerState<CategoryFormScreen> createState() =>
      _CategoryFormScreenState();
}

class _CategoryFormScreenState extends ConsumerState<CategoryFormScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _limitController = TextEditingController();

  String? _selectedIconName;
  Color? _selectedColor;
  int _priority = 3;
  bool _isLoading = false;
  String? _suggestedIconName;
  String? _parentCategoryId;
  String? _masterCategoryId;
  final bool _isPremiumUser = false; // For limiting subcategories if needed

  late AnimationController _springController;
  late Animation<double> _springAnimation;

  bool get isEditing => widget.categoryId != null;

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
    
    _selectedIconName = 'cart'; // Default
    _selectedColor = const Color(0xFF4A90E2);
    
    if (isEditing) _loadCategory();
    
    // Listen for name changes to suggest icons
    _nameController.addListener(_onNameChanged);
    
    _springController.forward();
  }

  @override
  void dispose() {
    _nameController.removeListener(_onNameChanged);
    _nameController.dispose();
    _limitController.dispose();
    _springController.dispose();
    super.dispose();
  }

  void _onNameChanged() {
    final suggested = IconSuggestionEngine.suggestIcon(_nameController.text);
    if (suggested != _suggestedIconName) {
      setState(() {
        _suggestedIconName = suggested;
      });
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

  Future<void> _loadCategory() async {
    setState(() => _isLoading = true);
    try {
      final db = ref.read(databaseProvider);
      final category = await db.getSemiBudgetById(widget.categoryId!);
      if (category != null && mounted) {
        _nameController.text = category.name;
        _limitController.text =
            (category.limitAmount / 100).toStringAsFixed(0);
        _selectedIconName = category.iconName;
        _selectedColor = category.colorHex != null
            ? Color(int.parse(category.colorHex!.replaceFirst('#', '0xFF')))
            : null;
        _priority = category.priority;
        _parentCategoryId = category.parentCategoryId;
        _masterCategoryId = category.masterCategoryId;
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = ref.watch(currencyProvider);
    final accent = _selectedColor ?? Theme.of(context).primaryColor;
    final theme = Theme.of(context);

    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? l10n.categoryEdit : l10n.categoryAdd),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () {
            HapticFeedback.lightImpact();
            context.pop();
          },
        ),
        actions: isEditing ? [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            color: AppColors.danger,
            onPressed: () => _confirmDelete(context),
          ),
        ] : null,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isSmallScreen = constraints.maxWidth < 360 || constraints.maxHeight < 600;
          final horizontalPadding = isSmallScreen ? 12.0 : 16.0;
          
          return Form(
            key: _formKey,
            child: ListView(
              padding: EdgeInsets.all(horizontalPadding),
              physics: const BouncingScrollPhysics(),
          children: [
            _buildPreview(accent),
            const SizedBox(height: 24),

            // Parent Category Selector (Hierarchy)
            _buildParentCategorySelector(),
            const SizedBox(height: 24),

            // Master Category Selector
            _buildMasterCategorySelector(),
            const SizedBox(height: 24),

            _buildLabel(l10n.categoryNameLabel),
            _buildTextField(
              controller: _nameController,
              hint: l10n.categoryNameHint,
              icon: Icons.label_rounded,
              keyboardType: TextInputType.text,
            ),
            
            // Inline Icon Suggestion
            if (_suggestedIconName != null && _suggestedIconName != _selectedIconName) ...[
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _applySuggestion,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: accent.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.auto_awesome, size: 18, color: accent),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          l10n.categorySuggestedIcon(_suggestedIconName!),
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
                          l10n.categoryApply,
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

            const SizedBox(height: 24),
            _buildLabel(l10n.categoryLimitLabel),
            _buildTextField(
              controller: _limitController,
              hint: l10n.formAmountHint,
              icon: Icons.euro_rounded,
              prefixText: '${_getCurrencySymbol(currency)} ',
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 24),
            _buildLabel(l10n.categoryIconLabel),
            const SizedBox(height: 12),
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

            const SizedBox(height: 24),
            _buildLabel(l10n.categoryColorLabel),
            const SizedBox(height: 12),
            CategoryColorSelector(
              selectedColor: _selectedColor,
              onColorSelected: (val) {
                HapticFeedback.selectionClick();
                setState(() => _selectedColor = val);
              },
            ),

            const SizedBox(height: 24),
            _buildLabel(l10n.categoryPriorityLabel),
            _buildPrioritySelector(),

            const SizedBox(height: 32),
            SizedBox(
              height: 56,
              child: FilledButton(
                onPressed: _isLoading ? null : _saveCategory,
                style: FilledButton.styleFrom(
                  backgroundColor: accent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2)
                    : Text(
                        isEditing ? l10n.categorySaveChanges : l10n.categoryAdd,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      );
    },
  ),
);
}

  // ---------------------------------------------------------------------------
  // UI PARTS
  // ---------------------------------------------------------------------------

  Widget _buildPreview(Color accent) {
    final l10n = AppLocalizations.of(context)!;
    return ScaleTransition(
      scale: _springAnimation,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
          border: Border.all(color: accent.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            // Apple-grade icon with depth
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(56 * 0.22),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withOpacity(0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(AppGradeIcons.getIcon(_selectedIconName), color: Colors.white, size: 28),
                ),
              ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _nameController.text.isEmpty ? l10n.categoryPreview : _nameController.text,
                    style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w600),
                  ),
                  if (_limitController.text.isNotEmpty)
                    Text(
                      'Limit: ${_getCurrencySymbol(ref.watch(currencyProvider))}${_limitController.text}',
                      style: AppTypography.bodySmall.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrioritySelector() {
    return Row(
      children: List.generate(5, (i) {
        final p = i + 1;
        final selected = _priority == p;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _priority = p);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.only(right: i < 4 ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: selected
                    ? Theme.of(context).primaryColor
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
                boxShadow: selected ? [
                  BoxShadow(
                    color: Theme.of(context).primaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ] : null,
              ),
              child: Center(
                child: Text(
                  '$p',
                  style: TextStyle(
                    color: selected ? Colors.white : null,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildMasterCategorySelector() {
    final categoriesAsync = ref.watch(allCategoriesProvider);

    return categoriesAsync.when(
      data: (categories) {
        if (categories.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel(AppLocalizations.of(context)!.categoryQuickSelect),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  Color? catColor;
                  try {
                    if (cat.colorHex != null) {
                      catColor = Color(int.parse(cat.colorHex!.replaceFirst('#', '0xFF')));
                    }
                  } catch (_) {}
                  
                  return FilterChip(
                    label: Text(cat.name),
                    avatar: cat.iconName != null 
                        ? Icon(AppGradeIcons.getIcon(cat.iconName), size: 16) 
                        : null,
                    onSelected: (_) {
                      HapticFeedback.selectionClick();
                      _autoFillFromMaster(cat);
                    },
                    backgroundColor: catColor?.withOpacity(0.1),
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildParentCategorySelector() {
    final semiBudgetsAsync = ref.watch(semiBudgetsProvider(widget.budgetId));
    final l10n = AppLocalizations.of(context)!;

    return semiBudgetsAsync.when(
      data: (semiBudgets) {
        // Only show root categories as potential parents
        // Also exclude the current category itself if editing
        final potentialParents = semiBudgets.where((s) => 
          s.parentCategoryId == null && s.id != widget.categoryId
        ).toList();

        if (potentialParents.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel(l10n.reportsCategories), // Reusing l10n or adding more
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                borderRadius: BorderRadius.circular(16),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String?>(
                  value: _parentCategoryId,
                  isExpanded: true,
                  hint: const Text('Main Category (Optional)'),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('No Parent (Top Level)'),
                    ),
                    ...potentialParents.map((s) => DropdownMenuItem<String?>(
                      value: s.id,
                      child: Row(
                        children: [
                          Icon(AppGradeIcons.getIcon(s.iconName ?? s.name), size: 18),
                          const SizedBox(width: 8),
                          Text(s.name),
                        ],
                      ),
                    )),
                  ],
                  onChanged: (val) {
                    setState(() => _parentCategoryId = val);
                    HapticFeedback.selectionClick();
                  },
                ),
              ),
            ),
            if (_parentCategoryId != null)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 4),
                child: Text(
                  'This will be a subcategory',
                  style: AppTypography.labelSmall.copyWith(
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  void _autoFillFromMaster(Category cat) {
    setState(() {
      _nameController.text = cat.name;
      if (cat.iconName != null) _selectedIconName = cat.iconName;
      if (cat.colorHex != null) {
        try {
          _selectedColor = Color(int.parse(cat.colorHex!.replaceFirst('#', '0xFF')));
        } catch (_) {}
      }
      _masterCategoryId = cat.id;
    });
    _springController.reset();
    _springController.forward();
  }

  // ---------------------------------------------------------------------------
  // HELPERS
  // ---------------------------------------------------------------------------

  Widget _buildLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w600)),
  );

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    String? prefixText,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: AppTypography.bodyLarge,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon),
        prefixText: prefixText,
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
      validator: (v) => v == null || v.isEmpty ? AppLocalizations.of(context)!.formRequired : null,
    );
  }

  void _confirmDelete(BuildContext context) {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.categoryDeleteTitle),
        content: Text(AppLocalizations.of(context)!.categoryDeleteMsg('')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.commonCancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final controller = ref.read(budgetControllerProvider.notifier);
                await controller.deleteSemiBudget(widget.categoryId!);
                if (mounted) context.pop();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(AppLocalizations.of(context)!.commonErrorMessage(e.toString()))),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: Text(AppLocalizations.of(context)!.commonDelete),
          ),
        ],
      ),
    );
  }

  Future<void> _saveCategory() async {
    if (!_formKey.currentState!.validate()) return;
    
    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);
    
    try {
      final controller = ref.read(budgetControllerProvider.notifier);
      final limit = int.parse(_limitController.text) * 100;
      final colorHex =
          '#${(_selectedColor ?? Theme.of(context).primaryColor).value.toRadixString(16).substring(2)}';

      if (isEditing) {
        await controller.updateSemiBudget(
          id: widget.categoryId!,
          name: _nameController.text,
          limitAmount: limit,
          priority: _priority,
          colorHex: colorHex,
          parentCategoryId: _parentCategoryId,
          masterCategoryId: _masterCategoryId,
        );
      } else {
        await controller.createSemiBudget(
          budgetId: widget.budgetId,
          name: _nameController.text,
          limitAmount: limit,
          priority: _priority,
          iconName: _selectedIconName,
          colorHex: colorHex,
          parentCategoryId: _parentCategoryId,
          masterCategoryId: _masterCategoryId,
        );
      }

      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'Error: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getCurrencySymbol(String code) =>
      {'EUR': '€', 'USD': '\$', 'GBP': '£', 'BDT': '৳'}[code] ?? code;
}
