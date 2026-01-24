/// Hash Service for Sync Conflict Detection
/// Generates consistent hashes of data entities for detecting conflicting changes
library;

import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../../data/drift/app_database.dart';

class HashService {
  /// Generate SHA-256 hash for a Budget
  /// Excludes fields that change during sync (revision, updatedAt, lastModifiedByDeviceId, syncState)
  static String generateBudgetHash(Budget budget) {
    final data = {
      'id': budget.id,
      'ownerId': budget.ownerId,
      'title': budget.title,
      'description': budget.description, // Added
      'type': budget.type,
      'startDate': budget.startDate.toIso8601String(),
      'endDate': budget.endDate.toIso8601String(),
      'currency': budget.currency,
      'totalLimit': budget.totalLimit,
      'isShared': budget.isShared,
      'isTemplate': budget.isTemplate, // Added
      'status': budget.status,
      'iconName': budget.iconName, // Added
      'colorHex': budget.colorHex, // Added
      'notes': budget.notes,
      'tags': budget.tags,
      'isDeleted': budget.isDeleted,
      // Exclude: revision, updatedAt, lastModifiedByDeviceId, syncState, globalSeq
    };
    
    return _hashMap(data);
  }

  /// Generate SHA-256 hash for an Expense
  static String generateExpenseHash(Expense expense) {
    final data = {
      'id': expense.id,
      'budgetId': expense.budgetId,
      'semiBudgetId': expense.semiBudgetId,
      'categoryId': expense.categoryId,
      'enteredBy': expense.enteredBy,
      'title': expense.title,
      'amount': expense.amount,
      'currency': expense.currency,
      'date': expense.date.toIso8601String(),
      'accountId': expense.accountId,
      'merchantName': expense.merchantName,
      'paymentMethod': expense.paymentMethod,
      'receiptUrl': expense.receiptUrl,
      'barcodeValue': expense.barcodeValue,
      'ocrText': expense.ocrText,
      'attachments': expense.attachments,
      'notes': expense.notes,
      'location_name': expense.locationName,  // FIXED: renamed from 'location'
      'tags': expense.tags,
      'isRecurring': expense.isRecurring,
      'recurringId': expense.recurringId,
      'isDeleted': expense.isDeleted,
      // Exclude: revision, updatedAt, lastModifiedByDeviceId, syncState, globalSeq, metadata
    };
    
    return _hashMap(data);
  }

  /// Generate SHA-256 hash from a map (deterministic)
  static String _hashMap(Map<String, dynamic> data) {
    // Sort keys for deterministic output
    final sortedKeys = data.keys.toList()..sort();
    final canonicalJson = sortedKeys.map((key) {
      final value = data[key];
      // Normalize nulls
      if (value == null) return '$key:null';
      return '$key:${value.toString()}';
    }).join('|');
    
    final bytes = utf8.encode(canonicalJson);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Extract stored hash from metadata field
  static String? getStoredHash(String? metadataJson) {
    if (metadataJson == null || metadataJson.isEmpty) return null;
    
    try {
      final Map<String, dynamic> metadata = json.decode(metadataJson);
      return metadata['_syncHash'] as String?;
    } catch (e) {
      return null;
    }
  }

  /// Store hash in metadata field
  static String setStoredHash(String? existingMetadataJson, String hash) {
    Map<String, dynamic> metadata;
    
    try {
      if (existingMetadataJson != null && existingMetadataJson.isNotEmpty) {
        metadata = json.decode(existingMetadataJson);
      } else {
        metadata = {};
      }
    } catch (e) {
      metadata = {};
    }
    
    metadata['_syncHash'] = hash;
    return json.encode(metadata);
  }
}
