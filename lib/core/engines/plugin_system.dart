/// Plugin System for Financial Intelligence Engine
/// Extensible architecture for adding new intelligence modules
library;

import 'dart:async';

/// Base class for all intelligence plugins
abstract class IntelligencePlugin {
  /// Plugin unique identifier
  String get name;
  
  /// Plugin version
  String get version;
  
  /// Plugin dependencies (other plugin names)
  List<String> get dependencies => [];
  
  /// Initialize plugin with engine context
  Future<void> initialize(EngineContext context);
  
  /// Contribute intelligence
  Future<PluginResult> analyze(AnalysisRequest request);
  
  /// Health check
  Future<bool> isHealthy() async => true;
  
  /// Cleanup resources
  Future<void> dispose() async {}
}

/// Engine context provided to plugins
class EngineContext {
  final dynamic database; // AppDatabase instance
  final dynamic supabase; // SupabaseClient instance
  final Map<String, dynamic> config;
  
  EngineContext({
    required this.database,
    required this.supabase,
    this.config = const {},
  });
}

/// Analysis request for plugins
class AnalysisRequest {
  final Map<String, dynamic> params;
  
  AnalysisRequest(this.params);
  
  T? get<T>(String key) => params[key] as T?;
  T getOrDefault<T>(String key, T defaultValue) => params[key] as T? ?? defaultValue;
}

/// Plugin analysis result
class PluginResult {
  final dynamic data;
  final Map<String, dynamic> metadata;
  
  PluginResult({
    required this.data,
    this.metadata = const {},
  });
}

/// Plugin registry and manager
class PluginSystem {
  final _plugins = <String, IntelligencePlugin>{};
  final _initialized = <String>{}; 
  
  /// Register a plugin
  void register(IntelligencePlugin plugin) {
    if (_plugins.containsKey(plugin.name)) {
      throw StateError('Plugin ${plugin.name} already registered');
    }
    
    _plugins[plugin.name] = plugin;
  }
  
  /// Initialize all plugins
  Future<void> initializeAll(EngineContext context) async {
    // Resolve dependencies and initialize in order
    final ordered = _resolveDependencies();
    
    for (final pluginName in ordered) {
      final plugin = _plugins[pluginName]!;
      await plugin.initialize(context);
      _initialized.add(pluginName);
    }
  }
  
  /// Query a specific plugin
  Future<T> query<T>({
    required String pluginName,
    required Map<String, dynamic> params,
  }) async {
    final plugin = _plugins[pluginName];
    if (plugin == null) {
      throw StateError('Plugin $pluginName not found');
    }
    
    if (!_initialized.contains(pluginName)) {
      throw StateError('Plugin $pluginName not initialized');
    }
    
    final result = await plugin.analyze(AnalysisRequest(params));
    return result.data as T;
  }
  
  /// Check health of all plugins
  Future<Map<String, bool>> checkHealth() async {
    final health = <String, bool>{};
    
    for (final entry in _plugins.entries) {
      health[entry.key] = await entry.value.isHealthy();
    }
    
    return health;
  }
  
  /// Dispose all plugins
  Future<void> disposeAll() async {
    for (final plugin in _plugins.values) {
      await plugin.dispose();
    }
    
    _plugins.clear();
    _initialized.clear();
  }
  
  /// Resolve plugin dependencies (topological sort)
  List<String> _resolveDependencies() {
    final result = <String>[];
    final visited = <String>{};
    final visiting = <String>{};
    
    void visit(String name) {
      if (visited.contains(name)) return;
      
      if (visiting.contains(name)) {
        throw StateError('Circular dependency detected: $name');
      }
      
      visiting.add(name);
      
      final plugin = _plugins[name];
      if (plugin != null) {
        for (final dep in plugin.dependencies) {
          if (!_plugins.containsKey(dep)) {
            throw StateError('Missing dependency: $dep for plugin $name');
          }
          visit(dep);
        }
      }
      
      visiting.remove(name);
      visited.add(name);
      result.add(name);
    }
    
    for (final name in _plugins.keys) {
      visit(name);
    }
    
    return result;
  }
  
  /// Get list of registered plugins
  List<String> get registeredPlugins => _plugins.keys.toList();
  
  /// Get list of initialized plugins
  List<String> get initializedPlugins => _initialized.toList();
}
