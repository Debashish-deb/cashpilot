
import 'package:cashpilot/core/providers/app_providers.dart' show currencyProvider;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../features/net_worth/providers/net_worth_providers.dart';
import '../../../../features/auth/providers/auth_provider.dart';
import '../../../../domain/entities/net_worth/liability.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/amount_utils.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../widgets/common/glass_widgets.dart';

class AddLiabilitySheet extends ConsumerStatefulWidget {
  const AddLiabilitySheet({super.key});

  @override
  ConsumerState<AddLiabilitySheet> createState() => _AddLiabilitySheetState();
}

class _AddLiabilitySheetState extends ConsumerState<AddLiabilitySheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController();
  final _interestController = TextEditingController();
  
  LiabilityType _selectedType = LiabilityType.creditCard;
  late String _currency;

  @override
  void initState() {
    super.initState();
    _currency = ref.read(currencyProvider);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    _interestController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      try {
        final user = ref.read(currentUserProvider);
        if (user == null) return;

        final balanceCents = AmountUtils.parseToCents(_balanceController.text);
        
        // Interest rate is a percentage, still worth using a safe parse but not toCents
        final sanitizedInterest = _interestController.text.replaceAll(',', '.');
        final interest = double.tryParse(sanitizedInterest);
        
        if (interest != null && (interest < 0 || interest > 100)) {
           throw const AmountValidationException('Interest rate must be between 0 and 100%');
        }

        final liability = Liability(
          id: const Uuid().v4(),
          userId: user.id,
          name: _nameController.text,
          type: _selectedType,
          currentBalance: balanceCents,
          interestRate: interest,
          currency: _currency,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final controller = ref.read(netWorthControllerProvider.notifier);
        await controller.addLiability(liability);
        
        if (mounted) {
          Navigator.pop(context);
        }
      } on AmountValidationException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to save liability: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 24,
        right: 24,
        top: 12,
      ),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      blur: 30,
      opacity: 0.12,
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Pull Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Text(
                'Add Liability',
                style: AppTypography.titleLarge.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              
              DropdownButtonFormField<LiabilityType>(
                initialValue: _selectedType,
                dropdownColor: const Color(0xFF1A1A1A),
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white70),
                style: AppTypography.bodyMedium.copyWith(color: Colors.white),
                decoration: _inputDecoration('Liability Type', Icons.account_balance_rounded),
                items: LiabilityType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.displayName),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedType = val!),
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _nameController,
                style: AppTypography.bodyMedium.copyWith(color: Colors.white),
                decoration: _inputDecoration('Liability Name', Icons.drive_file_rename_outline_rounded),
                validator: (val) => val == null || val.isEmpty ? 'Please enter a name' : null,
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _balanceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: AppTypography.bodyMedium.copyWith(color: Colors.white),
                decoration: _inputDecoration('Current Balance ($_currency)', Icons.money_off_rounded),
                validator: (val) => val == null || val.isEmpty ? 'Please enter the balance' : null,
              ),
              const SizedBox(height: 20),
              
               TextFormField(
                controller: _interestController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: AppTypography.bodyMedium.copyWith(color: Colors.white),
                decoration: _inputDecoration('Interest Rate (%)', Icons.percent_rounded, hint: 'Optional'),
              ),
              const SizedBox(height: 40),

              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: Text(
                  'Save Liability',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, size: 20, color: Colors.white60),
      labelStyle: const TextStyle(color: Colors.white60, fontSize: 14),
      hintStyle: const TextStyle(color: Colors.white24, fontSize: 14),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.05),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.red.withValues(alpha: 0.5)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
    );
  }
}
