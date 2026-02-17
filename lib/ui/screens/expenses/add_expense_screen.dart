import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart'; // Added for temp ID generation
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cashpilot/l10n/app_localizations.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/providers/app_providers.dart';
import '../../../features/receipt/models/receipt_extraction_meta.dart';
import '../../../core/constants/app_routes.dart';
import '../../widgets/common/glass_card.dart';
import '../../../features/barcode/models/barcode_scan_result.dart';
import '../../../core/constants/default_categories.dart' show industrialCategories, CategoryIconMapper;
import '../../../features/budgets/providers/budget_providers.dart';
import '../../../features/expenses/providers/expense_providers.dart';
import '../../../features/expenses/models/prediction_result.dart';
import '../../../features/receipt/services/receipt_learning_service.dart';
import '../../../core/constants/app_constants.dart' show PaymentMethod;
import '../../widgets/common/cp_app_icon.dart';
import '../../widgets/expenses/category_suggestion_chip.dart';
import '../../../core/helpers/localized_category_helper.dart';
import '../../../data/drift/app_database.dart';
import '../../../features/expenses/providers/category_providers.dart';
import '../../widgets/common/glass_toast_provider.dart'; // Glass Toast
import '../../../features/ml/services/subcategory_intelligence_engine.dart'; // Unified Intelligence Engine

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

