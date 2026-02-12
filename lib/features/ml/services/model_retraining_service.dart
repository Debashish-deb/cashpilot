import 'dart:convert';
import 'package:cross_file/cross_file.dart';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/drift/app_database.dart';
import 'naive_bayes_classifier.dart';

/// Model Version Information
class ModelVersion {
  final String id;
  final String modelName;
  final String version;
  final String region;
  final String status;
  final int? trainingDataCount;
  final Map<String, dynamic>? accuracyMetrics;
  final Map<String, dynamic>? deploymentConfig;
  final DateTime? trainedAt;
  final DateTime? deployedAt;
  final DateTime createdAt;

  ModelVersion({
    required this.id,
    required this.modelName,
    required this.version,
    this.region = 'global',
    required this.status,
    this.trainingDataCount,
    this.accuracyMetrics,
    this.deploymentConfig,
    this.trainedAt,
    this.deployedAt,
    required this.createdAt,
  });

  factory ModelVersion.fromJson(Map<String, dynamic> json) {
    return ModelVersion(
      id: json['id'] as String,
      modelName: json['model_name'] as String,
      version: json['version'] as String,
      region: json['region'] as String? ?? 'global',
      status: json['status'] as String,
      trainingDataCount: json['training_data_count'] as int?,
      accuracyMetrics: json['accuracy_metrics'] as Map<String, dynamic>?,
      deploymentConfig: json['deployment_config'] as Map<String, dynamic>?,
      trainedAt: json['trained_at'] != null 
          ? DateTime.parse(json['trained_at'] as String) 
          : null,
      deployedAt: json['deployed_at'] != null
          ? DateTime.parse(json['deployed_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'model_name': modelName,
        'version': version,
        'region': region,
        'status': status,
        'training_data_count': trainingDataCount,
        'accuracy_metrics': accuracyMetrics,
        'deployment_config': deploymentConfig,
        'trained_at': trainedAt?.toIso8601String(),
        'deployed_at': deployedAt?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
      };
}

/// Model Retraining Service - Phase 3
/// Manages ML model versions, retraining, and deployment
class ModelRetrainingService {
  final _supabase = Supabase.instance.client;

  /// Get all model versions for a specific model
  Future<List<ModelVersion>> getModelVersions(String modelName) async {
    try {
      final response = await _supabase
          .from('model_versions')
          .select()
          .eq('model_name', modelName)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => ModelVersion.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('[Retraining] Failed to fetch model versions: $e');
      return [];
    }
  }

  /// Get active model version for a region
  Future<ModelVersion?> getActiveVersion({
    required String modelName,
    String region = 'global',
  }) async {
    try {
      final response = await _supabase
          .from('model_versions')
          .select()
          .eq('model_name', modelName)
          .eq('region', region)
          .eq('status', 'active')
          .order('deployed_at', ascending: false)
          .limit(1)
          .maybeSingle();

      return response != null ? ModelVersion.fromJson(response) : null;
    } catch (e) {
      debugPrint('[Retraining] Failed to get active version: $e');
      return null;
    }
  }

  /// Trigger model retraining (simplified - no actual ML training)
  /// In production, this would call a cloud function to start training
  Future<String> triggerRetraining({
    required String modelName,
    String region = 'global',
    int minDataPoints = 1000,
  }) async {
    try {
      debugPrint('[Retraining] Starting retraining for $modelName ($region)...');

      // 1. Check if enough learning data
      final dataCount = await _getlearningDataCount(modelName);
      if (dataCount < minDataPoints) {
        throw Exception(
            'Not enough data for retraining: $dataCount < $minDataPoints');
      }

      // 2. Create new model version
      final currentVersion = await getActiveVersion(
        modelName: modelName,
        region: region,
      );

      final newVersion = _incrementVersion(currentVersion?.version ?? 'v1.0');

      final response = await _supabase.from('model_versions').insert({
        'model_name': modelName,
        'version': newVersion,
        'region': region,
        'status': 'training',
        'training_data_count': dataCount,
      }).select().single();

      final versionId = response['id'] as String;

      debugPrint('[Retraining] Created new version: $newVersion (ID: $versionId)');

      // 3. In production: Trigger cloud function for actual training
      // await _startCloudTrainingJob(versionId);

      // For now: Simulate training completion after a delay
      _simulateTraining(versionId, modelName, newVersion);

      return versionId;
    } catch (e) {
      debugPrint('[Retraining] Failed to trigger retraining: $e');
      rethrow;
    }
  }

  /// Simulate training completion (remove in production)
  Future<void> _simulateTraining(
      String versionId, String modelName, String version) async {
    // Simulate training taking 5 seconds
    await Future.delayed(const Duration(seconds: 5));

    try {
      await _supabase.from('model_versions').update({
        'status': 'testing',
        'trained_at': DateTime.now().toIso8601String(),
        'accuracy_metrics': {
          'precision': 0.87 + (DateTime.now().millisecond % 10) / 100,
          'recall': 0.84 + (DateTime.now().millisecond % 10) / 100,
          'f1': 0.855,
        },
      }).eq('id', versionId);

      debugPrint('[Retraining] ✅ Training complete for $version');
    } catch (e) {
      debugPrint('[Retraining] Failed to update training status: $e');
    }
  }

  /// Deploy a model version to production
  Future<void> deployVersion(String versionId) async {
    try {
      final version = await _supabase
          .from('model_versions')
          .select()
          .eq('id', versionId)
          .single();

      if (version['status'] != 'testing') {
        throw Exception('Can only deploy models in testing status');
      }

      // Deprecated current active version
      await _supabase
          .from('model_versions')
          .update({
            'status': 'deprecated',
            'deprecated_at': DateTime.now().toIso8601String(),
          })
          .eq('model_name', version['model_name'])
          .eq('region', version['region'])
          .eq('status', 'active');

      // Deploy new version
      await _supabase.from('model_versions').update({
        'status': 'active',
        'deployed_at': DateTime.now().toIso8601String(),
      }).eq('id', versionId);

      debugPrint('[Retraining] ✅ Deployed version: ${version['version']}');
    } catch (e) {
      debugPrint('[Retraining] Failed to deploy version: $e');
      rethrow;
    }
  }

  /// Get training status
  Future<ModelVersion?> getTrainingStatus(String versionId) async {
    try {
      final response = await _supabase
          .from('model_versions')
          .select()
          .eq('id', versionId)
          .single();

      return ModelVersion.fromJson(response);
    } catch (e) {
      debugPrint('[Retraining] Failed to get training status: $e');
      return null;
    }
  }

  /// Get learning data count for model
  Future<int> _getlearningDataCount(String modelName) async {
    try {
      final tableName = modelName == 'receipt_scanner'
          ? 'receipt_learning_events'
          : 'barcode_learning_events';

      final response = await _supabase
          .from(tableName)
          .select('id')
          .count(CountOption.exact);

      return response.count;
    } catch (e) {
      debugPrint('[Retraining] Failed to get learning data count: $e');
      return 0;
    }
  }

  /// Increment version number
  String _incrementVersion(String currentVersion) {
    final match = RegExp(r'v(\d+)\.(\d+)').firstMatch(currentVersion);
    if (match != null) {
      final major = int.parse(match.group(1)!);
      final minor = int.parse(match.group(2)!);
      return 'v$major.${minor + 1}';
    }
    return 'v1.1';
  }
  // ... (existing code)

  /// Perform On-Device Retraining
  /// Trains a Naive Bayes classifier on local verified expenses and saves it to storage.
  /// Perform On-Device Retraining
  /// Trains a Naive Bayes classifier on local verified expenses and saves it to storage.
  Future<String> retrainOnDevice({
    required AppDatabase db,
    required String modelName, // e.g. 'expense_classifier'
  }) async {
    if (kIsWeb) {
      debugPrint('[Retraining] On-device training not supported on Web');
      return '';
    }

    try {
      debugPrint('[Retraining] Starting On-Device training for $modelName...');

      // 1. Fetch Verified Data
      final expenses = await (db.select(db.expenses)
        ..where((t) => t.categoryId.isNotNull())
        ..where((t) => t.isVerified.equals(true))
      ).get();

      if (expenses.length < 10) {
        throw Exception('Insufficient data for training. Need at least 10 verified expenses.');
      }

      // 2. Train Model
      final classifier = NaiveBayesClassifier();
      final samples = expenses.map((e) => (
        text: e.merchantName ?? e.title, 
        category: e.categoryId!
      )).toList();
      
      classifier.trainBatch(samples);

      // 3. Serialize & Save
      // We avoid dart:io File here to prevent web compilation issues if this code is included.
      // But we are in a block guarded by !kIsWeb. 
      // However, dart:io imports are fatal.
      // We should use XFile or a platform abstraction.
      
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final version = 'v_local_$timestamp';
      final path = '${directory.path}/ml_models/${modelName}_$version.json';
      
      // Use XFile to save? XFile.saveTo works.
      final jsonContent = jsonEncode(classifier.toJson());
      final file = XFile.fromData(utf8.encode(jsonContent), name: 'model.json');
      await file.saveTo(path);

      debugPrint('[Retraining] Model saved to $path');

      // 4. Update Version Tracking (Local-only or Sync to Supabase)
      // For now, we return the path so the orchestrator can load it.
      return path;

    } catch (e) {
      debugPrint('[Retraining] Failed on-device training: $e');
      rethrow;
    }
  }

  // ... (rest of class)
}
