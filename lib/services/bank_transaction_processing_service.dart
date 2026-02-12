import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:uuid/uuid.dart';

import '../core/logging/logger.dart';
import 'bank_connection_service.dart';
import '../data/drift/app_database.dart';


class BankTransactionProcessingService {
  final _logger = Loggers.sync;
  static final BankTransactionProcessingService _instance =
      BankTransactionProcessingService._internal();
  factory BankTransactionProcessingService() => _instance;
  BankTransactionProcessingService._internal();

  /// Organize and process a list of raw bank transactions
  Future<List<ProcessedTransaction>> processTransactions(
      List<BankTransaction> transactions, {String? accountType}) async {
    final processed = <ProcessedTransaction>[];

    for (final tx in transactions) {
      // GATES: Error, Format, Date Range checks
      if (!_validateTransaction(tx)) {
        continue;
      }

      // 1. Normalization
      final normalizedMerchant = _normalizeMerchantName(tx.creditorName ?? tx.description ?? 'Unknown');

      // 2. Categorization (3-Layer)
      final category = await _categorize(tx, normalizedMerchant);

      // 3. Transfer Detection
      final isTransfer = _detectTransfer(tx);

      // 4. Handle account-specific logic (e.g., Credit Card sign inversion)
      bool isIncome = tx.amount > 0;
      if (accountType == 'credit' || accountType == 'CREDIT') {
        // Many credit card APIs return spending as positive numbers.
        // We assume Nordigen standard (outflow = negative) unless explicitly inverted.
        // For now, we trust the amount sign but flag for review.
      }

      processed.add(ProcessedTransaction(
        rawTransaction: tx,
        normalizedMerchant: normalizedMerchant,
        category: category,
        isTransfer: isTransfer,
        isIncome: isIncome,
        accountType: accountType,
      ));
    }

    return processed;
  }

  bool _validateTransaction(BankTransaction tx) {
    // 1. Error Check (Null/Required fields)
    if (tx.id.isEmpty) return false;

    // 2. Format Check (Amount and Currency)
    if (tx.amount == 0) return false;
    if (tx.currency.length != 3) return false;

    // 3. Date Range Check
    final now = DateTime.now();
    final twoYearsAgo = now.subtract(const Duration(days: 365 * 2));
    
    // Future date check (allow 24h for timezone drift/buffer)
    if (tx.bookingDate.isAfter(now.add(const Duration(hours: 24)))) {
      _logger.warning('Skipping future-dated transaction: ${tx.id}');
      return false;
    }
    
    // Too old check
    if (tx.bookingDate.isBefore(twoYearsAgo)) {
      _logger.warning('Skipping stale transaction (>2y): ${tx.id}');
      return false;
    }

    return true;
  }

  String _normalizeMerchantName(String rawName) {
    if (rawName.isEmpty) return 'Unknown';
    
    // Simple cleaning rules
    var name = rawName.toUpperCase();
    name = name.replaceAll(RegExp(r'\*'), ' ');
    name = name.replaceAll(RegExp(r'\d{4,}'), ''); // Remove long digit sequences
    name = name.split(RegExp(r'\s+')).take(3).join(' '); // Take first 3 words
    
    // Common pattern mapping
    if (name.contains('AMAZON') || name.contains('AMZN')) return 'Amazon';
    if (name.contains('UBER')) return 'Uber';
    if (name.contains('NETFLIX')) return 'Netflix';
    if (name.contains('SPOTIFY')) return 'Spotify';
    if (name.contains('APPLE')) return 'Apple';
    if (name.contains('GOOGLE')) return 'Google';
    if (name.contains('STARBUCKS')) return 'Starbucks';
    if (name.contains('SHELL') || name.contains('BP ')) return 'Fuel';
    if (name.contains('TESCO') || name.contains('LIDL') || name.contains('ALDI') || name.contains('ASDA')) return 'Groceries';
    
    return name.trim();
  }

  Future<String> _categorize(BankTransaction tx, String merchant) async {
    // Layer 1: User Rules (To be implemented with dedicated DB table)
    // For now, we use a simple heuristic
    
    // Layer 2: System Rules
    if (tx.amount > 0) return 'INCOME';
    
    final m = merchant.toLowerCase();
    if (m.contains('amazon') || m.contains('groceries')) return 'SHOPPING';
    if (m.contains('uber') || m.contains('transport') || m.contains('fuel')) return 'TRANSPORT';
    if (m.contains('rent') || m.contains('mortgage')) return 'HOUSING';
    if (m.contains('netflix') || m.contains('spotify') || m.contains('apple')) return 'ENTERTAINMENT';
    if (m.contains('starbucks') || m.contains('restaurant') || m.contains('pub')) return 'DINING';
    
    // Layer 3: Fallback
    return 'UNCATEGORIZED';
  }

  bool _detectTransfer(BankTransaction tx) {
    final desc = (tx.description ?? '').toLowerCase();
    return desc.contains('transfer') || desc.contains('internal') || desc.contains('own account');
  }

  /// Persist processed transactions to the app database with deduplication
  Future<int> persistTransactions(
    AppDatabase db,
    List<ProcessedTransaction> processed, {
    required String userId,
    required String budgetId,
  }) async {
    int addedCount = 0;

    for (final pt in processed) {
      final raw = pt.rawTransaction;

      // DEDUPLICATION: Check if this bank transaction ID already exists locally
      final existing = await (db.select(db.expenses)
            ..where((t) => t.bankTransactionId.equals(raw.id)))
          .getSingleOrNull();

      if (existing != null) {
        debugPrint('Skipping duplicate bank transaction: ${raw.id}');
        continue;
      }

      // Map to Expense companion
      await db.into(db.expenses).insert(ExpensesCompanion.insert(
            id: const Uuid().v4(),
            budgetId: budgetId,
            enteredBy: userId,
            title: pt.normalizedMerchant,
            amount: (raw.amount.abs() * 100).toInt(), // Convert to cents
            currency: Value(raw.currency),
            date: raw.bookingDate,
            merchantName: Value(pt.normalizedMerchant),
            bankTransactionId: Value(raw.id),
            source: const Value('bank_sync'),
            isVerified: const Value(false), // Needs user review
            syncState: const Value('dirty'),
            createdAt: Value(DateTime.now()),
            updatedAt: Value(DateTime.now()),
          ));

      addedCount++;
    }

    return addedCount;
  }
}

class ProcessedTransaction {
  final BankTransaction rawTransaction;
  final String normalizedMerchant;
  final String category;
  final bool isTransfer;
  final bool isIncome;
  final String? accountType;

  ProcessedTransaction({
    required this.rawTransaction,
    required this.normalizedMerchant,
    required this.category,
    required this.isTransfer,
    required this.isIncome,
    this.accountType,
  });
}

final bankTransactionProcessingService = BankTransactionProcessingService();
