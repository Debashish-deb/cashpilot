/// Family Member Selector Widget  
/// Email-based invitation system for shared budgets
/// Note: Full family member management requires Pro Plus subscription
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import '../../../features/family/screens/contact_picker_screen.dart';

import '../../../core/providers/app_providers.dart';

class FamilyMemberSelector extends ConsumerStatefulWidget {
  final List<String> selectedMemberIds;
  final List<String> inviteEmails;
  final Function(List<String>) onMembersChanged;
  final Function(List<String>) onEmailsChanged;

  const FamilyMemberSelector({
    super.key,
    required this.selectedMemberIds,
    required this.inviteEmails,
    required this.onMembersChanged,
    required this.onEmailsChanged,
  });

  @override
  ConsumerState<FamilyMemberSelector> createState() => _FamilyMemberSelectorState();
}

class _FamilyMemberSelectorState extends ConsumerState<FamilyMemberSelector> {
  final _emailController = TextEditingController();
  final _emailFocusNode = FocusNode();

  @override
  void dispose() {
    _emailController.dispose();
    _emailFocusNode.dispose();
    super.dispose();
  }

  void _toggleMember(String memberId) {
    final newList = List<String>.from(widget.selectedMemberIds);
    if (newList.contains(memberId)) {
      newList.remove(memberId);
    } else {
      newList.add(memberId);
    }
    widget.onMembersChanged(newList);
  }

  void _addEmail() {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;
    
    // Basic email validation
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid email format')),
      );
      return;
    }

    if (widget.inviteEmails.contains(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email already added')),
      );
      return;
    }

    final newList = List<String>.from(widget.inviteEmails)..add(email);
    widget.onEmailsChanged(newList);
    _emailController.clear();
  }

  void _removeEmail(String email) {
    final newList = List<String>.from(widget.inviteEmails)..remove(email);
    widget.onEmailsChanged(newList);
  }

  // Helper method to build the family members section
  Widget _buildFamilyMembersSection(BuildContext context, WidgetRef ref) {
    // Load real family members from Supabase
    final authService = ref.watch(authServiceProvider);
    final currentUserId = authService.currentUser?.id;
    
    if (currentUserId == null) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _loadFamilyMembers(authService.client, currentUserId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final members = snapshot.data ?? [];
        
        if (members.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Text(
              'Family Members',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: members.map((member) {
                final memberName = member['name'] as String? ?? 'Unknown';
                final memberEmail = member['email'] as String? ?? '';
                final memberId = member['id'] as String;
                final isSelected = widget.selectedMemberIds.contains(memberId); // Changed from selectedMembers

                return _MemberChip(
                  name: memberName,
                  email: memberEmail,
                  isSelected: isSelected,
                  onTap: () {
                    _toggleMember(memberId); // Use existing _toggleMember method
                  },
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }

  /// Load family members from Supabase profiles table
  Future<List<Map<String, dynamic>>> _loadFamilyMembers(
    SupabaseClient client,
    String currentUserId,
  ) async {
    try {
      final response = await client
          .from('profiles')
          .select('id, name, email')
          .eq('family_head_id', currentUserId)
          .limit(10);

      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      debugPrint('Error loading family members: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Removed the old FutureBuilder for family members and replaced with _buildFamilyMembersSection call
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildFamilyMembersSection(context, ref), // Call the new helper method here
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _emailController,
                  focusNode: _emailFocusNode,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'Invite by email',
                    prefixIcon: const Icon(Icons.email_outlined, size: 20),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.contacts_outlined, size: 20),
                      onPressed: () async {
                        final contact = await Navigator.push<Contact>(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ContactPickerScreen(),
                          ),
                        );
                        if (contact != null && contact.emails.isNotEmpty) {
                          _emailController.text = contact.emails.first.address;
                        }
                      },
                    ),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    isDense: true,
                  ),
                  onSubmitted: (_) => _addEmail(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _addEmail,
                icon: const Icon(Icons.add, size: 20),
                style: IconButton.styleFrom(
                  minimumSize: const Size(44, 44),
                ),
              ),
            ],
          ),

          // Pending invites
          if (widget.inviteEmails.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.inviteEmails.map((email) {
                return Chip(
                  avatar: CircleAvatar(
                    backgroundColor: theme.colorScheme.secondaryContainer,
                    child: Icon(
                      Icons.mail_outline,
                      size: 16,
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                  ),
                  label: Text(
                    email,
                    style: const TextStyle(fontSize: 13),
                  ),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () => _removeEmail(email),
                  backgroundColor: theme.colorScheme.secondaryContainer.withValues(alpha: 0.3),
                  side: BorderSide.none,
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _MemberChip extends StatelessWidget {
  final String name;
  final String email;
  final bool isSelected;
  final VoidCallback onTap;

  const _MemberChip({
    required this.name,
    required this.email,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary.withValues(alpha: 0.5)
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.surfaceContainerHighest,
              child: Text(
                name[0].toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? theme.colorScheme.onPrimaryContainer
                        : theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  email,
                  style: TextStyle(
                    fontSize: 11,
                    color: isSelected
                        ? theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.7)
                        : theme.textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.check_circle,
                size: 18,
                color: theme.colorScheme.primary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