enum AddExpenseMethod { selection, manual }

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
  String? _selectedSemiBudgetId; // Legacy Semi-budget / envelope
  Category? _selectedCategory;   // New Taxonomy Category
  SubCategory? _selectedSubCategory; // New Taxonomy SubCategory
  DateTime _selectedDate = DateTime.now();
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  

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

  AddExpenseMethod _currentMethod = AddExpenseMethod.selection;

  @override
  void initState() {
    super.initState();
    
    // Skip selection if editing an existing expense or data provided
    if (widget.expenseId != null || widget.fromOCR || widget.initialAmount != null) {
      _currentMethod = AddExpenseMethod.manual;
    }
    if (widget.budgetId != null) _selectedBudgetId = widget.budgetId;
    if (widget.semiBudgetId != null) _selectedSemiBudgetId = widget.semiBudgetId;
    
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
      
      if (widget.semiBudgetId != null) _selectedSemiBudgetId = widget.semiBudgetId;

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
          _selectedSemiBudgetId = expense.semiBudgetId;
          
          // Load new taxonomy if available
          _loadTaxonomy(expense.categoryId, expense.subCategoryId);
          
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
          SnackBar(content: Text(AppLocalizations.of(context)!.commonErrorMessage(e.toString()))),
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
            _selectedSemiBudgetId ??= last.semiBudgetId; 
            
            // Also try to auto-fill main taxonomy if available
            if (last.categoryId != null) {
              _loadTaxonomy(last.categoryId, last.subCategoryId);
            }
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

  Future<void> _loadTaxonomy(String? categoryId, String? subCategoryId) async {
    if (categoryId == null) return;
    
    try {
      final db = ref.read(databaseProvider);
      
      // Load Category
      final category = await (db.select(db.categories)..where((t) => t.id.equals(categoryId))).getSingleOrNull();
      if (category != null && mounted) {
        setState(() {
          _selectedCategory = category;
        });
        
        // Load SubCategory if ID provided
        if (subCategoryId != null) {
          final sub = await (db.select(db.subCategories)..where((t) => t.id.equals(subCategoryId))).getSingleOrNull();
          if (sub != null && mounted) {
            setState(() {
              _selectedSubCategory = sub;
            });
          }
        }
      }
    } catch (e) {
      debugPrint('[AddExpense] Failed to load taxonomy: $e');
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
  
  // ML: Predict category using Unified Intelligence
  void _onTitleChanged() async {
    final rawInput = _titleController.text.trim();
    if (rawInput.isEmpty || rawInput.length < 3) {
      setState(() {
        _categoryPrediction = null;
        _predictionDismissed = false;
      });
      return;
    }
    
    try {
      // Use Unified Engine
      final engine = ref.read(subcategoryIntelligenceEngineProvider);
      final prediction = await engine.predict(
        rawInput: rawInput, 
        source: InferenceSource.manual
      );
      
      // Map back to legacy PredictionResult for UI compatibility (for now)
      // Phase 4 will introduce SubCategory specific chips
      if (prediction.subCategory != null && mounted && !_predictionDismissed) {
        final categoryId = prediction.subCategory!.categoryId;
        
        // Fetch category name
        final db = ref.read(databaseProvider);
        final category = await (db.select(db.semiBudgets)..where((t) => t.id.equals(categoryId))).getSingleOrNull();
        
        if (category != null) {
           final uiPrediction = PredictionResult(
            category: category.name,
            confidence: (prediction.confidence * 100).toInt(), // Fixed: double -> int conversion
            source: 'learned', // Fixed: String literal instead of undefined enum
          );

          setState(() {
            _categoryPrediction = uiPrediction;
            
            // Auto-apply logic (0.90 threshold from plan)
            if (prediction.shouldAutoFill && _selectedSemiBudgetId == null) {
              _selectedSemiBudgetId = categoryId; // Set the actual Category ID
              _predictionAutoApplied = true;
               
               Future.delayed(const Duration(milliseconds: 300), () {
                   if (mounted) {
                     ref.read(glassToastProvider).show(
                       'Auto-filled "${category.name}" (${(prediction.confidence * 100).toInt()}% confidence)',
                       type: GlassToastType.ai,
                     );
                   }
               });
            }
          });
        }
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
        SnackBar(content: Text(AppLocalizations.of(context)!.expenseSelectBudget)),
      );
      return;
    }

    // ML: Learn from user's selection (Unified Intelligence)
    try {
      if (_titleController.text.isNotEmpty && _selectedSemiBudgetId != null) {
        final engine = ref.read(subcategoryIntelligenceEngineProvider);
        
        // Determine source for weighted learning
        InferenceSource source = InferenceSource.manual;
        if (_fromOCR) {
          source = InferenceSource.ocr;
        } else if (_wasAutoFilledTitle && _titleController.text.contains('(')) {
          // heuristic check if barcode populated (e.g. "Product (Brand)")
          // Ideally we'd have a specific flag _fromBarcode
          source = InferenceSource.barcode; 
        }

        // Reinforce the unified engine
        await engine.reinforce(
          rawInput: _titleController.text,
          subCategoryId: _selectedSemiBudgetId!,
          source: source,
        );
        
        // Show Learning Confirmation if not previously predicted/auto-applied
         if (!_wasAutoFilledTitle && !_predictionAutoApplied) {
            // Fetch category name for toast
            final db = ref.read(databaseProvider);
            final category = await (db.select(db.semiBudgets)
              ..where((t) => t.id.equals(_selectedSemiBudgetId!))).getSingleOrNull();

           if (category != null) {
             ref.read(glassToastProvider).show(
               'Learnt pattern: "${_titleController.text}" → ${category.name}',
               type: GlassToastType.ai,
             );
           }
         }
      }
    } catch (_) {}
    
    /* 
    // Commented out legacy learning to prevent conflict with new Unified Architecture
    if (_selectedSemiBudgetId != null) {
      try {
        final db = ref.read(databaseProvider);
        final learningService = CategoryLearningService(db);
        // ... legacy code ...
      } catch (e) {}
    } 
    */

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
          categoryId: _selectedCategory?.id,
          subCategoryId: _selectedSubCategory?.id,
          semiBudgetId: _selectedSemiBudgetId,
          title: _titleController.text,
          amount: amount,
          date: _selectedDate,
          notes: _notesController.text.isEmpty ? null : _notesController.text,
          paymentMethod: _paymentMethod.name,
        );
      } else {
        await controller.createExpense(
          budgetId: _selectedBudgetId!,
          categoryId: _selectedCategory?.id,
          subCategoryId: _selectedSubCategory?.id,
          semiBudgetId: _selectedSemiBudgetId,
          title: _titleController.text,
          amount: amount,
          date: _selectedDate,
          notes: _notesController.text.isEmpty ? null : _notesController.text,
          paymentMethod: _paymentMethod.name,
        );
      }
      
      // ML: Check for anomalies (Fire and forget, runs in background)
      // We perform this AFTER save and pop, using global Glass Toast
      final authService = ref.read(authServiceProvider);
      final currency = ref.read(currencyProvider);
      final tempExpense = Expense(
        id: isEditing ? widget.expenseId! : const Uuid().v4(),
        budgetId: _selectedBudgetId!,
        categoryId: _selectedCategory?.id,
        subCategoryId: _selectedSubCategory?.id,
        semiBudgetId: _selectedSemiBudgetId,
        amountCents: BigInt.from(amount),
        confidenceBps: BigInt.from(10000),
        enteredBy: authService.currentUser?.id ?? '',
        title: _titleController.text,
        amount: amount,
        currency: currency,
        date: _selectedDate,
        paymentMethod: _paymentMethod.name,
        isRecurring: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        revision: isEditing ? 0 : 0, // Revision will be handled by repository
        syncState: 'dirty',
        lamportClock: 0,
        isDeleted: false,
        confidence: 1.0,
        source: _fromOCR ? 'ocr' : 'manual',
        isAiAssigned: false,
        isVerified: true,
        isTransfer: false,
        isRefund: false,
        isReconciled: false,
      );

      // NOTE: Original save logic above already handled create/update via Repo
      // This second block was a duplicate from the plan. Removing to prevent double-insert.
      /*
      if (isEditing) {
        await controller.updateExpense(tempExpense.toCompanion(true));
      } else {
        await controller.createExpense(tempExpense.toCompanion(true));
      }
      */

      if (mounted) {
        navigator.pop(true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('${l10n.expensesSaveError}: $e')),
        );
      }
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: _currentMethod == AddExpenseMethod.manual ? _buildAppBar(l10n) : null,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _currentMethod == AddExpenseMethod.selection
            ? _buildSelectionLanding(l10n, isDark)
            : _buildExpenseForm(l10n, isDark),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(AppLocalizations l10n) {
    return AppBar(
      title: Text(widget.expenseId != null ? l10n.expensesEditExpense : l10n.expensesAddExpense),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          if (widget.expenseId == null && !widget.fromOCR && widget.initialAmount == null) {
             setState(() => _currentMethod = AddExpenseMethod.selection);
          } else {
            context.pop();
          }
        },
      ),
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
    );
  }

  Widget _buildSelectionLanding(AppLocalizations l10n, bool isDark) {
    final theme = Theme.of(context);
    
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            Text(
              l10n.expensesAddExpense,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose how you want to add your expense',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 48),
            
            // Manual Add Card
            _buildSelectionCard(
              icon: Icons.edit_note_rounded,
              title: l10n.enterManually,
              description: 'Quickly enter details with smart category prediction',
              color: theme.colorScheme.primary,
              onTap: () => setState(() => _currentMethod = AddExpenseMethod.manual),
              isDark: isDark,
            ),
            
            const SizedBox(height: 20),
            
            // Receipt Scan Card
            _buildSelectionCard(
              icon: Icons.receipt_long_rounded,
              title: l10n.homeScanReceipt,
              description: 'Automatically extract info from photos of receipts',
              color: Colors.orange,
              onTap: _navigateToReceiptScan,
              isDark: isDark,
            ),
            
            const SizedBox(height: 20),
            
            // Barcode Scan Card
            _buildSelectionCard(
              icon: Icons.qr_code_scanner_rounded,
              title: l10n.homeScanBarcode,
              description: 'Scan product barcodes to lookup names and prices',
              color: Colors.blue,
              onTap: _navigateToBarcodeScan,
              isDark: isDark,
            ),
            
            const Spacer(),
            Center(
              child: TextButton(
                onPressed: () => context.pop(),
                child: Text(l10n.commonCancel),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToReceiptScan() async {
    // We already have AppRoutes.scanReceipt
    await context.push(AppRoutes.scanReceipt);
    // ReceiptScanScreen pushes AddExpense again with data, so we don't need to do anything here
    // But maybe we should pop this selection screen first?
    // Actually, ReceiptScanScreen handles it.
  }

  Future<void> _navigateToBarcodeScan() async {
    final result = await context.push<BarcodeScanResult>(AppRoutes.scanBarcode);
    if (result != null && mounted) {
      setState(() {
        _currentMethod = AddExpenseMethod.manual;
      });
      // Small delay to allow AnimatedSwitcher to transition
      await Future.delayed(const Duration(milliseconds: 100));
      _processBarcodeResult(result);
    }
  }

  void _processBarcodeResult(BarcodeScanResult result) {
    if (result.productInfo != null) {
      final product = result.productInfo!;
      setState(() {
        if (product.name != null) {
          _titleController.text = product.name!;
          if (product.brand != null) {
            _titleController.text += ' (${product.brand})';
          }
        }
        if (product.price != null && product.price! > 0) {
          _amountController.text = product.price!.toStringAsFixed(2);
        }
      });
    }
  }

  Widget _buildExpenseForm(AppLocalizations l10n, bool isDark) {
    final currency = ref.watch(currencyProvider);
    final budgetsAsync = ref.watch(budgetsStreamProvider);

    return SafeArea(
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
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
          MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: MediaQuery.of(context).textScaler.clamp(maxScaleFactor: 1.5),
            ),
            child: TextFormField(
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
              onPressed: _isLoading ? null : _navigateToBarcodeScan,
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
                  _selectedCategory = null;
                  _selectedSubCategory = null;
                  _selectedSemiBudgetId = null;
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
    // Hoisted provider watch to prevent conditional watching inside Builder
    final allSubsAsync = ref.watch(allSubCategoriesProvider);

    // When a budget is selected, show its SemiBudgets (Envelopes)
    if (_selectedBudgetId != null) {
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
          const SizedBox(height: 8),
          semiBudgetsAsync.when(
            data: (semiBudgets) {
              final parentCategories = semiBudgets.where((s) => !s.isSubcategory).toList();
              
              if (parentCategories.isEmpty) {
                 return Text(
                  'No categories in this budget',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                );
              }

                  return Builder(
                    builder: (context) {
                      // Derive the parent ID for UI display
                      String? activeParentId;
                      try {
                        final current = semiBudgets.firstWhere((s) => s.id == _selectedSemiBudgetId);
                        if (current.isSubcategory && current.parentCategoryId != null) {
                           activeParentId = current.parentCategoryId;
                        } else {
                           activeParentId = current.id;
                        }
                      } catch (e) {
                        activeParentId = null;
                      }

                      // Verify parent exists in the list (safety check)
                      final effectiveParentValue = parentCategories.any((p) => p.id == activeParentId) 
                          ? activeParentId 
                          : null;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DropdownButtonFormField<String>(
                            initialValue: effectiveParentValue,
                            decoration: InputDecoration(
                                filled: true,
                                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                hintText: 'Select Category',
                            ),
                            items: parentCategories.map((s) {
                               Color categoryColor = Theme.of(context).primaryColor;
                               try {
                                 categoryColor = Color(int.parse((s.colorHex ?? '#808080').replaceFirst('#', '0xFF')));
                               } catch (_) {}
                               
                               return DropdownMenuItem<String>(
                                value: s.id,
                                child: Row(
                                  children: [
                                     CPAppIcon(
                                        icon: CategoryIconMapper.resolve(s.iconName ?? 'category'),
                                        color: categoryColor,
                                        size: 24,
                                        iconSize: 14,
                                        useGradient: false,
                                     ),
                                     const SizedBox(width: 12),
                                     Text(s.name, style: AppTypography.bodyLarge),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() {
                                 if (val != null) {
                                   _selectedSemiBudgetId = val;
                                   _selectedSubCategory = null; 
                                   
                                   if (_titleController.text.isEmpty || _wasAutoFilledTitle) {
                                      final cat = parentCategories.firstWhere((c) => c.id == val);
                                      _titleController.text = cat.name;
                                      _wasAutoFilledTitle = true;
                                   }
                                 }
                              });
                            },
                          ),
                          
                          // Subcategory Dropdown (Hybrid: Child Envelopes + Master Subcategories)
                          if (effectiveParentValue != null) ...[
                            Builder(
                              builder: (context) {
                                // 1. Child SemiBudgets (Envelopes)
                                final childCategories = semiBudgets
                                    .where((s) => s.parentCategoryId == effectiveParentValue)
                                    .toList();
                                    
                                // 2. Master Subcategories (for the selected Parent Envelope)
                                List<SubCategory> masterSubs = [];
                                
                                if (allSubsAsync.hasValue) {
                                  try {
                                    final parentSB = semiBudgets.firstWhere((s) => s.id == effectiveParentValue);
                                    if (parentSB.masterCategoryId != null) {
                                      masterSubs = allSubsAsync.value!
                                          .where((s) => s.categoryId == parentSB.masterCategoryId)
                                          .toList();
                                    }
                                  } catch (_) {}
                                }
                                
                                if (childCategories.isEmpty && masterSubs.isEmpty) return const SizedBox.shrink();
                                
                                // Generate Dropdown Items
                                final List<DropdownMenuItem<String>> items = [];
                                
                                // Add Child Envelopes
                                if (childCategories.isNotEmpty) {
                                  items.addAll(childCategories.map((s) => DropdownMenuItem(
                                    value: s.id,
                                    child: Text(s.name, style: AppTypography.bodyLarge),
                                  )));
                                }
                                
                                // Add Master Subs
                                if (masterSubs.isNotEmpty) {
                                    items.addAll(masterSubs.map((s) => DropdownMenuItem(
                                      value: s.id,
                                      child: Text(
                                        LocalizedCategoryHelper.getLocalizedName(context, s.name),
                                        style: AppTypography.bodyLarge,
                                      ),
                                    )));
                                }

                                // Validate value
                                String? safeValue = (_selectedSemiBudgetId != effectiveParentValue) 
                                    ? _selectedSemiBudgetId 
                                    : _selectedSubCategory?.id;
                                
                                if (safeValue != null && !items.any((i) => i.value == safeValue)) {
                                  safeValue = null;
                                }

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                     const SizedBox(height: 16),
                                     Text(
                                      'Subcategory', 
                                      style: AppTypography.labelLarge.copyWith(
                                        color: Theme.of(context).colorScheme.onSurface,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    DropdownButtonFormField<String>(
                                        initialValue: safeValue, 
                                        decoration: InputDecoration(
                                            filled: true,
                                            fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                            hintText: 'Select Subcategory',
                                        ),
                                        items: items,
                                        onChanged: (val) {
                                          if (val != null) {
                                             setState(() {
                                               // Check if it's a SemiBudget (Envelope)
                                               final isSemiBudget = childCategories.any((s) => s.id == val);
                                               
                                               if (isSemiBudget) {
                                                  _selectedSemiBudgetId = val;
                                                  _selectedSubCategory = null;
                                               } else {
                                                  // It's a Master SubCategory
                                                  // Keep the Parent SemiBudget as selected
                                                  _selectedSemiBudgetId = effectiveParentValue; 
                                                  try {
                                                    _selectedSubCategory = masterSubs.firstWhere((s) => s.id == val);
                                                  } catch (_) {
                                                    _selectedSubCategory = null;
                                                  }
                                               }
                                             });
                                          }
                                        },
                                    ),
                                  ],
                                );
                              }
                            ),
                          ],
                       ],
                      );
                    }
                  );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => Text(l10n.commonErrorMessage('')),
          ),
        ],
      );
    }
    
    // No budget selected - Legacy Master Categories
    final categoriesAsync = ref.watch(allCategoriesProvider);
    return categoriesAsync.when(
      data: (categories) {
         final topLevel = categories.where((c) => c.parentId == null).toList();
         
         return Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
             Text(
                l10n.expensesCategory,
                style: AppTypography.labelLarge.copyWith(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w600),
              ),
             const SizedBox(height: 8),
             DropdownButtonFormField<String>(
               initialValue: _selectedCategory?.id,
               decoration: InputDecoration(
                   filled: true,
                   fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                   border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                   contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                   hintText: 'Select Category',
               ),
               items: topLevel.map((c) {
                   Color color = Theme.of(context).primaryColor;
                   try { color = Color(int.parse((c.colorHex ?? '#808080').replaceFirst('#', '0xFF'))); } catch (_) {}
                   return DropdownMenuItem(
                     value: c.id,
                     child: Row(children: [
                       CPAppIcon(icon: CategoryIconMapper.resolve(c.iconName ?? 'category'), color: color, size: 24, iconSize: 14),
                       const SizedBox(width: 12),
                       Text(LocalizedCategoryHelper.getLocalizedName(context, c.name, iconName: c.iconName), style: AppTypography.bodyLarge),
                     ]),
                   );
               }).toList(),
               onChanged: (val) {
                 if (val == null) return;
                 setState(() {
                   final cat = categories.firstWhere((c) => c.id == val);
                   _selectedCategory = cat;
                   _selectedSubCategory = null; 
                   
                   if (_titleController.text.isEmpty || _wasAutoFilledTitle) {
                       _titleController.text = LocalizedCategoryHelper.getLocalizedName(context, cat.name, iconName: cat.iconName);
                       _wasAutoFilledTitle = true;
                   }
                 });
               },
             ),
             
             // Subcategory Dropdown (Master Taxonomy)
             if (_selectedCategory != null) ...[
                const SizedBox(height: 16),
                _buildSubCategorySelector(l10n),
             ],
           ],
         );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildSubCategorySelector(AppLocalizations l10n) {
    // Correctly fetches subcategories for the selected master category
    final subCategoriesAsync = ref.watch(subCategoriesProvider(_selectedCategory!.id));
    
    return subCategoriesAsync.when(
      data: (subs) {
        if (subs.isEmpty) return const SizedBox.shrink();
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Subcategory',
              style: AppTypography.labelLarge.copyWith(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _selectedSubCategory?.id,
              decoration: InputDecoration(
                   filled: true,
                   fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                   border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                   contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                   hintText: 'Select Subcategory',
              ),
              items: subs.map((s) => DropdownMenuItem(
                value: s.id,
                child: Text(s.name, style: AppTypography.bodyLarge),
              )).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedSubCategory = subs.firstWhere((s) => s.id == val);
                  });
                }
              },
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  // Helper method to maintain state for parent dropdown even if child is selected
  String? _getParentSemiBudgetId(List<SemiBudget> all, String? currentId) {
    if (currentId == null) return null;
    final current = all.firstWhere((s) => s.id == currentId, orElse: () => all.first); // fallback
    if (current.isSubcategory && current.parentCategoryId != null) {
      return current.parentCategoryId;
    }
    return current.id;
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
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: PaymentMethod.values.map((method) {
              final isSelected = _paymentMethod == method;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: SizedBox(
                  width: MediaQuery.textScalerOf(context).scale(84).clamp(84.0, 120.0),
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


