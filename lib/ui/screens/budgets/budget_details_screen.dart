import 'package:cashpilot/services/sync_engine.dart' show syncEngineProvider;
import 'package:cashpilot/ui/widgets/common/progress_bar.dart' show BudgetProgressBar;
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cashpilot/l10n/app_localizations.dart';
// LocalizedCategory
import 'package:uuid/uuid.dart';
import '../../../core/utils/app_snackbar.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/helpers/localized_category_helper.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../features/budgets/providers/budget_providers.dart';
import '../../../features/expenses/providers/expense_providers.dart';
import '../../../features/categories/providers/category_providers.dart';
import '../../../data/drift/app_database.dart';
import '../../../core/constants/app_routes.dart';
import '../../widgets/budgets/overspend_forecast_bar.dart';
import '../../widgets/common/glass_card.dart';
import '../../widgets/common/app_grade_icons.dart';
import '../../widgets/common/empty_state.dart';
import '../../../features/budgets/widgets/budget_members_section.dart';

class BudgetDetailsScreen extends ConsumerWidget {
  final String budgetId;

  const BudgetDetailsScreen({
    super.key,
    required this.budgetId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetDataAsync = ref.watch(budgetWithSemiBudgetsProvider(budgetId));
    final expensesAsync = ref.watch(expensesByBudgetProvider(budgetId));
    final currency = ref.watch(currencyProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: budgetDataAsync.when(
        data: (data) {
          if (data == null) {
            return Center(child: Text(l10n.budgetsNotFound));
          }

          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle.light.copyWith(
              statusBarColor: Colors.transparent,
            ),
            child: Scaffold(
              body: SafeArea(
                top: false, // SliverAppBar handles top
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    _buildSliverAppBar(
                      context,
                      ref,
                      data,
                      currency,
                      l10n,
                    ),
                    // Sticky mini-summary bar (per blueprint spec)
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _StickyMiniSummaryDelegate(
                        spent: data.totalSpent,
                        remaining: data.remaining,
                        dailyBudget: _calculateDailyBudget(data),
                        currency: currency,
                        l10n: l10n,
                      ),
                    ),
                    SliverLayoutBuilder(
                      builder: (context, constraints) {
                        final horizontalPadding = constraints.crossAxisExtent < 360 ? 12.0 : 16.0;
                        return SliverPadding(
                          padding: EdgeInsets.all(horizontalPadding),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate(
                          [
                            _buildSemiBudgetsSection(
                              context,
                              data,
                              currency,
                              l10n,
                            ),
                            const SizedBox(height: 24),
                            _buildExpensesSection(
                              context,
                              ref,
                              expensesAsync,
                              data,
                              currency,
                              l10n,
                            ),
                            const SizedBox(height: 24),
                            BudgetMembersSection(
                              budgetId: budgetId,
                              budget: data.budget,
                            ),
                            const SizedBox(height: 32),
                          ],
                        ),
                        ),
                      );
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, _) => Center(
          child: Text('${l10n.commonError}: $error'),
        ),
      ),
    );
  }

  /// Calculate daily budget remaining
  int _calculateDailyBudget(BudgetWithSemiBudgets data) {
    final remaining = data.remaining;
    final daysLeft = data.budget.endDate.difference(DateTime.now()).inDays;
    if (daysLeft <= 0) return 0;
    return (remaining / daysLeft).round();
  }

  // ---------------------------------------------------------------------------
  // APP BAR / HEADER
  // ---------------------------------------------------------------------------

  Widget _buildSliverAppBar(
    BuildContext context,
    WidgetRef ref,
    BudgetWithSemiBudgets data,
    String currency,
    AppLocalizations l10n,
  ) {
    final budget = data.budget;
    final rawProgress = data.spentPercentage;
    final safeProgress = rawProgress.isFinite
        ? rawProgress.clamp(0.0, 1.0)
        : 0.0; // extra safety for division issues

    final primaryColor = Theme.of(context).primaryColor;
    
    // SAFE MODE: Use fixed expandedHeight to prevent layout instability with font scaling
    const double expandedHeight = 400.0;

    return SliverAppBar(
      expandedHeight: expandedHeight,
      floating: false,
      pinned: true,
      stretch: true,
      backgroundColor: primaryColor,
      elevation: 0,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios_rounded,
          color: Theme.of(context).colorScheme.onPrimary,
        ),
        onPressed: () => context.pop(),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.edit_outlined, color: Theme.of(context).colorScheme.onPrimary),
          onPressed: () => context.push(AppRoutes.budgetEditPath(budgetId)),
          tooltip: l10n.commonEdit,
        ),
        IconButton(
          icon: Icon(Icons.more_vert_rounded, color: Theme.of(context).colorScheme.onPrimary),
          onPressed: () => _showBudgetMenu(context, ref, budget),
          tooltip: l10n.commonMore,
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                primaryColor,
                primaryColor.withValues(alpha: 0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          // SAFE MODE: Use fixed top padding or kToolbarHeight + safe area
          padding: const EdgeInsets.fromLTRB(16, 90, 16, 16),
          child: SingleChildScrollView(
              // SAFE MODE: Remove NeverScrollableScrollPhysics to allow scrolling if content overflows due to large fonts
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Title row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        budget.title,
                        style: AppTypography.headlineMedium.copyWith(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
                const SizedBox(height: 8),
                // Date range
                Text(
                  LocalizedDateFormatter.formatDateRange(
                    budget.startDate,
                    budget.endDate,
                    l10n.localeName,
                  ),
                  style: AppTypography.bodyMedium.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.8),
                    fontSize: 13,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 20),
                // Spent / Remaining row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: _HeaderMetric(
                        label: l10n.budgetsSpent,
                        value: _formatCurrency(context, data.totalSpent, currency),
                        alignRight: false,
                      ),
                    ),
                    if (budget.totalLimit != null) ...[
                      Expanded(
                        child: _HeaderMetric(
                          label: l10n.budgetsRemaining,
                          value: _formatCurrency(context, data.remaining, currency),
                          alignRight: true,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                // Quick Add Expense CTA
                GlassCard(
                  onTap: () => context.push(
                    Uri(
                      path: AppRoutes.addExpense,
                      queryParameters: {'budgetId': budgetId},
                    ).toString(),
                  ),
                  color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.15),
                  borderRadius: 30,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.add_circle_outline,
                        color: Theme.of(context).colorScheme.onPrimary,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.expensesAddExpense,
                        style: AppTypography.labelSmall.copyWith(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (budget.totalLimit != null) ...[
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: safeProgress,
                      backgroundColor: Colors.white.withValues(alpha: 0.3),
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.onPrimary),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${(safeProgress * 100).toStringAsFixed(0)}% of ${_formatCurrency(context, budget.totalLimit!, currency)}',
                    style: AppTypography.labelSmall.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.8),
                    ),
                  ),
                  OverspendForecastBar(
                    budget: budget,
                    totalSpent: data.totalSpent,
                    currency: currency,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SEMI-BUDGETS (CATEGORIES)
  // ---------------------------------------------------------------------------

  Widget _buildSemiBudgetsSection(
    BuildContext context,
    BudgetWithSemiBudgets data,
    String currency,
    AppLocalizations l10n,
  ) {
    final grouped = data.groupedSemiBudgets;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.budgetsCategories.toUpperCase(),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              TextButton.icon(
                onPressed: () =>
                    context.push(AppRoutes.categoryAddPath(budgetId)),
                icon: const Icon(Icons.add, size: 18),
                label: Text(l10n.commonAdd),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        
        // Render Grouped Categories
        ...grouped.entries.map((entry) {
          final parent = entry.key;
          final children = entry.value;
          
          if (children.isEmpty) {
            return _buildCategoryCard(context, data, parent, currency);
          } else {
            return _buildParentCategoryGroup(context, data, parent, children, currency);
          }
        }),
      ],
    );
  }

  Widget _buildCategoryCard(
    BuildContext context,
    BudgetWithSemiBudgets data,
    SemiBudget semiBudget,
    String currency, {
    bool isSubcategory = false,
  }) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final isDark = theme.brightness == Brightness.dark;

    final spent = data.semiBudgetSpending[semiBudget.id] ?? 0;
    final limit = semiBudget.limitAmount;
    final hasLimit = limit > 0;
    final progress = hasLimit ? (spent / limit).clamp(0.0, 2.0) : 0.0;

    final color = _getColorFromHex(semiBudget.colorHex, context);
    IconData iconData = AppGradeIcons.getIcon(semiBudget.iconName ?? semiBudget.name);

    return GlassCard(
      margin: EdgeInsets.only(bottom: 12, left: isSubcategory ? 24 : 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      borderRadius: 18,
      color: theme.colorScheme.surface.withValues(alpha: isSubcategory ? 0.4 : 0.6),
      border: Border.all(
        color: theme.dividerColor.withValues(alpha: isDark ? 0.14 : 0.10),
        width: 1,
      ),
      onTap: () => context.push(AppRoutes.categoryEditPath(budgetId, semiBudget.id)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: isSubcategory ? 36 : 44,
                height: isSubcategory ? 36 : 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(isSubcategory ? 10 : 14),
                ),
                child: Icon(
                  iconData,
                  size: isSubcategory ? 18 : 20,
                  color: color,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  LocalizedCategoryHelper.getLocalizedName(context, semiBudget.name, iconName: semiBudget.iconName),
                  style: (isSubcategory ? AppTypography.bodyMedium : AppTypography.titleSmall).copyWith(
                    color: onSurface,
                    fontWeight: isSubcategory ? FontWeight.w500 : FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                splashRadius: 20,
                iconSize: 18,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(Icons.edit_outlined, color: onSurface.withValues(alpha: 0.4)),
                onPressed: () => context.push(AppRoutes.categoryEditPath(budgetId, semiBudget.id)),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatCurrency(context, spent, currency),
                    style: AppTypography.labelMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: onSurface,
                    ),
                  ),
                  if (hasLimit)
                    Text(
                      'of ${_formatCurrency(context, limit, currency)}',
                      style: AppTypography.labelSmall.copyWith(
                        color: onSurface.withValues(alpha: 0.5),
                        fontSize: 10,
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          BudgetProgressBar(
            progress: progress,
            height: isSubcategory ? 4 : 6,
          ),
        ],
      ),
    );
  }

  Widget _buildParentCategoryGroup(
    BuildContext context,
    BudgetWithSemiBudgets data,
    SemiBudget parent,
    List<SemiBudget> children,
    String currency,
  ) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    
    // Aggregates
    final totalSpent = data.getAggregatedSpending(parent.id);
    final totalLimit = data.getAggregatedLimit(parent.id);
    final hasLimit = totalLimit > 0;
    final progress = hasLimit ? (totalSpent / totalLimit).clamp(0.0, 2.0) : 0.0;
    
    final color = _getColorFromHex(parent.colorHex, context);
    IconData iconData = AppGradeIcons.getIcon(parent.iconName ?? parent.name);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.1),
        ),
      ),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(iconData, size: 20, color: color),
          ),
          title: Text(
            LocalizedCategoryHelper.getLocalizedName(context, parent.name, iconName: parent.iconName),
            style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w700),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_formatCurrency(context, totalSpent, currency)} spent',
                      style: AppTypography.labelSmall.copyWith(color: onSurface.withValues(alpha: 0.6)),
                    ),
                    if (hasLimit)
                      Text(
                        'Limit: ${_formatCurrency(context, totalLimit, currency)}',
                        style: AppTypography.labelSmall.copyWith(color: onSurface.withValues(alpha: 0.6)),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                BudgetProgressBar(progress: progress, height: 6),
              ],
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                splashRadius: 20,
                iconSize: 18,
                icon: Icon(Icons.edit_outlined, color: onSurface.withValues(alpha: 0.4)),
                onPressed: () => context.push(AppRoutes.categoryEditPath(budgetId, parent.id)),
              ),
              const Icon(Icons.keyboard_arrow_down_rounded),
            ],
          ),
          children: [
            // Children subcategories
            ...children.map((child) => _buildCategoryCard(context, data, child, currency, isSubcategory: true)),
            
            // Edit Parent button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => context.push(AppRoutes.categoryEditPath(budgetId, parent.id)),
                    icon: const Icon(Icons.edit_outlined, size: 14),
                    label: Text(AppLocalizations.of(context)!.commonEdit, style: const TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }



  // ---------------------------------------------------------------------------
  // RECENT EXPENSES
  // ---------------------------------------------------------------------------

  Widget _buildExpensesSection(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<Expense>> expensesAsync,
    BudgetWithSemiBudgets data,
    String currency,
    AppLocalizations l10n,
  ) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final isDark = theme.brightness == Brightness.dark;

    // Watch categories and subcategories for mapping
    final categoriesAsync = ref.watch(allCategoriesProvider);
    final subCategoriesAsync = ref.watch(allSubCategoriesProvider);

    // Build efficient maps for O(1) lookups
    final categoryIcons = <String, String>{};
    final categoryColors = <String, Color>{};
    
    for (final cat in data.semiBudgets) {
      if (cat.iconName != null) {
        categoryIcons[cat.id] = cat.iconName!;
      }
      if (cat.colorHex != null) {
        categoryColors[cat.id] = _getColorFromHex(cat.colorHex!, context);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.expensesRecentExpenses,
          style: AppTypography.titleMedium.copyWith(
            color: onSurface,
          ),
        ),
        const SizedBox(height: 12),
        expensesAsync.when(
          data: (expenses) {
            if (expenses.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: EmptyState(
                  title: l10n.expensesNoExpenses,
                  message: l10n.budgetsTrackSpending,
                  buttonLabel: l10n.expensesAddExpense,
                  icon: Icons.receipt_long_rounded,
                  useGlass: false,
                  onAction: () => context.push(
                    Uri(
                      path: AppRoutes.addExpense,
                      queryParameters: {'budgetId': budgetId},
                    ).toString(),
                  ),
                ),
              );
            }

            // Build category and subcategory maps from providers
            final categoryMap = <String, Category>{};
            final subCategoryMap = <String, SubCategory>{};
            
            if (categoriesAsync.hasValue) {
              for (final c in categoriesAsync.value!) {
                categoryMap[c.id] = c;
              }
            }
            if (subCategoriesAsync.hasValue) {
              for (final s in subCategoriesAsync.value!) {
                subCategoryMap[s.id] = s;
              }
            }

            // Group expenses by Category -> Subcategory
            final hierarchy = <String, Map<String, List<Expense>>>{};
            for (var expense in expenses) {
              final catId = expense.categoryId ?? 'undeclared';
              final subCatId = expense.subCategoryId ?? 'none';
              
              hierarchy.putIfAbsent(catId, () => {});
              hierarchy[catId]!.putIfAbsent(subCatId, () => []).add(expense);
            }

            return Column(
              children: hierarchy.entries.map((categoryEntry) {
                final catId = categoryEntry.key;
                final subGroups = categoryEntry.value;
                final category = categoryMap[catId];
                
                final allExpensesInCategory = subGroups.values.expand((e) => e).toList();
                final totalAmount = allExpensesInCategory.fold<double>(0, (sum, e) => sum + (e.amount / 100));
                
                Color categoryColor = theme.colorScheme.primary;
                if (category?.colorHex != null) {
                  try {
                    categoryColor = Color(int.parse(category!.colorHex!.replaceFirst('#', '0xFF')));
                  } catch (_) {}
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildCategoryExpenseAccordion(
                    context,
                    ref,
                    category: category,
                    categoryId: catId,
                    subGroups: subGroups,
                    subCategoryMap: subCategoryMap,
                    totalAmount: totalAmount,
                    categoryColor: categoryColor,
                    currency: currency,
                    theme: theme,
                    onSurface: onSurface,
                    isDark: isDark,
                    categoryIcons: categoryIcons,
                    categoryColors: categoryColors,
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, _) => Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text('${l10n.commonError}: $error'),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // HELPERS
  // ---------------------------------------------------------------------------

  String _formatCurrency(BuildContext context, int amountInCents, String currency) {
    final amount = amountInCents / 100;
    final format = NumberFormat.currency(
      locale: AppLocalizations.of(context)!.localeName,
      symbol: currency == 'EUR' ? '€' : currency,
      decimalDigits: 2,
    );
    return format.format(amount);
  }

  /// Build category expense accordion for hierarchical display
  Widget _buildCategoryExpenseAccordion(
    BuildContext context,
    WidgetRef ref, {
    required Category? category,
    required String categoryId,
    required Map<String, List<Expense>> subGroups,
    required Map<String, SubCategory> subCategoryMap,
    required double totalAmount,
    required Color categoryColor,
    required String currency,
    required ThemeData theme,
    required Color onSurface,
    required bool isDark,
    required Map<String, String> categoryIcons,
    required Map<String, Color> categoryColors,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final categoryName = category != null 
        ? LocalizedCategoryHelper.getLocalizedName(context, category.name, iconName: category.iconName)
        : 'Uncategorized';
    final iconData = AppGradeIcons.getIcon(category?.iconName);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.1),
        ),
      ),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: categoryColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(iconData, size: 20, color: categoryColor),
          ),
          title: Text(
            categoryName,
            style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w700),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '$currency${totalAmount.toStringAsFixed(2)}',
              style: AppTypography.labelMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.danger,
              ),
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${subGroups.values.expand((e) => e).length} items',
                style: AppTypography.labelSmall.copyWith(color: onSurface.withValues(alpha: 0.5)),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.keyboard_arrow_down_rounded),
            ],
          ),
          children: subGroups.entries.map((subEntry) {
            final subCatId = subEntry.key;
            final expenses = subEntry.value;
            final subCategory = subCategoryMap[subCatId];
            final subTotal = expenses.fold<double>(0, (sum, e) => sum + (e.amount / 100));

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (subCategory != null && subCatId != 'none')
                  Padding(
                    padding: const EdgeInsets.only(left: 16, top: 8, bottom: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          LocalizedCategoryHelper.getLocalizedName(context, subCategory.name),
                          style: AppTypography.labelSmall.copyWith(
                            color: categoryColor.withValues(alpha: 0.8),
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 16),
                          child: Text(
                            '$currency${subTotal.toStringAsFixed(2)}',
                            style: AppTypography.labelSmall.copyWith(
                              color: onSurface.withValues(alpha: 0.6),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ...expenses.map((expense) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: _buildExpenseItem(
                    context,
                    ref,
                    expense,
                    currency,
                    theme,
                    onSurface,
                    isDark,
                    categoryIcons,
                    categoryColors,
                  ),
                )),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  /// Group expenses by date category
  Map<String, List<Expense>> _groupExpensesByDate(List<Expense> expenses, BuildContext context) {
    debugPrint('[BudgetDetails] Grouping ${expenses.length} expenses by date');
    
    if (expenses.isEmpty) {
      debugPrint('[BudgetDetails] No expenses to group');
      return {};
    }
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final l10n = AppLocalizations.of(context)!;

    // Use LinkedHashMap behavior to preserve insertion order
    final Map<String, List<Expense>> groups = {};

    for (final expense in expenses) {
      final expenseDate = DateTime(
        expense.date.year,
        expense.date.month,
        expense.date.day,
      );

      String label;
      if (expenseDate == today) {
        label = l10n.dateToday;
      } else if (expenseDate == yesterday) {
        label = l10n.dateYesterday;
      } else if (expenseDate.isAfter(weekStart.subtract(const Duration(days: 1)))) {
        label = l10n.dateThisWeek;
      } else {
        label = l10n.dateEarlier;
      }

      groups.putIfAbsent(label, () => []);
      groups[label]!.add(expense);
    }

    // Sort each group by date descending
    for (final list in groups.values) {
      list.sort((a, b) => b.date.compareTo(a.date));
    }

    debugPrint('[BudgetDetails] Grouped into ${groups.length} categories: ${groups.keys.join(", ")}');
    for (final entry in groups.entries) {
      debugPrint('[BudgetDetails]   ${entry.key}: ${entry.value.length} expenses');
    }

    return groups;
  }

  /// Get icon for date group label


  /// Build individual expense item
  Widget _buildExpenseItem(
    BuildContext context,
    WidgetRef ref,
    Expense expense,
    String currency,
    ThemeData theme,
    Color onSurface,
    bool isDark,
    Map<String, String> categoryIcons,
    Map<String, Color> categoryColors,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final categoryId = expense.semiBudgetId;
    final iconName = categoryIcons[categoryId];
    final categoryColor = categoryColors[categoryId] ?? theme.colorScheme.primary;
    final iconData = AppGradeIcons.getIcon(iconName);

    return InkWell(
      onTap: () => context.push('/expenses/edit/${expense.id}'),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark 
              ? Colors.white.withValues(alpha: 0.04)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark 
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.06),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: categoryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                iconData,
                size: 18,
                color: categoryColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    LocalizedCategoryHelper.getLocalizedName(context, expense.title),
                    style: AppTypography.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('h:mm a').format(expense.date),
                    style: AppTypography.bodySmall.copyWith(
                      color: onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '-${_formatCurrency(context, expense.amount, currency)}',
              style: AppTypography.titleSmall.copyWith(
                color: AppColors.danger,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert,
                size: 20,
                color: onSurface.withValues(alpha: 0.5),
              ),
              padding: EdgeInsets.zero,
              itemBuilder: (c) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      const Icon(Icons.edit_outlined, size: 18),
                      const SizedBox(width: 8),
                      Text(l10n.commonEdit),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outlined, size: 18, color: Colors.red),
                      const SizedBox(width: 8),
                      const Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
              onSelected: (action) {
                if (action == 'edit') {
                  context.push('/expenses/edit/${expense.id}');
                } else if (action == 'delete') {
                  _confirmDeleteExpense(context, ref, expense);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Color _getColorFromHex(String? hex, BuildContext context) {
    if (hex == null || hex.isEmpty) {
      return Theme.of(context).primaryColor;
    }
    try {
      final cleaned = hex.replaceFirst('#', '');
      return Color(int.parse('0xFF$cleaned'));
    } catch (_) {
      return Theme.of(context).primaryColor;
    }
  }

  // ---------------------------------------------------------------------------
  // BUDGET MENU / SHARE / DELETE
  // ---------------------------------------------------------------------------

  void _showBudgetMenu(
    BuildContext context,
    WidgetRef ref,
    Budget budget,
  ) {
    final l10n = AppLocalizations.of(context)!;
    // Capture the outer context (from widget tree) before modal opens
    final outerContext = context;
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalContext) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.share_outlined),
                title: Text(l10n.commonShare),
                onTap: () {
                  Navigator.pop(modalContext);
                  _showShareBudgetDialog(outerContext, ref, budget);
                },
              ),
              ListTile(
                leading: const Icon(Icons.copy_outlined),
                title: Text(l10n.commonDuplicate),
                onTap: () {
                  Navigator.pop(modalContext);
                  AppSnackBar.showInfo(outerContext, 'Duplicate feature coming soon');
                },
              ),
              ListTile(
                leading: const Icon(Icons.archive_outlined),
                title: Text(l10n.commonArchive),
                onTap: () {
                  Navigator.pop(modalContext);
                  AppSnackBar.showSuccess(outerContext, 'Budget archived');
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(
                  Icons.delete_outline,
                  color: AppColors.danger,
                ),
                title: const Text(
                  'Delete Budget',
                  style: TextStyle(color: AppColors.danger),
                ),
                onTap: () {
                  Navigator.pop(modalContext);
                  // Use the outer context which is still valid
                  _confirmDeleteBudget(outerContext, ref, budget);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showShareBudgetDialog(
    BuildContext context,
    WidgetRef ref,
    Budget budget,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final emailController = TextEditingController();
    String role = 'editor';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(AppLocalizations.of(context)!.budgetShareTitle), // Using generic/fallback until regenerated
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.budgetInviteMessage(budget.title)),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email Address', // Keep simple or add key if needed
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: role,
                decoration: const InputDecoration(
                  labelText: 'Access Level',
                  border: OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(
                    value: 'editor',
                    child: Text(l10n.budgetRoleEditor),
                  ),
                  DropdownMenuItem(
                    value: 'viewer',
                    child: Text(l10n.budgetRoleViewer),
                  ),
                ],
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => role = v);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.commonCancel),
            ),
            FilledButton(
              onPressed: () async {
                final email = emailController.text.trim();
                if (email.isEmpty) return;

                Navigator.pop(context);
                try {
                  final db = ref.read(databaseProvider);
                  final uuid = const Uuid().v4();

                  await db.into(db.budgetMembers).insert(
                        BudgetMembersCompanion.insert(
                          id: uuid,
                          budgetId: budget.id,
                          memberEmail: email,
                          role: role,
                          status: const Value('pending'),
                          invitedBy: const Value('me'), // SyncEngine fixes
                          invitedAt: Value(DateTime.now()),
                        ),
                      );

                  // Trigger sync to push invite
                  ref.read(syncEngineProvider).syncAll();

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.budgetInviteSent(email)),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.budgetInviteFailed(e.toString())),
                      ),
                    );
                  }
                }
              },
              child: Text(l10n.commonAdd), 
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteBudget(
    BuildContext context,
    WidgetRef ref,
    Budget budget,
  ) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.budgetDeleteConfirmTitle),
        content: Text(
          '${l10n.categoryDeleteConfirm(budget.title)}\n\nThis will also delete all expenses and categories in this budget.', // Leave this english for now or add key
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final scaffoldMessenger = ScaffoldMessenger.of(context);

              Navigator.pop(dialogContext); // close dialog

              try {
                final db = ref.read(databaseProvider);
                debugPrint('[BudgetDetails] 🗑️ Soft-deleting budget and syncing...');
                
                // Soft-delete locally (marks isDeleted=true, triggers cascades)
                await db.deleteBudget(budget.id);
                
                // Sync to Supabase (pushes isDeleted=true to server)
                // Server trigger will move it to recycle_bin automatically
                await ref.read(syncEngineProvider).syncAll();
                
                debugPrint('[BudgetDetails] ✅ Budget deleted and moved to recycle bin');

                navigator.pop(); // pop details screen
                scaffoldMessenger.showSnackBar(
                  SnackBar(content: Text('${budget.title} deleted')),
                );
              } catch (e) {
                debugPrint('[BudgetDetails] ⚠️ Error during deletion: $e');
                scaffoldMessenger.showSnackBar(
                  SnackBar(content: Text(l10n.budgetDeleteFailed(e.toString()))),
                );
              }
            },
            child: Text(l10n.budgetDeleteShort.toUpperCase()),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteExpense(
    BuildContext context,
    WidgetRef ref,
    Expense expense,
  ) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.expenseDeleteConfirmTitle),
        content: Text(l10n.expenseDeleteConfirmMessage(expense.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                final db = ref.read(databaseProvider);
                await db.deleteExpense(expense.id);
                ref.read(syncEngineProvider).syncAll();
                
                if (context.mounted) {
                  AppSnackBar.showSuccess(context, 'Expense deleted');
                }
              } catch (e) {
                if (context.mounted) {
                  AppSnackBar.showError(context, 'Failed to delete: $e');
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: Text(l10n.budgetDeleteShort),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// SMALL HEADER METRIC WIDGET (for spent / remaining)
// -----------------------------------------------------------------------------

class _HeaderMetric extends StatelessWidget {
  final String label;
  final String value;
  final bool alignRight;

  const _HeaderMetric({
    required this.label,
    required this.value,
    this.alignRight = false,
  });

  @override
  Widget build(BuildContext context) {
    final textAlign = alignRight ? TextAlign.right : TextAlign.left;

    return Column(
      crossAxisAlignment:
          alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.7),
          ),
          textAlign: textAlign,
        ),

        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: AppTypography.moneyMedium.copyWith(
              color: Theme.of(context).colorScheme.onPrimary,
            ),
            textAlign: textAlign,
          ),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// STICKY MINI-SUMMARY DELEGATE (per UPGRADE_PLAN blueprint)
// Appears as pinned bar when header collapses
// -----------------------------------------------------------------------------

class _StickyMiniSummaryDelegate extends SliverPersistentHeaderDelegate {
  final int spent;
  final int remaining;
  final int dailyBudget;
  final String currency;
  final AppLocalizations l10n;

  _StickyMiniSummaryDelegate({
    required this.spent,
    required this.remaining,
    required this.dailyBudget,
    required this.currency,
    required this.l10n,
  });

  @override
  double get minExtent => 48;

  @override
  double get maxExtent => 48;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surfaceContainerHigh
            : theme.colorScheme.surface,
        boxShadow: overlapsContent
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: _buildMiniStat(
              context,
              l10n.budgetsSpent,
              _formatCurrency(context, spent),
              AppColors.danger,
            ),
          ),
          _divider(context),
          Expanded(
            child: _buildMiniStat(
              context,
              l10n.budgetsRemaining,
              _formatCurrency(context, remaining),
              theme.colorScheme.primary,
            ),
          ),
          _divider(context),
          Expanded(
            child: _buildMiniStat(
              context,
              'Daily',
              _formatCurrency(context, dailyBudget),
              theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            fontSize: 10,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: AppTypography.labelMedium.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _divider(BuildContext context) {
    return Container(
      width: 1,
      height: 24,
      color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
    );
  }

  String _formatCurrency(BuildContext context, int amountInCents) {
    final amount = amountInCents / 100;
    final format = NumberFormat.simpleCurrency(
      locale: AppLocalizations.of(context)!.localeName,
      name: currency,
      decimalDigits: 2,
    );
    return format.format(amount);
  }
  @override
  bool shouldRebuild(covariant _StickyMiniSummaryDelegate oldDelegate) {
    return spent != oldDelegate.spent ||
        remaining != oldDelegate.remaining ||
        dailyBudget != oldDelegate.dailyBudget ||
        currency != oldDelegate.currency ||
        l10n != oldDelegate.l10n;
  }
}




