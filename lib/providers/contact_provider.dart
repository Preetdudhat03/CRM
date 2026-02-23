
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/contact_model.dart';
import '../repositories/contact_repository.dart';
import '../services/contact_service.dart';
import 'dashboard_provider.dart';

// Service Provider
final contactServiceProvider = Provider<ContactService>((ref) => ContactService());

final contactRepositoryProvider = Provider<ContactRepository>((ref) {
  return ContactRepository(ref.watch(contactServiceProvider));
});

// State Provider for Search Query
final contactSearchQueryProvider = StateProvider<String>((ref) => '');

// State Notifier for Contact List management
class ContactNotifier extends StateNotifier<AsyncValue<List<ContactModel>>> {
  final ContactRepository _repository;

  ContactNotifier(this._repository) : super(const AsyncValue.loading()) {
    getContacts();
  }

  Future<void> getContacts() async {
    try {
      state = const AsyncValue.loading();
      final contacts = await _repository.getContacts();
      state = AsyncValue.data(contacts);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addContact(ContactModel contact) async {
    try {
      final newContact = await _repository.addContact(contact);
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
      await _repository.updateContact(contact);
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
      await _repository.deleteContact(id);
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

  Future<void> toggleFavorite(String id, bool currentStatus) async {
    try {
      await _repository.toggleFavorite(id, currentStatus);
      state.whenData((contacts) {
        state = AsyncValue.data([
          for (final c in contacts)
            if (c.id == id) c.copyWith(isFavorite: !currentStatus) else c
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
  return ContactNotifier(ref.watch(contactRepositoryProvider));
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
// Dashboard Stats Provider
final contactStatsProvider = Provider<AsyncValue<Map<String, dynamic>>>((ref) {
  final contactsAsync = ref.watch(contactsProvider);
  final period = ref.watch(dashboardPeriodProvider);

  return contactsAsync.whenData((contacts) {
    int totalContacts = contacts.length;
    int leads = contacts.where((c) => c.status == ContactStatus.lead).length;
    int customers = contacts.where((c) => c.status == ContactStatus.customer).length;
    
    final currentPeriodContacts = contacts.where((c) => c.createdAt.isAfter(period.startDate)).length;
    final previousPeriodContacts = contacts.where((c) => 
      c.createdAt.isAfter(period.previousPeriodStartDate) && 
      c.createdAt.isBefore(period.previousPeriodEndDate)
    ).length;
    
    final trendData = calculateTrend(currentPeriodContacts, previousPeriodContacts);

    return {
      'total': totalContacts,
      'leads': leads,
      'customers': customers,
      'trendPercentage': trendData['trend'],
      'isUpTrend': trendData['isUp'],
    };
  });
});
