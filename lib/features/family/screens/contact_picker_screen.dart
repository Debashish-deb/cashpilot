import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../ui/widgets/common/cp_buttons.dart';
import '../../../ui/widgets/common/glass_card.dart';
import '../services/contact_service.dart';

class ContactPickerScreen extends ConsumerStatefulWidget {
  const ContactPickerScreen({super.key});

  @override
  ConsumerState<ContactPickerScreen> createState() => _ContactPickerScreenState();
}

class _ContactPickerScreenState extends ConsumerState<ContactPickerScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _permissionDenied = false;

  @override
  void initState() {
    super.initState();
    _checkPermission();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  Future<void> _checkPermission() async {
    final service = ref.read(contactServiceProvider);
    final granted = await service.requestPermission();
    if (mounted) {
      setState(() {
        _permissionDenied = !granted;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Contact'),
        centerTitle: true,
      ),
      body: _permissionDenied
          ? _buildPermissionDeniedState()
          : Column(
              children: [
                _buildSearchBar(),
                Expanded(
                  child: _buildContactList(),
                ),
              ],
            ),
    );
  }

  Widget _buildPermissionDeniedState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: GlassCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.contacts_outlined, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'Permission Required',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const Text(
                'We need access to your contacts to help you invite family members.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              CPButton(
                label: 'Open Settings',
                onTap: () => openAppSettings(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Search contacts...',
            border: InputBorder.none,
            icon: Icon(Icons.search),
          ),
        ),
      ),
    );
  }

  Widget _buildContactList() {
    final contactsAsync = ref.watch(contactsProvider(_searchQuery));

    return contactsAsync.when(
      data: (contacts) {
        if (contacts.isEmpty) {
          return const Center(child: Text('No contacts found'));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: contacts.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final contact = contacts[index];
            return GlassCard(
              onTap: () => context.pop(contact),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  child: Text(
                    contact.displayName.isNotEmpty 
                        ? contact.displayName[0].toUpperCase()
                        : '?',
                    style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer),
                  ),
                ),
                title: Text(contact.displayName),
                subtitle: contact.emails.isNotEmpty 
                    ? Text(contact.emails.first.address)
                    : contact.phones.isNotEmpty 
                        ? Text(contact.phones.first.number)
                        : null,
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }
}
