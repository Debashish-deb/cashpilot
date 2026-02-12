import 'package:cashpilot/data/repositories/expense_repository_impl.dart' show ExpenseRepositoryImpl;
import 'package:cashpilot/domain/repositories/i_expense_repository.dart' show IExpenseRepository;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';

final expenseRepositoryProvider = Provider<IExpenseRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return ExpenseRepositoryImpl(db);
});
