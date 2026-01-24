/// Recurring Expenses Screen
/// Manage automated recurring expenses
library;

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/providers/app_providers.dart';
import '../../../data/drift/app_database.dart';

const _uuid = Uuid();

// Recurring Expense Providers
final recurringExpensesProvider = StreamProvider<List<RecurringExpense>>((ref) {
  final db = ref.watch(databaseProvider);
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value([]);
  return db.watchRecurringExpenses(userId);
});

class RecurringExpensesScreen extends ConsumerWidget {
  const RecurringExpensesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recurringAsync = ref.watch(recurringExpensesProvider);
    final currency = ref.watch(currencyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recurring Expenses'),
      ),
      body: recurringAsync.when(
        data: (expenses) {
          if (expenses.isEmpty) {
            return _buildEmptyState(context);
          }

          // Separate active and inactive
          final active = expenses.where((e) => e.isActive).toList();
          final inactive = expenses.where((e) => !e.isActive).toList();

          return LayoutBuilder(
            builder: (context, constraints) {
              final horizontalPadding = constraints.maxWidth < 360 ? 12.0 : 16.0;
              return ListView(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 20),
            children: [
              // Monthly total
              _buildMonthlyTotal(context, active, currency),

              const SizedBox(height: 20),

              // Active recurring
              if (active.isNotEmpty) ...[
                Text(
                  'Active (${active.length})',
                  style: AppTypography.titleMedium.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                ...active.map((e) => _RecurringCard(
                      expense: e,
                      currency: currency,
                    )),
              ],

              // Inactive/Paused
              if (inactive.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(
                  'Paused (${inactive.length})',
                  style: AppTypography.titleMedium.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 12),
                ...inactive.map((e) => _RecurringCard(
                      expense: e,
                      currency: currency,
                      isPaused: true,
                    )),
              ],
              
              const SizedBox(height: 100), // Bottom padding for FAB
            ],
          );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddRecurringSheet(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Recurring'),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.autorenew_rounded,
                size: 64,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No recurring expenses',
              style: AppTypography.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Add recurring expenses like rent, subscriptions, or bills to automate your tracking',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyTotal(
    BuildContext context,
    List<RecurringExpense> active,
    String currency,
  ) {
    // Calculate monthly total
    int monthlyTotal = 0;
    for (final expense in active) {
      switch (expense.frequency) {
        case 'daily':
          monthlyTotal += expense.amount * 30;
          break;
        case 'weekly':
          monthlyTotal += (expense.amount * 4.33).round();
          break;
        case 'monthly':
          monthlyTotal += expense.amount;
          break;
        case 'yearly':
          monthlyTotal += (expense.amount / 12).round();
          break;
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.autorenew_rounded, color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.7), size: 20),
              const SizedBox(width: 8),
              Text(
                'Monthly Recurring',
                style: AppTypography.bodyMedium.copyWith(
                  color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _formatCurrency(monthlyTotal, currency),
            style: AppTypography.moneyLarge.copyWith(color: Theme.of(context).colorScheme.onPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            '${active.length} active ${active.length == 1 ? 'expense' : 'expenses'}',
            style: AppTypography.bodySmall.copyWith(color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.6)),
          ),
        ],
      ),
    );
  }

  void _showAddRecurringSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _AddRecurringSheet(),
    );
  }

  String _formatCurrency(int amountInCents, String currency) {
    final amount = amountInCents / 100;
    return NumberFormat.currency(
      symbol: currency == 'EUR' ? '€' : currency,
      decimalDigits: 2,
    ).format(amount);
  }
}

class _RecurringCard extends StatelessWidget {
  final RecurringExpense expense;
  final String currency;
  final bool isPaused;

