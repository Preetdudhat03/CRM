
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/lead_model.dart';
import '../models/role_model.dart';
import '../repositories/lead_repository.dart';
import '../services/lead_service.dart';
import 'auth_provider.dart';
import 'notification_provider.dart';
import 'dashboard_provider.dart';

// Service Provider
final leadServiceProvider = Provider<LeadService>((ref) => LeadService());

final leadRepositoryProvider = Provider<LeadRepository>((ref) {
  return LeadRepository(ref.watch(leadServiceProvider));
});


// State Provider for Search Query
final leadSearchQueryProvider = StateProvider<String>((ref) => '');

// State Notifier for Lead List management
class LeadNotifier extends StateNotifier<AsyncValue<List<LeadModel>>> {
  final LeadRepository _repository;
  final Ref _ref;

  int _currentPage = 0;
  final int _pageSize = 20;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  LeadNotifier(this._repository, this._ref) : super(const AsyncValue.loading()) {
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
      final leads = await _repository.getLeads(page: _currentPage, pageSize: _pageSize);
      if (leads.length < _pageSize) _hasMore = false;
      state = AsyncValue.data(leads);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> loadMore() async {
    if (!_hasMore || _isLoadingMore || state is AsyncLoading) return;

    _isLoadingMore = true;
    try {
      _currentPage++;
      final newLeads = await _repository.getLeads(page: _currentPage, pageSize: _pageSize);
      if (newLeads.length < _pageSize) _hasMore = false;
      state.whenData((currentLeads) {
        state = AsyncValue.data([...currentLeads, ...newLeads]);
      });
    } catch (e) {
      _currentPage--;
    } finally {
      _isLoadingMore = false;
    }
  }

  Future<void> refresh() async {
    return loadInitial();
  }

  Future<void> addLead(LeadModel lead) async {
    try {
      final newLead = await _repository.addLead(lead);
      state.whenData((leads) {
        state = AsyncValue.data([...leads, newLead]);
      });

      final currentUser = _ref.read(currentUserProvider);
      final userName = currentUser?.name ?? 'Someone';
      final role = currentUser?.role ?? Role.viewer;
      _ref.read(notificationsProvider.notifier).pushNotificationLocally(
        'New Lead Added',
        '$userName added a new lead: ${newLead.name}',
        relatedEntityId: newLead.id,
        relatedEntityType: 'lead',
        targetRoles: getUpperRanks(role),
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateLead(LeadModel lead) async {
    try {
      await _repository.updateLead(lead);
      
      // Determine if assignedTo changed, or just a general update
      bool isAssigned = lead.assignedTo.isNotEmpty;

      state.whenData((leads) {
        final existingLead = leads.firstWhere((l) => l.id == lead.id, orElse: () => lead);
        
        state = AsyncValue.data([
          for (final l in leads)
            if (l.id == lead.id) lead else l
        ]);

        if (existingLead.assignedTo != lead.assignedTo && isAssigned) {
          final currentUser = _ref.read(currentUserProvider);
          final userName = currentUser?.name ?? 'Someone';
          final role = currentUser?.role ?? Role.viewer;
          _ref.read(notificationsProvider.notifier).pushNotificationLocally(
            'Lead Assigned',
            '$userName assigned the lead ${lead.name} to ${lead.assignedTo}',
            relatedEntityId: lead.id,
            relatedEntityType: 'lead',
            targetRoles: getUpperRanks(role),
          );
        }
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteLead(String id) async {
    try {
      await _repository.deleteLead(id);
      state.whenData((leads) {
        state = AsyncValue.data([
          for (final l in leads)
            if (l.id != id) l
        ]);
      });
    } catch (e) {
      // Handle error
    }
  }
}

// Leads List Provider
final leadsProvider =
    StateNotifierProvider<LeadNotifier, AsyncValue<List<LeadModel>>>((ref) {
  return LeadNotifier(ref.watch(leadRepositoryProvider), ref);
});

// Filtered Leads Provider
final filteredLeadsProvider = Provider<AsyncValue<List<LeadModel>>>((ref) {
  final leadsAsync = ref.watch(leadsProvider);
  final query = ref.watch(leadSearchQueryProvider).toLowerCase();

  return leadsAsync.whenData((leads) {
    if (query.isEmpty) return leads;
    return leads.where((lead) {
      return lead.name.toLowerCase().contains(query) ||
          lead.email.toLowerCase().contains(query) ||
          lead.source.toLowerCase().contains(query);
    }).toList();
  });
});

