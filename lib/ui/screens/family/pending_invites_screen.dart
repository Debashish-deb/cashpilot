/// Pending Invites Screen
/// Shows and manages pending budget invitations for the current user
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' show Value, OrderingTerm;

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/providers/app_providers.dart';
import '../../../data/drift/app_database.dart';
import '../../../features/auth/providers/auth_provider.dart';
import 'package:cashpilot/l10n/app_localizations.dart';
import '../../../services/auth_service.dart';
import '../../../services/sync_engine.dart';

/// Provider to watch pending invites for current user's email
final pendingInvitesForUserProvider = StreamProvider<List<BudgetMember>>((ref) async* {
  final db = ref.watch(databaseProvider);
  final authState = ref.watch(authProvider);
  final userEmail = authState.user?.email;
  
  if (userEmail == null) {
    yield [];
    return;
  }
  
  // Watch all budget members where email matches and status is pending
  yield* (db.select(db.budgetMembers)
    ..where((t) => t.memberEmail.equals(userEmail.toLowerCase()))
    ..where((t) => t.status.equals('pending'))
    ..orderBy([(t) => OrderingTerm.desc(t.invitedAt)]))
    .watch();
});

class PendingInvitesScreen extends ConsumerWidget {
  const PendingInvitesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invitesAsync = ref.watch(pendingInvitesForUserProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.notifPendingInvites),
        centerTitle: false,
      ),
      body: invitesAsync.when(
        data: (invites) {
          if (invites.isEmpty) {
            return _buildEmptyState(context);
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final horizontalPadding = constraints.maxWidth < 360 ? 12.0 : 16.0;
              return ListView.builder(
                padding: EdgeInsets.all(horizontalPadding),
            itemCount: invites.length,
            itemBuilder: (context, index) {
              final invite = invites[index];
              return _InviteCard(
                invite: invite,
                onAccept: () => _acceptInvite(context, ref, invite),
                onDecline: () => _declineInvite(context, ref, invite),
              );
            });
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.danger),
              const SizedBox(height: 16),
              Text('Error loading invites', style: AppTypography.titleMedium),
              const SizedBox(height: 8),
              Text('$e', style: AppTypography.bodySmall),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.mail_outline_rounded,
                size: 64,
                color: Theme.of(context).primaryColor.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Pending Invites',
              style: AppTypography.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'When someone invites you to share a budget, it will appear here.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _acceptInvite(BuildContext context, WidgetRef ref, BudgetMember invite) async {
    try {
      final db = ref.read(databaseProvider);
      final userId = ref.read(currentUserIdProvider);
      
      // Update status to active and link user_id
      await db.updateBudgetMember(BudgetMembersCompanion(
        id: Value(invite.id),
        budgetId: Value(invite.budgetId),
        userId: Value(userId),
        memberEmail: Value(invite.memberEmail),
        memberName: Value(invite.memberName),
        role: Value(invite.role),
        status: const Value('active'),
        acceptedAt: Value(DateTime.now()),
        invitedAt: Value(invite.invitedAt),
        invitedBy: Value(invite.invitedBy),
      ));

      // Trigger sync immediately
      try {
        ref.read(syncEngineProvider).syncBudgetMember(invite.id);
      } catch (e) {
        debugPrint('Sync trigger failed: $e');
      }

      if (context.mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.notifInviteAcceptedMsg),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error accepting invite: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _declineInvite(BuildContext context, WidgetRef ref, BudgetMember invite) async {
    final l10n = AppLocalizations.of(context)!;
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.notifDeclineInviteTitle),
        content: Text(l10n.notifDeclineInviteDesc),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.commonCancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.notifDecline),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final db = ref.read(databaseProvider);
      
      // Delete the invite
      await db.deleteBudgetMember(invite.id);

      // WORKAROUND: Schema lacks isDeleted, so manually delete from cloud
      try {
          await authService.client.from('budget_members').delete().eq('id', invite.id);
      } catch (e) { 
          debugPrint('Delete sync error: $e'); 
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invite declined')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.commonErrorMessage(e.toString())),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }
}

class _InviteCard extends StatelessWidget {
  final BudgetMember invite;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const _InviteCard({
    required this.invite,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.mail_outline,
                    color: Theme.of(context).primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Budget Invitation',
                        style: AppTypography.titleSmall.copyWith(
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      Text(
                        _formatDate(invite.invitedAt),
                        style: AppTypography.bodySmall.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                _buildRoleBadge(context, invite.role),
              ],
            ),
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Budget info (we'd need to fetch this)
                Row(
                  children: [
                    const Icon(Icons.account_balance_wallet_outlined, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Shared Budget',
                        style: AppTypography.bodyMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // Role description
                Text(
                  'You will be added as: ${invite.role.toUpperCase()}',
                  style: AppTypography.bodySmall.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                Text(
                  _getRoleDescription(invite.role),
                  style: AppTypography.bodySmall.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          
          // Action buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onDecline,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      side: const BorderSide(color: AppColors.danger),
                    ),
                    child: Text(l10n.commonDecline),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: onAccept,
                    icon: const Icon(Icons.check, size: 18),
                    label: Text(l10n.notifAccept),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleBadge(BuildContext context, String role) {
    final color = _getRoleColor(context, role);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        role.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Color _getRoleColor(BuildContext context, String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return const Color(0xFF2196F3);
      case 'member':
        return Theme.of(context).primaryColor;
      case 'viewer':
        return const Color(0xFF607D8B);
      default:
        return Theme.of(context).primaryColor;
    }
  }

  String _getRoleDescription(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return 'You can edit budgets and manage members';
      case 'member':
        return 'You can add expenses and view budgets';
      case 'viewer':
        return 'You have read-only access';
      default:
        return '';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        return '${diff.inMinutes} minutes ago';
      }
      return '${diff.inHours} hours ago';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
