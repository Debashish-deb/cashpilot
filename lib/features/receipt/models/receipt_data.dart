import 'package:flutter/foundation.dart';

/// A data class representing parsed receipt data.
@immutable
class ReceiptData {
  final double? total;
  final double? subtotal;
  final double? tax;
  final DateTime? date;
  final String? merchantName;
  final String? currencyCode;

  const ReceiptData({
    this.total,
    this.subtotal,
    this.tax,
    this.date,
    this.merchantName,
    this.currencyCode,
  });

  @override
  String toString() => 'ReceiptData(total: $total, subtotal: $subtotal, tax: $tax, date: $date, merchant: $merchantName, currency: $currencyCode)';

  ReceiptData copyWith({
    double? total,
    double? subtotal,
    double? tax,
    DateTime? date,
    String? merchantName,
    String? currencyCode,
  }) {
    return ReceiptData(
      total: total ?? this.total,
      subtotal: subtotal ?? this.subtotal,
      tax: tax ?? this.tax,
      date: date ?? this.date,
      merchantName: merchantName ?? this.merchantName,
      currencyCode: currencyCode ?? this.currencyCode,
    );
  }
}
