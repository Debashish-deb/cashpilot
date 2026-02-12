import 'package:flutter/material.dart' show immutable;

@immutable
class ReceiptModelInfo {
  final String modelName;
  final String modelVersion;
  final DateTime trainedAt;
  final double validationAccuracy;
  final Map<String, double> perFieldAccuracy;
  final List<String> supportedLanguages;
  final bool supportsOffline;

  const ReceiptModelInfo({
    required this.modelName,
    required this.modelVersion,
    required this.trainedAt,
    required this.validationAccuracy,
    this.perFieldAccuracy = const {},
    this.supportedLanguages = const ['en'],
    this.supportsOffline = true,
  });

  bool get isProductionSafe => validationAccuracy > 0.9;
}
