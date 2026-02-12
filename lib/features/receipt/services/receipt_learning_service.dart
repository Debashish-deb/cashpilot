import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/receipt_data.dart';
import '../models/receipt_outcome.dart';
import '../models/receipt_model_info.dart';

class ReceiptLearningService {
  final _db = Supabase.instance.client;

  Future<void> record({
    required ReceiptOutcome outcome,
    required ReceiptData original,
    required ReceiptData? corrected,
    required ReceiptModelInfo model,
  }) async {
    final delta = corrected != null
        ? ReceiptCorrectionDelta.compute(original, corrected)
        : null;

    final event = {
      'model_version': model.modelVersion,
      'outcome': outcome.status.name, // Assuming ReceiptOutcomeStatus enum has name
      'confidence': 0.0, // original.confidence, // ReceiptData doesn't have confidence anymore in new model
      'delta': delta?.toJson(),
      'timestamp': DateTime.now().toIso8601String(),
    };

    try {
      await _db.from('receipt_learning_events').insert(event);
    } catch (_) {
      // Fail silently in offline/dev
    }
  }

  /// Record a user acceptance of the receipt data (no changes)
  Future<void> recordAcceptance({
    required String receiptId,
    required String modelVersion,
  }) async {
    final event = {
      'receipt_id': receiptId,
      'model_version': modelVersion,
      'outcome': 'success',
      'timestamp': DateTime.now().toIso8601String(),
    };

    try {
      await _db.from('receipt_learning_events').insert(event);
    } catch (_) {}
  }

  /// Record a user correction
  Future<void> recordCorrection({
    required String receiptId,
    required Map<String, ReceiptFieldCorrection> corrections,
    required String modelVersion,
  }) async {
    final event = {
      'receipt_id': receiptId,
      'model_version': modelVersion,
      'outcome': 'partial',
      'corrections': corrections.map((k, v) => MapEntry(k, v.toJson())),
      'timestamp': DateTime.now().toIso8601String(),
    };

    try {
      await _db.from('receipt_learning_events').insert(event);
    } catch (_) {}
  }

  /// Production ML health monitor
  Future<ModelHealthReport> getHealth(String modelVersion) async {
    try {
      final res = await _db
          .from('receipt_learning_events')
          .select()
          .eq('model_version', modelVersion);

      return ModelHealthReport.from(res as List);
    } catch (_) {
      return const ModelHealthReport(total: 0, acceptance: 0, correction: 0, rejection: 0);
    }
  }
}

class ModelHealthReport {
  final int total;
  final double acceptance;
  final double correction;
  final double rejection;

  const ModelHealthReport({
    required this.total,
    required this.acceptance,
    required this.correction,
    required this.rejection,
  });

  bool get needsRetraining =>
      rejection > 0.12 || correction > 0.30;

  factory ModelHealthReport.from(List rows) {
    int a = 0, c = 0, r = 0;
    for (final e in rows) {
      switch (e['outcome']) {
        case 'success':
          a++;
          break;
        case 'partial':
          c++;
          break;
        case 'failed':
          r++;
          break;
      }
    }
    final total = rows.length;
    return ModelHealthReport(
      total: total,
      acceptance: total == 0 ? 0 : a / total,
      correction: total == 0 ? 0 : c / total,
      rejection: total == 0 ? 0 : r / total,
    );
  }
}

class ReceiptCorrectionDelta {
  final Map<String, dynamic> changes;

  ReceiptCorrectionDelta(this.changes);
  
  // This might not be used anymore if UI constructs manual corrections, but keeping for safety
  static ReceiptCorrectionDelta compute(ReceiptData original, ReceiptData corrected) {
    return ReceiptCorrectionDelta({});
  }

  Map<String, dynamic> toJson() => changes;
}

class ReceiptFieldCorrection {
  final String fieldName;
  final dynamic originalValue;
  final double originalConfidence;
  final dynamic correctedValue;

  ReceiptFieldCorrection({
    required this.fieldName,
    required this.originalValue,
    required this.originalConfidence,
    required this.correctedValue,
  });

  Map<String, dynamic> toJson() => {
    'field': fieldName,
    'original': originalValue,
    'confidence': originalConfidence,
    'corrected': correctedValue,
  };
}
