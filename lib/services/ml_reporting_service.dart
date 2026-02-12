import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cashpilot/features/ml/services/model_evaluation_service.dart';
import 'email_service.dart';

/// ML Reporting Service - Sends weekly email reports
/// Now wired to emailService (Supabase Edge Function + Resend)
class MLReportingService {

  
  /// Send weekly ML performance report
  /// 
  /// This will email admins a summary of:
  /// - Model performance metrics
  /// - Acceptance/edit/rejection rates
  /// - Most corrected fields
  /// - Recommendations for improvement
  Future<void> sendWeeklyReport({
    required String adminEmail,
  }) async {
    try {
      debugPrint('[ML Report] Generating weekly report...');     
      // Gather metrics
      final modelEval = ModelEvaluationService();
      final receiptPerf = await modelEval.evaluateReceiptModel('receipt_v1.0');
      final topFields = await _getTopCorrectedFields(receiptPerf);
      
      // Generate HTML report
      final html = _generateReportHTML(receiptPerf, topFields);
      
      // Send via email service (Supabase Edge Function + Resend)
      final sent = await emailService.sendEmail(
        to: adminEmail,
        subject: 'CashPilot ML Weekly Report - ${_getWeekRange()}',
        html: html,
      );
      
      if (sent) {
        debugPrint('[ML Report] Report sent successfully to $adminEmail');
      } else {
        debugPrint('[ML Report] Failed to send report');
      }
    } catch (e) {
      debugPrint('[ML Report] Failed to send weekly report: $e');
    }
  }
  
  /// Generate HTML email report
  String _generateReportHTML(ModelPerformance perf, List<String> topFields) {
    final acceptancePercent = (perf.acceptanceRate * 100).toInt();
    final editPercent = (perf.editRate * 100).toInt();
    final rejectionPercent = (perf.rejectionRate * 100).toInt();
    
    return '''
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <style>
          body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Arial, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 600px;
            margin: 0 auto;
            padding: 20px;
            background-color: #f4f4f6;
          }
          .container {
            background: white;
            border-radius: 12px;
            padding: 32px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.1);
          }
          h1 {
            color: #6750A4;
            margin-top: 0;
            font-size: 28px;
          }
          h2 {
            color: #5A5A5F;
            font-size: 20px;
            margin-top: 24px;
            border-bottom: 2px solid #E6E6EA;
            padding-bottom: 8px;
          }
          .metric-grid {
            display: grid;
            grid-template-columns: repeat(2, 1fr);
            gap: 16px;
            margin: 20px 0;
          }
          .metric {
            text-align: center;
            padding: 20px;
            background: #f8f8f9;
            border-radius: 8px;
          }
          .metric-value {
            font-size: 36px;
            font-weight: bold;
            display: block;
          }
          .metric-label {
            color: #8C8C91;
            font-size: 14px;
            margin-top: 4px;
          }
          .status {
            padding: 12px 16px;
            border-radius: 8px;
            margin: 20px 0;
            display: flex;
            align-items: center;
            gap: 12px;
          }
          .status.good {
            background: #E6F7EB;
            color: #1F8A41;
          }
          .status.warning {
            background: #FFF3DE;
            color: #C77B00;
          }
          .status-icon {
            font-size: 24px;
          }
          .field-list {
            list-style: none;
            padding: 0;
            margin: 12px 0;
          }
          .field-list li {
            padding: 8px 12px;
            background: #f8f8f9;
            margin-bottom: 8px;
            border-radius: 6px;
            border-left: 3px solid #6750A4;
          }
          .footer {
            margin-top: 32px;
            padding-top: 20px;
            border-top: 1px solid #E6E6EA;
            color: #8C8C91;
            font-size: 12px;
            text-align: center;
          }
        </style>
      </head>
      <body>
        <div class="container">
          <h1>🤖 ML Performance Report</h1>
          <p><strong>Week of ${_getWeekRange()}</strong></p>
          
          <h2>Receipt Scanner (v1.0)</h2>
          <div class="metric-grid">
            <div class="metric">
              <span class="metric-value">${perf.totalScans}</span>
              <span class="metric-label">Total Scans</span>
            </div>
            <div class="metric">
              <span class="metric-value">$acceptancePercent%</span>
              <span class="metric-label">Acceptance Rate</span>
            </div>
            <div class="metric">
              <span class="metric-value">$editPercent%</span>
              <span class="metric-label">Edited</span>
            </div>
            <div class="metric">
              <span class="metric-value">$rejectionPercent%</span>
              <span class="metric-label">Rejected</span>
            </div>
          </div>
          
          <div class="status ${perf.needsImprovement ? 'warning' : 'good'}">
            <span class="status-icon">${perf.needsImprovement ? '⚠️' : '✅'}</span>
            <span>${perf.needsImprovement ? 'Model needs improvement' : 'Performance is good'}</span>
          </div>
          
          ${topFields.isNotEmpty ? '''
          <h2>Most Corrected Fields</h2>
          <ul class="field-list">
            ${topFields.map((f) => '<li>$f</li>').join('')}
          </ul>
          ''' : ''}
          
          <div class="footer">
            <p>This is an automated report from CashPilot ML System</p>
            <p>Visit ML Dashboard for detailed analytics</p>
          </div>
        </div>
      </body>
      </html>
    ''';
  }
  
  /// Get top corrected fields for reporting
  Future<List<String>> _getTopCorrectedFields(ModelPerformance perf) async {
    final fields = perf.mostCorrectedFields.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return fields
        .take(5)
        .map((e) => '${e.key.capitalize()} (${e.value} corrections)')
        .toList();
  }
  
  /// Get current week date range
  String _getWeekRange() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));
    return '${_formatDate(weekStart)} - ${_formatDate(weekEnd)}';
  }
  
  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}';
  }
  

}

extension StringExt on String {
  String capitalize() {
    return isEmpty ? this : "${this[0].toUpperCase()}${substring(1)}";
  }
}
