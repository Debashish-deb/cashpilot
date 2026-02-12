import 'package:cashpilot/l10n/app_localizations.dart' show AppLocalizations;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cashpilot/features/ml/providers/ab_testing_providers.dart';

class CreateTestDialog extends ConsumerStatefulWidget {
  const CreateTestDialog({super.key});

  @override
  ConsumerState<CreateTestDialog> createState() => _CreateTestDialogState();
}

class _CreateTestDialogState extends ConsumerState<CreateTestDialog> {
  final _formKey = GlobalKey<FormState>();
  final _testNameController = TextEditingController();
  final _controlVersionController = TextEditingController(text: 'v1.0.0');
  final _treatmentVersionController = TextEditingController(text: 'v1.1.0-beta');
  
  String _selectedModel = 'expense_categorizer';
  double _treatmentRatio = 0.5;
  bool _isLoading = false;

  final List<String> _models = [
    'expense_categorizer',
    'income_predictor',
    'anomaly_detector',
  ];

  @override
  void dispose() {
    _testNameController.dispose();
    _controlVersionController.dispose();
    _treatmentVersionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final service = ref.read(abTestingServiceProvider);
      await service.createTest(
        testName: _testNameController.text,
        modelName: _selectedModel,
        controlVersion: _controlVersionController.text,
        treatmentVersion: _treatmentVersionController.text,
        treatmentRatio: _treatmentRatio,
      );

      if (mounted) {
        Navigator.of(context).pop(true); // Return true on success
        // Invalidate providers to refresh lists
        ref.invalidate(activeTestsProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating test: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.adminNewTest),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _testNameController,
                decoration: const InputDecoration(
                  labelText: 'Test Name',
                  hintText: 'e.g., Improved Categorizer V2',
                ),
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedModel,
                decoration: const InputDecoration(labelText: 'Target Model'),
                items: _models.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                onChanged: (v) => setState(() => _selectedModel = v!),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _controlVersionController,
                      decoration: const InputDecoration(labelText: 'Control (A)'),
                      validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _treatmentVersionController,
                      decoration: const InputDecoration(labelText: 'Treatment (B)'),
                      validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text('Treatment Ratio: ${(_treatmentRatio * 100).toInt()}%'),
              Slider(
                value: _treatmentRatio,
                min: 0.1,
                max: 0.9,
                divisions: 8,
                label: '${(_treatmentRatio * 100).toInt()}%',
                onChanged: (v) => setState(() => _treatmentRatio = v),
              ),
              Text(
                '${(_treatmentRatio * 100).toInt()}% of users will get Treatment (B)',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text(AppLocalizations.of(context)!.commonAdd),
        ),
      ],
    );
  }
}
