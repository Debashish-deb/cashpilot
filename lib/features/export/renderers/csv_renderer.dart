import 'dart:convert';
import 'dart:typed_data';
import 'package:csv/csv.dart';
import '../models/export_bundle.dart';
import 'i_renderer.dart';

class CsvRenderer implements IRenderer {
  @override
  String get extension => 'csv';

  @override
  String get mimeType => 'text/csv';

  @override
  Future<Uint8List> render(ExportBundle bundle) async {
    final List<List<dynamic>> rows = [];

    // Header
    rows.add([
      'Date',
      'Title',
      'Amount',
      'Currency',
      'Category',
      'Merchant',
      'Notes',
      'Payment Method',
      'VAT Amount'
    ]);

    // Data Rows
    for (final e in bundle.expenses) {
      final amount = e.amount / 100.0;
      // We derive a rough VAT per expense for the CSV if needed, 
      // or just use the bundle's summary. 
      // For row-level, we'll use the default rate used in the bundle if we can access it,
      // but let's just use 0 for now as it's not stored per expense.
      final vatPerExpense = 0.0; 

      rows.add([
        e.date.toIso8601String(),
        e.title,
        amount,
        e.currency,
        e.categoryId ?? 'Uncategorized',
        e.merchantName ?? '',
        e.notes ?? '',
        e.paymentMethod,
        vatPerExpense,
      ]);
    }

    final csvString = const ListToCsvConverter().convert(rows);
    return Uint8List.fromList(utf8.encode(csvString));
  }
}
