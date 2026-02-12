import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' show Value;
import 'package:uuid/uuid.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/providers/app_providers.dart';
import '../../../data/drift/app_database.dart';
import '../../../services/sync_engine.dart';
import '../../../services/email_service.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../providers/budget_providers.dart';

/// Budget Members Section - Shows and manages members for a specific budget
class BudgetMembersSection extends ConsumerWidget {
  final String budgetId;
  final Budget budget;
  
  const BudgetMembersSection({
    super.key,
    required this.budgetId,
    required this.budget,
  });
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(budgetMembersProvider(budgetId));
    final isOwner = ref.watch(isBudgetOwnerProvider(budget));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.group_rounded,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Family Members',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            if (isOwner)
              TextButton.icon(
                onPressed: () => _showInviteDialog(context, ref),
                icon: const Icon(Icons.person_add_rounded, size: 18),
                label: const Text('Invite'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // Members list
        membersAsync.when(
          data: (members) {
            if (members.isEmpty) {
              return _buildEmptyState(context, isOwner);
            }
            
            return Container(
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.05),
                ),
              ),
              child: Column(
                children: [
                  // Owner row (current user if owner)
                  if (isOwner) _buildOwnerRow(context),
                  
                  // Member rows
                  ...members.map((m) => _MemberTile(
                    member: m,
                    isOwner: isOwner,
                    onRemove: isOwner ? () => _removeMember(context, ref, m) : null,
                    onChangeRole: isOwner ? () => _changeRole(context, ref, m) : null,
                  )),
                ],
              ),
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text('Error: $e'),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildEmptyState(BuildContext context, bool isOwner) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.family_restroom_rounded,
            size: 48,
            color: Theme.of(context).hintColor,
          ),
          const SizedBox(height: 12),
          Text(
            'No family members yet',
            style: AppTypography.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isOwner
                ? 'Invite family members to share this budget'
                : 'Only the budget owner can invite members',
            style: AppTypography.bodySmall.copyWith(
              color: Theme.of(context).hintColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildOwnerRow(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.primaryGreen,
        child: const Icon(Icons.person, color: Colors.white, size: 20),
      ),
      title: const Text('You', style: TextStyle(fontWeight: FontWeight.w600)),
      subtitle: const Text('Owner'),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.primaryGreen.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          'Owner',
          style: TextStyle(
            color: AppColors.primaryGreen,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
  
  void _showInviteDialog(BuildContext context, WidgetRef ref) {
    final parentContext = context;
    final emailController = TextEditingController();
    String role = 'editor';
    bool sendEmail = true;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Invite Family Member'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Invite someone to "${budget.title}"',
                style: AppTypography.bodyMedium.copyWith(
                  color: Theme.of(context).hintColor,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: role,
                decoration: const InputDecoration(
                  labelText: 'Access Level',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'editor', child: Text('Editor - Can add expenses')),
                  DropdownMenuItem(value: 'viewer', child: Text('Viewer - Read only')),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => role = v);
                },
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                value: sendEmail,
                onChanged: (v) => setState(() => sendEmail = v),
                title: const Text('Send Email Notification'),
                subtitle: Text(
                  sendEmail 
                    ? 'They\'ll receive an email with the invite' 
                    : 'They\'ll only see it in-app after signing in',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).hintColor,
                  ),
                ),
                secondary: Icon(
                  sendEmail ? Icons.email : Icons.phone_android,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final email = emailController.text.trim();
                if (email.isEmpty) return;
                
                Navigator.pop(context);
                await _inviteMember(parentContext, ref, email, role, sendEmail);
              },
              child: const Text('Send Invite'),
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _inviteMember(BuildContext context, WidgetRef ref, String email, String role, bool sendEmail) async {
    try {
      final db = ref.read(databaseProvider);
      final uuid = const Uuid().v4();
      
      // 1. Create database invite
      await db.insertBudgetMember(BudgetMembersCompanion.insert(
        id: uuid,
        budgetId: budgetId,
        memberEmail: email,
        role: role,
        status: const Value('pending'),
        invitedBy: Value(ref.read(currentUserIdProvider)!),
        invitedAt: Value(DateTime.now()),
      ));
      
      // 2. Sync to cloud
      ref.read(syncEngineProvider).syncAll();
      
      // 3. Send email if requested
      if (sendEmail) {
        final currentUser = ref.read(authProvider).user;
        final userName = currentUser?.userMetadata?['name'] ?? currentUser?.email?.split('@').first ?? 'Someone';
        
        final emailSent = await emailService.sendBudgetInvite(
          toEmail: email,
          inviterName: userName,
          budgetName: budget.title,
        );
        
        if (context.mounted) {
          final message = emailSent 
            ? 'Invitation sent to $email ✉️'
            : 'Invite created (email failed, but they\'ll see it in-app)';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: emailSent ? Colors.green : Colors.orange,
            ),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invitation created (they\'ll see it in-app)'),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to invite: $e')),
        );
      }
    }
  }
  
  Future<void> _removeMember(BuildContext context, WidgetRef ref, BudgetMember member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Remove Member'),
        content: Text('Remove ${member.memberEmail} from this budget?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      final db = ref.read(databaseProvider);
      await db.deleteBudgetMember(member.id);
      ref.read(syncEngineProvider).syncAll();
    }
  }
  
  void _changeRole(BuildContext context, WidgetRef ref, BudgetMember member) {
    final newRole = member.role == 'editor' ? 'viewer' : 'editor';
    
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Change Role'),
        content: Text('Change ${member.memberEmail} to $newRole?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(c);
              final db = ref.read(databaseProvider);
              await db.updateBudgetMember(member.toCompanion(false).copyWith(
                role: Value(newRole),
              ));
              ref.read(syncEngineProvider).syncAll();
            },
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  final BudgetMember member;
  final bool isOwner;
  final VoidCallback? onRemove;
  final VoidCallback? onChangeRole;
  
  const _MemberTile({
    required this.member,
    required this.isOwner,
    this.onRemove,
    this.onChangeRole,
  });
  
  @override
  Widget build(BuildContext context) {
    final isPending = member.status == 'pending';
    final roleColor = member.role == 'editor' ? AppColors.accent : Colors.grey;
    
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isPending ? Colors.orange : roleColor,
        child: Icon(
          isPending ? Icons.hourglass_empty : Icons.person,
          color: Colors.white,
          size: 20,
        ),
      ),
      title: Text(
        member.memberEmail,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        isPending ? 'Pending invite' : member.role.toUpperCase(),
        style: TextStyle(
          color: isPending ? Colors.orange : null,
          fontSize: 12,
        ),
      ),
      trailing: isOwner
          ? PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (v) {
                if (v == 'role') onChangeRole?.call();
                if (v == 'remove') onRemove?.call();
              },
              itemBuilder: (c) => [
                const PopupMenuItem(value: 'role', child: Text('Change Role')),
                const PopupMenuItem(
                  value: 'remove',
                  child: Text('Remove', style: TextStyle(color: Colors.red)),
                ),
              ],
            )
          : null,
    );
  }
}
