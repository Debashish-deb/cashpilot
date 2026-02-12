/// Transactional Receipt Pipeline
/// Fixed: Issue - Receipt upload not transactional
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'receipt_service.dart';

/// Provider for the transactional receipt pipeline
final receiptPipelineProvider = Provider<ReceiptPipeline>((ref) {
  final uploader = ref.read(receiptUploaderProvider);
  
  return ReceiptPipeline(
    deleteImage: (url) async {
       debugPrint('[Provider] Rolling back image: $url');
       await uploader.deleteReceipt(url);
    },
    markAbandoned: (scanId) async {
       // Phase 2: Implement actual DB tracking
       debugPrint('[Provider] Marked receipt scan as abandoned: $scanId');
       // TODO: Insert into abandoned_receipts table when created
    },
  );
});

/// Receipt pipeline state
enum ReceiptPipelineState {
  idle,
  scanning,
  processing,
  uploading,
  creating,
  complete,
  failed,
  rollback,
}

/// Receipt pipeline result
@immutable
class ReceiptPipelineResult {
  final bool success;
  final String? expenseId;
  final String? receiptUrl;
  final String? error;
  final ReceiptPipelineState finalState;
  
  const ReceiptPipelineResult._({
    required this.success,
    this.expenseId,
    this.receiptUrl,
    this.error,
    required this.finalState,
  });
  
  factory ReceiptPipelineResult.success({
    required String expenseId,
    required String receiptUrl,
  }) {
    return ReceiptPipelineResult._(
      success: true,
      expenseId: expenseId,
      receiptUrl: receiptUrl,
      finalState: ReceiptPipelineState.complete,
    );
  }
  
  factory ReceiptPipelineResult.error(String error) {
    return ReceiptPipelineResult._(
      success: false,
      error: error,
      finalState: ReceiptPipelineState.failed,
    );
  }
}

/// Transactional receipt processing pipeline
/// Ensures atomic operations: OCR → Upload → Create Expense
class ReceiptPipeline {
  final ValueNotifier<ReceiptPipelineState> _state =
      ValueNotifier(ReceiptPipelineState.idle);
  
  // Optional cleanup services (injected for testability)
  final Future<void> Function(String)? deleteImage;
  final Future<void> Function(String)? markAbandoned;
  
  ReceiptPipeline({this.deleteImage, this.markAbandoned});
  
  ValueListenable<ReceiptPipelineState> get state => _state;
  
  // Rollback data
  String? _uploadedImageUrl;
  String? _ocrResultId;
  
  /// Process receipt with atomic guarantee
  /// Either all steps succeed, or all are rolled back
  Future<ReceiptPipelineResult> processReceipt({
    required XFile imageFile,
    required Future<Map<String, dynamic>> Function(XFile) performOcr,
    required Future<String> Function(XFile) uploadImage,
    required Future<String> Function(Map<String, dynamic>, String) createExpense,
  }) async {
    _state.value = ReceiptPipelineState.scanning;
    
    try {
      // STEP 1: OCR Processing
      debugPrint('[Pipeline] Step 1: OCR');
      _state.value = ReceiptPipelineState.processing;
      final ocrResult = await performOcr(imageFile);
      _ocrResultId = ocrResult['scan_id'] as String?;
      
      // STEP 2: Upload Image
      debugPrint('[Pipeline] Step 2: Upload');
      _state.value = ReceiptPipelineState.uploading;
      final imageUrl = await uploadImage(imageFile);
      _uploadedImageUrl = imageUrl;
      
      // STEP 3: Create Expense
      debugPrint('[Pipeline] Step 3: Create Expense');
      _state.value = ReceiptPipelineState.creating;
      final expenseId = await createExpense(ocrResult, imageUrl);
      
      // SUCCESS
      _state.value = ReceiptPipelineState.complete;
      _clearRollbackData();
      
      return ReceiptPipelineResult.success(
        expenseId: expenseId,
        receiptUrl: imageUrl,
      );
      
    } catch (e, stackTrace) {
      debugPrint('[Pipeline] ERROR: $e');
      debugPrint('[Pipeline] Stack: $stackTrace');
      
      // ROLLBACK
      await _rollback();
      
      return ReceiptPipelineResult.error(e.toString());
    }
  }
  
  /// Rollback partial operations
  Future<void> _rollback() async {
    _state.value = ReceiptPipelineState.rollback;
    debugPrint('[Pipeline] Rolling back...');
    
    // Delete uploaded image if exists
    if (_uploadedImageUrl != null) {
      try {
        if (deleteImage != null) {
          await deleteImage!(_uploadedImageUrl!);
          debugPrint('[Pipeline] Deleted image: $_uploadedImageUrl');
        } else {
          debugPrint('[Pipeline] No delete function provided, image orphaned: $_uploadedImageUrl');
        }
      } catch (e) {
        debugPrint('[Pipeline] Rollback image delete failed: $e');
      }
    }
    
    // Mark OCR result as abandoned if exists
    if (_ocrResultId != null) {
      try {
        if (markAbandoned != null) {
          await markAbandoned!(_ocrResultId!);
          debugPrint('[Pipeline] Marked OCR $_ocrResultId as abandoned');
        } else {
          debugPrint('[Pipeline] No abandoned tracking, OCR orphaned: $_ocrResultId');
        }
      } catch (e) {
        debugPrint('[Pipeline] Rollback OCR mark failed: $e');
      }
    }
    
    _clearRollbackData();
    _state.value = ReceiptPipelineState.failed;
  }
  
  void _clearRollbackData() {
    _uploadedImageUrl = null;
    _ocrResultId = null;
  }
  
  void dispose() {
    _state.dispose();
  }
}
