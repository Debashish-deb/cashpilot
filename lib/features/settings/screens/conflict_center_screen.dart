/// Conflict Center Screen
/// Displays and resolves sync conflicts
library;

import 'dart:convert';
import 'package:cashpilot/features/sync/sync_providers.dart' show conflictListProvider, conflictServiceProvider, openConflictsProvider;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../data/drift/app_database.dart';
import '../../../services/sync/conflict_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import 'package:cashpilot/l10n/app_localizations.dart';
import 'widgets/conflict_merge_dialog.dart';

class ConflictCenterScreen extends ConsumerWidget {
  const ConflictCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conflictsAsync = ref.watch(conflictListProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.conflictTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(conflictListProvider),
            tooltip: l10n.conflictRefresh,
          ),
        ],
      ),
      body: conflictsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (conflicts) {
          if (conflicts.isEmpty) {
            return _buildEmptyState(context);
          }
          return _buildConflictList(context, ref, conflicts);
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 80,
            color: AppColors.success.withValues(alpha: 0.7),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.conflictNone,
            style: AppTypography.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.conflictAllGood,
            style: AppTypography.bodyMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConflictList(BuildContext context, WidgetRef ref, List<ConflictData> conflicts) {
    return Column(
      children: [
        _buildSummaryBar(context, conflicts.length),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: conflicts.length,
            itemBuilder: (context, index) {
              return _ConflictCard(
                conflict: conflicts[index],
                onResolve: (resolution, [mergedData]) => _resolveConflict(ref, conflicts[index], resolution, mergedData),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryBar(BuildContext context, int count) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.warning.withValues(alpha: 0.1),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: AppColors.warning),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.conflictCount(count),
              style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _resolveConflict(WidgetRef ref, ConflictData conflict, ConflictResolution resolution, [Map<String, dynamic>? mergedData]) async {
    await ref.read(conflictServiceProvider).resolveConflict(
      conflictId: conflict.id,
      resolution: resolution,
      mergedData: mergedData,
    );
    ref.invalidate(conflictListProvider);
    ref.invalidate(openConflictsProvider);
  }
}

class _ConflictCard extends StatelessWidget {
  final ConflictData conflict;
  final Function(ConflictResolution, [Map<String, dynamic>?]) onResolve;

  const _ConflictCard({
    required this.conflict,
    required this.onResolve,
  });

  @override
  Widget build(BuildContext context) {
    final localData = _parseJson(conflict.localJson);
    final remoteData = _parseJson(conflict.remoteJson);
    final diffs = _parseDiffs(conflict.diffJson);
    final l10n = AppLocalizations.of(context)!;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        leading: _getEntityIcon(conflict.entityType),
        title: Text(
          _getEntityTitle(context, localData, remoteData, conflict.entityType),
          style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${conflict.entityType} • ${DateFormat.yMMMd().format(conflict.createdAt)}',
          style: AppTypography.bodySmall.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Diff rows
                if (diffs.isNotEmpty) ...[
                  Text(l10n.syncChanges, style: AppTypography.labelLarge),
                  const SizedBox(height: 8),
                  ...diffs.map((diff) => _DiffRow(diff: diff)),
                  const SizedBox(height: 16),
                ],
                
                // Resolution buttons
                Text(l10n.syncResolution, style: AppTypography.labelLarge),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _ResolutionButton(
                      label: l10n.conflictKeepLocal,
                      icon: Icons.phone_android,
                      color: AppColors.info,
                      onPressed: () => onResolve(ConflictResolution.keepLocal),
                    ),
                    _ResolutionButton(
                      label: l10n.conflictKeepCloud,
                      icon: Icons.cloud,
                      color: AppColors.success,
                      onPressed: () => onResolve(ConflictResolution.keepRemote),
                    ),
                    _ResolutionButton(
                      label: 'Expert Merge',
                      icon: Icons.merge_type_rounded,
                      color: AppColors.warning,
                      onPressed: () => _showMergeDialog(context, conflict),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showMergeDialog(BuildContext context, ConflictData conflict) {
    showDialog(
      context: context,
      builder: (context) => ConflictMergeDialog(
        conflict: conflict,
        onMerge: (mergedData) => onResolve(ConflictResolution.merge, mergedData),
      ),
    );
  }

  Widget _getEntityIcon(String entityType) {
    final iconData = switch (entityType) {
      'expense' => Icons.receipt_long,
      'budget' => Icons.account_balance_wallet,
      'account' => Icons.account_balance,
      'category' => Icons.category,
      'recurring' => Icons.repeat,
      _ => Icons.description,
    };
    return CircleAvatar(
      backgroundColor: AppColors.warning.withValues(alpha: 0.2),
      child: Icon(iconData, color: AppColors.warning),
    );
  }

  String _getEntityTitle(BuildContext context, Map<String, dynamic> local, Map<String, dynamic> remote, String entityType) {
    final l10n = AppLocalizations.of(context)!;
    switch (entityType) {
      case 'expense':
        return local['description'] ?? remote['description'] ?? l10n.conflictExpense;
      case 'budget':
        return local['title'] ?? remote['title'] ?? l10n.conflictBudget;
      case 'account':
        return local['name'] ?? remote['name'] ?? l10n.conflictAccount;
      default:
        return entityType.toUpperCase();
    }
  }

  Map<String, dynamic> _parseJson(String json) {
    try {
      return jsonDecode(json) as Map<String, dynamic>;
    } catch (e) {
      return {};
    }
  }

  List<Map<String, dynamic>> _parseDiffs(String? diffJson) {
    if (diffJson == null) return [];
    try {
      return (jsonDecode(diffJson) as List).cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }
}

class _DiffRow extends StatelessWidget {
  final Map<String, dynamic> diff;

  const _DiffRow({required this.diff});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              _formatFieldName(diff['field'] as String? ?? ''),
              style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                // Local value
                _ValueChip(
                  value: diff['local']?.toString() ?? 'null',
                  color: AppColors.info,
                  icon: Icons.phone_android,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.arrow_forward, size: 16),
                ),
                // Remote value
                _ValueChip(
                  value: diff['remote']?.toString() ?? 'null',
                  color: AppColors.success,
                  icon: Icons.cloud,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatFieldName(String field) {
    // Convert camelCase to Title Case
    return field.replaceAllMapped(
      RegExp(r'([A-Z])'),
      (m) => ' ${m.group(0)}',
    ).trim().split(' ').map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}').join(' ');
  }
}

class _ValueChip extends StatelessWidget {
  final String value;
  final Color color;
  final IconData icon;

  const _ValueChip({
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            value.length > 20 ? '${value.substring(0, 20)}...' : value,
            style: AppTypography.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _ResolutionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _ResolutionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withValues(alpha: 0.5)),
      ),
    );
  }
}
