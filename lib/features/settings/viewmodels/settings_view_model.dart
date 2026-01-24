import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../features/auth/providers/auth_provider.dart';
import '../../../../features/subscription/providers/subscription_providers.dart';

// State for the Settings Screen (mostly transient UI state)
class SettingsState {
  final bool isLoading;
  final String? errorMessage;

  const SettingsState({
    this.isLoading = false,
    this.errorMessage,
  });

  SettingsState copyWith({
    bool? isLoading,
    String? errorMessage,
  }) {
    return SettingsState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage, // Reset error on state change unless explicitly provided
    );
  }
}

class SettingsViewModel extends AutoDisposeNotifier<SettingsState> {
  @override
  SettingsState build() {
    return const SettingsState();
  }

  Future<void> openUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        state = state.copyWith(errorMessage: 'Could not launch $url');
      }
    } catch (e) {
      state = state.copyWith(errorMessage: 'Error launching URL: $e');
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);
    try {
      await ref.read(authProvider.notifier).signOut();
    } catch (e) {
      state = state.copyWith(errorMessage: 'Sign out failed: $e');
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> refreshSubscription() async {
    state = state.copyWith(isLoading: true);
    try {
      await ref.read(subscriptionServiceProvider).sync();
      ref.invalidate(currentTierProvider);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to sync subscription: $e');
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

final settingsViewModelProvider = NotifierProvider.autoDispose<SettingsViewModel, SettingsState>(() {
  return SettingsViewModel();
});
