import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter/foundation.dart';
import '../../../domain/entities/net_worth/asset.dart';
import '../../../domain/entities/net_worth/liability.dart';
import '../../../domain/repositories/net_worth/net_worth_repository.dart';
import '../../../data/repositories/net_worth/net_worth_repository_impl.dart';
import '../../../domain/entities/net_worth/net_worth_models.dart';
import '../../../core/providers/app_providers.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/services/forecasting_service.dart';

part 'net_worth_providers.g.dart';

// REPOSITORY PROVIDER
@Riverpod(keepAlive: true)
NetWorthRepository netWorthRepository(NetWorthRepositoryRef ref) {
  final db = ref.watch(databaseProvider);
  return NetWorthRepositoryImpl(db);
}

// ASSETS STREAM
@riverpod
Stream<List<Asset>> assetsStream(AssetsStreamRef ref) {
  final repo = ref.watch(netWorthRepositoryProvider);
  final user = ref.watch(currentUserProvider);
  if (user == null) return const Stream.empty();
  return repo.watchAssets(user.id);
}

// LIABILITIES STREAM
@riverpod
Stream<List<Liability>> liabilitiesStream(LiabilitiesStreamRef ref) {
  final repo = ref.watch(netWorthRepositoryProvider);
  final user = ref.watch(currentUserProvider);
  if (user == null) return const Stream.empty();
  return repo.watchLiabilities(user.id);
}

// LIVE NET WORTH STREAM
@riverpod
Stream<int> liveNetWorth(LiveNetWorthRef ref) {
  final repo = ref.watch(netWorthRepositoryProvider);
  final user = ref.watch(currentUserProvider);
  if (user == null) return const Stream.empty();
  return repo.watchNetWorth(user.id);
}

// NET WORTH HISTORY (For Graphing)
@riverpod
Future<List<NetWorthHistoryPoint>> netWorthHistory(NetWorthHistoryRef ref, {int days = 30}) async {
  final repo = ref.watch(netWorthRepositoryProvider);
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  
  final raw = await repo.getNetWorthHistory(user.id, days: days);
  return raw.map((m) => NetWorthHistoryPoint(
    date: DateTime.parse(m['date']),
    valueCents: m['value'] as int,
  )).toList();
}

// SUMMARY PROVIDER (For UI Cards)
@riverpod
Stream<NetWorthSummaryData> netWorthSummary(NetWorthSummaryRef ref) {
  final assetsAsync = ref.watch(assetsStreamProvider);
  final liabilitiesAsync = ref.watch(liabilitiesStreamProvider);
  
  if (assetsAsync.isLoading || liabilitiesAsync.isLoading) {
    return const Stream.empty();
  }
  
  final assets = assetsAsync.valueOrNull ?? [];
  final liabilities = liabilitiesAsync.valueOrNull ?? [];
  
  int totalAssets = assets.fold(0, (sum, item) => sum + item.currentValue);
  int totalLiabilities = liabilities.fold(0, (sum, item) => sum + item.currentBalance);
  int netWorth = totalAssets - totalLiabilities;
  
  return Stream.value(NetWorthSummaryData(
    totalAssets: totalAssets,
    totalLiabilities: totalLiabilities,
    netWorth: netWorth,
  ));
}

// NetWorthSummaryData is now moved to net_worth_models.dart

// FORECASTING SERVICE PROVIDER
@Riverpod(keepAlive: true)
ForecastingService forecastingService(ForecastingServiceRef ref) {
  return ForecastingService();
}

// NET WORTH FORECAST (e.g., 1 Year Projection)
@riverpod
Future<double> netWorthForecast(NetWorthForecastRef ref, {required DateTime targetDate}) async {
  final history = await ref.watch(netWorthHistoryProvider(days: 90).future);
  if (history.isEmpty) return 0.0;
  
  final service = ref.watch(forecastingServiceProvider);
  final points = history.map((h) => ValuationPoint(
    h.date,
    h.valueCents,
  )).toList();
  
  return service.predictNetWorth(points, targetDate);
}

// DAYS TO GOAL
@riverpod
Future<int> daysToNetWorthGoal(DaysToNetWorthGoalRef ref, {required double goal}) async {
  final history = await ref.watch(netWorthHistoryProvider(days: 90).future);
  if (history.isEmpty) return -1;
  
  final service = ref.watch(forecastingServiceProvider);
  final points = history.map((h) => ValuationPoint(
    h.date,
    h.valueCents,
  )).toList();
  
  return service.daysToReachGoal(points, goal.round());
}

// CONTROLLER for Mutations
@riverpod
class NetWorthController extends _$NetWorthController {
  @override
  FutureOr<void> build() {
    // Initial state is void/idle
  }

  Future<void> addAsset(Asset asset) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(netWorthRepositoryProvider).addAsset(asset);
      await _checkMilestones();
    });
  }
  
  Future<void> updateAsset(Asset asset) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(netWorthRepositoryProvider).updateAsset(asset);
      await _checkMilestones();
    });
  }

  Future<void> deleteAsset(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(netWorthRepositoryProvider).deleteAsset(id);
      await _checkMilestones();
    });
  }

  Future<void> addLiability(Liability liability) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(netWorthRepositoryProvider).addLiability(liability);
      await _checkMilestones();
    });
  }
  
  Future<void> updateLiability(Liability liability) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(netWorthRepositoryProvider).updateLiability(liability);
      await _checkMilestones();
    });
  }

  Future<void> deleteLiability(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(netWorthRepositoryProvider).deleteLiability(id);
      await _checkMilestones();
    });
  }

  Future<void> _checkMilestones() async {
    // This would typically involve checking the current net worth against thresholds
    // and showing a toast if a new one is crossed.
    // Logic: fetch current net worth, compare with 'last_known_milestone' in Prefs.
    // For this implementation, we log the check to debug.
    final summary = await ref.read(netWorthSummaryProvider.future);
    debugPrint('[Milestones] Current Net Worth: ${summary.netWorth}');
    
    // In a real app, we'd trigger a GlassToast.show() here if a threshold is crossed.
    // Since we don't have a BuildContext in the controller, we might use a listener in the UI.
  }
}
