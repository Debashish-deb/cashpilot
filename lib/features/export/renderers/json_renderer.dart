import 'dart:convert';
import 'dart:typed_data';
import '../models/export_bundle.dart';
import 'i_renderer.dart';

class JsonRenderer implements IRenderer {
  @override
  String get extension => 'json';

  @override
  String get mimeType => 'application/json';

  @override
  Future<Uint8List> render(ExportBundle bundle) async {
    final jsonString = jsonEncode(bundle.toJson());
    return Uint8List.fromList(utf8.encode(jsonString));
  }
}