  const _RecurringCard({
    required this.expense,
    required this.currency,
    this.isPaused = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getCategoryColor(expense.category, context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: isPaused
            ? null
            : [
                BoxShadow(
                  color: color.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Opacity(
        opacity: isPaused ? 0.6 : 1.0,
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getCategoryIcon(expense.category),
                color: color,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expense.title,
                    style: AppTypography.titleSmall.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _getFrequencyLabel(expense.frequency),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Next: ${_formatNextDue(expense.nextDueDate)}',
                        style: AppTypography.bodySmall.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatCurrency(expense.amount),
                  style: AppTypography.titleMedium.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (isPaused)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Paused',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.warning,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String? category) {
    switch (category) {
      case 'rent':
        return Icons.home_outlined;
      case 'utilities':
        return Icons.bolt_outlined;
      case 'subscriptions':
        return Icons.subscriptions_outlined;
      case 'insurance':
        return Icons.security_outlined;
      case 'internet':
        return Icons.wifi_outlined;
      case 'phone':
        return Icons.phone_android_outlined;
      default:
        return Icons.autorenew_rounded;
    }
  }

  Color _getCategoryColor(String? category, BuildContext context) {
    switch (category) {
      case 'rent':
        return const Color(0xFF795548);
      case 'utilities':
        return const Color(0xFFFFEB3B);
      case 'subscriptions':
        return const Color(0xFF00BCD4);
      case 'insurance':
        return const Color(0xFF607D8B);
      case 'internet':
        return const Color(0xFF2196F3);
      case 'phone':
        return const Color(0xFF9C27B0);
      default:
        return Theme.of(context).primaryColor;
    }
  }

  String _getFrequencyLabel(String frequency) {
    switch (frequency) {
      case 'daily':
        return 'Daily';
      case 'weekly':
        return 'Weekly';
      case 'monthly':
        return 'Monthly';
      case 'yearly':
        return 'Yearly';
      default:
        return frequency;
    }
  }

  String _formatNextDue(DateTime date) {
    final now = DateTime.now();
    final diff = date.difference(now).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff < 7) return 'in $diff days';

    return DateFormat('MMM d').format(date);
  }

  String _formatCurrency(int amountInCents) {
    final amount = amountInCents / 100;
    return NumberFormat.currency(
      symbol: currency == 'EUR' ? '€' : currency,
      decimalDigits: 2,
    ).format(amount);
  }
}

class _AddRecurringSheet extends ConsumerStatefulWidget {
  @override
  ConsumerState<_AddRecurringSheet> createState() => _AddRecurringSheetState();
}

class _AddRecurringSheetState extends ConsumerState<_AddRecurringSheet> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  String _frequency = 'monthly';
  String _category = 'subscriptions';
  int _dayOfMonth = 1;
  bool _isLoading = false;

  final List<Map<String, dynamic>> _frequencies = [
    {'value': 'daily', 'label': 'Daily'},
    {'value': 'weekly', 'label': 'Weekly'},
    {'value': 'monthly', 'label': 'Monthly'},
    {'value': 'yearly', 'label': 'Yearly'},
  ];

  final List<Map<String, dynamic>> _categories = [
    {'value': 'rent', 'label': 'Rent', 'icon': Icons.home_outlined},
    {'value': 'utilities', 'label': 'Utilities', 'icon': Icons.bolt_outlined},
    {'value': 'subscriptions', 'label': 'Subscriptions', 'icon': Icons.subscriptions_outlined},
    {'value': 'insurance', 'label': 'Insurance', 'icon': Icons.security_outlined},
    {'value': 'internet', 'label': 'Internet', 'icon': Icons.wifi_outlined},
    {'value': 'phone', 'label': 'Phone', 'icon': Icons.phone_android_outlined},
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add Recurring Expense', style: AppTypography.titleLarge),
            const SizedBox(height: 24),

            // Title
            Text('Title', style: AppTypography.labelLarge),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: 'e.g., Netflix, Rent, Gym',
              ),
            ),

            const SizedBox(height: 20),

            // Amount
            Text('Amount', style: AppTypography.labelLarge),
            const SizedBox(height: 8),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: '0.00',
                prefixText: '${ref.watch(currencyProvider)} ',
              ),
            ),

            const SizedBox(height: 20),

            // Frequency
            Text('Frequency', style: AppTypography.labelLarge),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: _frequencies.map((f) {
                final isSelected = _frequency == f['value'];
                return ChoiceChip(
                  label: Text(f['label'] as String),
                  selected: isSelected,
                  onSelected: (_) {
                    setState(() => _frequency = f['value'] as String);
                  },
                  selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            // Category
            Text('Category', style: AppTypography.labelLarge),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((c) {
                final isSelected = _category == c['value'];
                return GestureDetector(
                  onTap: () {
                    setState(() => _category = c['value'] as String);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).primaryColor.withValues(alpha: 0.15)
                          : Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          c['icon'] as IconData,
                          size: 16,
                          color: isSelected
                              ? Theme.of(context).primaryColor
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          c['label'] as String,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            color: isSelected
                                ? Theme.of(context).primaryColor
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            // Day of month (for monthly)
            if (_frequency == 'monthly') ...[
              Text('Day of Month', style: AppTypography.labelLarge),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: _dayOfMonth.toDouble(),
                      min: 1,
                      max: 28,
                      divisions: 27,
                      label: _dayOfMonth.toString(),
                      onChanged: (v) {
                        setState(() => _dayOfMonth = v.round());
                      },
                    ),
                  ),
                  Container(
                    width: 48,
                    alignment: Alignment.center,
                    child: Text(
                      _dayOfMonth.toString(),
                      style: AppTypography.titleMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            const SizedBox(height: 24),

            // Add Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _addRecurring,
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Add Recurring'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addRecurring() async {
    if (_titleController.text.isEmpty || _amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    // Capture navigator before async operation
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    setState(() => _isLoading = true);

    try {
      final db = ref.read(databaseProvider);
      final userId = ref.read(currentUserIdProvider);
      final amount = (double.tryParse(_amountController.text) ?? 0) * 100;

      // Calculate next due date
      final now = DateTime.now();
      DateTime nextDue;
      switch (_frequency) {
        case 'daily':
          nextDue = now.add(const Duration(days: 1));
          break;
        case 'weekly':
          nextDue = now.add(const Duration(days: 7));
          break;
        case 'monthly':
          nextDue = DateTime(now.year, now.month + 1, _dayOfMonth);
          if (nextDue.isBefore(now)) {
            nextDue = DateTime(now.year, now.month + 2, _dayOfMonth);
          }
          break;
        case 'yearly':
          nextDue = DateTime(now.year + 1, now.month, now.day);
          break;
        default:
          nextDue = now.add(const Duration(days: 30));
      }

      await db.insertRecurringExpense(RecurringExpensesCompanion(
        id: Value(_uuid.v4()),
        userId: Value(userId ?? ''),
        title: Value(_titleController.text),
        amount: Value(amount.round()),
        frequency: Value(_frequency),
        dayOfMonth: Value(_frequency == 'monthly' ? _dayOfMonth : null),
        category: Value(_category),
        paymentMethod: const Value('card'),
        nextDueDate: Value(nextDue),
        isActive: const Value(true),
      ));

      navigator.pop();
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Recurring expense added!'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
