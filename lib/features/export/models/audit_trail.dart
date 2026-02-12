class AuditTrail {
  final List<String> actions;
  final DateTime generatedAt;
  final String generatedBy;
  final String exportFormat;

  AuditTrail({
    required this.actions,
    required this.generatedAt,
    required this.generatedBy,
    required this.exportFormat,
  });

  Map<String, dynamic> toJson() => {
        'actions': actions,
        'generatedAt': generatedAt.toIso8601String(),
        'generatedBy': generatedBy,
        'exportFormat': exportFormat,
      };
}
