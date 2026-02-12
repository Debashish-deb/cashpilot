import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final greetingManagerProvider = Provider<GreetingManager>((ref) {
  return GreetingManager();
});

class GreetingManager {
  DateTime? _lastRotation;
  
  // 20+ Welcome variations (Keys map to arb files)
  // We handle the actual string lookup in the UI using these keys/logic
  // BUT: Since l10n is context-dependent, we'll return a "type" or index
  
  // Actually, simplest way is to return an enum or ID, and let UI map it.
  // Or, since we need "20 messages", we can define them in code if they are generic, 
  // but user said "100% localized". So they must be in ARB.
  
  // Strategy:
  // 1. Return a 'GreetingType' (TimeBased vs Randomized)
  // 2. If Randomized, return an index 1-20.
  // 3. UI calls `l10n.welcomeMessage_X` based on index.
  
  bool _isFirstLaunch = true; // resets on app restart (memory)

  GreetingConfiguration getGreetingConfig() {
    final now = DateTime.now();
    
    // First time always time-based
    if (_isFirstLaunch) {
      _isFirstLaunch = false;
      _lastRotation = now;
      return const GreetingConfiguration(type: GreetingType.timeBased);
    }

    // Check if 30 mins passed
    if (_lastRotation == null || now.difference(_lastRotation!).inMinutes >= 30) {
      _lastRotation = now; // Update rotation time
      
      // Randomize: 1 to 20
      final randomIndex = Random().nextInt(20) + 1;
      return GreetingConfiguration(
        type: GreetingType.random, 
        index: randomIndex
      );
    }

    // If < 30 mins, return the current state or default
    return const GreetingConfiguration(type: GreetingType.timeBased);
  }
}

enum GreetingType {
  timeBased,
  random,
}

class GreetingConfiguration {
  final GreetingType type;
  final int index; // 1-20 for random

  const GreetingConfiguration({required this.type, this.index = 0});
}

// Improved provider to hold state
final greetingStateProvider = StateNotifierProvider<GreetingNotifier, GreetingConfiguration>((ref) {
  return GreetingNotifier();
});

class GreetingNotifier extends StateNotifier<GreetingConfiguration> {
  GreetingNotifier() : super(const GreetingConfiguration(type: GreetingType.timeBased));

  DateTime _lastUpdate = DateTime.now();

  void checkUpdates() {
    final now = DateTime.now();
    if (now.difference(_lastUpdate).inMinutes >= 30) {
      final randomIndex = Random().nextInt(20) + 1;
      state = GreetingConfiguration(type: GreetingType.random, index: randomIndex);
      _lastUpdate = now;
    }
  }
}
