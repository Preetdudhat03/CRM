
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/contact_model.dart';
import '../models/role_model.dart';
import '../repositories/contact_repository.dart';
import '../services/contact_service.dart';
import '../services/activity_service.dart';
import 'dashboard_provider.dart';
import 'auth_provider.dart';
import 'notification_provider.dart';

// Service Provider
final contactServiceProvider = Provider<ContactService>((ref) => ContactService());

final contactRepositoryProvider = Provider<ContactRepository>((ref) {
  return ContactRepository(ref.watch(contactServiceProvider));
});

// State Provider for Search Query
final contactSearchQueryProvider = StateProvider<String>((ref) => '');

class ContactNotifier extends StateNotifier<AsyncValue<List<ContactModel>>> {
  final ContactRepository _repository;
  final Ref _ref;

  int _currentPage = 0;
  final int _pageSize = 20;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  ContactNotifier(this._repository, this._ref) : super(const AsyncValue.loading()) {
    loadInitial();
  }

  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;

  Future<void> loadInitial() async {
    _currentPage = 0;
    _hasMore = true;
    _isLoadingMore = false;
    try {
      state = const AsyncValue.loading();
      final contacts = await _repository.getContacts(page: _currentPage, pageSize: _pageSize);
      if (contacts.length < _pageSize) {
        _hasMore = false;
      }
      state = AsyncValue.data(contacts);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> loadMore() async {
    if (!_hasMore || _isLoadingMore || state is AsyncLoading) return;

    _isLoadingMore = true;
    try {
      _currentPage++;
      final newContacts = await _repository.getContacts(page: _currentPage, pageSize: _pageSize);
      if (newContacts.length < _pageSize) {
        _hasMore = false;
      }
      state.whenData((currentContacts) {
        state = AsyncValue.data([...currentContacts, ...newContacts]);
      });
    } catch (e) {
      _currentPage--; // Revert
    } finally {
      _isLoadingMore = false;
    }
  }

  Future<void> refresh() async {
    _currentPage = 0;
    _hasMore = true;
    _isLoadingMore = false;
    try {
      final contacts = await _repository.getContacts(page: _currentPage, pageSize: _pageSize);
      if (contacts.length < _pageSize) _hasMore = false;
      state = AsyncValue.data(contacts);
    } catch (e, stack) {
      if (!state.hasValue) {
        state = AsyncValue.error(e, stack);
      }
    }
  }

  Future<void> addContact(ContactModel contact) async {
    try {
      final newContact = await _repository.addContact(contact);
      state.whenData((contacts) {
        state = AsyncValue.data([...contacts, newContact]);
      });
      
      ActivityService.log(title: 'Created contact: ${newContact.name}', type: 'contact', relatedEntityId: newContact.id);

      final currentUser = _ref.read(currentUserProvider);
      final userName = currentUser?.name ?? 'Someone';
      final role = currentUser?.role ?? Role.viewer;
      _ref.read(notificationsProvider.notifier).pushNotificationLocally(
        'New Contact Created',
        '$userName added a new contact: ${newContact.name}',
        relatedEntityId: newContact.id,
        relatedEntityType: 'contact',
        targetRoles: getUpperRanks(role),
        showOnDevice: false,
      );
    } catch (e) {
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
      ActivityService.log(title: 'Updated contact: ${contact.name}', type: 'contact', relatedEntityId: contact.id);
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
      ActivityService.log(title: 'Deleted a contact', type: 'contact', relatedEntityId: id);
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
  return ContactNotifier(ref.watch(contactRepositoryProvider), ref);
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
