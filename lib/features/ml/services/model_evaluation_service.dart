/// Model Evaluation Service - Analyzes ML model performance
/// Uses learning event data to evaluate and optimize models
library;

import 'package:supabase_flutter/supabase_flutter.dart';

/// Model performance metrics
class ModelPerformance {
  final String modelVersion;
  final int totalScans;
  final int accepted;
  final int edited;
  final int rejected;
  final double acceptanceRate;
  final double editRate;
  final double rejectionRate;
  final Map<String, int> mostCorrectedFields;
  final DateTime evaluatedAt;
  
  const ModelPerformance({
    required this.modelVersion,
    required this.totalScans,
    required this.accepted,
    required this.edited,
    required this.rejected,
    required this.acceptanceRate,
    required this.editRate,
    required this.rejectionRate,
    required this.mostCorrectedFields,
    required this.evaluatedAt,
  });
  
  /// Is model performing well?
  bool get isHealthy => acceptanceRate >= 0.70 && rejectionRate < 0.15;
  
  /// Needs immediate attention?
  bool get needsImprovement => acceptanceRate < 0.50 || rejectionRate > 0.25;
  
  Map<String, dynamic> toJson() => {
    'model_version': modelVersion,
    'total_scans': totalScans,
    'accepted': accepted,
    'edited': edited,
    'rejected': rejected,
    'acceptance_rate': acceptanceRate,
    'edit_rate': editRate,
    'rejection_rate': rejectionRate,
    'most_corrected_fields': mostCorrectedFields,
    'evaluated_at': evaluatedAt.toIso8601String(),
  };
}

/// Service for evaluating ML model performance
class ModelEvaluationService {
  final _supabase = Supabase.instance.client;
  
  /// Evaluate receipt model performance
  Future<ModelPerformance> evaluateReceiptModel(String modelVersion) async {
    try {
      // Get learning events
      final response = await _supabase
          .from('receipt_learning_events')
          .select()
          .eq('model_version', modelVersion);
      
      final events = response as List;
      
      if (events.isEmpty) {
        return ModelPerformance(
          modelVersion: modelVersion,
          totalScans: 0,
          accepted: 0,
          edited: 0,
          rejected: 0,
          acceptanceRate: 0.0,
          editRate: 0.0,
          rejectionRate: 0.0,
          mostCorrectedFields: {},
          evaluatedAt: DateTime.now(),
        );
      }
      
      final accepted = events.where((e) => e['outcome'] == 'accepted').length;
      final edited = events.where((e) => e['outcome'] == 'edited').length;
      final rejected = events.where((e) => e['outcome'] == 'rejected').length;
      final total = events.length;
      
      // Analyze most corrected fields
      final fieldCounts = <String, int>{};
      for (final event in events) {
        if (event['outcome'] == 'edited' && event['corrections'] != null) {
          final corrections = event['corrections'] as Map<String, dynamic>;
          for (final field in corrections.keys) {
            fieldCounts[field] = (fieldCounts[field] ?? 0) + 1;
          }
        }
      }
      
      return ModelPerformance(
        modelVersion: modelVersion,
        totalScans: total,
        accepted: accepted,
        edited: edited,
        rejected: rejected,
        acceptanceRate: accepted / total,
        editRate: edited / total,
        rejectionRate: rejected / total,
        mostCorrectedFields: fieldCounts,
        evaluatedAt: DateTime.now(),
      );
    } catch (e) {
      print('Failed to evaluate model: $e');
      rethrow;
    }
  }
  
  /// Compare two model versions
  Future<Map<String, dynamic>> compareModels(
    String modelA,
    String modelB,
  ) async {
    final perfA = await evaluateReceiptModel(modelA);
    final perfB = await evaluateReceiptModel(modelB);
    
    return {
      'model_a': perfA.toJson(),
      'model_b': perfB.toJson(),
      'improvements': {
        'acceptance_rate': perfB.acceptanceRate - perfA.acceptanceRate,
        'rejection_rate': perfB.rejectionRate - perfA.rejectionRate,
      },
      'winner': perfB.acceptanceRate > perfA.acceptanceRate ? modelB : modelA,
    };
  }
  
  /// Get historical performance trend
  Future<List<Map<String, dynamic>>> getPerformanceTrend(
    String modelVersion, {
    int days = 30,
  }) async {
    try {
      final cutoff = DateTime.now().subtract(Duration(days: days));
      
      final response = await _supabase
          .from('receipt_learning_events')
          .select()
          .eq('model_version', modelVersion)
          .gte('timestamp', cutoff.toIso8601String())
          .order('timestamp');
      
      final events = response as List;
      
      // Group by day
      final dailyStats = <String, Map<String, int>>{};
      
      for (final event in events) {
        final date = DateTime.parse(event['timestamp'] as String);
        final dayKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        
        dailyStats.putIfAbsent(dayKey, () => {
          'accepted': 0,
          'edited': 0,
          'rejected': 0,
        });
        
        final outcome = event['outcome'] as String;
        dailyStats[dayKey]![outcome] = (dailyStats[dayKey]![outcome] ?? 0) + 1;
      }
      
      // Convert to list
      return dailyStats.entries.map((e) {
        final total = (e.value['accepted'] ?? 0) + 
                     (e.value['edited'] ?? 0) + 
                     (e.value['rejected'] ?? 0);
        
        return {
          'date': e.key,
          'accepted': e.value['accepted'],
          'edited': e.value['edited'],
          'rejected': e.value['rejected'],
          'acceptance_rate': total > 0 ? (e.value['accepted'] ?? 0) / total : 0.0,
        };
      }).toList();
    } catch (e) {
      print('Failed to get performance trend: $e');
      return [];
    }
  }
}
