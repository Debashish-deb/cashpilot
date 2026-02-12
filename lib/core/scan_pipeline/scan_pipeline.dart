import 'package:cashpilot/features/receipt/models/receipt_data.dart' show ReceiptData;
import 'package:share_plus/share_plus.dart';

import '../image_processing/image_processor.dart';
import '../ocr/ocr_engine.dart';
import '../receipt_parser/receipt_parser.dart';

enum PipelineStage {
  idle,
  preprocessing,
  ocr,
  parsing,
  completed,
  failed,
}

class ScanResult {
  final ReceiptData data;
  final String rawText;
  final XFile sourceImage;

  ScanResult({
    required this.data,
    required this.rawText,
    required this.sourceImage,
  });
}

class ScanPipeline {
  final ImageProcessor _imageProcessor;
  final OcrEngine _ocrEngine;
  final ReceiptParser _parser;

  // Callback to report progress updates
  final Function(PipelineStage stage)? onStageChanged;

  ScanPipeline({
    ImageProcessor? imageProcessor,
    OcrEngine? ocrEngine,
    ReceiptParser? parser,
    this.onStageChanged,
  })  : _imageProcessor = imageProcessor ?? ImageProcessor(),
        _ocrEngine = ocrEngine ?? OcrEngine(),
        _parser = parser ?? ReceiptParser();

  /// Runs the full receipt scanning pipeline.
  Future<ScanResult> run(XFile imageFile) async {
    try {
      _reportStage(PipelineStage.preprocessing);
      final processedImage = await _imageProcessor.process(imageFile);

      _reportStage(PipelineStage.ocr);
      final rawText = await _ocrEngine.extractText(processedImage);

      _reportStage(PipelineStage.parsing);
      final data = _parser.parse(rawText);

      _reportStage(PipelineStage.completed);
      return ScanResult(
        data: data,
        rawText: rawText,
        sourceImage: processedImage,
      );
    } catch (e) {
      _reportStage(PipelineStage.failed);
      rethrow;
    }
  }

  void dispose() {
    _ocrEngine.dispose();
  }

  void _reportStage(PipelineStage stage) {
    onStageChanged?.call(stage);
  }
}
