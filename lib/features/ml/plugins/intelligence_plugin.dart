import '../../../data/drift/app_database.dart';

/// Interface for Intelligence Plugins
/// Plugins can enrich, validate, or analyze expenses in the pipeline.
abstract class IntelligencePlugin {
  String get id;
  
  /// Priority of the plugin in the pipeline (Lower = Earlier)
  int get priority;

  /// Process an expense and return the modified/enriched version
  /// Or throw an exception to block the expense (e.g. security policy)
  Future<Expense> process(Expense expense, {bool isCorrection = false});

  /// Optional: Cleanup resources
  Future<void> dispose() async {}
}
