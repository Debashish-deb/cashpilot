/// CashPilot Budget List Screen
/// Displays all user budgets with enhanced filtering, search, and statistics
library;

import 'dart:io' show File;

import 'package:cashpilot/data/drift/app_database.dart' show Budget;
import 'package:cashpilot/ui/widgets/cards/budget_list_item.dart' show BudgetListItem;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cashpilot/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../widgets/common/empty_state.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/app_routes.dart';
import '../../../features/budgets/providers/budget_providers.dart';

// Using budgetTypeFilterProvider from budget_providers.dart for filtering

class BudgetListScreen extends ConsumerStatefulWidget {
  const BudgetListScreen({super.key});

  @override
  ConsumerState<BudgetListScreen> createState() => _BudgetListScreenState();
}

class _BudgetListScreenState extends ConsumerState<BudgetListScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  late AnimationController _searchAnimationController;
  final double _scrollOffset = 0;
  bool _showSearchBar = false;

  @override
  void initState() {
    super.initState();
    _searchAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    // Load recent searches
  }




  void _toggleSearchBar() {
    setState(() {
      _showSearchBar = !_showSearchBar;
      if (_showSearchBar) {
        _searchAnimationController.forward();
        Future.delayed(const Duration(milliseconds: 200), () {
          _searchFocusNode.requestFocus();
        });
      } else {
        _searchAnimationController.reverse();
        _searchController.clear();
        _searchFocusNode.unfocus();
        ref.read(budgetSearchProvider.notifier).state = '';
      }
    });
  }

  void _updateSearch(String query) {
    ref.read(budgetSearchProvider.notifier).state = query;
  }

  void showSortOptions(BuildContext context, WidgetRef ref) {
    final currentSort = ref.read(budgetSortProvider);
    final l10n = AppLocalizations.of(context)!;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.commonSort,
              style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ...BudgetSortOption.values.map((option) => ListTile(
              leading: Icon(_getSortIcon(option)),
              title: Text(_getSortLabel(option, l10n)),
              trailing: currentSort == option 
                  ? Icon(Icons.check_circle, color: AppColors.primaryGreen) 
                  : null,
              onTap: () {
                ref.read(budgetSortProvider.notifier).state = option;
                Navigator.pop(context);
              },
            )),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
  
  IconData _getSortIcon(BudgetSortOption option) {
    switch (option) {
      case BudgetSortOption.dateNewest:
        return Icons.arrow_downward_rounded;
      case BudgetSortOption.dateOldest:
        return Icons.arrow_upward_rounded;
      case BudgetSortOption.nameAZ:
        return Icons.sort_by_alpha_rounded;
      case BudgetSortOption.nameZA:
        return Icons.sort_by_alpha_rounded;
      case BudgetSortOption.amountHighest:
        return Icons.trending_up_rounded;
      case BudgetSortOption.amountLowest:
        return Icons.trending_down_rounded;
    }
  }
  
  String _getSortLabel(BudgetSortOption option, AppLocalizations l10n) {
    switch (option) {
      case BudgetSortOption.dateNewest:
        return l10n.sortNewestFirst;
      case BudgetSortOption.dateOldest:
        return l10n.sortOldestFirst;
      case BudgetSortOption.nameAZ:
        return l10n.sortNameAZ;
      case BudgetSortOption.nameZA:
        return l10n.sortNameZA;
      case BudgetSortOption.amountHighest:
        return l10n.sortAmountHighLow;
      case BudgetSortOption.amountLowest:
        return l10n.sortAmountLowHigh;
    }
  }

  void showBudgetStatistics(BuildContext context, WidgetRef ref) {
    final stats = ref.read(budgetStatisticsProvider);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.budgetsStatisticsTitle,
                style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: _buildStatCard(theme, l10n.budgetsStatTotal, stats.total, Icons.folder_outlined, Colors.blue)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildStatCard(theme, l10n.budgetsActive, stats.active, Icons.play_circle_outline, AppColors.primaryGreenDark)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildStatCard(theme, l10n.budgetsStatCompleted, stats.completed, Icons.check_circle_outline, Colors.grey)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildStatCard(theme, l10n.budgetsUpcoming, stats.upcoming, Icons.schedule_outlined, Colors.orange)),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.account_balance_wallet_outlined, color: AppColors.primaryGreenDark),
                    const SizedBox(width: 12),
                    Text(
                      '${l10n.budgetsTotalBudget}: ${NumberFormat.simpleCurrency(locale: l10n.localeName, decimalDigits: 0).format(stats.totalBudget / 100)}',
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryGreenDark,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildStatCard(ThemeData theme, String label, int value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value.toString(),
            style: AppTypography.headlineMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _searchAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sortedBudgets = ref.watch(sortedBudgetsProvider);
    final currentSort = ref.watch(budgetSortProvider);
    final typeFilter = ref.watch(budgetTypeFilterProvider);
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final searchQuery = ref.watch(budgetSearchProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      // Removed: redundant FAB - the global FAB from main navigation is used
      body: SafeArea(
        top: false, // AppBar handles top
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                title: Text(
                  l10n.budgetsTitle,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.5,
                  ),
                ),
                centerTitle: true,
                floating: true,
                pinned: true,
                snap: true,
                backgroundColor: theme.colorScheme.surface,
                surfaceTintColor: theme.colorScheme.surfaceTint,
                elevation: 0,
                scrolledUnderElevation: 0,
                forceElevated: innerBoxIsScrolled,
                actions: [
                  IconButton(
                    icon: Icon(
                      _showSearchBar ? Icons.close : Icons.search_rounded,
                      color: theme.colorScheme.onSurface,
                    ),
                    onPressed: _toggleSearchBar,
                    tooltip: _showSearchBar ? 'Close search' : 'Search budgets',
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert,
                      color: theme.colorScheme.onSurface,
                    ),
                    tooltip: 'More options',
                    onSelected: (value) {
                      if (value == 'sort') {
                        showSortOptions(context, ref);
                      } else if (value == 'recurring') {
                        context.push(AppRoutes.recurringExpenses);
                      } else if (value == 'categories') {
                        context.push(AppRoutes.categories);
                      } else if (value == 'export') {
                        _exportBudgets(context, ref);
                      } else if (value == 'stats') {
                        showBudgetStatistics(context, ref);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'sort',
                        child: Row(
                          children: [
                            const Icon(Icons.sort, size: 20),
                            const SizedBox(width: 12),
                            Text(l10n.commonSort),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      PopupMenuItem(
                        value: 'recurring',
                        child: Row(
                          children: [
                            const Icon(Icons.autorenew_rounded, size: 20),
                            const SizedBox(width: 12),
                            Text(l10n.expensesRecurring),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'categories',
                        child: Row(
                          children: [
                            const Icon(Icons.category_outlined, size: 20),
                            const SizedBox(width: 12),
                            Text(l10n.commonCategories),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      PopupMenuItem(
                        value: 'export',
                        child: Row(
                          children: [
                            const Icon(Icons.download_outlined, size: 20),
                            const SizedBox(width: 12),
                            Text(l10n.commonExport),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'stats',
                        child: Row(
                          children: [
                            const Icon(Icons.insights_outlined, size: 20),
                            const SizedBox(width: 12),
                            Text(l10n.budgetsStatisticsTitle),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Pinned Search Bar (if visible)
              if (_showSearchBar)
                SliverToBoxAdapter(
                  child: _buildSearchBar(theme, l10n),
                ),
              // Pinned Filter Chips
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverHeaderDelegate(
                  height: MediaQuery.textScalerOf(context).scale(72).clamp(72.0, 110.0),
                  child: Container(
                    color: theme.colorScheme.surface,
                    child: Column(
                      children: [
                        _buildFilterChips(l10n, theme),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ),
            ];
          },
          body: sortedBudgets.when(
            data: (budgetList) {
              if (budgetList.isEmpty) {
                String emptyTitle;
                String emptyMsg;
                String? btnLabel;
                VoidCallback? action;
                IconData icon;
    
                switch (typeFilter) {
                  case 'active':
                    emptyTitle = l10n.budgetsNoActive;
                    emptyMsg = l10n.budgetsNoActiveMsg;
                    btnLabel = l10n.budgetsCreateBudget;
                    action = () => context.push(AppRoutes.budgetCreate);
                    icon = Icons.play_circle_outline_rounded;
                    break;
                  case 'upcoming':
                    emptyTitle = l10n.budgetsNoUpcoming;
                    emptyMsg = l10n.budgetsNoUpcomingMsg;
                    btnLabel = l10n.budgetsSchedule;
                    action = () => context.push(AppRoutes.budgetCreate);
                    icon = Icons.calendar_month_outlined;
                    break;
                  case 'completed': // "Past"
                    emptyTitle = l10n.budgetsNoPast;
                    emptyMsg = l10n.budgetsNoPastMsg;
                    btnLabel = null; // No action needed for history
                    action = null;
                    icon = Icons.history_rounded;
                    break;
                  case 'family':
                    emptyTitle = l10n.budgetsNoFamily;
                    emptyMsg = l10n.budgetsNoFamilyMsg;
                    btnLabel = l10n.budgetsCreateShared;
                    action = () => context.push(AppRoutes.budgetCreate);
                    icon = Icons.family_restroom_rounded;
                    break;
                  default: // 'all' or fallback
                    emptyTitle = l10n.budgetsNoBudgets;
                    emptyMsg = l10n.homeCreateFirstBudget;
                    btnLabel = l10n.budgetsCreateBudget;
                    action = () => context.push(AppRoutes.budgetCreate);
                    icon = Icons.account_balance_wallet_outlined;
                }
    
                return EmptyState(
                  title: emptyTitle,
                  message: emptyMsg,
                  buttonLabel: btnLabel ?? '',
                  onAction: action,
                  icon: icon,
                  useGlass: false,
                );
              }
              return _buildBudgetList(budgetList, l10n, theme);
            },
            loading: () => _buildLoadingState(theme),
            error: (error, _) => _buildErrorState(error, l10n, theme, ref),
          ),
        ),
      ),
    );

  }

  Widget _buildSearchBar(ThemeData theme, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: theme.colorScheme.surface,
      child: Material(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        elevation: 2,
        child: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          onChanged: _updateSearch,
          decoration: InputDecoration(
            hintText: l10n.commonSearchBudgets,
            prefixIcon: Icon(
              Icons.search_rounded,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.clear,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    onPressed: () {
                      _searchController.clear();
                      _updateSearch('');
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          style: AppTypography.bodyLarge.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips(AppLocalizations l10n, ThemeData theme) {
    final filterValues = ['all', 'active', 'upcoming', 'completed', 'family'];
    final currentFilter = ref.watch(budgetTypeFilterProvider);

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filterValues.length,
        itemBuilder: (context, index) {
          final filterValue = filterValues[index];
          final displayLabel = _getFilterLabel(filterValue, l10n);
          final isSelected = currentFilter == filterValue;

          return Padding(
            padding: EdgeInsets.only(
              right: index == filterValues.length - 1 ? 0 : 8,
              left: index == 0 ? 0 : 0,
            ),
            child: GestureDetector(
              onTap: () {
                ref.read(budgetTypeFilterProvider.notifier).state = filterValue;
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).primaryColor
                        : theme.colorScheme.outline.withValues(alpha: 0.3),
                    width: 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getFilterIcon(filterValue),
                      size: 16,
                      color: isSelected
                          ? Colors.white
                          : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _getFilterLabel(displayLabel, l10n),
                      style: AppTypography.labelLarge.copyWith(
                        color: isSelected
                            ? Colors.white
                            : theme.colorScheme.onSurface,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBudgetList(List<Budget> budgets, AppLocalizations l10n, ThemeData theme) {
    // Group budgets by status
    final now = DateTime.now();
    final activeBudgets = budgets
        .where((b) =>
            b.startDate.isBefore(now) &&
            b.endDate.isAfter(now))
        .toList();
    final upcomingBudgets =
        budgets.where((b) => b.startDate.isAfter(now)).toList();
    final pastBudgets =
        budgets.where((b) => b.endDate.isBefore(now)).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 360;
        final horizontalPadding = isSmallScreen ? 12.0 : 16.0;
        
        return ListView(
          padding: EdgeInsets.all(horizontalPadding),
      children: [
        if (activeBudgets.isNotEmpty) ...[
          _buildBudgetSection(l10n.budgetsActive, activeBudgets.length, true),
          const SizedBox(height: 8),
          ...activeBudgets.map((budget) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: BudgetListItem(budget: budget),
            );
          }),
        ],
        if (upcomingBudgets.isNotEmpty) ...[
          const SizedBox(height: 24),
          _buildBudgetSection(l10n.budgetsUpcoming, upcomingBudgets.length, false),
          const SizedBox(height: 8),
          ...upcomingBudgets.map((budget) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: BudgetListItem(budget: budget),
            );
          }),
        ],
        if (pastBudgets.isNotEmpty) ...[
          const SizedBox(height: 24),
          _buildBudgetSection(l10n.budgetsPast, pastBudgets.length, false),
          const SizedBox(height: 8),
          ...pastBudgets.map((budget) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: BudgetListItem(budget: budget),
            );
          }),
        ],
        ],
      );
      },
    );
  }

  Widget _buildLoadingState(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: List.generate(3, (index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 150,
                    height: 24,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 60,
                    height: 24,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 100,
                    height: 16,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 60,
                    height: 14,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  Container(
                    width: 60,
                    height: 14,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildErrorState(Object error, AppLocalizations l10n, ThemeData theme, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 40,
                color: AppColors.danger,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.commonErrorMessage(''),
              style: AppTypography.titleLarge.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () => ref.refresh(budgetsStreamProvider),
                  icon: const Icon(Icons.refresh),
                  label: Text(l10n.commonRetry),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () => context.push('/support'),
                  icon: const Icon(Icons.support_agent),
                  label: Text(l10n.commonSupport),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetSection(String title, int count, bool isActive) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primaryGreenDark : AppColors.neutral60,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: AppTypography.titleSmall.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.success.withValues(alpha: 0.1)
                : AppColors.neutral60.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: AppTypography.labelSmall.copyWith(
              color: isActive ? AppColors.primaryGreenDark : AppColors.neutral60,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _exportBudgets(BuildContext context, WidgetRef ref) async {
    final budgets = ref.read(budgetsStreamProvider).valueOrNull ?? [];
    
    if (budgets.isEmpty) {
      AppSnackBar.showWarning(context, 'No budgets to export');
      return;
    }

    try {
      // Create CSV data
      List<List<dynamic>> csvData = [];
      
      // Add header
      csvData.add([
        'Title',
        'Description',
        'Start Date',
        'End Date',
        'Total Limit',
        'Total Spent',
        'Remaining',
        'Currency',
        'Status',
        'Categories',
        'Shared',
        'Created At',
        'Updated At',
      ]);
      
      final now = DateTime.now();
      
      // Add budget data
      for (final budget in budgets) {
        final isActive = budget.startDate.isBefore(now) && budget.endDate.isAfter(now);
        final isUpcoming = budget.startDate.isAfter(now);
        final status = isActive ? 'Active' : isUpcoming ? 'Upcoming' : 'Past';
        final remaining = (budget.totalLimit ?? 0) / 100;
        
        csvData.add([
          budget.title,
          budget.notes ?? '',
          DateFormat('yyyy-MM-dd').format(budget.startDate),
          DateFormat('yyyy-MM-dd').format(budget.endDate),
          (budget.totalLimit ?? 0) / 100,
          0 / 100, // spent placeholder
          remaining,
          budget.currency,
          status,
          '', // categories placeholder
          budget.isShared == true ? 'Yes' : 'No',
          DateFormat('yyyy-MM-dd HH:mm:ss').format(budget.createdAt),
          DateFormat('yyyy-MM-dd HH:mm:ss').format(budget.updatedAt),
        ]);
      }
      
      // Convert to CSV manually
      String csv = csvData.map((row) => row.map((cell) => '"${cell.toString().replaceAll('"', '""')}"').join(',')).join('\n');
      
      // Get directory
      final directory = await getTemporaryDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final file = File('${directory.path}/cashpilot_budgets_$timestamp.csv');
      
      // Write to file
      await file.writeAsString(csv);
      
      // Share file using Share.shareXFiles (Corrected from hallucinatory SharePlus call)
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'CashPilot Budgets Export',
        text: 'Exported ${budgets.length} budgets from CashPilot\n\n'
              'Generated on: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
      );
      
      if (context.mounted) {
        AppSnackBar.showSuccess(context, 'Successfully exported ${budgets.length} budgets');
      }
      
      // Clean up after 30 seconds
      Future.delayed(const Duration(seconds: 30), () {
        file.delete();
      });
    } catch (e) {
      if (context.mounted) {
        AppSnackBar.showError(context, 'Export failed: $e');
      }
    }
  }

  IconData _getFilterIcon(String filterValue) {
    switch (filterValue) {
      case 'all':
        return Icons.dashboard_outlined;
      case 'active':
        return Icons.play_circle_outline;
      case 'upcoming':
        return Icons.upcoming_outlined;
      case 'completed':
        return Icons.check_circle_outline;
      case 'family':
        return Icons.people_outline;
      default:
        return Icons.category_outlined;
    }
  }

  String _getFilterLabel(String filterValue, AppLocalizations l10n) {
    switch (filterValue) {
      case 'all':
        return l10n.budgetsAll;
      case 'active':
        return l10n.budgetsActive;
      case 'upcoming':
        return l10n.budgetsUpcoming;
      case 'completed':
        return l10n.budgetsPast;
      case 'family':
        return l10n.catGroupFamily;
      default:
        return filterValue;
    }
  }
}

// Budget Search Delegate
// ignore: unused_element - kept for future search enhancement
class _BudgetSearchDelegate extends SearchDelegate<Budget?> {
  final WidgetRef ref;

  _BudgetSearchDelegate(this.ref);

  @override
  String get searchFieldLabel => 'Search budgets...';

  @override
  TextStyle get searchFieldStyle => AppTypography.bodyLarge;

  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = Theme.of(context);
    return theme.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: theme.colorScheme.surface,
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.1),
      ),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: query.isNotEmpty ? 1.0 : 0.0,
        child: IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () => query = '',
          tooltip: 'Clear search',
        ),
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
      tooltip: 'Back',
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return _buildRecentSearches(context);
    }
    return _buildSearchResults(context);
  }

  Widget _buildRecentSearches(BuildContext context) {
    final recentSearches = ref.read(recentSearchesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Recent Searches',
            style: AppTypography.titleSmall.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (recentSearches.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'No recent searches',
              style: TextStyle(color: Colors.grey),
            ),
          )
        else
          ...recentSearches.map((search) {
            return ListTile(
              leading: const Icon(Icons.history_outlined),
              title: Text(search),
              onTap: () {
                query = search;
                showResults(context);
              },
            );
          }),
        const Divider(),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Search Tips',
            style: AppTypography.titleSmall.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            '• Search by budget name\n• Filter by date range\n• Search for shared budgets',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResults(BuildContext context) {
    final budgetsAsync = ref.watch(budgetsStreamProvider);
    final l10n = AppLocalizations.of(context)!;

    return budgetsAsync.when(
      data: (budgets) {
        final filtered = budgets
            .where((b) =>
                b.title.toLowerCase().contains(query.toLowerCase()) ||
                (b.notes?.toLowerCase().contains(query.toLowerCase()) ==
                    true))
            .toList();

        if (filtered.isEmpty) {
          return _buildNoResults();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final budget = filtered[index];
            final now = DateTime.now();
            final isActive =
                budget.startDate.isBefore(now) && budget.endDate.isAfter(now);
            final progress = budget.totalLimit != null && budget.totalLimit! > 0
                ? 0.0 // Spent value would go here
                : 0.0;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.success.withValues(alpha: 0.1)
                        : Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isActive ? Icons.play_circle : Icons.calendar_today,
                    color: isActive ? AppColors.success : Colors.grey,
                  ),
                ),
                title: Text(
                  budget.title,
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      '${DateFormat('MMM d', l10n.localeName).format(budget.startDate)} - ${DateFormat('MMM d, y', l10n.localeName).format(budget.endDate)}',
                      style: AppTypography.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        progress > 0.9
                            ? AppColors.danger
                            : progress > 0.7
                                ? AppColors.warning
                                : AppColors.success,
                      ),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ],
                ),
                trailing: Text(
                  '${(budget.totalLimit ?? 0) / 100} ${budget.currency}',
                  style: AppTypography.labelLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () => close(context, budget),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(l10n.commonErrorMessage('')),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No budgets found',
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try searching for something else',
            style: AppTypography.bodyMedium.copyWith(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

class _SliverHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  _SliverHeaderDelegate({required this.child, required this.height});

  @override
  double get minExtent => height;
  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(_SliverHeaderDelegate oldDelegate) {
    return oldDelegate.child != child || oldDelegate.height != height;
  }
}