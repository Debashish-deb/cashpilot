import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cashpilot/l10n/app_localizations.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/providers/app_providers.dart';
import '../../../features/receipt/models/receipt_extraction_meta.dart';
import '../../../features/receipt/models/receipt_outcome.dart';
import '../../../core/providers/ml_providers.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/default_categories.dart' show industrialCategories, CategoryIconMapper;
import '../../../features/budgets/providers/budget_providers.dart';
import '../../../features/expenses/providers/expense_providers.dart';
import '../../../features/expenses/models/prediction_result.dart';
import '../../../features/expenses/services/category_learning_service.dart';
import '../../../core/constants/app_constants.dart' show PaymentMethod;
import '../../../features/barcode/services/barcode_scanner_service.dart';
import '../../widgets/common/cp_app_icon.dart';
import '../../widgets/expenses/category_suggestion_chip.dart';

/// Extension for PaymentMethod display helpers
extension PaymentMethodDisplay on PaymentMethod {
  String get displayName {
    switch (this) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.card:
        return 'Card';
      case PaymentMethod.bank:
        return 'Bank';
      case PaymentMethod.wallet:
        return 'Wallet';
    }
  }

  IconData get icon {
    switch (this) {
      case PaymentMethod.cash:
        return Icons.money;
      case PaymentMethod.card:
        return Icons.credit_card;
      case PaymentMethod.bank:
        return Icons.account_balance;
      case PaymentMethod.wallet:
        return Icons.account_balance_wallet;
    }
  }
}

class AddExpenseScreen extends ConsumerStatefulWidget {
  final String? budgetId;
  final String? semiBudgetId;
  final String? expenseId;
  final int? initialAmount;
  final String? initialTitle;
  final DateTime? initialDate;
  final bool fromOCR;
  final ReceiptExtractionMeta? receiptMeta;

  const AddExpenseScreen({
    super.key,
    this.budgetId,
    this.semiBudgetId,
    this.expenseId,
    this.initialAmount,
    this.initialTitle,
    this.initialDate,
    this.fromOCR = false,
    this.receiptMeta,
  });

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isLoading = false;
  String? _selectedBudgetId;
  String? _selectedCategoryId; // Semi-budget / envelope
  DateTime _selectedDate = DateTime.now();
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  
  // Modern features
  final bool _detailsExpanded = false;
  double? _budgetImpactPercentage;
  String? _budgetName;
  bool _wasAutoFilledTitle = false;
  
  // ML Categorization
  PredictionResult? _categoryPrediction;
  bool _predictionDismissed = false;
  bool _predictionAutoApplied = false;
  
  // ML Receipt Learning
  bool _fromOCR = false;
  Map<String, dynamic>? _originalScanData;
  ReceiptExtractionMeta? _originalReceiptMeta;

  bool get isEditing => widget.expenseId != null;

  @override
  void initState() {
    super.initState();
    if (widget.budgetId != null) _selectedBudgetId = widget.budgetId;
    if (widget.semiBudgetId != null) _selectedCategoryId = widget.semiBudgetId;
    
    // ML: Listen to title changes for category prediction
    _titleController.addListener(_onTitleChanged);
    
    // ML: Initialize receipt learning data if from OCR scan
    _fromOCR = widget.fromOCR;
    if (_fromOCR && widget.receiptMeta != null) {
      _originalReceiptMeta = widget.receiptMeta;
      _originalScanData = {
        'amount': widget.initialAmount,
        'merchant': widget.initialTitle,
        'date': widget.initialDate,
      };
    }
    
    if (isEditing) {
      _loadExpense();
    } else {
      // Pre-fill from usage arguments (e.g. Scan)
      if (widget.initialAmount != null) {
        _amountController.text = (widget.initialAmount! / 100).toStringAsFixed(2);
      }
      if (widget.initialTitle != null) {
        _titleController.text = widget.initialTitle!;
      }
      if (widget.initialDate != null) {
        _selectedDate = widget.initialDate!;
      }

      // Smart Defaults: If no budget provided, try to auto-fill from habits
      if (widget.budgetId == null) {
        _loadSmartDefaults();
      } else if (widget.semiBudgetId != null) {
        // Auto-fill title from pre-selected category
        _autoFillTitleFromCategory(widget.semiBudgetId!);
      }
    }
  }
  
