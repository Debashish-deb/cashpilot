/// App Core Provider - Unified Single Source of Truth
/// 
/// This is the CENTRAL HUB that connects:
/// - Database (Drift) - Data layer
/// - Financial Intelligence Engine - Analytics/ML
/// - Analytics Manager - Tracking/Insights
/// - Settings - User preferences
/// 
/// ALL systems access data through this provider to ensure SSOT.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/drift/app_database.dart';
import '../constants/app_constants.dart';
import '../engines/financial_intelligence_engine.dart';
import '../engines/models/intelligence_models.dart';
import '../managers/analytics_manager.dart';
import 'app_providers.dart';

// =============================================================================
// APP CORE - UNIFIED SINGLE SOURCE OF TRUTH
// =============================================================================

/// AppCore state - contains all connected systems
class AppCoreState {
  final bool isInitialized;
  final String? currentUserId;
  final String currency;
  final String language;
  
  const AppCoreState({
    this.isInitialized = false,
    this.currentUserId,
    this.currency = 'EUR',
    this.language = 'en',
  });
  
  AppCoreState copyWith({
    bool? isInitialized,
    String? currentUserId,
    String? currency,
    String? language,
  }) {
    return AppCoreState(
      isInitialized: isInitialized ?? this.isInitialized,
      currentUserId: currentUserId ?? this.currentUserId,
      currency: currency ?? this.currency,
      language: language ?? this.language,
    );
  }
}

/// AppCore Notifier - manages unified state
class AppCoreNotifier extends StateNotifier<AppCoreState> {
  final Ref _ref;
  
  AppCoreNotifier(this._ref) : super(const AppCoreState());
  
  // ---------------------------------------------------------------------------
  // INITIALIZATION
  // ---------------------------------------------------------------------------
  
  /// Initialize all connected systems
  Future<void> initialize() async {
    if (state.isInitialized) return;
    
    debugPrint('[AppCore] Initializing unified system...');
    
    try {
      // 1. Get current user
      final user = Supabase.instance.client.auth.currentUser;
      
      // 2. Initialize Analytics Manager
      await analyticsManager.initialize();
      
      // 3. Initialize Intelligence Engine through Analytics Manager
      final db = _ref.read(databaseProvider);
      await analyticsManager.onAppStarted(db);
      await analyticsManager.initializeIntelligenceEngine();
      
      // 4. Get current settings
      final currency = _ref.read(currencyProvider);
      final language = _ref.read(languageProvider);
      
      state = state.copyWith(
        isInitialized: true,
        currentUserId: user?.id,
        currency: currency,
        language: language.code,
      );
      
      debugPrint('[AppCore] ✅ Unified system initialized');
      debugPrint('[AppCore] User: ${user?.id ?? "anonymous"}');
      debugPrint('[AppCore] Currency: $currency, Language: ${language.code}');
    } catch (e, stack) {
      debugPrint('[AppCore] ❌ Initialization failed: $e');
      debugPrintStack(stackTrace: stack);
    }
  }
  
  // ---------------------------------------------------------------------------
  // DATA ACCESS (SSOT)
  // ---------------------------------------------------------------------------
  
  /// Get database - SINGLE SOURCE for all data
  AppDatabase get database => _ref.read(databaseProvider);
  
  /// Get Intelligence Engine - SINGLE SOURCE for analytics/ML
  FinancialIntelligenceEngine get intelligenceEngine => 
      analyticsManager.intelligenceEngine;
  
  // ---------------------------------------------------------------------------
  // ANALYTICS & INTELLIGENCE (Connected)
  // ---------------------------------------------------------------------------
  
  /// Get budget intelligence (connected to database + ML)
  Future<BudgetIntelligence> getBudgetIntelligence(String budgetId) async {
    return analyticsManager.getBudgetIntelligence(budgetId);
  }
  
  /// Get spending patterns (connected to database + ML)
  Future<SpendingIntelligence> getSpendingPatterns() async {
    if (state.currentUserId == null) {
      throw Exception('User not authenticated');
    }
    return analyticsManager.getSpendingPatterns(userId: state.currentUserId!);
  }
  
  /// Predict category for expense (ML connected to real data)
  Future<CategoryPrediction> predictCategory({
    required String title,
    String? merchant,
    int? amount,
  }) async {
    return analyticsManager.predictCategory(
      title: title,
      merchant: merchant,
      amount: amount,
    );
  }
  
  // ---------------------------------------------------------------------------
  // SETTINGS (Connected - changes propagate to all systems)
  // ---------------------------------------------------------------------------
  
  /// Update currency (propagates to all systems)
  Future<void> setCurrency(String currency) async {
    await _ref.read(currencyProvider.notifier).setCurrency(currency);
    state = state.copyWith(currency: currency);
    debugPrint('[AppCore] Currency updated: $currency');
  }
  
  /// Update language (propagates to all systems)
  Future<void> setLanguage(AppLanguage language) async {
    await _ref.read(languageProvider.notifier).setLanguage(language);
    state = state.copyWith(language: language.code);
    debugPrint('[AppCore] Language updated: ${language.code}');
  }
  
  // ---------------------------------------------------------------------------
  // USER STATE
  // ---------------------------------------------------------------------------
  
  /// Update current user
  void setCurrentUser(String? userId) {
    state = state.copyWith(currentUserId: userId);
  }
}

// =============================================================================
// PROVIDERS
// =============================================================================

/// Main AppCore provider - SINGLE SOURCE OF TRUTH for entire app
final appCoreProvider = StateNotifierProvider<AppCoreNotifier, AppCoreState>((ref) {
  return AppCoreNotifier(ref);
});

/// Convenience provider for quick access to Intelligence Engine
final unifiedIntelligenceProvider = Provider<FinancialIntelligenceEngine>((ref) {
  final core = ref.watch(appCoreProvider.notifier);
  return core.intelligenceEngine;
});

/// Convenience provider for budget intelligence with auto-refresh
final unifiedBudgetIntelligenceProvider = FutureProvider.family<BudgetIntelligence, String>((ref, budgetId) async {
  final core = ref.watch(appCoreProvider.notifier);
  return core.getBudgetIntelligence(budgetId);
});

/// Convenience provider for spending patterns
final unifiedSpendingPatternsProvider = FutureProvider<SpendingIntelligence>((ref) async {
  final core = ref.watch(appCoreProvider.notifier);
  return core.getSpendingPatterns();
});

/// Convenience provider for category prediction
final unifiedCategoryPredictionProvider = FutureProvider.family<CategoryPrediction, String>((ref, title) async {
  final core = ref.watch(appCoreProvider.notifier);
  return core.predictCategory(title: title);
});
