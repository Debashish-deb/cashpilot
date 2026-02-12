import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';
import 'dart:io' if (dart.library.html) 'dart:html'; // Dummy conditional to avoid dart:io error or just use Universal IO if available.
// Better: Abstract file writing.

// For now, let's use XFile.saveTo which is cross_file 0.3.0+.
// But honestly, for saveLocally, we only need it for native.
// So we can use `universal_io` or just conditional logic.

// BUT, if I import dart:io, it breaks web build.
// I will remove saveLocally logic for now or implement it via XFile.saveTo if possible.
// XFile.saveTo implemented in cross_file?
// cross_file: ^0.3.0 -> yes saveTo(String path).

class DeliveryChannels {
  /// Saves the file locally and returns the path. Only works on Native.
  Future<String> saveLocally(Uint8List bytes, String fileName) async {
    if (kIsWeb) {
      throw UnsupportedError('Saving files locally is not supported on Web');
    }
    
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/$fileName';
    final file = XFile.fromData(bytes, name: fileName);
    await file.saveTo(path);
    return path;
  }

  /// Shares the file using the system share sheet.
  Future<void> shareFile(Uint8List bytes, String fileName, String mimeType) async {
    await Share.shareXFiles(
      [XFile.fromData(bytes, name: fileName, mimeType: mimeType)],
    );
  }

  /// Placeholder for email delivery.
  Future<void> sendEmail(Uint8List bytes, String fileName, String email) async {
    // In a real app, you might use a mailer service or open local mail app.
  }

  /// Placeholder for accounting API push (e.g., QuickBooks).
  Future<void> pushToAccountingApi(Uint8List bytes, String fileName, String provider) async {
    // logic to upload to QuickBooks/Xero API.
  }
}
