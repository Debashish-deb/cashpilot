import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final contactServiceProvider = Provider<ContactService>((ref) {
  return ContactService();
});

final contactsProvider = FutureProvider.autoDispose.family<List<Contact>, String>((ref, query) async {
  final service = ref.watch(contactServiceProvider);
  return service.getContacts(query: query);
});

class ContactService {
  Future<bool> requestPermission() async {
    return await FlutterContacts.requestPermission(readonly: true);
  }

  Future<List<Contact>> getContacts({String? query}) async {
    if (!await FlutterContacts.requestPermission(readonly: true)) {
      return [];
    }

    // Fetch contacts with properties (name, email, phone) but no photo for performance
    final contacts = await FlutterContacts.getContacts(
        withProperties: true, withPhoto: false);

    if (query != null && query.isNotEmpty) {
      final lowerQuery = query.toLowerCase();
      return contacts.where((c) =>
          c.displayName.toLowerCase().contains(lowerQuery) ||
          c.emails.any((e) => e.address.toLowerCase().contains(lowerQuery))
      ).toList();
    }
    
    return contacts;
  }
}
