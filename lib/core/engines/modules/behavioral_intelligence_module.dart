/// Behavioral Intelligence Module
/// Detects emotional and contextual spending patterns (e.g., Stress Spending)
library;

import 'dart:math' as math;
import 'package:flutter/foundation.dart';

import '../plugin_system.dart' as plugin;
import '../models/intelligence_models.dart';
import '../../../data/drift/app_database.dart';

/// Behavioral pattern detection and analysis module
class BehavioralIntelligenceModule extends plugin.IntelligencePlugin {
  AppDatabase? _db;
  
  @override
  String get name => 'behavioral_intelligence';
  
  @override
  String get version => '1.0.0';
  
  @override
  Future<void> initialize(plugin.EngineContext context) async {
    _db = context.database as AppDatabase;
    debugPrint('[BehavioralIntelligence] Initialized');
  }
  
  @override
  Future<plugin.PluginResult> analyze(plugin.AnalysisRequest request) async {
    final userId = request.get<String>('userId');
    final scope = request.get<AnalysisScope>('scope') ?? AnalysisScope.last30Days;
    
    if (userId == null) {
      throw ArgumentError('userId is required');
    }
    
    final patterns = await _detectBehavioralPatterns(userId, scope);
    return plugin.PluginResult(data: patterns);
  }
  
  /// Detect behavioral patterns like stress spending
  Future<List<SpendingPattern>> _detectBehavioralPatterns(
    String userId,
    AnalysisScope scope,
  ) async {
    // 1. Fetch expenses in range with behavioral metadata
    // Note: We'll use a specific query if available, or fetch and filter
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    
    final expenses = await _db!.getExpensesByUserInDateRange(
      userId: userId, 
      startDate: thirtyDaysAgo, 
      endDate: now
    );

    if (expenses.isEmpty) return [];

    final behavioralPatterns = <SpendingPattern>[];

    // 2. Identify Stress Spending
    // Pattern: Mood == 'stressed' or 'anxious' AND amount > average
    final stressExpenses = expenses.where((e) => 
      e.mood != null && (e.mood!.toLowerCase().contains('stress') || e.mood!.toLowerCase().contains('anxious'))
    ).toList();

    if (stressExpenses.isNotEmpty) {
      final totalStressAmount = stressExpenses.fold<int>(0, (sum, e) => sum + e.amount);
      final avgStressAmount = totalStressAmount ~/ stressExpenses.length;
      
      behavioralPatterns.add(SpendingPattern(
        id: 'stress_spending_cluster',
        type: PatternType.stressSpending,
        merchant: null,
        frequencyCount: stressExpenses.length,
        averageAmount: avgStressAmount,
        confidence: math.min(stressExpenses.length / 5, 1.0),
        notes: 'Detected ${stressExpenses.length} transactions during periods of high stress.',
      ));
    }

    // 3. Social Context Analysis
    // Pattern: Identify if spending is higher in specific social contexts (e.g., 'friends')
    final socialGroups = <String, List<Expense>>{};
    for (final exp in expenses) {
      if (exp.socialContext != null) {
        socialGroups.putIfAbsent(exp.socialContext!, () => []).add(exp);
      }
    }

    for (final entry in socialGroups.entries) {
      if (entry.value.length >= 3) {
        final totalAmount = entry.value.fold<int>(0, (sum, e) => sum + e.amount);
        final avgAmount = totalAmount ~/ entry.value.length;
        
        // We could create a custom PatternType for social spending or use recurringMerchant if appropriate
        // For now, let's just log it if it's significant
        if (avgAmount > 5000) { // arbitrary threshold >$50
           debugPrint('[BehavioralIntelligence] Significant social spending detected: ${entry.key}');
        }
      }
    }

    return behavioralPatterns;
  }
}
