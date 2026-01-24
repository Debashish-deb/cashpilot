import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';

import '../data/drift/app_database.dart';

/// Export service for generating CSV and PDF reports
class ExportService {
  // ============================================================
  // CSV EXPORTS
  // ============================================================
  
  /// Export budgets to CSV
  Future<File> exportBudgetsToCSV(List<Budget> budgets) async {
    final rows = [
      // Header
      ['Title', 'Type', 'Start Date', 'End Date', 'Limit', 'Status', 'Notes'],
      
      // Data
      ...budgets.map((b) => [
        b.title,
        b.type,
       DateFormat('yyyy-MM-dd').format(b.startDate),
        DateFormat('yyyy-MM-dd').format(b.endDate),
        '\$${(b.totalLimit ?? 0) / 100}',
        b.status,
        b.notes ?? '',
      ]),
    ];
    
    final csv = const ListToCsvConverter().convert(rows);
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/budgets_export_${DateTime.now().millisecondsSinceEpoch}.csv');
    await file.writeAsString(csv);
    return file;
  }
  
  /// Export expenses to CSV
  Future<File> exportExpensesToCSV(List<Expense> expenses) async {
    final rows = [
      // Header
      ['Date', 'Title', 'Amount', 'Budget ID', 'Category ID', 'Payment Method', 'Merchant', 'Notes'],
      
      // Data
      ...expenses.map((e) => [
        DateFormat('yyyy-MM-dd HH:mm').format(e.date),
        e.title,
        '\$${e.amount / 100}',
        e.budgetId,
        e.categoryId ?? '',
        e.paymentMethod,
        e.merchantName ?? '',
        e.notes ?? '',
      ]),
    ];
    
    final csv = const ListToCsvConverter().convert(rows);
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/expenses_export_${DateTime.now().millisecondsSinceEpoch}.csv');
    await file.writeAsString(csv);
    return file;
  }
  
  // ============================================================
  // PDF EXPORTS
  // ============================================================
  
  /// Export monthly budget summary to PDF
  Future<File> exportBudgetSummaryPDF({
    required String budgetTitle,
    required int totalLimit,
    required int totalSpent,
    required List<({String name, int spent, int limit})> categories,
  }) async {
    final pdf = pw.Document();
    final remaining = totalLimit - totalSpent;
    final percentUsed = totalLimit > 0 ? (totalSpent / totalLimit * 100).toInt() : 0;
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          // Header
          pw.Header(
            level: 0,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Budget Summary',
                  style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(
                  DateFormat('MMMM dd, yyyy').format(DateTime.now()),
                  style: const pw.TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
          
          pw.SizedBox(height: 20),
          
          // Budget Title
          pw.Text(
            budgetTitle,
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
          
          pw.SizedBox(height: 20),
          
          // Summary Section
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey200,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Summary',
                  style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 12),
                _buildStatRow('Total Budget', '\$${totalLimit / 100}'),
                _buildStatRow('Total Spent', '\$${totalSpent / 100}'),
                _buildStatRow('Remaining', '\$${remaining / 100}'),
                _buildStatRow('Usage', '$percentUsed%'),
              ],
            ),
          ),
          
          pw.SizedBox(height: 30),
          
          // Category Breakdown
          if (categories.isNotEmpty) ...[
            pw.Text(
              'Category Breakdown',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 16),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400),
              children: [
                // Header row
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  children: [
                    _buildTableCell('Category', bold: true),
                    _buildTableCell('Limit', bold: true),
                    _buildTableCell('Spent', bold: true),
                    _buildTableCell('Remaining', bold: true),
                    _buildTableCell('%', bold: true),
                  ],
                ),
                
                // Data rows
                ...categories.map((cat) {
                  final catRemaining = cat.limit - cat.spent;
                  final catPercent = cat.limit > 0 ? (cat.spent / cat.limit * 100).toInt() : 0;
                  return pw.TableRow(
                    children: [
                      _buildTableCell(cat.name),
                      _buildTableCell('\$${cat.limit / 100}'),
                      _buildTableCell('\$${cat.spent / 100}'),
                      _buildTableCell('\$${catRemaining / 100}'),
                      _buildTableCell('$catPercent%'),
                    ],
                  );
                }),
              ],
            ),
          ],
          
          pw.SizedBox(height: 30),
          
          // Footer
          pw.Divider(),
          pw.SizedBox(height: 10),
          pw.Text(
            'Generated by CashPilot',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );
    
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/budget_summary_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }
  
  // ============================================================
  // HELPER METHODS
  // ============================================================
  
  pw.Widget _buildStatRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 14)),
          pw.Text(
            value,
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }
  
  pw.Widget _buildTableCell(String text, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: bold 
          ? pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)
          : const pw.TextStyle(fontSize: 12),
      ),
    );
  }
}
