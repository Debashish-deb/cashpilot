/// Family Sharing Screen
/// Manage shared family budgets and members
library;

import 'package:cashpilot/core/utils/app_snackbar.dart' show AppSnackBar;
import 'package:go_router/go_router.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/family/family_tree_graph.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/constants/app_routes.dart';
import '../../../data/drift/app_database.dart';
import '../../../services/feature_gate_service.dart';
import '../../../features/budgets/providers/budget_providers.dart';
import 'package:cashpilot/l10n/app_localizations.dart';
import '../../../services/auth_service.dart';
import '../../../services/sync_engine.dart';

// Family members provider - watches all members for budgets owned by current user
final familyMembersProvider = StreamProvider<List<BudgetMember>>((ref) {
  final db = ref.watch(databaseProvider);
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value([]);
  
  // Stream all budget members for budgets where current user is owner
  return db.watchAllFamilyMembers(userId);
});

// Pending invites provider - watches invites for current user's email
final pendingInvitesProvider = StreamProvider<List<BudgetMember>>((ref) {
  final db = ref.watch(databaseProvider);
  // For pending invites, we need to query by email which requires auth state
  // This will be implemented via direct query
  return Stream.value([]);
});

// NEW: Global Family Contacts Provider
final globalFamilyContactsProvider = StreamProvider<List<FamilyContact>>((ref) {
  final repo = ref.watch(familyRepositoryProvider);
  return repo.watchFamilyContacts();
});

// NEW: All Relationships Provider
final allFamilyRelationsProvider = FutureProvider<List<FamilyRelation>>((ref) async {
  final repo = ref.watch(familyRepositoryProvider);
  return repo.getRelations();
});

// NEW: Group members by budget for hierarchical display
final groupedMembersByBudgetProvider = FutureProvider<Map<Budget, List<BudgetMember>>>((ref) async {
  final db = ref.watch(databaseProvider);
  final budgetsAsync = ref.watch(budgetsStreamProvider);
  
  return budgetsAsync.when(
    data: (budgets) async {
      final grouped = <Budget, List<BudgetMember>>{};
      for (final budget in budgets) {
        final members = await db.getBudgetMembers(budget.id);
        grouped[budget] = members;
      }
      return grouped;
    },
    loading: () => {},
    error: (_, __) => {},
  );
});

class FamilySharingScreen extends ConsumerWidget {
  const FamilySharingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final familyAsync = ref.watch(familyMembersProvider);
    final l10n = AppLocalizations.of(context)!;

