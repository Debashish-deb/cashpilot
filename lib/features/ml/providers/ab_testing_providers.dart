import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/ab_testing_service.dart';

/// Provider for the ABTestingService singleton
final abTestingServiceProvider = Provider<ABTestingService>((ref) {
  return ABTestingService();
});

/// Future provider for fetching active A/B tests
final activeTestsProvider = FutureProvider.autoDispose<List<ABTest>>((ref) async {
  final service = ref.watch(abTestingServiceProvider);
  return service.getActiveTests();
});

/// Future provider for fetching completed A/B tests
final completedTestsProvider = FutureProvider.autoDispose<List<ABTest>>((ref) async {
  final service = ref.watch(abTestingServiceProvider);
  return service.getCompletedTests();
});

/// State provider for tracking A/B Test creation form state if needed
final abTestFormProcessingProvider = StateProvider<bool>((ref) => false);