  Future<void> _autoFillTitleFromCategory(String categoryId) async {
    await Future.delayed(Duration.zero);
    if (!mounted) return;
    
    try {
      final db = ref.read(databaseProvider);
      final category = await (db.select(db.semiBudgets)
        ..where((t) => t.id.equals(categoryId))).getSingleOrNull();
      
      if (category != null && mounted && _titleController.text.isEmpty) {
        setState(() {
          _titleController.text = category.name;
          _wasAutoFilledTitle = true;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadExpense() async {
    await Future.delayed(Duration.zero);
    if (!mounted) return;

    setState(() => _isLoading = true);
    
    try {
      final db = ref.read(databaseProvider);
      final expense = await (db.select(db.expenses)..where((t) => t.id.equals(widget.expenseId!))).getSingleOrNull();
      
      if (expense != null && mounted) {
        setState(() {
          _amountController.text = (expense.amount / 100).toStringAsFixed(2);
          _titleController.text = expense.title;
          _notesController.text = expense.notes ?? '';
          _selectedDate = expense.date;
          _selectedBudgetId = expense.budgetId;
          _selectedCategoryId = expense.semiBudgetId;
          
          try {
            _paymentMethod = PaymentMethod.values.firstWhere(
              (e) => e.name == expense.paymentMethod,
              orElse: () => PaymentMethod.cash,
            );
          } catch (_) {}
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load expense: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadSmartDefaults() async {
    // Wait for frame to ensure providers are ready? Not strictly needed for .read
    // We delay slightly to not block UI init
    await Future.delayed(Duration.zero);
    if (!mounted) return;

    try {
      // Fetch available budgets to validate against (prevent dropdown crash)
      final availableBudgets = await ref.read(budgetsStreamProvider.future);
      final expenses = await ref.read(recentExpensesProvider.future);
      
      if (expenses.isNotEmpty) {
        final last = expenses.first;
        final candidateId = last.budgetId;
        
        // Only auto-fill if the budget is still valid/visible
        if (availableBudgets.any((b) => b.id == candidateId)) {
          setState(() {
            _selectedBudgetId ??= candidateId;
            
            // Only auto-fill category if it belongs to the same budget
            _selectedCategoryId ??= last.semiBudgetId; 
            
            // Auto-fill payment method
            try {
              _paymentMethod = PaymentMethod.values.firstWhere(
                (e) => e.name == last.paymentMethod, 
                orElse: () => PaymentMethod.cash
              );
            } catch (_) {}
          });
          return;
        }
      } 
      
      // Fallback: No habits or invalid previous budget? Select first active budget
      final activeBudgetsAsync = ref.read(activeBudgetsProvider);
      final activeBudgets = activeBudgetsAsync.valueOrNull ?? [];
      
      if (activeBudgets.isNotEmpty) {
          setState(() {
            _selectedBudgetId = activeBudgets.first.id;
          });
      }

    } catch (e) {
      // Ignore errors in smart defaults
    }
  }

  @override
  void dispose() {
    _titleController.removeListener(_onTitleChanged);
    _amountController.dispose();
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }
  
  // ML: Predict category when title changes
  void _onTitleChanged() async {
    final merchant = _titleController.text.trim();
    if (merchant.isEmpty || merchant.length < 3) {
      setState(() {
        _categoryPrediction = null;
        _predictionDismissed = false;
      });
      return;
    }
    
    try {
      final predictor = ref.read(categoryPredictorProvider);
      final amount = _amountController.text.isNotEmpty 
          ? (double.tryParse(_amountController.text) ?? 0) * 100 
          : 0;
      
      final prediction = await predictor.predictTop(
        merchant: merchant,
        amountInCents: amount.round(),
        timestamp: _selectedDate,
      );
      
      if (prediction != null && mounted && !_predictionDismissed) {
        setState(() {
          _categoryPrediction = prediction;
          
          // Auto-apply if confidence >= 85% and no category selected
          if (predictor.shouldAutoApply(prediction) && _selectedCategoryId == null) {
            // Find matching category by name
            // Note: This is simplified - in production match by category ID
            _predictionAutoApplied = true;
          }
        });
      }
    } catch (e) {
      // Ignore prediction errors
    }
  }

  Future<void> _deleteExpense() async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.expensesDeleteExpense),
        content: Text(l10n.expensesDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Capture navigator before async operation
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    setState(() => _isLoading = true);

    try {
      final controller = ref.read(expenseControllerProvider);
      await controller.deleteExpense(widget.expenseId!);
      
      navigator.pop();
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text(l10n.expensesDeleted)),
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('${l10n.expensesDeleteError}: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBudgetId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a budget')),
      );
      return;
    }

    // ML: Learn from user's category selection
    if (_selectedCategoryId != null) {
      try {
        final db = ref.read(databaseProvider);
        final learningService = CategoryLearningService(db);
        final category = await (db.select(db.semiBudgets)
          ..where((t) => t.id.equals(_selectedCategoryId!))).getSingleOrNull();
        
        if (category != null) {
          await learningService.learnPattern(
            merchant: _titleController.text,
            selectedCategory: category.name,
          );
        }
      } catch (e) {
        // Ignore learning errors
      }
    }

    // ML: Learn from receipt scan edits (if this expense came from OCR)
    if (_fromOCR && _originalScanData != null && _originalReceiptMeta != null) {
      try {
        final receiptLearning = ref.read(receiptLearningServiceProvider);
        final originalAmount = _originalScanData!['amount'] as int?;
        final originalMerchant = _originalScanData!['merchant'] as String?;
        
        final currentAmount = (double.parse(_amountController.text) * 100).round();
        final currentMerchant = _titleController.text;
        
        // Track if user edited the scanned data
        final wasEdited = originalAmount != currentAmount || 
                         originalMerchant != currentMerchant;
        
        if (wasEdited) {
          // User edited - record what they changed
          final corrections = <String, ReceiptFieldCorrection>{};
          if (originalAmount != null && originalAmount != currentAmount) {
            corrections['total'] = ReceiptFieldCorrection(
              fieldName: 'total',
              originalValue: originalAmount / 100.0,
              originalConfidence: _originalReceiptMeta!.total?.confidence ?? 0.0,
              correctedValue: currentAmount / 100.0,
            );
          }
          if (originalMerchant != null && originalMerchant != currentMerchant) {
            corrections['merchant'] = ReceiptFieldCorrection(
              fieldName: 'merchant',
              originalValue: originalMerchant,
              originalConfidence: _originalReceiptMeta!.merchant?.confidence ?? 0.0,
              correctedValue: currentMerchant,
            );
          }
          
          await receiptLearning.recordCorrection(
            receiptId: 'temp_${DateTime.now().millisecondsSinceEpoch}',
            corrections: corrections,
            modelVersion: _originalReceiptMeta!.modelVersion,
          );
        } else {
          // User accepted scan as-is
          await receiptLearning.recordAcceptance(
            receiptId: 'temp_${DateTime.now().millisecondsSinceEpoch}',
            modelVersion: _originalReceiptMeta!.modelVersion,
          );
        }
      } catch (e) {
        // Ignore learning errors
        debugPrint('[ML] Failed to record receipt learning: $e');
      }
    }

    // Capture navigator before async operation
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    setState(() => _isLoading = true);

    try {
      final controller = ref.read(expenseControllerProvider);
      final amount = (double.parse(_amountController.text) * 100).round();

      if (isEditing) {
        await controller.updateExpense(
          id: widget.expenseId!,
          budgetId: _selectedBudgetId,
          semiBudgetId: _selectedCategoryId,
          title: _titleController.text,
          amount: amount,
          date: _selectedDate,
          notes: _notesController.text.isEmpty ? null : _notesController.text,
          paymentMethod: _paymentMethod.name,
        );
      } else {
        await controller.createExpense(
          budgetId: _selectedBudgetId!,
          semiBudgetId: _selectedCategoryId,
          title: _titleController.text,
          amount: amount,
          date: _selectedDate,
          notes: _notesController.text.isEmpty ? null : _notesController.text,
          paymentMethod: _paymentMethod.name,
        );
      }

      navigator.pop(true); // Return true to indicate success
    } catch (e) {
      final l10n = AppLocalizations.of(context)!;
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('${l10n.expensesSaveError}: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _scanBarcode() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      // 1. Scan Barcode
      final result = await BarcodeScannerService().scanBarcode();
      if (result == null || result.rawValue.isEmpty) return;

      if (!mounted) return;

      // 2. Show loading feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.expensesProductLookup),
          duration: Duration(seconds: 1),
        ),
      );

      setState(() => _isLoading = true);

      // 3. Lookup Product Info
      final product = await BarcodeScannerService().lookupProduct(result.rawValue);

      if (!mounted) return;

      if (product != null) {
        setState(() {
          // Auto-fill Title
          if (product.name != null && product.name!.isNotEmpty) {
            _titleController.text = product.name!;
            if (product.brand != null && product.brand!.isNotEmpty) {
              _titleController.text += ' (${product.brand})';
            }
          }

          // Auto-fill Amount (if price available)
          if (product.price != null && product.price! > 0) {
             _amountController.text = product.price!.toStringAsFixed(2);
          }
          
          // Auto-fill Notes with description if empty
          if (_notesController.text.isEmpty && product.description != null) {
            _notesController.text = product.description!;
          }
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.expensesProductFound}: ${product.name ?? "Product"}'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Fallback if no product info found, just use the barcode itself?
        // Or just let the user know.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.expensesProductNotFound)),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.expensesScanFailed}: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currency = ref.watch(currencyProvider);
    final budgetsAsync = ref.watch(budgetsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? l10n.expensesEditExpense : l10n.expensesAddExpense),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.danger),
              onPressed: _isLoading ? null : _deleteExpense,
            ),
          TextButton(
            onPressed: _isLoading ? null : _saveExpense,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.commonSave),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Amount Input
            _buildAmountInput(currency, l10n),
            const SizedBox(height: 24),

            // Title Input
            _buildTitleInput(l10n),
            const SizedBox(height: 20),

            // Budget Selection
            _buildBudgetSelector(budgetsAsync, l10n),
            const SizedBox(height: 20),

            // ML Category Suggestion
            if (_categoryPrediction != null && !_predictionDismissed)
              CategorySuggestionChip(
                prediction: _categoryPrediction!,
                l10n: l10n,
                isAutoApplied: _predictionAutoApplied,
                onApply: () {
                  // Apply prediction - simplified for now
                  setState(() {
                    _predictionAutoApplied = true;
                  });
                },
                onDismiss: () {
                  setState(() {
                    _predictionDismissed = true;
                    _categoryPrediction = null;
                    _predictionAutoApplied = false;
                  });
                },
              ),

            // Category Selection - ALWAYS visible
            _buildCategorySelector(l10n),

            // Date Picker
            _buildDatePicker(l10n),
            const SizedBox(height: 20),

            // Payment Method
            _buildPaymentMethodSelector(l10n),
            const SizedBox(height: 20),

            // Notes
            _buildNotesInput(l10n),
            const SizedBox(height: 32),

            // Save Button
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveExpense,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(l10n.expensesAddExpense,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountInput(String currency, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Text(
            l10n.expensesAmount,
            style: AppTypography.labelLarge.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            style: AppTypography.displayMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            decoration: InputDecoration(
              prefixText: _getCurrencySymbol(currency),
              prefixStyle: AppTypography.displayMedium.copyWith(
                color: Colors.white70,
                fontWeight: FontWeight.bold,
              ),
              border: InputBorder.none,
              filled: false, // Ensure transparent background
              hintText: l10n.expensesAmountHint,
              hintStyle: AppTypography.displayMedium.copyWith(
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            ],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Required';
              }
              final amount = double.tryParse(value);
              if (amount == null || amount <= 0) {
                return 'Please enter a valid amount';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTitleInput(AppLocalizations l10n) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.expensesTitle,
          style: AppTypography.labelLarge.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _titleController,
          style: AppTypography.bodyLarge.copyWith(
            color: isLight ? Colors.black : Colors.white, // High contrast text
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: l10n.expensesTitleExample,
            hintStyle: TextStyle(
              color: isLight ? Colors.black38 : Colors.white30,
            ),
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
            suffixIcon: IconButton(
              icon: const Icon(Icons.qr_code_scanner),
              tooltip: 'Scan Barcode',
              onPressed: _isLoading ? null : _scanBarcode,
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Required';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildBudgetSelector(
      AsyncValue<List<dynamic>> budgetsAsync, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.expensesBudget,
          style: AppTypography.labelLarge.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        budgetsAsync.when(
          data: (budgets) {
            if (budgets.isEmpty) {
              return SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: () => context.push(AppRoutes.budgetCreate),
                  icon: const Icon(Icons.add),
                  label: Text(l10n.budgetsCreateBudget),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              );
            }
            return DropdownButtonFormField<String>(
              initialValue: _selectedBudgetId,
              decoration: InputDecoration(
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
              hint: Text(l10n.expensesSelectBudget),
              items: budgets.map((budget) {
                return DropdownMenuItem<String>(
                  value: budget.id,
                  child: Text(
                    budget.title,
                    style: AppTypography.bodyLarge.copyWith(
                      color: Theme.of(context).brightness == Brightness.light ? Colors.black : Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedBudgetId = value;
                  _selectedCategoryId = null;
                });
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Text('Error loading budgets'),
        ),
      ],
    );
  }

  Widget _buildCategorySelector(AppLocalizations l10n) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // If budget is selected, use budget-specific categories
    // Otherwise, show global industrial categories
    if (_selectedBudgetId != null) {
      return _buildBudgetCategorySelector(l10n, isDarkMode);
    } else {
      return _buildGlobalCategorySelector(l10n, isDarkMode);
    }
  }
  
  // Category selector when a budget IS selected (uses semi_budgets)
  Widget _buildBudgetCategorySelector(AppLocalizations l10n, bool isDarkMode) {
    final semiBudgetsAsync = ref.watch(semiBudgetsProvider(_selectedBudgetId!));
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.expensesCategory,
          style: AppTypography.labelLarge.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        semiBudgetsAsync.when(
          data: (categories) {
            if (categories.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Theme.of(context).hintColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'No categories in this budget',
                        style: TextStyle(color: Theme.of(context).hintColor),
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.pushNamed(
                         AppRoutes.budgetEdit, 
                         pathParameters: {'id': _selectedBudgetId!}
                      ),
                      child: const Text('Add'),
                    ),
                  ],
                ),
              );
            }
            return _buildCategoryGrid(
              categories.map((c) => _CategoryItem(
                id: c.id,
                name: c.name,
                iconName: c.iconName ?? 'category',
                colorHex: c.colorHex ?? '#808080',
              )).toList(),
              isDarkMode,
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Text('Error loading categories'),
        ),
      ],
    );
  }
  
  // Category selector when NO budget is selected (uses global industrialCategories)
  Widget _buildGlobalCategorySelector(AppLocalizations l10n, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              l10n.expensesCategory,
              style: AppTypography.labelLarge.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Select budget for more',
                style: AppTypography.labelSmall.copyWith(
                  color: Theme.of(context).primaryColor,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildCategoryGrid(
          industrialCategories.take(16).map((c) => _CategoryItem(
            id: c.localizationKey,
            name: c.getLocalizedName(context),
            iconName: c.iconName,
            colorHex: c.colorHex,
          )).toList(),
          isDarkMode,
        ),
      ],
    );
  }
  
  // Shared Apple-style grid builder
  Widget _buildCategoryGrid(List<_CategoryItem> categories, bool isDarkMode) {
    final sortedCategories = List.of(categories)..sort((a, b) => a.name.compareTo(b.name));
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.85,
      ),
      itemCount: sortedCategories.length,
      itemBuilder: (context, index) {
        final category = sortedCategories[index];
        final isSelected = _selectedCategoryId == category.id;
        
        Color categoryColor = Theme.of(context).primaryColor;
        try {
          categoryColor = Color(int.parse(category.colorHex.replaceFirst('#', '0xFF')));
        } catch (_) {}
        
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() {
              final wasSelected = _selectedCategoryId == category.id;
              _selectedCategoryId = wasSelected ? null : category.id;
              
              if (!wasSelected) {
                 if (_titleController.text.isEmpty || _wasAutoFilledTitle) {
                   _titleController.text = category.name;
                   _wasAutoFilledTitle = true;
                 }
              } else if (_wasAutoFilledTitle) {
                 _titleController.text = '';
               }
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected 
                  ? categoryColor.withValues(alpha: 0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              // No border for clean Apple look
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CPAppIcon(
                  icon: CategoryIconMapper.resolve(category.iconName),
                  color: categoryColor,
                  size: 36,
                  iconSize: 20,
                  useGradient: true,
                  useShadow: isSelected,
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    category.name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.labelSmall.copyWith(
                      fontSize: 10,
                      color: isSelected 
                          ? categoryColor 
                          : (isDarkMode ? Colors.white70 : Colors.black87),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      height: 1.1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDatePicker(AppLocalizations l10n) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.expensesDate,
          style: AppTypography.labelLarge.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _pickDate,
          borderRadius: BorderRadius.circular(16), // Match inputs
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.2), 
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today,
                    color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  DateFormat('EEEE, MMMM d, yyyy', l10n.localeName).format(_selectedDate),
                  style: AppTypography.bodyLarge.copyWith(
                    color: isLight ? Colors.black : Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodSelector(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.expensesPaymentMethod,
          style: AppTypography.labelLarge.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: PaymentMethod.values.map((method) {
            final isSelected = _paymentMethod == method;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _PaymentMethodChip(
                  label: _getLocalizedPaymentMethodName(method, l10n),
                  icon: method.icon,
                  isSelected: isSelected,
                  onTap: () => setState(() => _paymentMethod = method),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildNotesInput(AppLocalizations l10n) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.expensesNotes,
          style: AppTypography.labelLarge.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _notesController,
          maxLines: 3,
          style: AppTypography.bodyLarge.copyWith(
            color: isLight ? Colors.black : Colors.white,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: l10n.expensesNotesHint,
            hintStyle: TextStyle(
              color: isLight ? Colors.black38 : Colors.white30,
            ),
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
  String _getLocalizedPaymentMethodName(PaymentMethod method, AppLocalizations l10n) {
    switch (method) {
      case PaymentMethod.cash:
        return l10n.paymentMethodCash;
      case PaymentMethod.card:
        return l10n.paymentMethodCard;
      case PaymentMethod.bank:
        return l10n.paymentMethodBank;
      case PaymentMethod.wallet:
        return l10n.paymentMethodWallet;
    }
  }
}

class _PaymentMethodChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentMethodChip({
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
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  isSelected ? Theme.of(context).primaryColor : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 24,
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Helper class for unified category display
class _CategoryItem {
  final String id;
  final String name;
  final String iconName;
  final String colorHex;
  
  const _CategoryItem({
    required this.id,
    required this.name,
    required this.iconName,
    required this.colorHex,
  });
}
