import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cashpilot/l10n/app_localizations.dart';
import '../../../../features/savings_goals/application/commands/contribute_to_goal_cmd.dart';
import '../../../../features/savings_goals/domain/entities/savings_goal.dart';
import '../../../../features/savings_goals/presentation/providers/savings_goals_providers.dart';
import '../../../../core/providers/app_providers.dart'; // For auth/user and currency
// import '../../../../features/budgets/providers/budget_providers.dart'; // We need this later for budgets

class ContributeDialog extends ConsumerStatefulWidget {
  final SavingsGoal goal;

  const ContributeDialog({super.key, required this.goal});

  @override
  ConsumerState<ContributeDialog> createState() => _ContributeDialogState();
}

class _ContributeDialogState extends ConsumerState<ContributeDialog> {
  final _amountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _selectedBudgetId; // For "Add from Remaining" logic

  @override
  Widget build(BuildContext context) {
    final currency = ref.watch(currencyProvider);
    final currencySymbol = _getCurrencySymbol(currency);
    final l10n = AppLocalizations.of(context)!;
    
    // TODO: Fetch active budgets to show "Deduct from Budget" dropdown
    // final budgetsAsync = ref.watch(activeBudgetsProvider); 

    return AlertDialog(
      title: Text('Contribute to ${widget.goal.title}'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _amountController,
              decoration: InputDecoration(
                labelText: 'Amount ($currencySymbol)',
                prefixText: '$currencySymbol ',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Enter amount';
                final amount = double.tryParse(value);
                if (amount == null || amount <= 0) return 'Invalid amount';
                if (amount > 999999999) return 'Amount too large';
                return null;
              },
            ),
            const SizedBox(height: 16),
            // Placeholder for Budget Dropdown
            // if (budgetsAsync.hasData) ...[
            //   DropdownButtonFormField(...)
            // ]
            const Text(
              'Optional: Deduct this amount from a budget to track it as an expense.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Contribute'),
        ),
      ],
    );
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final amount = (double.parse(_amountController.text) * 100).toInt(); // Convert to cents
      final userId = ref.read(authServiceProvider).currentUser?.id ?? 'unknown';

      final cmd = ContributeToGoalCmd(
        goalId: widget.goal.id,
        amount: amount,
        userId: userId,
        budgetId: _selectedBudgetId,
      );

      ref.read(savingsGoalsControllerProvider.notifier).contribute(cmd);
      Navigator.pop(context);
    }
  }

  String _getCurrencySymbol(String code) {
    const symbols = {'EUR': '€', 'USD': '\$', 'GBP': '£', 'BDT': '৳', 'INR': '₹'};
    return symbols[code] ?? code;
  }
}
