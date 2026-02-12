import 'package:flutter/foundation.dart';
import '../../../data/drift/app_database.dart';
import 'intelligence_plugin.dart';

/// Registry for managing Intelligence Plugins
class IntelligenceRegistry {
  final List<IntelligencePlugin> _plugins = [];

  /// Register a new plugin
  void register(IntelligencePlugin plugin) {
    _plugins.add(plugin);
    _plugins.sort((a, b) => a.priority.compareTo(b.priority));
    debugPrint('[IntelligenceRegistry] Registered plugin: ${plugin.id} (Priority: ${plugin.priority})');
  }

  /// Unregister a plugin
  void unregister(String pluginId) {
    _plugins.removeWhere((p) => p.id == pluginId);
  }

  /// Execute the pipeline on an expense
  Future<Expense> runPipeline(Expense expense, {bool isCorrection = false}) async {
    var current = expense;
    
    for (final plugin in _plugins) {
      try {
        current = await plugin.process(current, isCorrection: isCorrection);
      } catch (e) {
        debugPrint('[IntelligenceRegistry] Plugin ${plugin.id} failed: $e');
        // We decide whether to abort or continue. For now, we continue with original.
        // In strict mode, we might rethrow.
      }
    }
    
    return current;
  }
}
