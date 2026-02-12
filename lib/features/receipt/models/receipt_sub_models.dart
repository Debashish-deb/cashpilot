import 'package:flutter/material.dart' show immutable;

@immutable
class ReceiptTaxBreakdown {
  final double rate;
  final double amount;
  final double confidence;

  const ReceiptTaxBreakdown({
    required this.rate,
    required this.amount,
    this.confidence = 0.0,
  });
}

@immutable
class ReceiptLineItem {
  final String name;
  final int quantity;
  final double unitPrice;
  final double total;
  final double confidence;

  const ReceiptLineItem({
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.total,
    this.confidence = 0.0,
  });
}

@immutable
class ReceiptPaymentMeta {
  final String method;
  final String? cardLast4;
  final double confidence;

  const ReceiptPaymentMeta({
    required this.method,
    this.cardLast4,
    this.confidence = 0.0,
  });
}
