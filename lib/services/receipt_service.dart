import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:mime/mime.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/utils/validators.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

final receiptUploaderProvider = Provider<ReceiptUploader>(
  (ref) => ReceiptUploader(),
);

class ReceiptUploader {
  ReceiptUploader();

  SupabaseClient get _supabase => Supabase.instance.client;
  static const _uuid = Uuid();

  static const String _bucketName = 'receipts';
  static const int _maxFileSizeBytes = 10 * 1024 * 1024; // 10 MB hard limit

  /// Uploads a receipt image to Supabase Storage
  ///
  /// Returns a public URL of the uploaded file.
  /// Throws a controlled [Exception] if upload fails.
  Future<String> uploadReceipt({
    required File file,
    required String expenseId,
    required String budgetId,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    if (!file.existsSync()) {
      throw Exception('Receipt file not found');
    }

    final fileSize = await file.length();
    if (fileSize <= 0) {
      throw Exception('Receipt file is empty');
    }

    if (fileSize > _maxFileSizeBytes) {
      throw Exception('Receipt file is too large (max 10 MB)');
    }

    // Validate MIME type (security)
    final mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';
    if (!Validators.isValidReceiptMimeType(mimeType)) {
      throw Exception(
        'Invalid file type. Allowed: ${Validators.getAllowedReceiptExtensions().join(", ")}',
      );
    }

    final userId = user.id;
    final fileExtension = _safeFileExtension(file.path);
    final contentType = _contentTypeForExtension(fileExtension);
    final uniqueId = _uuid.v4();

    // Stable, debuggable, collision-safe path
    final storagePath =
        'receipts/$userId/$budgetId/$expenseId-$uniqueId.$fileExtension';

    final metadata = <String, String>{
      'user_id': userId,
      'expense_id': expenseId,
      'budget_id': budgetId,
      'uploaded_at': DateTime.now().toUtc().toIso8601String(),
      'platform': defaultTargetPlatform.name,
      'source': 'mobile_app',
    };

    try {
      final bytes = await file.readAsBytes();

      final storage = _supabase.storage.from(_bucketName);

      await storage.uploadBinary(
        storagePath,
        bytes,
        fileOptions: FileOptions(
          cacheControl: '3600',
          upsert: false,
          contentType: contentType,
        ),
      );

      final publicUrl = storage.getPublicUrl(storagePath);

      if (publicUrl.isEmpty) {
        throw Exception('Failed to generate public URL');
      }

      return publicUrl;
    } on StorageException catch (e, stack) {
      debugPrint('StorageException: ${e.message}\n$stack');
      throw Exception('Receipt upload failed (storage error)');
    } on FileSystemException catch (e) {
      throw Exception('Receipt file access error: ${e.message}');
    } catch (e, stack) {
      debugPrint('Receipt upload error: $e\n$stack');
      throw Exception('Receipt upload failed');
    }
  }

  /// Deletes a receipt image from Supabase Storage
  ///
  /// [publicUrl] is the full public URL of the image.
  /// Throws a controlled [Exception] if deletion fails.
  Future<void> deleteReceipt(String publicUrl) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Extract path from public URL
      // Format: .../storage/v1/object/public/receipts/path/to/file.jpg
      final uri = Uri.parse(publicUrl);
      final pathSegments = uri.pathSegments;
      
      // Find 'receipts' index and take everything after it
      final bucketIndex = pathSegments.indexOf(_bucketName);
      if (bucketIndex == -1 || bucketIndex + 1 >= pathSegments.length) {
         throw Exception('Invalid receipt URL format');
      }

      final storagePath = pathSegments.sublist(bucketIndex + 1).join('/');

      await _supabase.storage.from(_bucketName).remove([storagePath]);
      debugPrint('[ReceiptUploader] Deleted receipt: $storagePath');

    } on StorageException catch (e, stack) {
      debugPrint('StorageException (delete): ${e.message}\n$stack');
      throw Exception('Receipt deletion failed (storage error)');
    } catch (e, stack) {
      debugPrint('Receipt delete error: $e\n$stack');
      throw Exception('Receipt deletion failed');
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String _safeFileExtension(String path) {
    final parts = path.split('.');
    if (parts.length < 2) return 'jpg';

    final ext = parts.last.toLowerCase();

    // Allowlist extensions (security best practice)
    switch (ext) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'webp':
      case 'heic':
        return ext;
      default:
        return 'jpg';
    }
  }

  String _contentTypeForExtension(String ext) {
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'heic':
        return 'image/heic';
      case 'jpg':
      case 'jpeg':
      default:
        return 'image/jpeg';
    }
  }
}
