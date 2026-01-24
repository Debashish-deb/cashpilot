import 'package:cashpilot/features/sync/orchestrator/sync_orchestrator.dart' show SyncOrchestrator;
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../data/drift/app_database.dart';
import '../../../core/providers/app_providers.dart';
import '../../../features/sync/sync_providers.dart';

final savingsGoalsStreamProvider = StreamProvider<List<SavingsGoal>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.savingsGoals)
        ..where((g) => g.isDeleted.equals(false))
        ..orderBy([(g) => OrderingTerm.desc(g.createdAt)]))
      .watch();
});

final savingsGoalsControllerProvider = StateNotifierProvider<SavingsGoalsController, AsyncValue<void>>((ref) {
  return SavingsGoalsController(ref);
});

class SavingsGoalsController extends StateNotifier<AsyncValue<void>> {
  final Ref ref;
  final Uuid _uuid = const Uuid();

  SavingsGoalsController(this.ref) : super(const AsyncValue.data(null));

  AppDatabase get _db => ref.read(databaseProvider);
  SyncOrchestrator get _orchestrator => ref.read(syncOrchestratorProvider);

  Future<void> createGoal({
    required String title,
    required int targetAmount,
    required String userId,
    int currentAmount = 0,
    String? iconName,
    String? colorHex,
    DateTime? deadline,
  }) async {
    state = const AsyncValue.loading();
    try {
      final id = _uuid.v4();
      final now = DateTime.now();

      final goal = SavingsGoalsCompanion.insert(
        id: id,
        userId: userId,
        title: title,
        targetAmount: targetAmount,
        currentAmount: Value(currentAmount),
        iconName: Value(iconName),
        colorHex: Value(colorHex),
        deadline: Value(deadline),
        createdAt: Value(now),
        updatedAt: Value(now),
        revision: const Value(1),
        syncState: const Value('dirty'),
      );

      await _db.into(_db.savingsGoals).insert(goal);
      await _orchestrator.requestSync(SyncReason.manualUserAction);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateGoal({
    required String id,
    String? title,
    int? targetAmount,
    int? currentAmount,
    String? iconName,
    String? colorHex,
    DateTime? deadline,
  }) async {
    state = const AsyncValue.loading();
    try {
      final existing = await (_db.select(_db.savingsGoals)
            ..where((g) => g.id.equals(id)))
          .getSingleOrNull();
      if (existing == null) throw Exception('Goal not found');
      
      final goal = SavingsGoalsCompanion(
        id: Value(id),
        title: title != null ? Value(title) : const Value.absent(),
        targetAmount: targetAmount != null ? Value(targetAmount) : const Value.absent(),
        currentAmount: currentAmount != null ? Value(currentAmount) : const Value.absent(),
        iconName: iconName != null ? Value(iconName) : const Value.absent(),
        colorHex: colorHex != null ? Value(colorHex) : const Value.absent(),
        deadline: deadline != null ? Value(deadline) : const Value.absent(),
        updatedAt: Value(DateTime.now()),
        revision: Value(existing.revision + 1),
        syncState: const Value('dirty'),
      );

      await (_db.update(_db.savingsGoals)..where((g) => g.id.equals(id))).write(goal);
      await _orchestrator.requestSync(SyncReason.manualUserAction);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteGoal(String id) async {
    state = const AsyncValue.loading();
    try {
      await (_db.update(_db.savingsGoals)..where((g) => g.id.equals(id)))
          .write(SavingsGoalsCompanion(
        isDeleted: const Value(true),
        updatedAt: Value(DateTime.now()),
        syncState: const Value('dirty'),
      ));
      await _orchestrator.requestSync(SyncReason.manualUserAction);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
