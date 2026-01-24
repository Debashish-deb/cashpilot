import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../data/drift/app_database.dart';
import '../../../../features/savings/providers/savings_providers.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../widgets/input/category_icon_selector.dart';
import '../../../widgets/input/category_color_selector.dart';

class SavingsGoalFormDialog extends ConsumerStatefulWidget {
  final SavingsGoal? existingGoal;

  const SavingsGoalFormDialog({super.key, this.existingGoal});

  @override
  ConsumerState<SavingsGoalFormDialog> createState() => _SavingsGoalFormDialogState();
}

class _SavingsGoalFormDialogState extends ConsumerState<SavingsGoalFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _targetController;
  late TextEditingController _currentController;
  
  String? _selectedIcon = 'savings';
  Color? _selectedColor;
  DateTime? _deadline;

  @override
  void initState() {
    super.initState();
    final goal = widget.existingGoal;
    _titleController = TextEditingController(text: goal?.title ?? '');
    _targetController = TextEditingController(text: goal != null ? (goal.targetAmount / 100).toStringAsFixed(0) : '');
    _currentController = TextEditingController(text: goal != null ? (goal.currentAmount / 100).toStringAsFixed(0) : '');
    
    if (goal != null) {
      _selectedIcon = goal.iconName;
      try {
        if (goal.colorHex != null) {
          _selectedColor = Color(int.parse(goal.colorHex!.replaceFirst('#', '0xFF')));
        }
      } catch (_) {}
      _deadline = goal.deadline;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _targetController.dispose();
    _currentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final controller = ref.read(savingsGoalsControllerProvider.notifier);
    final userId = ref.read(currentUserIdProvider);
    
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User not signed in')));
      return;
    }

    final target = (double.tryParse(_targetController.text) ?? 0) * 100;
    final current = (double.tryParse(_currentController.text) ?? 0) * 100;
    
    final colorHex = _selectedColor != null 
        ? '#${_selectedColor!.toARGB32().toRadixString(16).substring(2)}' 
        : null;

    if (widget.existingGoal != null) {
      await controller.updateGoal(
        id: widget.existingGoal!.id,
        title: _titleController.text,
        targetAmount: target.toInt(),
        currentAmount: current.toInt(),
        iconName: _selectedIcon,
        colorHex: colorHex,
        deadline: _deadline,
      );
    } else {
      await controller.createGoal(
        title: _titleController.text,
        targetAmount: target.toInt(),
        currentAmount: current.toInt(),
        userId: userId,
        iconName: _selectedIcon,
        colorHex: colorHex,
        deadline: _deadline,
      );
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(savingsGoalsControllerProvider);
    final isLoading = state is AsyncLoading;

    return AlertDialog(
      title: Text(widget.existingGoal != null ? 'Edit Goal' : 'New Savings Goal'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Goal Title'),
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _targetController,
                decoration: const InputDecoration(labelText: 'Target Amount', prefixText: '€ '),
                keyboardType: TextInputType.number,
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
              if (widget.existingGoal != null) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _currentController,
                  decoration: const InputDecoration(labelText: 'Current Saved', prefixText: '€ '),
                  keyboardType: TextInputType.number,
                ),
              ],
              const SizedBox(height: 16),
              ListTile(
                title: Text(_deadline == null 
                    ? 'Set Target Date' 
                    : 'Target: ${DateFormat.yMMMd().format(_deadline!)}'),
                leading: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _deadline ?? DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 3650)),
                  );
                  if (date != null) setState(() => _deadline = date);
                },
              ),
              const SizedBox(height: 16),
              CategoryIconSelector(
                selectedIconName: _selectedIcon,
                accentColor: _selectedColor ?? Theme.of(context).primaryColor,
                onIconSelected: (v) => setState(() => _selectedIcon = v),
              ),
              const SizedBox(height: 16),
              CategoryColorSelector(
                selectedColor: _selectedColor,
                onColorSelected: (c) => setState(() => _selectedColor = c),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: isLoading ? null : _submit,
          child: isLoading 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Save'),
        ),
      ],
    );
  }
}
