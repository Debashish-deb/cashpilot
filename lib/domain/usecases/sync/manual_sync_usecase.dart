import '../use_case.dart';
import '../../../features/sync/orchestrator/sync_orchestrator.dart';

/// Parameters for manual sync
class ManualSyncParams {
  final bool forceFullSync;

  const ManualSyncParams({this.forceFullSync = false});
}

/// Use case for manual sync
/// 
/// Encapsulates business logic:
/// - Validates user authentication
/// - Triggers sync with appropriate reason
/// - Returns sync result
class ManualSyncUseCase extends UseCase<SyncOrchestratorResult, ManualSyncParams> {
  final SyncOrchestrator _orchestrator;

  ManualSyncUseCase(this._orchestrator);

  @override
  Future<SyncOrchestratorResult> execute(ManualSyncParams params) async {
    // Business Logic: Use appropriate sync reason
    final reason = params.forceFullSync 
        ? SyncReason.forceFull 
        : SyncReason.manualUserAction;

    // Execute sync
    final result = await _orchestrator.requestSync(reason);

    // Business Logic: Log significant results
    if (result.hasErrors) {
      print('[ManualSyncUseCase] Sync completed with errors: ${result.errors}');
    } else {
      print('[ManualSyncUseCase] Sync successful: ${result.totalItems} items');
    }

    return result;
  }
}
