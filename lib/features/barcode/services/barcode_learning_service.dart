/// Barcode Learning Service - Captures user corrections for ML improvement
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/scan_outcome.dart';
import '../models/scan_metadata.dart';
import '../models/barcode_scan_result.dart';

/// Provider for barcode learning service
final barcodeLearningServiceProvider = Provider<BarcodeLearningService>((ref) {
  return BarcodeLearningService();
});

/// Service for tracking and learning from barcode scan corrections
class BarcodeLearningService {
  final _supabase = Supabase.instance.client;
  
  /// Record when user accepts a barcode scan without changes
  Future<void> recordAcceptance({
    required String barcode,
    required double confidence,
    String? modelVersion,
  }) async {
    final event = ScanLearningEvent(
      barcode: barcode,
      confidence: confidence,
      outcome: ScanOutcome.accepted,
      timestamp: DateTime.now(),
      modelVersion: modelVersion ?? BarcodeModelInfo.currentVersion,
    );
    
    await _persistEvent(event);
  }
  
  /// Record when user corrects product information
  Future<void> recordCorrection({
    required String barcode,
    required double confidence,
    required ProductInfo correctedProduct,
    String? modelVersion,
  }) async {
    final event = ScanLearningEvent(
      barcode: barcode,
      confidence: confidence,
      outcome: ScanOutcome.corrected,
      correctedProduct: correctedProduct,
      timestamp: DateTime.now(),
      modelVersion: modelVersion ?? BarcodeModelInfo.currentVersion,
    );
    
    await _persistEvent(event);
  }
  
  /// Record when user rejects/rescans
  Future<void> recordRejection({
    required String barcode,
    required double confidence,
    String? modelVersion,
  }) async {
    final event = ScanLearningEvent(
      barcode: barcode,
      confidence: confidence,
      outcome: ScanOutcome.rejected,
      timestamp: DateTime.now(),
      modelVersion: modelVersion ?? BarcodeModelInfo.currentVersion,
    );
    
    await _persistEvent(event);
  }
  
  /// Persist learning event to Supabase
  Future<void> _persistEvent(ScanLearningEvent event) async {
    try {
      await _supabase.from('barcode_learning_events').insert({
        'barcode': event.barcode,
        'confidence': event.confidence,
        'outcome': event.outcome.toJson(),
        'corrected_product': event.correctedProduct?.toJson(),
        'timestamp': event.timestamp.toIso8601String(),
        'model_version': event.modelVersion,
        'user_id': _supabase.auth.currentUser?.id,
      });
    } catch (e) {
      // Don't block user flow if learning fails
      print('Failed to persist barcode learning event: $e');
    }
  }
  
  /// Get acceptance rate for a barcode
  Future<double> getBarcodeAcceptanceRate(String barcode) async {
    try {
      final response = await _supabase
          .from('barcode_learning_events')
          .select()
          .eq('barcode', barcode);
      
      if ((response as List).isEmpty) return 0.0;
      
      final accepted = response.where((e) => e['outcome'] == 'accepted').length;
      return accepted / response.length;
    } catch (e) {
      print('Failed to get barcode acceptance rate: $e');
      return 0.0;
    }
  }
  
  /// Get model statistics
  Future<Map<String, dynamic>> getModelStats(String modelVersion) async {
    try {
      final response = await _supabase
          .from('barcode_learning_events')
          .select()
          .eq('model_version', modelVersion);
      
      final events = (response as List).map((e) => 
        ScanLearningEvent.fromJson(e as Map<String, dynamic>)
      ).toList();
      
      final accepted = events.where((e) => e.outcome == ScanOutcome.accepted).length;
      final corrected = events.where((e) => e.outcome == ScanOutcome.corrected).length;
      final rejected = events.where((e) => e.outcome == ScanOutcome.rejected).length;
      
      return {
        'total_scans': events.length,
        'accepted': accepted,
        'corrected': corrected,
        'rejected': rejected,
        'acceptance_rate': events.isEmpty ? 0.0 : accepted / events.length,
      };
    } catch (e) {
      print('Failed to get model stats: $e');
      return {};
    }
  }
}
