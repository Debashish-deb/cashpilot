
import 'package:cashpilot/features/receipt/models/receipt_data.dart' show ReceiptData;
import 'package:cashpilot/features/receipt/models/receipt_extraction_meta.dart' show ReceiptExtractionMeta;
import 'package:flutter/material.dart' show immutable;

enum ReceiptOutcomeStatus {
  success,
  partial,
  needsUserReview,
  failed,
}

@immutable
class ReceiptOutcome {
  final ReceiptData data;
  final ReceiptExtractionMeta meta;
  final ReceiptOutcomeStatus status;
  final List<String> actionHints;

  const ReceiptOutcome({
    required this.data,
    required this.meta,
    required this.status,
    this.actionHints = const [],
  });

  factory ReceiptOutcome.evaluate(
    ReceiptData data,
    ReceiptExtractionMeta meta,
  ) {
    ReceiptOutcomeStatus status;

    if (meta.globalConfidence > 0.85) {
      status = ReceiptOutcomeStatus.success;
    } else if (meta.globalConfidence > 0.6) {
      status = ReceiptOutcomeStatus.partial;
    } else if (meta.globalConfidence > 0.4) {
      status = ReceiptOutcomeStatus.needsUserReview;
    } else {
      status = ReceiptOutcomeStatus.failed;
    }

    return ReceiptOutcome(
      data: data,
      meta: meta,
      status: status,
      actionHints: _suggestActions(status),
    );
  }

  static List<String> _suggestActions(ReceiptOutcomeStatus status) {
    switch (status) {
      case ReceiptOutcomeStatus.success:
        return ['Auto-approved'];
      case ReceiptOutcomeStatus.partial:
        return ['Review totals', 'Verify date'];
      case ReceiptOutcomeStatus.needsUserReview:
        return ['Retake photo', 'Confirm merchant', 'Adjust crop'];
      case ReceiptOutcomeStatus.failed:
        return ['Retake receipt photo', 'Improve lighting', 'Avoid glare'];
    }
  }
}
