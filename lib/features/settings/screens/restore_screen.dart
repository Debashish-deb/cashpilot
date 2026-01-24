/// Restore Screen
/// Allows users to select, preview, and restore backups
library;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../controllers/backup_restore_controller.dart';
import '../models/operation_result.dart';

import 'package:cashpilot/l10n/app_localizations.dart';

class RestoreScreen extends ConsumerStatefulWidget {
  const RestoreScreen({super.key});

  @override
  ConsumerState<RestoreScreen> createState() => _RestoreScreenState();
}

class _RestoreScreenState extends ConsumerState<RestoreScreen> {
  File? _selectedFile;
  BackupFileResult? _backupAnalysis;
  bool _isAnalyzing = false;
  bool _isRestoring = false;
  RestoreMode _selectedMode = RestoreMode.replace;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.restoreTitle),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFileSelector(),
            if (_backupAnalysis != null) ...[
              const SizedBox(height: 24),
              _buildBackupPreview(),
              const SizedBox(height: 24),
              _buildRestoreModeSelector(),
              const SizedBox(height: 24),
              _buildRestoreButton(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFileSelector() {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.restoreStepSelect, style: AppTypography.titleMedium),
            const SizedBox(height: 8),
            Text(
              l10n.restoreSelectFileDesc,
              style: AppTypography.bodyMedium.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isAnalyzing ? null : _pickFile,
                icon: _isAnalyzing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.folder_open),
                label: Text(_selectedFile != null
                    ? _selectedFile!.path.split('/').last
                    : l10n.restoreChooseFile),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackupPreview() {
    final analysis = _backupAnalysis!;
    final manifest = analysis.manifest;
    final l10n = AppLocalizations.of(context)!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.verified, color: AppColors.success),
                const SizedBox(width: 8),
                Text(l10n.restoreStepPreview, style: AppTypography.titleMedium),
              ],
            ),
            const SizedBox(height: 16),
            _buildPreviewRow(l10n.restoreLabelCreated, manifest['createdAt'] ?? 'Unknown'),
            _buildPreviewRow(l10n.restoreLabelAppVersion, manifest['appVersion'] ?? 'Unknown'),
            _buildPreviewRow(l10n.restoreLabelSchema, manifest['schemaVersion']?.toString() ?? 'Unknown'),
            const Divider(height: 24),
            Text(l10n.restoreDataSummary, style: AppTypography.labelLarge),
            const SizedBox(height: 8),
            _buildCountRow(Icons.account_balance_wallet, l10n.navigationBudgets, analysis.budgetCount),
            _buildCountRow(Icons.account_balance, l10n.conflictAccount, analysis.accountCount),
            _buildCountRow(Icons.receipt_long, l10n.expensesTitle, analysis.expenseCount),
            _buildCountRow(Icons.category, l10n.reportsCategories, analysis.categoryCount),
            if (analysis.checksumValid) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: AppColors.success, size: 16),
                    const SizedBox(width: 8),
                    Text(l10n.restoreIntegrity),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.bodyMedium.copyWith(color: Colors.grey)),
          Text(value, style: AppTypography.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildCountRow(IconData icon, String label, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 8),
          Text(label),
          const Spacer(),
          Text('$count', style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildRestoreModeSelector() {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.restoreStepMode, style: AppTypography.titleMedium),
            const SizedBox(height: 16),
            _buildModeOption(
              RestoreMode.replace,
              l10n.restoreReplaceAll,
              l10n.restoreModeReplaceDesc,
              Icons.delete_sweep,
              AppColors.warning,
            ),
            const SizedBox(height: 8),
            _buildModeOption(
              RestoreMode.merge,
              l10n.restoreModeMerge,
              l10n.restoreModeMergeDesc,
              Icons.merge_type,
              AppColors.info,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeOption(
    RestoreMode mode,
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    final isSelected = _selectedMode == mode;
    return InkWell(
      onTap: () => setState(() => _selectedMode = mode),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
          color: isSelected ? color.withOpacity(0.1) : null,
        ),
        child: Row(
          children: [
            Radio<RestoreMode>(
              value: mode,
              groupValue: _selectedMode,
              onChanged: (v) => setState(() => _selectedMode = v!),
              activeColor: color,
            ),
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.titleSmall),
                  Text(
                    subtitle,
                    style: AppTypography.bodySmall.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRestoreButton() {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isRestoring ? null : _performRestore,
        style: ElevatedButton.styleFrom(
          backgroundColor: _selectedMode == RestoreMode.replace
              ? AppColors.warning
              : AppColors.success,
          padding: const EdgeInsets.all(16),
        ),
        icon: _isRestoring
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            : const Icon(Icons.restore),
        label: Text(
          _isRestoring ? l10n.restoreActionProgress : l10n.restoreAction,
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
        _isAnalyzing = true;
        _backupAnalysis = null;
      });

      try {
        final controller = ref.read(backupRestoreControllerProvider);
        final analysis = await controller.analyzeBackup(_selectedFile!);
        setState(() {
          _backupAnalysis = analysis;
          _isAnalyzing = false;
        });
      } catch (e) {
        setState(() => _isAnalyzing = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to analyze backup: $e'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      }
    }
  }

  Future<void> _performRestore() async {
    if (_selectedFile == null || _backupAnalysis == null) return;

    final l10n = AppLocalizations.of(context)!;
    
    // Show confirmation dialog for replace mode
    if (_selectedMode == RestoreMode.replace) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.restoreConfirmTitle),
          content: Text(
            l10n.restoreConfirmBody,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.commonCancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
              child: Text(l10n.restoreReplaceAll),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    setState(() => _isRestoring = true);

    try {
      final controller = ref.read(backupRestoreControllerProvider);
      final result = await controller.restoreBackup(
        _selectedFile!,
        _selectedMode,
      );

      if (mounted) {
        setState(() => _isRestoring = false);
        
        if (result.isSuccess) {
          _showRestoreReport(result.data!);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Restore failed: ${result.message}'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isRestoring = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Restore error: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  void _showRestoreReport(RestoreReport report) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: AppColors.success),
            const SizedBox(width: 8),
            Text(l10n.restoreComplete),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.restoreSuccessDetail, style: AppTypography.labelLarge),
            const SizedBox(height: 8),
            Text(l10n.restoreBudgetsCount(report.budgetsRestored)),
            Text(l10n.restoreAccountsCount(report.accountsRestored)),
            Text(l10n.restoreExpensesCount(report.expensesRestored)),
            if (report.warnings.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(l10n.restoreWarnings, style: AppTypography.labelLarge.copyWith(color: AppColors.warning)),
              const SizedBox(height: 4),
              ...report.warnings.map((w) => Text('• $w', style: const TextStyle(fontSize: 12))),
            ],
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Return to settings
            },
            child: Text(l10n.commonOk),
          ),
        ],
      ),
    );
  }
}
