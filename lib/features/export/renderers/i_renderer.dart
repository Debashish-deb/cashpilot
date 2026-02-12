import 'dart:typed_data';
import '../models/export_bundle.dart';

abstract class IRenderer {
  /// Renders the [ExportBundle] into a specific format as bytes.
  Future<Uint8List> render(ExportBundle bundle);
  
  /// The file extension for this format (e.g., 'csv', 'pdf').
  String get extension;
  
  /// The mime type for this format.
  String get mimeType;
}
