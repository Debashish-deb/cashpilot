import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math';

/// A/B Test configuration
class ABTest {
  final String id;
  final String testName;
  final String modelName;
  final String controlVersion;
  final String treatmentVersion;
  final double treatmentRatio;
  final String status;
  final DateTime startDate;
  final DateTime? endDate;
  final Map<String, dynamic>? results;
  final ModelStats controlStats;
  final ModelStats treatmentStats;

  ABTest({
    required this.id,
    required this.testName,
    required this.modelName,
    required this.controlVersion,
    required this.treatmentVersion,
    required this.treatmentRatio,
    required this.status,
    required this.startDate,
    this.endDate,
    this.results,
    required this.controlStats,
    required this.treatmentStats,
  });

  factory ABTest.fromJson(Map<String, dynamic> json, ModelStats control, ModelStats treatment) {
    return ABTest(
      id: json['id'] as String,
      testName: json['test_name'] as String,
      modelName: json['model_name'] as String,
      controlVersion: json['control_version'] as String,
      treatmentVersion: json['treatment_version'] as String,
      treatmentRatio: (json['treatment_ratio'] as num).toDouble(),
      status: json['status'] as String,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date'] as String) : null,
      results: json['results'] as Map<String, dynamic>?,
      controlStats: control,
      treatmentStats: treatment,
    );
  }
}

/// Model statistics for A/B testing
class ModelStats {
  final int totalScans;
  final int acceptedScans;
  final double acceptanceRate;

  ModelStats({
    required this.totalScans,
    required this.acceptedScans,
    required this.acceptanceRate,
  });
}

/// A/B Testing Service - Phase 3
/// Manages A/B tests for model comparison
class ABTestingService {
  final _supabase = Supabase.instance.client;
  static final _random = Random();

  /// Get active A/B tests
  Future<List<ABTest>> getActiveTests() async {
    try {
      final response = await _supabase
          .from('ab_test_configs')
          .select()
          .eq('status', 'active')
          .order('start_date', ascending: false);

      final tests = <ABTest>[];
      for (final json in (response as List)) {
        final control = await _getModelStats(json['model_name'], json['control_version']);
        final treatment = await _getModelStats(json['model_name'], json['treatment_version']);
        tests.add(ABTest.fromJson(json, control, treatment));
      }

      return tests;
    } catch (e) {
      debugPrint('[ABTesting] Failed to fetch active tests: $e');
      return [];
    }
  }

  /// Get completed A/B tests
  Future<List<ABTest>> getCompletedTests() async {
    try {
      final response = await _supabase
          .from('ab_test_configs')
          .select()
          .eq('status', 'completed')
          .order('end_date', ascending: false)
          .limit(10);

      final tests = <ABTest>[];
      for (final json in (response as List)) {
        final control = await _getModelStats(json['model_name'], json['control_version']);
        final treatment = await _getModelStats(json['model_name'], json['treatment_version']);
        tests.add(ABTest.fromJson(json, control, treatment));
      }

      return tests;
    } catch (e) {
      debugPrint('[ABTesting] Failed to fetch completed tests: $e');
      return [];
    }
  }

  /// Get user's assigned model version (sticky A/B testing)
  Future<String?> getUserModelVersion(String userId, String modelName) async {
    try {
      // Check active test
      final testResponse = await _supabase
          .from('ab_test_configs')
          .select()
          .eq('model_name', modelName)
          .eq('status', 'active')
          .order('start_date', ascending: false)
          .limit(1)
          .maybeSingle();

      if (testResponse == null) {
        // No active test, use production version
        return _getActiveVersion(modelName);
      }

      final test = testResponse;
      final testId = test['id'] as String;

      // Check if user already has assignment
      final assignmentResponse = await _supabase
          .from('user_model_assignments')
          .select()
          .eq('user_id', userId)
          .eq('test_id', testId)
          .maybeSingle();

      if (assignmentResponse != null) {
        return assignmentResponse['assigned_version'] as String;
      }

      // Assign user to variant
      final treatmentRatio = (test['treatment_ratio'] as num).toDouble();
      final assignToTreatment = _random.nextDouble() < treatmentRatio;
      final assignedVersion = assignToTreatment
          ? test['treatment_version'] as String
          : test['control_version'] as String;

      // Save assignment
      await _supabase.from('user_model_assignments').insert({
        'user_id': userId,
        'test_id': testId,
        'assigned_version': assignedVersion,
      });

      debugPrint('[ABTesting] Assigned user to: $assignedVersion');
      return assignedVersion;
    } catch (e) {
      debugPrint('[ABTesting] Failed to get user model version: $e');
      return _getActiveVersion(modelName);
    }
  }

  /// End an A/B test
  Future<void> endTest(String testId) async {
    try {
      // Calculate final results
      final test = await _supabase
          .from('ab_test_configs')
          .select()
          .eq('id', testId)
          .single();

      final controlStats = await _getModelStats(
        test['model_name'],
        test['control_version'],
      );
      final treatmentStats = await _getModelStats(
        test['model_name'],
        test['treatment_version'],
      );

      final improvement =
          treatmentStats.acceptanceRate - controlStats.acceptanceRate;

      await _supabase.from('ab_test_configs').update({
        'status': 'completed',
        'end_date': DateTime.now().toIso8601String(),
        'results': {
          'improvement': improvement,
          'control_acceptance': controlStats.acceptanceRate,
          'treatment_acceptance': treatmentStats.acceptanceRate,
          'winner': improvement > 0
              ? test['treatment_version']
              : test['control_version'],
        },
      }).eq('id', testId);

      debugPrint('[ABTesting] Test ended: improvement = ${(improvement * 100).toStringAsFixed(2)}%');
    } catch (e) {
      debugPrint('[ABTesting] Failed to end test: $e');
      rethrow;
    }
  }

  /// Create a new A/B Test
  Future<void> createTest({
    required String testName,
    required String modelName,
    required String controlVersion,
    required String treatmentVersion,
    required double treatmentRatio,
  }) async {
    try {
      await _supabase.from('ab_test_configs').insert({
        'test_name': testName,
        'model_name': modelName,
        'control_version': controlVersion,
        'treatment_version': treatmentVersion,
        'treatment_ratio': treatmentRatio,
        'status': 'active',
        'start_date': DateTime.now().toIso8601String(),
        'results': {},
      });
      debugPrint('[ABTesting] Created test: $testName');
    } catch (e) {
      debugPrint('[ABTesting] Failed to create test: $e');
      rethrow;
    }
  }

  /// Get active production version
  Future<String> _getActiveVersion(String modelName) async {
    final response = await _supabase
        .from('model_versions')
        .select('version')
        .eq('model_name', modelName)
        .eq('status', 'active')
        .eq('region', 'global')
        .order('deployed_at', ascending: false)
        .limit(1)
        .single();

    return response['version'] as String;
  }

  /// Get model statistics (simplified)
  Future<ModelStats> _getModelStats(String modelName, String version) async {
    try {
      // In production, fetch actual stats from learning events
      // For now, return simulated stats
      final totalScans = 500 + _random.nextInt(5000);
      final acceptedScans = (totalScans * (0.65 + _random.nextDouble() * 0.25)).round();

      return ModelStats(
        totalScans: totalScans,
        acceptedScans: acceptedScans,
        acceptanceRate: acceptedScans / totalScans,
      );
    } catch (e) {
      return ModelStats(totalScans: 0, acceptedScans: 0, acceptanceRate: 0.0);
    }
  }
}
