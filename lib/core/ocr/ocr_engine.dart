import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:share_plus/share_plus.dart';

/// A robust wrapper around Google MLKit Text Recognition.
/// 
/// This engine handles the details of processing an input image and returning
/// raw text. It includes basic error handling and resource management.
class OcrEngine {
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  /// Extracts text from the given [imageFile].
  /// 
  /// Returns the raw string of detected text, or throws an exception if
  /// recognition fails.
  Future<String> extractText(XFile imageFile) async {
    // WEB GUARD: ML Kit is not supported on web
    if (kIsWeb) {
      debugPrint('OCR not supported on web currently');
      return "OCR NOT SUPPORTED ON WEB";
    }

    try {
      final inputImage = InputImage.fromFilePath(imageFile.path);
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      return recognizedText.text;
    } catch (e) {
      // In a real app, we might wrap this in a custom DomainException
      throw Exception('OCR Failed: $e');
    }
  }

  /// Releases resources used by the text recognizer.
  Future<void> dispose() async {
    await _textRecognizer.close();
  }
}