    // Check for Pro Plus subscription (Family budgets are Pro Plus only)
    return FutureBuilder<bool>(
      future: ref.read(featureGateProvider).canUseFamilyBudgets(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (snapshot.data == false) {
          // Not Pro Plus - show upgrade screen
          return Scaffold(
            appBar: AppBar(
              title: Text(l10n.familySharingTitle),
              centerTitle: true,
              elevation: 0,
              scrolledUnderElevation: 0,
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.family_restroom, size: 64, color: AppColors.gold),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Family Sharing',
                      style: AppTypography.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Share budgets and collaborate with family members in real-time',
                      style: AppTypography.bodyMedium.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          _buildProPlusFeature(context, Icons.group, 'Invite unlimited family members'),
                          _buildProPlusFeature(context, Icons.sync, 'Real-time expense sync'),
                          _buildProPlusFeature(context, Icons.lock, 'Role-based permissions'),
                          _buildProPlusFeature(context, Icons.notifications, 'Instant notifications'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: () => context.push(AppRoutes.paywall),
                      icon: const Icon(Icons.workspace_premium),
                      label: Text(l10n.commonUpgrade),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '🚀 Pro Plus exclusive feature',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.gold,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // User has Pro - show normal screen
        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              title: Text(l10n.familySharingTitle),
              centerTitle: true,
              elevation: 0,
              scrolledUnderElevation: 0,
              bottom: const TabBar(
                tabs: [
                  Tab(text: 'Members', icon: Icon(Icons.people_outline)),
                  Tab(text: 'Family Tree', icon: Icon(Icons.account_tree_outlined)),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.help_outline),
                  onPressed: () => _showHelpDialog(context),
                ),
              ],
            ),
            body: SafeArea(
              child: TabBarView(
                children: [
                  // Tab 1: Members List
                  ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Feature overview card
                      _buildFeatureCard(context),
                      const SizedBox(height: 24),
                      // Family members grouped by budget
                      _buildGroupedMembersView(context, ref),
                    ],
                  ),
                  
                  // Tab 2: Family Tree
                  Consumer(
                    builder: (context, ref, child) {
                      final contactsAsync = ref.watch(globalFamilyContactsProvider);
                      final relationsAsync = ref.watch(allFamilyRelationsProvider);
                      
                      return contactsAsync.when(
                        data: (contacts) => relationsAsync.when(
                          data: (relations) => FamilyTreeGraph(
                            contacts: contacts,
                            relations: relations,
                          ),
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (e, _) => Center(child: Text('Error loading relations: $e')),
                        ),
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (e, _) => Center(child: Text('Error loading contacts: $e')),
                      );
                    },
                  ),
                ],
              ),
            ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () => _showInviteSheet(context, ref),
              icon: const Icon(Icons.person_add_outlined),
              label: Text(l10n.commonInvite),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGroupedMembersView(BuildContext context, WidgetRef ref) {
    final groupedAsync = ref.watch(groupedMembersByBudgetProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return groupedAsync.when(
      data: (grouped) {
        if (grouped.isEmpty) {
          return _buildEmptyState(context, ref);
        }
        
        // Separate budgets with and without members
        final budgetsWithMembers = grouped.entries.where((e) => e.value.isNotEmpty).toList();
        final budgetsWithoutMembers = grouped.entries.where((e) => e.value.isEmpty).toList();
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section: Budgets with members
            if (budgetsWithMembers.isNotEmpty) ...[
              Text(
                'Shared Budgets (${budgetsWithMembers.length})',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              ...budgetsWithMembers.map((entry) => _BudgetMembersCard(
                budget: entry.key,
                members: entry.value,
                onInvite: () => _showInviteSheetForBudget(context, ref, entry.key),
                onChangeRole: (m) => _showChangeRoleDialog(context, ref, m),
                onRemove: (m) => _showRemoveMemberDialog(context, ref, m),
              )),
            ],
            
            // Section: Budgets without members
            if (budgetsWithoutMembers.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                'Ready to Share (${budgetsWithoutMembers.length})',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).hintColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tap to invite family members',
                style: AppTypography.bodySmall.copyWith(
                  color: Theme.of(context).hintColor,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: budgetsWithoutMembers.map((entry) => ActionChip(
                  avatar: const Icon(Icons.add, size: 18),
                  label: Text(entry.key.title, overflow: TextOverflow.ellipsis),
                  onPressed: () => _showInviteSheetForBudget(context, ref, entry.key),
                )).toList(),
              ),
            ],
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(AppLocalizations.of(context)!.commonErrorMessage(e.toString()))),
    );
  }
  
  void _showInviteSheetForBudget(BuildContext context, WidgetRef ref, Budget budget) {
    final l10n = AppLocalizations.of(context)!;
    final emailController = TextEditingController();
    String role = 'editor';
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Invite to "${budget.title}"',
                style: AppTypography.titleLarge,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.email_outlined),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.contacts_outlined),
                    tooltip: 'Pick from contacts',
                    onPressed: () async {
                      final contact = await context.push<Contact>(AppRoutes.contactPicker); 
                      
                      if (contact != null && contact.emails.isNotEmpty) {
                        emailController.text = contact.emails.first.address;
                      }
                    },
                  ),
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
                items: [
                  DropdownMenuItem(value: 'editor', child: Text(l10n.familyRoleEditor)),
                  DropdownMenuItem(value: 'viewer', child: Text(l10n.familyRoleViewer)),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => role = v);
                },
              ),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () async {
                    final email = emailController.text.trim();
                    if (email.isEmpty) return;
                    
                    Navigator.pop(context);
                    
                    try {
                      final db = ref.read(databaseProvider);
                      final authService = ref.read(authServiceProvider);
                      final uuid = const Uuid().v4();
                      
                      await db.insertBudgetMember(BudgetMembersCompanion.insert(
                        id: uuid,
                        budgetId: budget.id,
                        memberEmail: email,
                        role: role,
                        status: const Value('pending'),
                        invitedBy: Value(ref.read(currentUserIdProvider)!),
                        invitedAt: Value(DateTime.now()),
                      ));
                      
                      // Send invite email via Supabase Edge Function
                      try {
                        await authService.client.functions.invoke(
                          'send-family-invite',
                          body: {
                            'recipientEmail': email,
                            'inviterName': authService.client.auth.currentUser?.email ?? 'Someone',
                            'budgetName': budget.title,
                          },
                        );
                      } catch (emailError) {
                        debugPrint('Email send failed (invite still created): $emailError');
                      }
                      
                      ref.read(syncEngineProvider).syncAll();
                      ref.invalidate(groupedMembersByBudgetProvider);
                      
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.commonInviteSent(email))),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.commonInviteFailed(e.toString()))),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.send),
                  label: Text(l10n.commonSendInvite),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.accent,
            AppColors.accent.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.family_restroom_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Family Budget',
                      style: AppTypography.titleLarge.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Share expenses with family',
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildFeatureItem(Icons.sync_outlined, 'Real-time sync'),
              const SizedBox(width: 16),
              _buildFeatureItem(Icons.visibility_outlined, 'Shared view'),
              const SizedBox(width: 16),
              _buildFeatureItem(Icons.lock_outline, 'Permissions'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.people_outline_rounded,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No family members yet',
            style: AppTypography.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Invite your family members to share and manage budgets together',
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showInviteSheet(context, ref),
            icon: const Icon(Icons.person_add_outlined),
            label: Text(l10n.familyInviteFirst),
          ),
        ],
      ),
    );
  }

  void _showInviteSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const _InviteMemberSheet(),
    );
  }

  void _showChangeRoleDialog(BuildContext context, WidgetRef ref, BudgetMember member) {
    final l10n = AppLocalizations.of(context)!;
    String selectedRole = member.role;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(l10n.familyChangeRole),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.familyChangeRoleFor(member.memberName ?? member.memberEmail)),
              const SizedBox(height: 16),
              ...['admin', 'member', 'viewer'].map((role) => RadioListTile<String>(
                title: Text(role.toUpperCase()),
                subtitle: Text(_getRoleDescription(role)),
                value: role,
                groupValue: selectedRole,
                onChanged: (v) => setState(() => selectedRole = v!),
              )),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.commonCancel),
            ),
            ElevatedButton(
              onPressed: () async {
                final db = ref.read(databaseProvider);
                await db.updateBudgetMember(BudgetMembersCompanion(
                  id: Value(member.id),
                  budgetId: Value(member.budgetId),
                  memberEmail: Value(member.memberEmail),
                  role: Value(selectedRole),
                  status: Value(member.status),
                ));
                
                // Trigger sync immediately
                try {
                  ref.read(syncEngineProvider).syncBudgetMember(member.id);
                } catch (e) {
                  debugPrint('Sync trigger failed: $e');
                }

                if (context.mounted) {
                  Navigator.pop(context);
                  AppSnackBar.showSuccess(context, 'Role updated');
                }
              },
              child: Text(l10n.commonSave),
            ),
          ],
        ),
      ),
    );
  }

  void _showRemoveMemberDialog(BuildContext context, WidgetRef ref, BudgetMember member) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (c) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_remove_rounded,
                  color: AppColors.danger,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Remove Member?',
                style: AppTypography.titleLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Remove ${member.memberName ?? member.memberEmail} from this budget?',
                style: AppTypography.bodyMedium.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(c),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(l10n.commonCancel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () async {
                        final db = ref.read(databaseProvider);
                        await db.deleteBudgetMember(member.id);
                        
                        // WORKAROUND: Schema lacks isDeleted, so manually delete from cloud to ensure sync
                        try {
                            await authService.client.from('budget_members').delete().eq('id', member.id);
                        } catch (e) { 
                            debugPrint('Delete sync error: $e'); 
                        }

                        if (c.mounted) {
                          Navigator.pop(c);
                          AppSnackBar.showInfo(context, 'Member removed');
                        }
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.danger,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(l10n.commonRemove),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getRoleDescription(String role) {
    switch (role) {
      case 'admin': return 'Can edit budgets and manage members';
      case 'member': return 'Can add expenses and view budgets';
      case 'viewer': return 'Read-only access';
      default: return '';
    }
  }

  void _showHelpDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.familyAboutTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.familyAboutDesc),
            SizedBox(height: 12),
            Text('• Share budgets with family members'),
            Text('• Track expenses together'),
            Text('• Set spending limits per member'),
            Text('• Get real-time notifications'),
            SizedBox(height: 12),
            Text(l10n.familyRolesTitle),
            Text('• Owner: Full control'),
            Text('• Admin: Can edit budgets'),  
            Text('• Member: Can add expenses'),
            Text('• Viewer: Read-only access'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.commonGotIt),
          ),
        ],
      ),
    );
  }

  Widget _buildProPlusFeature(BuildContext context, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.gold),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: AppTypography.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _InviteMemberSheet extends ConsumerStatefulWidget {
  const _InviteMemberSheet();

  @override
  ConsumerState<_InviteMemberSheet> createState() => _InviteMemberSheetState();
}

