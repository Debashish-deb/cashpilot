
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';

class AppSettingsState {
  final bool performanceMode;

  const AppSettingsState({
    this.performanceMode = false,
  });

  AppSettingsState copyWith({
    bool? performanceMode,
  }) {
    return AppSettingsState(
      performanceMode: performanceMode ?? this.performanceMode,
    );
  }
}

class AppSettingsNotifier extends Notifier<AppSettingsState> {
  static const _perfKey = 'performance_mode';

  @override
  AppSettingsState build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final isPerfMode = prefs.getBool(_perfKey) ?? false;
    return AppSettingsState(performanceMode: isPerfMode);
  }

  Future<void> togglePerformanceMode(bool value) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(_perfKey, value);
    state = state.copyWith(performanceMode: value);
  }
}

final appSettingsProvider = NotifierProvider<AppSettingsNotifier, AppSettingsState>(() {
  return AppSettingsNotifier();
});
