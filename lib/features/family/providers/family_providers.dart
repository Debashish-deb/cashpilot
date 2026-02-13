import 'package:cashpilot/features/sync/sync_providers.dart' show syncOrchestratorProvider, SyncReason;
import 'package:cashpilot/l10n/app_localizations.dart' show AppLocalizations;
import 'package:cashpilot/services/email_service.dart' show emailService;
import 'package:cashpilot/services/notification_service.dart' show notificationService;
import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/drift/app_database.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/logging/logger.dart';

final familyControllerProvider = Provider((ref) => FamilyController(ref));

class FamilyController {
  final Ref _ref;
  final Logger _logger = Loggers.sharing;

  FamilyController(this._ref);

  AppDatabase get _db => _ref.read(databaseProvider);

  Future<void> acceptInvitation(String memberId) async {
    _logger.info('Accepting invitation', context: {'memberId': memberId});
    try {
      await _db.acceptInvitation(memberId);
      // Invalidate relevant providers
    } catch (e, st) {
      _logger.error('Failed to accept invitation', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<void> declineInvitation(String memberId) async {
    _logger.info('Declining invitation', context: {'memberId': memberId});
    try {
      await _db.declineInvitation(memberId);
    } catch (e, st) {
      _logger.error('Failed to decline invitation', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<void> setSpendingLimit(String memberId, int? limitInCents) async {
     _logger.info('Setting spending limit', context: {'memberId': memberId, 'limit': limitInCents});
     try {
       await _db.updateBudgetMember(BudgetMembersCompanion(
         id: Value(memberId),
         spendingLimit: Value(limitInCents),
       ));
     } catch (e, st) {
       _logger.error('Failed to set spending limit', error: e, stackTrace: st);
       rethrow;
     }
  }

  Future<void> inviteMember({
    required String budgetId,
    required String email,
    String? name,
    String role = 'editor',
    int? spendingLimit,
  }) async {
    _logger.info('Inviting member', context: {'budgetId': budgetId, 'email': email});
    try {
      final budget = await (_db.select(_db.budgets)..where((t) => t.id.equals(budgetId))).getSingleOrNull();
      if (budget == null) throw Exception('Budget not found');

      final inviterId = _ref.read(currentUserIdProvider);
      final inviter = inviterId != null ? await _db.getUserById(inviterId) : null;

      await _db.inviteMember(
        budgetId: budgetId,
        email: email,
        name: name,
        role: role,
        invitedBy: inviterId,
        spendingLimit: spendingLimit,
      );

      // 1. Send Email Invite
      _ref.read(emailServiceProvider).sendBudgetInvite(
        toEmail: email,
        inviterName: inviter?.name ?? 'A user',
        budgetName: budget.title,
      );

      // 2. Trigger Sync
      _ref.read(syncOrchestratorProvider).requestSync(SyncReason.manualUserAction);

      _logger.info('Member invited successfully', context: {'email': email});
    } catch (e, st) {
      _logger.error('Failed to invite member', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Trigger push notifications for shared spending (P1)
  Future<void> notifySharedSpending({
    required String budgetId,
    required String spenderName,
    required int amount,
    required String currency,
    required String category,
  }) async {
    // In a real app, this would be a server-side push triggered by a database hook.
    // Here we simulate it for Phase 6 completion.
    try {
      final formattedAmount = (amount / 100).toStringAsFixed(2);
      final currencySymbol = currency == 'EUR' ? '€' : currency;

      await notificationService.showNotification(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: 'New Shared Spending',
        body: '$spenderName spent $currencySymbol$formattedAmount on $category',
        l10n: _ref.read(l10nProvider),
      );
    } catch (e) {
      _logger.warning('Failed to trigger mock push notification: $e');
    }
  }
}

final emailServiceProvider = Provider((ref) => emailService);
final l10nProvider = Provider<AppLocalizations>((ref) {
  // This is a placeholder; real apps would get l10n from context or a dedicated provider
  throw UnimplementedError('L10n provider must be implemented based on UI context');
});
