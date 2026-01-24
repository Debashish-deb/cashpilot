import '../use_case.dart';
import '../../../data/drift/app_database.dart';
import 'package:drift/drift.dart';

/// Parameters for creating a budget
class CreateBudgetParams {
  final String ownerId;
  final String title;
  final int totalLimit;
  final String type; // 'monthly', 'weekly', etc.
  final DateTime startDate;
  final DateTime? endDate;
  final String currency;

  CreateBudgetParams({
    required this.ownerId,
    required this.title,
    required this.totalLimit,
    required this.type,
    required this.startDate,
    this.endDate,
    this.currency = 'USD',
  });
}

/// Use case for creating a budget
/// 
/// Business logic:
/// - Generates UUID
/// - Validates dates (start before end)
/// - Sets default end date if not provided
/// - Marks as dirty for sync
class CreateBudgetUseCase extends UseCase<String, CreateBudgetParams> {
  final AppDatabase _db;

  CreateBudgetUseCase(this._db);

  @override
  Future<String> execute(CreateBudgetParams params) async {
    // Business Logic: Validate dates
    if (params.endDate != null && params.endDate!.isBefore(params.startDate)) {
      throw Exception('End date must be after start date');
    }

    // Business Logic: Default end date (30 days)
    final endDate = params.endDate ?? params.startDate.add(const Duration(days: 30));

    final budgetId = _generateBudgetId();

    await _db.into(_db.budgets).insert(
      BudgetsCompanion.insert(
        id: budgetId,
        ownerId: params.ownerId,
        title: params.title,
        totalLimit: Value(params.totalLimit),
        type: params.type,
        currency: Value(params.currency),
        startDate: params.startDate,
        endDate: endDate,
        syncState: const Value('dirty'),
        revision: const Value(1),
      ),
    );

    return budgetId;
  }

  String _generateBudgetId() {
    return 'budget_${DateTime.now().millisecondsSinceEpoch}_${_randomString(6)}';
  }

  String _randomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return String.fromCharCodes(
      Iterable.generate(
        length,
        (_) => chars.codeUnitAt((DateTime.now().microsecond * 17) % chars.length),
      ),
    );
  }
}
