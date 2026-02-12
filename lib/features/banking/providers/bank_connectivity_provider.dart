import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/bank_connection_service.dart';

/// Provider for bank connectivity activation state
final bankConnectivityEnabledProvider = StateNotifierProvider<BankConnectivityNotifier, bool>((ref) {
  return BankConnectivityNotifier();
});

class BankConnectivityNotifier extends StateNotifier<bool> {
  BankConnectivityNotifier() : super(false) {
    _loadState();
  }

  static const _storageKey = 'bank_connectivity_enabled';

  Future<void> _loadState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      state = prefs.getBool(_storageKey) ?? false;
    } catch (_) {
      state = false;
    }
  }

  Future<void> toggle(bool value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_storageKey, value);
  }
}

/// Stream of connected bank accounts
final bankAccountStreamProvider = StreamProvider<List<BankAccount>>((ref) {
  // Assuming bankConnectionService is available globally or can be imported
  // Based on previous research it is in lib/services/bank_connection_service.dart
  return bankConnectionService.watchBankAccounts();
});
