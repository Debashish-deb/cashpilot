import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/providers/app_providers.dart';
import '../../../domain/cfse/i_financial_state_engine.dart';
import '../../../services/cfse/financial_state_engine.dart';
import '../../../domain/cfse/financial_state.dart';

part 'cfse_providers.g.dart';

@Riverpod(keepAlive: true)
IFinancialStateEngine financialStateEngine(FinancialStateEngineRef ref) {
  final db = ref.watch(databaseProvider);
  return FinancialStateEngine(db);
}

@riverpod
Stream<FinancialState> currentFinancialState(CurrentFinancialStateRef ref, String userId) {
  final engine = ref.watch(financialStateEngineProvider);
  return engine.watchState(userId);
}
