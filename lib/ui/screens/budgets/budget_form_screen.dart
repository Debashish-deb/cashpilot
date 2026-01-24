import 'package:cashpilot/core/constants/app_constants.dart' show BudgetType;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cashpilot/l10n/app_localizations.dart';
import '../../../core/utils/app_snackbar.dart';

import '../../../core/theme/app_typography.dart';
import '../../../core/providers/app_providers.dart';
import '../../../features/budgets/providers/budget_providers.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../core/constants/default_categories.dart';
import '../../../services/analytics_tracking_service.dart';
import '../../widgets/common/cp_app_icon.dart';
import '../../widgets/budgets/collapsible_section.dart';
import '../../../core/tier/tier_guard.dart';
import '../../widgets/budgets/family_member_selector.dart';

class BudgetFormScreen extends ConsumerStatefulWidget {
  final String? budgetId;

  const BudgetFormScreen({super.key, this.budgetId});

  @override
  ConsumerState<BudgetFormScreen> createState() => _BudgetFormScreenState();
}

class _BudgetFormScreenState extends ConsumerState<BudgetFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _limitController = TextEditingController();
  final _notesController = TextEditingController();
  
  bool _isLoading = false;
  late BudgetType _selectedType;
  late DateTime _startDate;
  late DateTime _endDate;
  bool _isShared = false; // Single (false) vs Family (true) budget
  final List<String> _newCategories = [];
  
  // Enhanced features
  final Map<String, bool> _expandedSections = {
    'categories': false,
    'advanced': false,
  };
  final List<String> _selectedMemberIds = [];
  final List<String> _inviteEmails = [];

  bool get isEditing => widget.budgetId != null;

  @override
  void initState() {
    super.initState();
    _selectedType = BudgetType.monthly;
    _isShared = false;
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1);
    _endDate = DateTime(now.year, now.month + 1, 0);

    if (isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadBudgetData());
    }
  }

  Future<void> _loadBudgetData() async {
    setState(() => _isLoading = true);
    try {
      final database = ref.read(databaseProvider);
      final budget = await database.getBudgetById(widget.budgetId!);
      
      // FIX: Handle deleted/missing budget
      if (budget == null || budget.isDeleted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Budget not found or has been deleted'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          context.pop();
        }
        return;
      }
      
      setState(() {
        _titleController.text = budget.title;
        _limitController.text = (budget.totalLimit != null ? budget.totalLimit! / 100 : '').toString();
        _notesController.text = budget.notes ?? '';
        _selectedType = BudgetType.fromString(budget.type); // FIX: Convert string to enum
        _startDate = budget.startDate;
        _endDate = budget.endDate;
        _isShared = budget.isShared;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading budget: $e')),
        );
        context.pop();
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _limitController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    
    return Scaffold(
      // iOS-style app bar
      appBar: AppBar(
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          isEditing ? l10n.budgetsEditBudget : l10n.budgetsCreateBudget,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 17,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, size: 22),
          onPressed: () => context.pop(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(
            height: 0.5,
            color: theme.dividerColor.withValues(alpha: 0.1),
          ),
        ),
      ),
      
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isSmallScreen = constraints.maxWidth < 360 || constraints.maxHeight < 600;
          final horizontalPadding = isSmallScreen ? 12.0 : 16.0;
          
          return Form(
            key: _formKey,
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 12),
          children: [
            // ULTRA-COMPACT: Title + Amount in ONE card
            Container(
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
                  // Title field - full width
                  TextFormField(
                    controller: _titleController,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      hintText: l10n.formTitleHint,
                      hintStyle: TextStyle(
                        color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.3),
                        fontWeight: FontWeight.w600,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    validator: (value) => value?.isEmpty ?? true ? l10n.formRequired : null,
                  ),
                  const SizedBox(height: 12),
                  // Amount - with large currency display
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        _getCurrencySymbol(ref.watch(currencyProvider)),
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: TextFormField(
                          controller: _limitController,
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.primary,
                          ),
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: l10n.formAmountHint,
                            hintStyle: TextStyle(
                              color: theme.colorScheme.primary.withValues(alpha: 0.3),
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // COMPACT: Type + Dates in minimal space
            Container(
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
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  // Type chips - single row, compact
                  Row(
                    children: [
                      _CompactTypeChip(
                        label: l10n.formTypeMonth,
                        icon: Icons.calendar_month,
                        isSelected: _selectedType == BudgetType.monthly,
                        onTap: () {
                          setState(() => _selectedType = BudgetType.monthly);
                          _setDefaultDates();
                        },
                      ),
                      const SizedBox(width: 8),
                      _CompactTypeChip(
                        label: l10n.formTypeWeek,
                        icon: Icons.calendar_view_week,
                        isSelected: _selectedType == BudgetType.weekly,
                        onTap: () {
                          setState(() => _selectedType = BudgetType.weekly);
                          _setDefaultDates();
                        },
                      ),
                      const SizedBox(width: 8),
                      _CompactTypeChip(
                        label: l10n.formTypeYear,
                        icon: Icons.calendar_today,
                        isSelected: _selectedType == BudgetType.annual,
                        onTap: () {
                          setState(() => _selectedType = BudgetType.annual);
                          _setDefaultDates();
                        },
                      ),
                      const SizedBox(width: 8),
                      _CompactTypeChip(
                        label: l10n.formTypeCustom,
                        icon: Icons.tune,
                        isSelected: _selectedType == BudgetType.custom,
                        onTap: () => setState(() => _selectedType = BudgetType.custom),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.2)),
                  const SizedBox(height: 12),
                  // Dates - compact inline
                  Row(
                    children: [
                      Expanded(
                        child: _CompactDateButton(
                          label: DateFormat('MMM d').format(_startDate),
                          onTap: () => _selectDate(isStart: true),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Icon(
                          Icons.arrow_forward,
                          size: 16,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),
                      Expanded(
                        child: _CompactDateButton(
                          label: DateFormat('MMM d').format(_endDate),
                          onTap: () => _selectDate(isStart: false),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // FAMILY SHARING (Collapsible or Direct)
            if (_isShared)
              Column(
                children: [
                  Container(
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
                    child: Column(
                      children: [
                        _buildSharingToggle(l10n, theme),
                        Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.2)),
                        FamilyMemberSelector(
                          selectedMemberIds: _selectedMemberIds,
                          inviteEmails: _inviteEmails,
                          onMembersChanged: (ids) {
                            setState(() {
                              _selectedMemberIds.clear();
                              _selectedMemberIds.addAll(ids);
                            });
                          },
                          onEmailsChanged: (emails) {
                            setState(() {
                              _inviteEmails.clear();
                              _inviteEmails.addAll(emails);
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              )
            else
              Column(
                children: [
                  Container(
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
                    child: _buildSharingToggle(l10n, theme),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            
            // CATEGORIES (Collapsible) - only when creating
            if (!isEditing) ...[
              CollapsibleSection(
                title: l10n.formSectionCategories,
                badge: _newCategories.isEmpty ? null : '${_newCategories.length}',
                isExpanded: _expandedSections['categories']!,
                onToggle: () => setState(() => _expandedSections['categories'] = !_expandedSections['categories']!),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildCategoriesSection(l10n),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            
            // ADVANCED (Collapsible)
            CollapsibleSection(
              title: l10n.formSectionAdvanced,
              isExpanded: _expandedSections['advanced']!,
              onToggle: () => setState(() => _expandedSections['advanced'] = !_expandedSections['advanced']!),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.budgetsNotes,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _notesController,
                        style: const TextStyle(fontSize: 15),
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: l10n.formNotes,
                          filled: true,
                          fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.all(12),
                          isDense: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            // SAVE BUTTON
            _buildSaveButton(l10n),
            
            const SizedBox(height: 24),
            ],
          ),
        );
      },
    ));
  }


  // ================================================
  // HELPER METHODS - Apple-inspired UI components
  // ================================================

  /// Build a grouped section card (iOS Settings style)
  // ignore: unused_element
  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ),
        
        // Card
        Container(
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
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  /// Build inline field (iOS Settings style label-value pair)
  // ignore: unused_element
  Widget _buildInlineField({
    required String label,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }

  /// Build subtle divider
  // ignore: unused_element
  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: Divider(
        height: 1,
        thickness: 0.5,
        color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
      ),
    );
  }

  /// Build date row (tappable)
  // ignore: unused_element
  Widget _buildDateRow(String label, DateTime date, bool isStart) {
    return InkWell(
      onTap: () => _selectDate(isStart: isStart),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            SizedBox(
              width: 100,
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('MMM d, yyyy').format(date),
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ],
        ),
      ),
    );
  }

  /// Build save button
  Widget _buildSaveButton(AppLocalizations l10n) {
    return SizedBox(
      height: 54,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveBudget,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                isEditing ? l10n.commonSave : l10n.budgetsCreateBudget,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  // Controller for new category input
  final TextEditingController _categoryController = TextEditingController();

  void _setDefaultDates() {
    final now = DateTime.now();
    switch (_selectedType) {
      case BudgetType.weekly:
        // Start from Monday of current week
        _startDate = now.subtract(Duration(days: now.weekday - 1));
        _endDate = _startDate.add(const Duration(days: 6));
        break;
      case BudgetType.monthly:
        _startDate = DateTime(now.year, now.month, 1);
        _endDate = DateTime(now.year, now.month + 1, 0);
        break;
      case BudgetType.annual:
        _startDate = DateTime(now.year, 1, 1);
        _endDate = DateTime(now.year, 12, 31);
        break;
      case BudgetType.custom:
        // Don't change dates for custom
        break;
      default:
        break;
    }
    setState(() {});
  }

  Widget _buildCategoriesSection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Add category button
        OutlinedButton.icon(
          onPressed: _addDefaultCategories,
          icon: const Icon(Icons.grid_view_rounded, size: 18),
          label: Text(_newCategories.isEmpty ? l10n.categorySelect : l10n.categoryModify),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 44),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Selected categories
        if (_newCategories.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _newCategories.map((catKey) {
              final defaultCat = industrialCategories.firstWhere(
                (c) => c.localizationKey == catKey,
                orElse: () => LocalizedCategory(
                  localizationKey: catKey,
                  groupKey: '',
                  colorHex: '#808080',
                ),
              );
              
              final label = defaultCat.getLocalizedName(context);
              final color = defaultCat.resolveColor(context);
              
              return Chip(
                avatar: CPAppIcon(
                  icon: defaultCat.resolveIcon(),
                  color: color,
                  size: 24,
                  iconSize: 14,
                  useGradient: true,
                  useShadow: false,
                ),
                label: Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onDeleted: () {
                  setState(() => _newCategories.remove(catKey));
                },
                deleteIconColor: color.withValues(alpha: 0.6),
                backgroundColor: color.withValues(alpha: 0.1),
                side: BorderSide(
                  color: color.withValues(alpha: 0.2),
                  width: 1.0,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              );
            }).toList(),
          ),
          
        if (isEditing)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text(
              l10n.categoryNoteExisting,
              style: AppTypography.bodySmall,
            ),
          ),
      ],
    );
  }

  // ignore: unused_element
  void _addCategory() {
    final text = _categoryController.text.trim();
    if (text.isNotEmpty && !_newCategories.contains(text)) {
      setState(() {
        _newCategories.add(text);
        _categoryController.clear();
      });
    }
  }

  // ignore: unused_element
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    Widget? prefix,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.labelLarge.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          style: AppTypography.bodyLarge.copyWith(
            color: isLight ? Colors.black : Colors.white,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: isLight ? Colors.black38 : Colors.white30,
            ),
            prefixIcon: Icon(icon, color: Theme.of(context).primaryColor),
            prefix: prefix,
            filled: true,
            fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.2), 
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.2), 
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: Theme.of(context).primaryColor,
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }

  // ignore: unused_element
  Widget _buildTypeSelector(AppLocalizations l10n) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _TypeChip(
          label: l10n.budgetTypeMonthly,
          icon: Icons.calendar_month_outlined,
          isSelected: _selectedType == BudgetType.monthly,
          onTap: () {
            setState(() => _selectedType = BudgetType.monthly);
            _setDefaultDates();
          },
        ),
        _TypeChip(
          label: l10n.budgetTypeWeekly,
          icon: Icons.calendar_view_week_outlined,
          isSelected: _selectedType == BudgetType.weekly,
          onTap: () {
            setState(() => _selectedType = BudgetType.weekly);
            _setDefaultDates();
          },
        ),
        _TypeChip(
          label: l10n.budgetTypeAnnual,
          icon: Icons.calendar_today_outlined,
          isSelected: _selectedType == BudgetType.annual,
          onTap: () {
            setState(() => _selectedType = BudgetType.annual);
            _setDefaultDates();
          },
        ),
        _TypeChip(
          label: l10n.budgetTypeCustom,
          icon: Icons.tune_outlined,
          isSelected: _selectedType == BudgetType.custom,
          onTap: () {
            setState(() => _selectedType = BudgetType.custom);
          },
        ),
      ],
    );
  }
  Widget _buildSharingSelector(AppLocalizations l10n) {
    final subscriptionTierAsync = ref.watch(subscriptionTierProvider);
    final isProPlus = subscriptionTierAsync.valueOrNull == 'pro_plus';
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Family Budget',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                Text(
                  isProPlus 
                      ? 'Share with family members' 
                      : 'Requires Pro Plus',
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
          ),
          CupertinoSwitch(
            value: _isShared,
            onChanged: isProPlus
                ? (val) => setState(() => _isShared = val)
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildDateRangeSelector(AppLocalizations l10n) {
    final dateFormat = DateFormat('MMM d, yyyy');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.budgetsDateRange,
          style: AppTypography.labelLarge.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _DateButton(
                label: l10n.budgetDateStart,
                date: dateFormat.format(_startDate),
                onTap: () => _selectDate(isStart: true),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Icon(Icons.arrow_forward_rounded, size: 20),
            ),
            Expanded(
              child: _DateButton(
                label: l10n.budgetDateEnd,
                date: dateFormat.format(_endDate),
                onTap: () => _selectDate(isStart: false),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _selectDate({required bool isStart}) async {
    final initialDate = isStart ? _startDate : _endDate;
    final firstDate = isStart
        ? DateTime.now().subtract(const Duration(days: 365))
        : _startDate;
    final lastDate = DateTime.now().add(const Duration(days: 365 * 5));

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate.add(const Duration(days: 1));
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _addDefaultCategories() {
    _showCategorySelectionDialog();
  }

  Future<void> _showCategorySelectionDialog() async {
    // Group categories by localized group key
    final groups = <String, List<LocalizedCategory>>{};
    for (var cat in industrialCategories) {
      if (!groups.containsKey(cat.groupKey)) {
        groups[cat.groupKey] = [];
      }
      groups[cat.groupKey]!.add(cat);
    }

    // Temporary list of selected category localization keys
    final selected = List<String>.from(_newCategories);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.9,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (dialogContext, scrollController) {
                return Column(
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              AppLocalizations.of(dialogContext)!.budgetsCategories, 
                              style: AppTypography.titleLarge,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _newCategories.clear();
                                _newCategories.addAll(selected);
                              });
                              dialogContext.pop();
                            },
                            child: Text(AppLocalizations.of(dialogContext)!.commonSave),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    
                    // Apple-style Grid List
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        itemCount: groups.length,
                        itemBuilder: (dialogContext, index) {
                          final groupKey = groups.keys.elementAt(index);
                          final categories = groups[groupKey]!;
                          final localizedGroup = categories.first.getLocalizedGroup(dialogContext);
                          
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Group Header
                              Padding(
                                padding: const EdgeInsets.fromLTRB(8, 24, 8, 12),
                                child: Text(
                                  localizedGroup.toUpperCase(),
                                  style: AppTypography.labelSmall.copyWith(
                                    color: Theme.of(dialogContext).colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                              // Apple-style 4-column Grid
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 4,
                                  mainAxisSpacing: 8,
                                  crossAxisSpacing: 8,
                                  childAspectRatio: 0.85,
                                ),
                                itemCount: categories.length,
                                itemBuilder: (context, catIndex) {
                                  final cat = categories[catIndex];
                                  final isSelected = selected.contains(cat.localizationKey);
                                  final localizedName = cat.getLocalizedName(dialogContext);
                                  final color = cat.resolveColor(dialogContext);
                                  
                                  return GestureDetector(
                                    onTap: () {
                                      HapticFeedback.selectionClick();
                                      setModalState(() {
                                        if (isSelected) {
                                          selected.remove(cat.localizationKey);
                                        } else {
                                          selected.add(cat.localizationKey);
                                        }
                                      });
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      decoration: BoxDecoration(
                                        // Transparent background, tinted only when selected
                                        color: isSelected 
                                            ? color.withValues(alpha: 0.12)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(16),
                                        // No border for clean Apple look
                                      ),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          // Icon on Top
                                          CPAppIcon(
                                            icon: cat.resolveIcon(),
                                            color: color,
                                            size: 44,
                                            iconSize: 24,
                                            useGradient: true,
                                            useShadow: isSelected,
                                          ),
                                          const SizedBox(height: 6),
                                          // Title Below
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 2),
                                            child: Text(
                                              localizedName,
                                              textAlign: TextAlign.center,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: AppTypography.labelSmall.copyWith(
                                                fontSize: 10,
                                                color: isSelected 
                                                    ? color 
                                                    : Theme.of(dialogContext).colorScheme.onSurface.withValues(alpha: 0.8),
                                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                                height: 1.1,
                                              ),
                                            ),
                                          ),
                                          // Checkmark indicator for selected
                                          if (isSelected)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 2),
                                              child: Icon(
                                                Icons.check_circle,
                                                size: 14,
                                                color: color,
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
                        },
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
  Future<void> _showUpgradeDialog(TierValidationResult result) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limit Reached'),
        content: Text(result.toString()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to subscription screen if it exists, or show upgrade info
            },
            child: const Text('Upgrade'),
          ),
        ],
      ),
    );
  }


  Future<void> _saveBudget() async {
    if (!_formKey.currentState!.validate()) return;

    if (!isEditing && _newCategories.isEmpty) {
      // Prompt user with a compact, elegant dialog
      final confirm = await showDialog<bool>(
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
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.category_outlined,
                    color: Theme.of(context).primaryColor,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'No Categories?',
                  style: AppTypography.titleLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Add default categories for better expense tracking?',
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
                        child: const Text('Skip'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          _addDefaultCategories();
                          Navigator.pop(c, true);
                        },
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Add'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
      
      if (confirm == true) {
        // Categories were added, continue to save (don't return early)
      } else if (confirm == null) {
        // Cancelled
        return;
      }
      // false = continue to save without categories
    }

    // Capture navigation references before any async operations
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;

    // 1. TIER VALIDATION PRE-CHECK
    try {
      final tier = await ref.read(subscriptionTierProvider.future);
      
      if (!isEditing) {
        // Check budget limit
        // We'd need current budget count here, but for now we focus on the reported Category limit.
      }

      // Check category limit
      // The user wants to create 16 categories. TierGuard allows 20.
      final categoryCheck = await TierGuard.canAddCategory(
        tier: tier,
        currentCategoryCount: _newCategories.length,
      );

      if (!categoryCheck.isAllowed) {
        await _showUpgradeDialog(categoryCheck);
        return;
      }
    } catch (e) {
      debugPrint('Tier check failed (non-blocking): $e');
    }

    setState(() => _isLoading = true);

    try {
      final controller = ref.read(budgetControllerProvider.notifier);
      final limit = int.tryParse(_limitController.text);
      String budgetId;

      if (isEditing) {
        budgetId = widget.budgetId!;
        await controller.updateBudget(
          id: budgetId,
          title: _titleController.text,
          type: _selectedType.value,
          startDate: _startDate,
          endDate: _endDate,
          totalLimit: limit != null ? limit * 100 : null,
          notes: _notesController.text.isEmpty ? null : _notesController.text,
          isShared: _isShared,
        );
      } else {
        budgetId = await controller.createBudget(
          title: _titleController.text,
          type: _selectedType.value,
          startDate: _startDate,
          endDate: _endDate,
          currency: ref.read(currencyProvider),
          totalLimit: limit != null ? limit * 100 : null,
          notes: _notesController.text.isEmpty ? null : _notesController.text,
          isShared: _isShared,
        );
      }
      
      // Create categories
      for (final catKey in _newCategories) {
        // Find metadata by localization key
        final defaultCat = industrialCategories.firstWhere(
          (c) => c.localizationKey == catKey, 
          orElse: () => LocalizedCategory(
            localizationKey: catKey, 
            groupKey: 'catGroupTech', // fallback
            colorHex: '#808080',
          ),
        );

        // Get the localized name to save to DB (using current language)
        final localizedName = defaultCat.getLocalizedName(context);

        await controller.createSemiBudget(
          budgetId: budgetId,
          name: localizedName,
          limitAmount: 0, // Default 0 limit implies no specific limit
          iconName: defaultCat.iconName,
          colorHex: defaultCat.colorHex,
        );
      }

      // Track analytics
      final currency = ref.read(currencyProvider);
      analyticsService.trackEvent(AnalyticsEventType.budgetCreated, {
        'is_edit': isEditing,
        'type': _selectedType.toString().split('.').last,
        'limit_amount': limit ?? 0,
        'category_count': _newCategories.length,
        'currency': currency,
      });

      // Navigate back immediately
      navigator.pop();
      AppSnackBar.showSuccess(context, isEditing ? 'Budget updated!' : 'Budget created!');
    } catch (e) {
      AppSnackBar.showError(context, 'Error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getCurrencySymbol(String code) {
    switch (code) {
      case 'EUR':
        return '€';
      case 'USD':
        return '\$';
      case 'GBP':
        return '£';
      case 'BDT':
        return '৳';
      default:
        return code;
    }
  }

  // Build sharing toggle - for family budget section
  Widget _buildSharingToggle(AppLocalizations l10n, ThemeData theme) {
    final subscriptionTierAsync = ref.watch(subscriptionTierProvider);
    final isProPlus = subscriptionTierAsync.valueOrNull == 'pro_plus';
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Family Budget',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  isProPlus 
                      ? 'Share with family members' 
                      : 'Requires Pro Plus',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
          ),
          CupertinoSwitch(
            value: _isShared,
            onChanged: isProPlus
                ? (val) => setState(() => _isShared = val)
                : null,
          ),
        ],
      ),
    );
  }
}

// Compact Type Chip Widget
class _CompactTypeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _CompactTypeChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primaryContainer
                : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
            border: isSelected
                ? Border.all(color: theme.colorScheme.primary, width: 1.5)
                : null,
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.textTheme.bodyMedium?.color,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.textTheme.bodyMedium?.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

//Compact Date Button Widget
class _CompactDateButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _CompactDateButton({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today,
              size: 14,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: theme.textTheme.bodyMedium?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _TypeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected
          ? Theme.of(context).primaryColor.withValues(alpha: 0.15)
          : Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : Colors.transparent,
              width: 2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Theme.of(context).colorScheme.onSurface,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateButton extends StatelessWidget {
  final String label;
  final String date;
  final VoidCallback onTap;

  const _DateButton({
    required this.label,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.labelSmall.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                date,
                style: AppTypography.titleSmall.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
