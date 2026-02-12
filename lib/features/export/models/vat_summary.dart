class VatSummary {
  final double netAmount;
  final double vatRate;
  final double vatAmount;
  final double grossTotal;

  VatSummary({
    required this.netAmount,
    required this.vatRate,
    required this.vatAmount,
    required this.grossTotal,
  });

  Map<String, dynamic> toJson() => {
        'netAmount': netAmount,
        'vatRate': vatRate,
        'vatAmount': vatAmount,
        'grossTotal': grossTotal,
      };
}
