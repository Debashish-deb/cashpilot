import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';

import 'package:cashpilot/data/drift/app_database.dart';

class ExportService {
  final AppDatabase db;

  ExportService(this.db);

  // ===========================================================================
  // FULL BACKUP (JSON)
  // ===========================================================================

  /// Creates a full, portable JSON backup of all critical user data
  /// and triggers OS-level sharing.
  Future<void> createFullBackup() async {
    try {
      final now = DateTime.now().toUtc();

      final expenses = await db.select(db.expenses).get();
      final budgets = await db.select(db.budgets).get();
      final accounts = await db.select(db.accounts).get();
      final semiBudgets = await db.select(db.semiBudgets).get();
      final recurring = await db.select(db.recurringExpenses).get();
      final goals = await db.select(db.savingsGoals).get();
      final categories = await db.select(db.categories).get();

      final backupPayload = {
        'meta': {
          'app': 'CashPilot',
          'backup_version': 1,
          'created_at': now.toIso8601String(),
          'timezone': 'UTC',
        },
        'data': {
          'expenses': expenses.map((e) => e.toJson()).toList(),
          'budgets': budgets.map((b) => b.toJson()).toList(),
          'accounts': accounts.map((a) => a.toJson()).toList(),
          'semi_budgets': semiBudgets.map((sb) => sb.toJson()).toList(),
          'recurring_expenses': recurring.map((r) => r.toJson()).toList(),
          'savings_goals': goals.map((g) => g.toJson()).toList(),
          'categories': categories.map((c) => c.toJson()).toList(),
        },
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(backupPayload);
      final fileName = _timestampedFileName('cashpilot_backup', 'json');
      
      final xFile = XFile.fromData(
        utf8.encode(jsonString),
        name: fileName,
        mimeType: 'application/json',
      );

      await Share.shareXFiles(
        [xFile],
        subject: 'CashPilot Backup',
        text: 'CashPilot full backup created on ${now.toLocal()}',
      );
    } catch (e, stack) {
      debugPrint('❌ Full backup failed: $e');
      debugPrintStack(stackTrace: stack);
      rethrow;
    }
  }

  // ===========================================================================
  // EXPENSE EXPORT (CSV)
  // ===========================================================================

  /// Exports expenses into a spreadsheet-friendly CSV file.
  Future<void> exportExpensesToCsv() async {
    try {
      final expenses = await (db.select(db.expenses)
            ..orderBy([(t) => OrderingTerm.desc(t.date)]))
          .get();

      final rows = <List<dynamic>>[];

      // CSV Header
      rows.add([
        'Date',
        'Title',
        'Amount',
        'Category ID',
        'Account ID',
        'Note',
        'Payment Method',
        'Recurring',
      ]);

      for (final e in expenses) {
        rows.add([
          _formatDate(e.date),
          e.title,
          _formatAmount(e.amount),
          e.categoryId ?? '',
          e.accountId ?? '',
          e.notes ?? '',
          e.paymentMethod,
          e.isRecurring ? 'Yes' : 'No',
        ]);
      }

      final csvData = const ListToCsvConverter().convert(rows);
      final fileName = _timestampedFileName('cashpilot_expenses', 'csv');

      final xFile = XFile.fromData(
        utf8.encode(csvData),
        name: fileName,
        mimeType: 'text/csv',
      );

      await Share.shareXFiles(
        [xFile],
        subject: 'CashPilot Expense Report',
        text: 'CashPilot expense report (CSV)',
      );
    } catch (e, stack) {
      debugPrint('❌ CSV export failed: $e');
      debugPrintStack(stackTrace: stack);
      rethrow;
    }
  }

  // ===========================================================================
  // HELPERS
  // ===========================================================================

  String _timestampedFileName(String base, String ext) {
    final ts = DateTime.now().millisecondsSinceEpoch;
    return '${base}_$ts.$ext';
  }

  String _formatDate(DateTime date) {
    return date.toIso8601String().split('T').first;
  }

  String _formatAmount(int cents) {
    return (cents / 100).toStringAsFixed(2);
  }
}
