
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../controllers/backup_restore_controller.dart';
import '../models/operation_result.dart';
import 'package:cashpilot/l10n/app_localizations.dart';

class BackupRestoreScreen extends ConsumerStatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  ConsumerState<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends ConsumerState<BackupRestoreScreen> {
  XFile? _selectedFile;
  BackupFileResult? _backupAnalysis;
  bool _isAnalyzing = false;
  bool _isRestoring = false;
  bool _isBackingUp = false;
  RestoreMode _selectedMode = RestoreMode.replace;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsBackupRestore),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBackupSection(l10n),
            const SizedBox(height: 24),
            _buildRestoreSection(l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildBackupSection(AppLocalizations l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.backup_outlined, color: AppColors.primaryGreen),
                const SizedBox(width: 8),
                Text('Create Backup', style: AppTypography.titleMedium),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Generate a local backup of all your budgets, expenses, and settings.',
              style: AppTypography.bodyMedium.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isBackingUp ? null : _performBackup,
                icon: _isBackingUp
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.save_alt),
                label: Text(_isBackingUp ? 'Backing up...' : 'Backup Now'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRestoreSection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.restore_outlined, color: AppColors.accent),
                    const SizedBox(width: 8),
                    Text(l10n.restoreTitle, style: AppTypography.titleMedium),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.restoreSelectFileDesc,
                  style: AppTypography.bodyMedium.copyWith(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isAnalyzing || _isRestoring ? null : _pickFile,
                    icon: _isAnalyzing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.folder_open),
                    label: Text(_selectedFile != null
                        ? _selectedFile!.name
                        : l10n.restoreChooseFile),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_backupAnalysis != null) ...[
          const SizedBox(height: 16),
          _buildBackupPreview(l10n),
          const SizedBox(height: 16),
          _buildRestoreModeSelector(l10n),
          const SizedBox(height: 24),
          _buildRestoreButton(l10n),
        ],
      ],
    );
  }

  Widget _buildBackupPreview(AppLocalizations l10n) {
    final analysis = _backupAnalysis!;
    final manifest = analysis.manifest;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.verified_outlined, color: AppColors.success),
                const SizedBox(width: 8),
                Text(l10n.restoreStepPreview, style: AppTypography.titleMedium),
              ],
            ),
            const SizedBox(height: 16),
            _buildPreviewRow(l10n.restoreLabelCreated, manifest['created_at'] ?? 'Unknown'),
            _buildPreviewRow(l10n.restoreLabelAppVersion, manifest['app_version'] ?? 'Unknown'),
            const Divider(height: 24),
            Text(l10n.restoreDataSummary, style: AppTypography.labelLarge),
            const SizedBox(height: 8),
            _buildCountRow(Icons.account_balance_wallet, l10n.navigationBudgets, analysis.budgetCount),
            _buildCountRow(Icons.receipt_long, l10n.expensesTitle, analysis.expenseCount),
            _buildCountRow(Icons.account_balance, 'Accounts', analysis.accountCount),
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

  Widget _buildRestoreModeSelector(AppLocalizations l10n) {
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
            color: isSelected ? color : Colors.grey.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
          color: isSelected ? color.withValues(alpha: 0.1) : null,
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRestoreButton(AppLocalizations l10n) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isRestoring ? null : _performRestore,
        style: ElevatedButton.styleFrom(
          backgroundColor: _selectedMode == RestoreMode.replace
              ? AppColors.danger
              : AppColors.accent,
          foregroundColor: Colors.white,
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
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Future<void> _performBackup() async {
    setState(() => _isBackingUp = true);
    
    try {
      final controller = ref.read(backupRestoreControllerProvider);
      final result = await controller.createBackup();
      
      if (mounted) {
        setState(() => _isBackingUp = false);
        
        if (result.isSuccess && result.filePath != null) {
          // Share the file
          await Share.shareXFiles(
            [XFile(result.filePath!)],
            subject: 'CashPilot Backup',
          );
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Backup created and saved: ${result.filePath!.split('/').last}'),
              backgroundColor: AppColors.success,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Backup failed: ${result.message}'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isBackingUp = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Backup error: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true, // Needed for web
    );

    if (result != null) {
      final platformFile = result.files.single;
      final xFile = XFile(
        platformFile.path ?? '',
        bytes: platformFile.bytes,
        name: platformFile.name,
      );

      setState(() {
        _selectedFile = xFile;
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
    
    if (_selectedMode == RestoreMode.replace) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.restoreConfirmTitle),
          content: Text(l10n.restoreConfirmBody),
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
      barrierDismissible: false,
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
            const SizedBox(height: 12),
            _buildReportRow(l10n.navigationBudgets, report.budgetsRestored),
            _buildReportRow(l10n.expensesTitle, report.expensesRestored),
            _buildReportRow('Accounts', report.accountsRestored),
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

  Widget _buildReportRow(String label, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13)),
          Text('$count', style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
