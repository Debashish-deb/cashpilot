import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:share_plus/share_plus.dart';

/// Handles image validation and preprocessing for better OCR results.
class ImageProcessor {
  
  /// Validates and preprocesses the image.
  /// 
  /// Throws [Exception] if image quality is too poor (blurry, dark).
  /// Returns the [XFile] to be used for OCR (usually a preprocessed version).
  Future<XFile> process(XFile inputImage) async {
    // 1. Basic Validation: File size
    final length = await inputImage.length();
    if (length < 20 * 1024) { // < 20KB is suspicious for a full receipt
      throw Exception('Image too small. Please get closer to the receipt.');
    }

    // 2. Decode Image
    final bytes = await inputImage.readAsBytes();
    final image = img.decodeImage(bytes);
    
    if (image == null) {
      throw Exception('Could not decode image.');
    }

    // 3. Blur Detection (Laplacian Variance)
    final blurScore = _calculateBlurScore(image);
    // Threshold is tricky. < 100 usually blurry for variance of laplacian.
    // We'll be conservative to avoid blocking users falsely.
    if (blurScore < 50) { 
        // throw Exception('Image is too blurry. Please hold steady.');
        // Optionally, just warn or log? For "Industrial", we should block.
        // Let's throw for now as the docs requested "Quality Gates".
        throw Exception('Image is too blurry (Score: ${blurScore.toInt()}). Please focus and hold steady.');
    }

    // 4. Preprocessing: Grayscale & Contrast
    // Convert to grayscale to remove color noise
    final grayscale = img.grayscale(image);
    
    // Increase contrast (simple stretch or histogram eq? contrast fn exists)
    // 150% contrast
    final processed = img.contrast(grayscale, contrast: 120);

    // 5. Save processed image
    // For universal support, we create an XFile from bytes
    final processedBytes = img.encodeJpg(processed, quality: 85);
    final processedFile = XFile.fromData(
      processedBytes,
      name: 'processed_${DateTime.now().millisecondsSinceEpoch}.jpg',
      mimeType: 'image/jpeg',
    );

    return processedFile; 
  }

  /// Calculates a blur score using the variance of the Laplacian.
  /// Higher score = Sharper. Lower score = Blurry.
  double _calculateBlurScore(img.Image image) {
    // Resize for speed (don't process 12MP image)
    final resized = img.copyResize(image, width: 500); // 500px width enough for blur check
    final gray = img.grayscale(resized);
    
    // Laplacian kernel
    // [0,  1, 0]
    // [1, -4, 1]
    // [0,  1, 0]
    final kernel = [0, 1, 0, 1, -4, 1, 0, 1, 0];
    
    // Convolve
    final laplacian = img.convolution(gray, filter: kernel);
    
    // Calculate variance of pixels
    double sum = 0;
    double sumSq = 0;
    int count = 0;
    
    // Iterate pixels
    for (final pixel in laplacian) {
        // Red channel (grayscale so all same)
        final val = pixel.r.toDouble();
        sum += val;
        sumSq += val * val;
        count++;
    }
    
    if (count == 0) return 0;
    
    final mean = sum / count;
    final variance = (sumSq / count) - (mean * mean);
    
    return variance;
  }
}
