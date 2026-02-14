
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../features/net_worth/providers/net_worth_providers.dart';
import '../../../../features/auth/providers/auth_provider.dart';
import '../../../../domain/entities/net_worth/asset.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/amount_utils.dart';
import '../../../widgets/common/glass_widgets.dart';

class AddAssetSheet extends ConsumerStatefulWidget {
  const AddAssetSheet({super.key});

  @override
  ConsumerState<AddAssetSheet> createState() => _AddAssetSheetState();
}

class _AddAssetSheetState extends ConsumerState<AddAssetSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _valueController = TextEditingController();
  final _institutionController = TextEditingController();
  
  AssetType _selectedType = AssetType.cash;
  late String _currency;

  @override
  void initState() {
    super.initState();
    _currency = ref.read(currencyProvider);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _valueController.dispose();
    _institutionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      try {
        final user = ref.read(currentUserProvider);
        if (user == null) return;

        final cents = AmountUtils.parseToCents(_valueController.text);
        
        final asset = Asset(
          id: const Uuid().v4(),
          userId: user.id,
          name: _nameController.text,
          type: _selectedType,
          currentValue: cents,
          currency: _currency,
          institutionName: _institutionController.text.isNotEmpty ? _institutionController.text : null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final controller = ref.read(netWorthControllerProvider.notifier);
        await controller.addAsset(asset);
        
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
              content: Text('Failed to save asset: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
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
                'Add Asset',
                style: AppTypography.titleLarge.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              
              // Type Selector
              DropdownButtonFormField<AssetType>(
                initialValue: _selectedType,
                dropdownColor: const Color(0xFF1A1A1A),
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white70),
                style: AppTypography.bodyMedium.copyWith(color: Colors.white),
                decoration: _inputDecoration('Asset Type', Icons.category_outlined),
                items: AssetType.values.map((type) {
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
                decoration: _inputDecoration('Asset Name', Icons.drive_file_rename_outline_rounded),
                validator: (val) => val == null || val.isEmpty ? 'Please enter a name' : null,
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _valueController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: AppTypography.bodyMedium.copyWith(color: Colors.white),
                decoration: _inputDecoration('Current Value ($_currency)', Icons.account_balance_wallet_outlined),
                validator: (val) => val == null || val.isEmpty ? 'Please enter a value' : null,
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _institutionController,
                style: AppTypography.bodyMedium.copyWith(color: Colors.white),
                decoration: _inputDecoration('Institution (Optional)', Icons.business_rounded, hint: 'e.g. Chase, Robinhood'),
              ),
              const SizedBox(height: 40),

              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: Text(
                  'Save Asset',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black, // Dark text on green button for better contrast
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
        borderSide: const BorderSide(color: AppColors.primaryGreen, width: 1.5),
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
