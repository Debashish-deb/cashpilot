import 'dart:typed_data';
import 'package:excel/excel.dart';
import '../models/export_bundle.dart';
import 'i_renderer.dart';

class XlsxRenderer implements IRenderer {
  @override
  String get extension => 'xlsx';

  @override
  String get mimeType => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

  @override
  Future<Uint8List> render(ExportBundle bundle) async {
    final excel = Excel.createExcel();
    final sheet = excel['Expenses'];

    // Header
    sheet.appendRow([
      TextCellValue('Date'),
      TextCellValue('Title'),
      TextCellValue('Amount'),
      TextCellValue('Currency'),
      TextCellValue('Category'),
      TextCellValue('Merchant'),
      TextCellValue('Payment Method'),
    ]);

    // Data Rows
    for (final e in bundle.expenses) {
      sheet.appendRow([
        TextCellValue(e.date.toIso8601String()),
        TextCellValue(e.title),
        DoubleCellValue(e.amount / 100.0),
        TextCellValue(e.currency),
        TextCellValue(e.categoryId ?? 'Uncategorized'),
        TextCellValue(e.merchantName ?? ''),
        TextCellValue(e.paymentMethod),
      ]);
    }

    // Summary Sheet
    final summarySheet = excel['Summary'];
    summarySheet.appendRow([TextCellValue('Category'), TextCellValue('Total')]);
    bundle.categoryTotals.forEach((cat, total) {
      summarySheet.appendRow([TextCellValue(cat), DoubleCellValue(total)]);
    });

    final fileBytes = excel.save();
    return Uint8List.fromList(fileBytes!);
  }
}
