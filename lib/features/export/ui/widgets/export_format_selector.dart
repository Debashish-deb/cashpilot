import 'package:flutter/material.dart';

class ExportFormatSelector extends StatelessWidget {
  final String selectedFormat;
  final ValueChanged<String> onFormatChanged;

  const ExportFormatSelector({
    super.key,
    required this.selectedFormat,
    required this.onFormatChanged,
  });

  @override
  Widget build(BuildContext context) {
    final formats = ['CSV', 'XLSX', 'PDF', 'JSON', 'QBO'];

    return Wrap(
      spacing: 8.0,
      children: formats.map((format) {
        final isSelected = selectedFormat.toUpperCase() == format;
        return ChoiceChip(
          label: Text(format),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) onFormatChanged(format.toLowerCase());
          },
        );
      }).toList(),
    );
  }
}
