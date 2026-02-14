
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/contact_model.dart';
import '../services/contact_service.dart';

// Service Provider
final contactServiceProvider = Provider<ContactService>((ref) => ContactService());

// State Provider for Search Query
final contactSearchQueryProvider = StateProvider<String>((ref) => '');

// State Notifier for Contact List management
class ContactNotifier extends StateNotifier<AsyncValue<List<ContactModel>>> {
  final ContactService _contactService;

  ContactNotifier(this._contactService) : super(const AsyncValue.loading()) {
    getContacts();
  }

  Future<void> getContacts() async {
    try {
      state = const AsyncValue.loading();
      final contacts = await _contactService.getContacts();
      state = AsyncValue.data(contacts);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addContact(ContactModel contact) async {
    try {
      final newContact = await _contactService.addContact(contact);
      state.whenData((contacts) {
        state = AsyncValue.data([...contacts, newContact]);
      });
    } catch (e) {
      // Handle or propagate error
      rethrow;
    }
  }

  Future<void> updateContact(ContactModel contact) async {
    try {
      await _contactService.updateContact(contact);
      state.whenData((contacts) {
        state = AsyncValue.data([
          for (final c in contacts)
            if (c.id == contact.id) contact else c
        ]);
      });
    } catch (e) {
      // Handle error
    }
  }

  Future<void> deleteContact(String id) async {
    try {
      await _contactService.deleteContact(id);
      state.whenData((contacts) {
        state = AsyncValue.data([
          for (final c in contacts)
            if (c.id != id) c
        ]);
      });
    } catch (e) {
      // Handle error
    }
  }
}

// Contacts List Provider
final contactsProvider =
    StateNotifierProvider<ContactNotifier, AsyncValue<List<ContactModel>>>((ref) {
  return ContactNotifier(ref.watch(contactServiceProvider));
});

// Filtered Contacts Provider
final filteredContactsProvider = Provider<AsyncValue<List<ContactModel>>>((ref) {
  final contactsAsync = ref.watch(contactsProvider);
  final query = ref.watch(contactSearchQueryProvider).toLowerCase();

  return contactsAsync.whenData((contacts) {
    if (query.isEmpty) return contacts;
    return contacts.where((contact) {
      return contact.name.toLowerCase().contains(query) ||
          contact.email.toLowerCase().contains(query) ||
          contact.company.toLowerCase().contains(query);
    }).toList();
  });
});
