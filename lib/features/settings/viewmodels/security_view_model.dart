import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../services/biometric_service.dart';
import '../../../../core/providers/app_providers.dart';
import '../models/operation_result.dart';
import '../controllers/security_controller.dart';

class SecurityViewState {
  final bool biometricEnabled;
  final bool appLockEnabled;
  final int autoLockTimeoutSeconds;
  final bool isBiometricHardwareAvailable;
  final String biometricTypeDescription;
  final bool isLoading;
  final String? error;

  const SecurityViewState({
    this.biometricEnabled = false,
    this.appLockEnabled = false,
    this.autoLockTimeoutSeconds = 60,
    this.isBiometricHardwareAvailable = false,
    this.biometricTypeDescription = 'Biometric',
    this.isLoading = false,
    this.error,
  });

  SecurityViewState copyWith({
    bool? biometricEnabled,
    bool? appLockEnabled,
    int? autoLockTimeoutSeconds,
    bool? isBiometricHardwareAvailable,
    String? biometricTypeDescription,
    bool? isLoading,
    String? error,
  }) {
    return SecurityViewState(
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      appLockEnabled: appLockEnabled ?? this.appLockEnabled,
      autoLockTimeoutSeconds: autoLockTimeoutSeconds ?? this.autoLockTimeoutSeconds,
      isBiometricHardwareAvailable: isBiometricHardwareAvailable ?? this.isBiometricHardwareAvailable,
      biometricTypeDescription: biometricTypeDescription ?? this.biometricTypeDescription,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class SecurityViewModel extends AutoDisposeAsyncNotifier<SecurityViewState> {
  @override
  Future<SecurityViewState> build() async {
    final settings = await ref.watch(securityControllerProvider).getSettings();
    final isAvailable = await biometricService.isAvailable();
    final description = await biometricService.getBiometricTypeDescription();

    return SecurityViewState(
      biometricEnabled: settings.biometricEnabled,
      appLockEnabled: settings.appLockEnabled,
      autoLockTimeoutSeconds: settings.autoLockTimeoutSeconds,
      isBiometricHardwareAvailable: isAvailable,
      biometricTypeDescription: description,
    );
  }

  Future<OperationResult<void>> toggleBiometric(bool enabled) async {
    state = AsyncData(state.value!.copyWith(isLoading: true));
    
    try {
      final controller = ref.read(securityControllerProvider);
      final result = await controller.setBiometricEnabled(enabled);
      
      if (result.isSuccess) {
        // Update the provider state as well (to keep legacy parts in sync if any)
        ref.read(biometricEnabledProvider.notifier).refreshFromPrefs();
        
        state = AsyncData(state.value!.copyWith(
          biometricEnabled: enabled,
          isLoading: false,
        ));
      } else {
        state = AsyncData(state.value!.copyWith(
          isLoading: false,
          error: result.message,
        ));
      }
      return result;
    } catch (e) {
      state = AsyncData(state.value!.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
      return OperationResult.failure(message: e.toString(), error: e);
    }
  }

  Future<OperationResult<void>> toggleAppLock(bool enabled) async {
    state = AsyncData(state.value!.copyWith(isLoading: true));
    
    try {
      final controller = ref.read(securityControllerProvider);
      final result = await controller.setAppLockEnabled(enabled);
      
      if (result.isSuccess) {
        state = AsyncData(state.value!.copyWith(
          appLockEnabled: enabled,
          isLoading: false,
        ));
      } else {
        state = AsyncData(state.value!.copyWith(
          isLoading: false,
          error: result.message,
        ));
      }
      return result;
    } catch (e) {
      state = AsyncData(state.value!.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
      return OperationResult.failure(message: e.toString(), error: e);
    }
  }

  Future<OperationResult<void>> setAutoLockTimeout(int seconds) async {
    state = AsyncData(state.value!.copyWith(isLoading: true));
    
    try {
      final controller = ref.read(securityControllerProvider);
      final result = await controller.setAutoLockTimeout(seconds);
      
      if (result.isSuccess) {
        state = AsyncData(state.value!.copyWith(
          autoLockTimeoutSeconds: seconds,
          isLoading: false,
        ));
      } else {
        state = AsyncData(state.value!.copyWith(
          isLoading: false,
          error: result.message,
        ));
      }
      return result;
    } catch (e) {
      state = AsyncData(state.value!.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
      return OperationResult.failure(message: e.toString(), error: e);
    }
  }

  void clearError() {
    if (state.hasValue) {
      state = AsyncData(state.value!.copyWith(error: null));
    }
  }
}

final securityViewModelProvider = AsyncNotifierProvider.autoDispose<SecurityViewModel, SecurityViewState>(() {
  return SecurityViewModel();
});
