import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/error_taxonomy.dart';

@immutable
class BudgetState {
  /// Whether an operation is in progress
  final bool isLoading;
  
  /// Error from last operation (if any)
  final AsyncValue<void> lastOperation;
  
  /// ID of the last successfully modified budget (for navigation/snackbars)
  final String? lastSuccessId;

  const BudgetState({
    this.isLoading = false,
    this.lastOperation = const AsyncValue.data(null),
    this.lastSuccessId,
  });

  BudgetState copyWith({
    bool? isLoading,
    AsyncValue<void>? lastOperation,
    String? lastSuccessId,
  }) {
    return BudgetState(
      isLoading: isLoading ?? this.isLoading,
      lastOperation: lastOperation ?? this.lastOperation,
      lastSuccessId: lastSuccessId ?? this.lastSuccessId,
    );
  }
}
