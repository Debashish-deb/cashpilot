import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../features/savings_goals/application/commands/withdraw_from_goal_cmd.dart';
import '../../../../features/savings_goals/domain/entities/savings_goal.dart';
import '../../../../features/savings_goals/presentation/providers/savings_goals_providers.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/managers/format_manager.dart';

class WithdrawDialog extends ConsumerStatefulWidget {
  final SavingsGoal goal;

  const WithdrawDialog({super.key, required this.goal});

  @override
  ConsumerState<WithdrawDialog> createState() => _WithdrawDialogState();
}

class _WithdrawDialogState extends ConsumerState<WithdrawDialog> {
  final _amountController = TextEditingController();
  final _reasonController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final currency = ref.watch(currencyProvider);
    final formatter = ref.watch(formatManagerProvider);
    final currencySymbol = _getCurrencySymbol(currency);

    return AlertDialog(
      title: Text('Withdraw from ${widget.goal.title}'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Current Balance: ${formatter.formatCurrency(widget.goal.currentAmount / 100, currencyCode: currency)}'),
            const SizedBox(height: 16),
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
                if ((amount * 100) > widget.goal.currentAmount) return 'Exceeds balance';
                return null;
              },
            ),
             const SizedBox(height: 12),
            TextFormField(
              controller: _reasonController,
              decoration: const InputDecoration(labelText: 'Reason (Optional)'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _submit,
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: const Text('Withdraw'),
        ),
      ],
    );
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final amount = (double.parse(_amountController.text) * 100).toInt(); 

      final cmd = WithdrawFromGoalCmd(
        goalId: widget.goal.id,
        amount: amount,
        reason: _reasonController.text,
      );

      ref.read(savingsGoalsControllerProvider.notifier).withdraw(cmd);
      Navigator.pop(context);
    }
  }

  String _getCurrencySymbol(String code) {
    const symbols = {'EUR': '€', 'USD': '\$', 'GBP': '£', 'BDT': '৳', 'INR': '₹'};
    return symbols[code] ?? code;
  }
}