class _InviteMemberSheetState extends ConsumerState<_InviteMemberSheet> {
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  String _selectedRole = 'member';
  String? _selectedBudgetId;
  bool _isLoading = false;
  bool _showSavedContacts = true;

  final List<Map<String, dynamic>> _roles = [
    {
      'value': 'admin',
      'label': 'Admin',
      'description': 'Can edit budgets and manage members',
      'icon': Icons.admin_panel_settings_outlined,
    },
    {
      'value': 'member',
      'label': 'Member',
      'description': 'Can add expenses and view budgets',
      'icon': Icons.person_outlined,
    },
    {
      'value': 'viewer',
      'label': 'Viewer',
      'description': 'Read-only access to budgets',
      'icon': Icons.visibility_outlined,
    },
  ];

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final budgetsAsync = ref.watch(activeBudgetsProvider);
    // Import saved contacts from profile
    List<dynamic> savedContacts = [];
    try {
      savedContacts = []; // TODO: Implement family contacts provider", "StartLine": 911
    } catch (_) {
      // Provider may not exist if profile screen hasn't been imported
    }

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            Text('Invite Family Member', style: AppTypography.titleLarge),
            const SizedBox(height: 24),

            // Budget Selection
            Text('Select Budget to Share', style: AppTypography.labelLarge),
            const SizedBox(height: 8),
            budgetsAsync.when(
              data: (budgets) {
                if (budgets.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber, color: AppColors.warning),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'You need to create a budget first before inviting members.',
                            style: AppTypography.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                
                return DropdownButtonFormField<String>(
                  initialValue: _selectedBudgetId,
                  decoration: InputDecoration(
                    hintText: 'Choose a budget',
                    prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: budgets.map((b) => DropdownMenuItem(
                    value: b.id,
                    child: Text(b.title, overflow: TextOverflow.ellipsis),
                  )).toList(),
                  onChanged: (v) => setState(() => _selectedBudgetId = v),
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (e, _) => Text('Error loading budgets: $e'),
            ),

            const SizedBox(height: 20),

            // Saved Contacts Section
            if (savedContacts.isNotEmpty) ...[
              Row(
                children: [
                  Text('Choose from Saved Contacts', style: AppTypography.labelLarge),
                  const Spacer(),
                  TextButton(
                    onPressed: () => setState(() => _showSavedContacts = !_showSavedContacts),
                    child: Text(_showSavedContacts ? 'Enter manually' : 'Show saved'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              if (_showSavedContacts) ...[
                SizedBox(
                  height: 80,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: savedContacts.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final contact = savedContacts[index];
                      final isSelected = _emailController.text == contact.email;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _emailController.text = contact.email;
                            _nameController.text = contact.name;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected 
                              ? Theme.of(context).primaryColor.withValues(alpha: 0.15)
                              : Theme.of(context).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected 
                                ? Theme.of(context).primaryColor 
                                : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                                child: Text(
                                  contact.name.isNotEmpty ? contact.name[0].toUpperCase() : '?',
                                  style: TextStyle(
                                    color: Theme.of(context).primaryColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                contact.name,
                                style: AppTypography.labelSmall.copyWith(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ],

            // Manual Entry (always show if no saved contacts or toggle is off)
            if (savedContacts.isEmpty || !_showSavedContacts) ...[
              // Name (optional)
              Text('Name (optional)', style: AppTypography.labelLarge),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'John Doe',
                  prefixIcon: const Icon(Icons.person_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Email - always visible
            Text('Email Address', style: AppTypography.labelLarge),
            const SizedBox(height: 8),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: 'family@example.com',
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),

            const SizedBox(height: 24),

            // Role selection
            Text('Role', style: AppTypography.labelLarge),
            const SizedBox(height: 12),

            ...(_roles.map((role) {
              final isSelected = _selectedRole == role['value'];
              return GestureDetector(
                onTap: () {
                  setState(() => _selectedRole = role['value'] as String);
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Theme.of(context).primaryColor.withValues(alpha: 0.15)
                              : Theme.of(context).dividerColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          role['icon'] as IconData,
                          color: isSelected
                              ? Theme.of(context).primaryColor
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              role['label'] as String,
                              style: AppTypography.titleSmall.copyWith(
                                color: isSelected
                                    ? Theme.of(context).primaryColor
                                    : Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              role['description'] as String,
                              style: AppTypography.bodySmall.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check_circle_rounded,
                          color: Theme.of(context).primaryColor,
                        ),
                    ],
                  ),
                ),
              );
            })),

            const SizedBox(height: 24),

            // Send Invite button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading || _selectedBudgetId == null ? null : _sendInvite,
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Send Invite'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendInvite() async {
    if (_emailController.text.isEmpty) {
      AppSnackBar.showWarning(context, 'Please enter email address');
      return;
    }

    if (_selectedBudgetId == null) {
      AppSnackBar.showWarning(context, 'Please select a budget to share');
      return;
    }

    // Validate email format
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(_emailController.text)) {
      AppSnackBar.showWarning(context, 'Please enter a valid email');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final db = ref.read(databaseProvider);
      final userId = ref.read(currentUserIdProvider);

      // Generate proper UUID
      final memberId = const Uuid().v4();

      await db.insertBudgetMember(BudgetMembersCompanion(
        id: Value(memberId),
        budgetId: Value(_selectedBudgetId!),
        memberEmail: Value(_emailController.text.trim().toLowerCase()),
        memberName: Value(_nameController.text.isNotEmpty ? _nameController.text.trim() : null),
        role: Value(_selectedRole),
        status: const Value('pending'),
        invitedAt: Value(DateTime.now()),
        invitedBy: Value(userId),
      ));

      // Trigger sync immediately
      try {
        ref.read(syncEngineProvider).syncBudgetMember(memberId);
      } catch (e) {
        debugPrint('Sync trigger failed: $e');
      }

      if (mounted) {
        Navigator.pop(context);
        AppSnackBar.showSuccess(context, 'Invite sent successfully!');
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'Error: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

/// Card showing a budget with its members (collapsible)
class _BudgetMembersCard extends StatefulWidget {
  final Budget budget;
  final List<BudgetMember> members;
  final VoidCallback onInvite;
  final void Function(BudgetMember) onChangeRole;
  final void Function(BudgetMember) onRemove;
  
  const _BudgetMembersCard({
    required this.budget,
    required this.members,
    required this.onInvite,
    required this.onChangeRole,
    required this.onRemove,
  });
  
  @override
  State<_BudgetMembersCard> createState() => _BudgetMembersCardState();
}

class _BudgetMembersCardState extends State<_BudgetMembersCard> {
  bool _expanded = true;
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.08),
        ),
        boxShadow: isDark ? null : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header - Budget info with expand/collapse
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Budget icon
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.account_balance_wallet_rounded,
                      color: AppColors.primaryGreen,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Budget title and member count
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.budget.title,
                          style: AppTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${widget.members.length} member${widget.members.length == 1 ? '' : 's'}',
                          style: AppTypography.bodySmall.copyWith(
                            color: Theme.of(context).hintColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Invite button
                  IconButton(
                    icon: const Icon(Icons.person_add_outlined, size: 20),
                    onPressed: widget.onInvite,
                    tooltip: 'Invite member',
                  ),
                  
                  // Expand/collapse arrow
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.keyboard_arrow_down),
                  ),
                ],
              ),
            ),
          ),
          
          // Member list (expandable)
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              children: [
                const Divider(height: 1),
                ...widget.members.map((member) => _MemberRow(
                  member: member,
                  onChangeRole: () => widget.onChangeRole(member),
                  onRemove: () => widget.onRemove(member),
                )),
              ],
            ),
            crossFadeState: _expanded 
                ? CrossFadeState.showSecond 
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  final BudgetMember member;
  final VoidCallback onChangeRole;
  final VoidCallback onRemove;
  
  const _MemberRow({
    required this.member,
    required this.onChangeRole,
    required this.onRemove,
  });
  
  @override
  Widget build(BuildContext context) {
    final isPending = member.status == 'pending';
    final roleColor = member.role == 'editor' 
        ? AppColors.accent 
        : Colors.grey;
    
    return ListTile(
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: isPending ? Colors.orange : roleColor,
        child: Icon(
          isPending ? Icons.hourglass_empty : Icons.person,
          color: Colors.white,
          size: 18,
        ),
      ),
      title: Text(
        member.memberEmail,
        style: const TextStyle(fontSize: 14),
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        isPending ? 'Pending invite' : member.role,
        style: TextStyle(
          fontSize: 12,
          color: isPending ? Colors.orange : null,
        ),
      ),
      trailing: PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert, size: 20),
        itemBuilder: (c) => [
          const PopupMenuItem(value: 'role', child: Text('Change Role')),
          const PopupMenuItem(
            value: 'remove',
            child: Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
        onSelected: (v) {
          if (v == 'role') onChangeRole();
          if (v == 'remove') onRemove();
        },
      ),
    );
  }
}
