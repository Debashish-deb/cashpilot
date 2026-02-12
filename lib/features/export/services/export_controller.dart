import 'package:drift/drift.dart';
import '../../../data/drift/app_database.dart';
import '../renderers/i_renderer.dart';
import '../renderers/csv_renderer.dart';
import '../renderers/json_renderer.dart';
import '../renderers/xlsx_renderer.dart';
import '../renderers/pdf_renderer.dart';
import '../renderers/qbo_renderer.dart';
import 'export_intelligence_engine.dart';
import 'compliance_formatter.dart';
import 'security_privacy_layer.dart';
import 'delivery_channels.dart';

class ExportController {
  final AppDatabase _db;
  final ExportIntelligenceEngine _engine = ExportIntelligenceEngine();
  final ComplianceFormatter _formatter = ComplianceFormatter();
  final SecurityPrivacyLayer _privacy = SecurityPrivacyLayer();
  final DeliveryChannels _delivery = DeliveryChannels();

  ExportController(this._db);

  /// Triggers an export job.
  Future<void> export({
    required String userId,
    required DateTime start,
    required DateTime end,
    required String format,
    required String generatedBy,
    bool maskNotes = false,
    bool shareAfterExport = true,
  }) async {
    // 1. Fetch data
    final expenses = await _db.getExpensesInDateRange(userId, start, end);
    final budgets = await _db.getAllBudgets(userId);

    // 2. Aggregate data
    var bundle = await _engine.generateBundle(
      expenses: expenses,
      budgets: budgets,
      generatedBy: generatedBy,
      exportFormat: format,
    );

    // 3. Apply compliance and privacy
    bundle = _formatter.formatForIFRS(bundle);
    bundle = _privacy.applyPrivacyFilter(bundle, maskNotes: maskNotes);

    // 4. Render
    final renderer = _getRenderer(format);
    final bytes = await renderer.render(bundle);

    // 5. Deliver
    final fileName = 'CashPilot_Export_${DateTime.now().millisecondsSinceEpoch}.${renderer.extension}';
    if (shareAfterExport) {
      await _delivery.shareFile(bytes, fileName, renderer.mimeType);
    } else {
      await _delivery.saveLocally(bytes, fileName);
    }

    // 6. Audit Log (Enterprise feature)
    await _db.into(_db.auditLogs).insert(AuditLogsCompanion.insert(
      id: DateTime.now().toIso8601String(), // Or use UUID
      entityType: 'export',
      entityId: fileName,
      action: 'generate',
      userId: userId,
      metadata: Value({'format': format, 'count': expenses.length}),
    ));
  }

  IRenderer _getRenderer(String format) {
    switch (format.toLowerCase()) {
      case 'csv':
        return CsvRenderer();
      case 'json':
        return JsonRenderer();
      case 'xlsx':
        return XlsxRenderer();
      case 'pdf':
        return PdfRenderer();
      case 'qbo':
        return QboRenderer();
      default:
        return CsvRenderer();
    }
  }
}
