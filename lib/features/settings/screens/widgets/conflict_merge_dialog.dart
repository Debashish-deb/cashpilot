import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '/../../data/drift/app_database.dart';
import '/../../services/sync/conflict_service.dart';
import '/../../core/theme/app_colors.dart';
import '/../../core/theme/app_typography.dart';
import 'package:cashpilot/l10n/app_localizations.dart';

class ConflictMergeDialog extends StatefulWidget {
  final Conflict conflict;
  final Function(Map<String, dynamic>) onMerge;

  const ConflictMergeDialog({
    super.key,
    required this.conflict,
    required this.onMerge,
  });

  @override
  State<ConflictMergeDialog> createState() => _ConflictMergeDialogState();
}

class _ConflictMergeDialogState extends State<ConflictMergeDialog> {
  late Map<String, dynamic> _localData;
  late Map<String, dynamic> _remoteData;
  late List<Map<String, dynamic>> _diffs;
  final Map<String, String> _selections = {}; // field -> 'local' or 'remote'

  @override
  void initState() {
    super.initState();
    _localData = jsonDecode(widget.conflict.localJson) as Map<String, dynamic>;
    _remoteData = jsonDecode(widget.conflict.remoteJson) as Map<String, dynamic>;
    _diffs = (jsonDecode(widget.conflict.diffJson ?? '[]') as List).cast<Map<String, dynamic>>();
    
    // Initialize with local by default for all fields
    for (final diff in _diffs) {
      _selections[diff['field'] as String] = 'local';
    }
  }

  void _onToggle(String field, String value) {
    setState(() {
      _selections[field] = value;
    });
  }

  void _confirm() {
    final merged = Map<String, dynamic>.from(_localData);
    for (final field in _selections.keys) {
      if (_selections[field] == 'remote') {
        merged[field] = _remoteData[field];
      }
    }
    widget.onMerge(merged);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 500,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.warning.withValues(alpha: 0.1),
                    child: Icon(Icons.merge_type_rounded, color: AppColors.warning),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Expert Merge',
                          style: AppTypography.titleLarge,
                        ),
                        Text(
                          'Pick individual values for each field',
                          style: AppTypography.bodySmall.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const Divider(height: 1),
            
            // Diffs List
            Flexible(
              child: ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: _diffs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 20),
                itemBuilder: (context, index) {
                  final diff = _diffs[index];
                  final field = diff['field'] as String;
                  return _buildMergeRow(field, diff);
                },
              ),
            ),
            
            const Divider(height: 1),
            
            // Footer
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(l10n.cancel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _confirm,
                      child: const Text('Resolve Merge'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMergeRow(String field, Map<String, dynamic> diff) {
    final selection = _selections[field];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _formatFieldName(field),
          style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ValuePicker(
                label: 'Local',
                value: diff['local']?.toString() ?? 'null',
                isSelected: selection == 'local',
                icon: Icons.phone_android,
                color: AppColors.info,
                onTap: () => _onToggle(field, 'local'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ValuePicker(
                label: 'Cloud',
                value: diff['remote']?.toString() ?? 'null',
                isSelected: selection == 'remote',
                icon: Icons.cloud,
                color: AppColors.success,
                onTap: () => _onToggle(field, 'remote'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatFieldName(String field) {
    return field.replaceAllMapped(
      RegExp(r'([A-Z])'),
      (m) => ' ${m.group(0)}',
    ).trim().split(' ').map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}').join(' ');
  }
}

class _ValuePicker extends StatelessWidget {
  final String label;
  final String value;
  final bool isSelected;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ValuePicker({
    required this.label,
    required this.value,
    required this.isSelected,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Theme.of(context).dividerColor.withValues(alpha: 0.5),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: isSelected ? color : Colors.grey),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: AppTypography.labelSmall.copyWith(
                    color: isSelected ? color : Colors.grey,
                    fontWeight: isSelected ? FontWeight.bold : null,
                  ),
                ),
                const Spacer(),
                if (isSelected)
                  Icon(Icons.check_circle, size: 16, color: color),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodySmall.copyWith(
                fontWeight: isSelected ? FontWeight.w500 : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
