/// Receipt Learning Service - Captures user corrections for ML improvement
/// Tracks how users edit OCR results to improve future extractions
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/receipt_outcome.dart';
import '../models/receipt_model_info.dart';

/// Provider for receipt learning service
final receiptLearningServiceProvider = Provider<ReceiptLearningService>((ref) {
  return ReceiptLearningService();
});

/// Service for tracking and learning from receipt corrections
class ReceiptLearningService {
  final _supabase = Supabase.instance.client;
  
  /// Record when user accepts a receipt scan without changes
  Future<void> recordAcceptance({
    required String receiptId,
    required String modelVersion,
  }) async {
    final event = ReceiptCorrectionEvent(
      receiptId: receiptId,
      outcome: ReceiptOutcome.accepted,
      corrections: {},
      timestamp: DateTime.now(),
      modelVersion: modelVersion,
    );
    
    await _persistEvent(event);
  }
  
  /// Record when user edits receipt fields
  Future<void> recordCorrection({
    required String receiptId,
    required Map<String, ReceiptFieldCorrection> corrections,
    String? modelVersion,
  }) async {
    final event = ReceiptCorrectionEvent(
      receiptId: receiptId,
      outcome: ReceiptOutcome.edited,
      corrections: corrections,
      timestamp: DateTime.now(),
      modelVersion: modelVersion ?? ReceiptModelInfo.currentVersion,
    );
    
    await _persistEvent(event);
  }
  
  /// Record when user rejects/discards a scan
  Future<void> recordRejection({
    required String receiptId,
    required String modelVersion,
  }) async {
    final event = ReceiptCorrectionEvent(
      receiptId: receiptId,
      outcome: ReceiptOutcome.rejected,
      corrections: {},
      timestamp: DateTime.now(),
      modelVersion: modelVersion,
    );
    
    await _persistEvent(event);
  }
  
  /// Persist learning event to Supabase
  Future<void> _persistEvent(ReceiptCorrectionEvent event) async {
    try {
      // Store in a dedicated learning_events table
      await _supabase.from('receipt_learning_events').insert({
        'receipt_id': event.receiptId,
        'outcome': event.outcome.toJson(),
        'corrections': event.corrections.map((k, v) => MapEntry(k, v.toJson())),
        'timestamp': event.timestamp.toIso8601String(),
        'model_version': event.modelVersion,
        'user_id': _supabase.auth.currentUser?.id,
      });
    } catch (e) {
      // Don't block user flow if learning fails
      print('Failed to persist receipt learning event: $e');
    }
  }
  
  /// Get learning statistics for a model version
  Future<Map<String, dynamic>> getModelStats(String modelVersion) async {
    try {
      final response = await _supabase
          .from('receipt_learning_events')
          .select()
          .eq('model_version', modelVersion);
      
      final events = (response as List).map((e) => 
        ReceiptCorrectionEvent.fromJson(e as Map<String, dynamic>)
      ).toList();
      
      final accepted = events.where((e) => e.outcome == ReceiptOutcome.accepted).length;
      final edited = events.where((e) => e.outcome == ReceiptOutcome.edited).length;
      final rejected = events.where((e) => e.outcome == ReceiptOutcome.rejected).length;
      
      return {
        'total_scans': events.length,
        'accepted': accepted,
        'edited': edited,
        'rejected': rejected,
        'acceptance_rate': events.isEmpty ? 0.0 : accepted / events.length,
      };
    } catch (e) {
      print('Failed to get model stats: $e');
      return {};
    }
  }
  
  /// Get most commonly corrected fields (for model improvement)
  Future<List<String>> getMostCorrectedFields(String modelVersion) async {
    try {
      final response = await _supabase
          .from('receipt_learning_events')
          .select()
          .eq('model_version', modelVersion)
          .eq('outcome', 'edited');
      
      final fieldCounts = <String, int>{};
      
      for (final item in response as List) {
        final event = ReceiptCorrectionEvent.fromJson(item as Map<String, dynamic>);
        for (final fieldName in event.corrections.keys) {
          fieldCounts[fieldName] = (fieldCounts[fieldName] ?? 0) + 1;
        }
      }
      
      // Sort by count descending
      final sorted = fieldCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      return sorted.map((e) => e.key).toList();
    } catch (e) {
      print('Failed to get corrected fields: $e');
      return [];
    }
  }
}
